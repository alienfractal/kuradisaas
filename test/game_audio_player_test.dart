import 'dart:async';

import 'package:kuradi_saased/audio/game_sounds.dart';
import 'package:kuradi_saased/audio/game_audio_player.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePool implements AudioPool {
  @override
  final Map<String, AudioPlayer> currentPlayers = {};
  int starts = 0;
  int disposals = 0;
  bool failStart = false;
  Completer<StopFunction>? pendingStart;
  @override
  Future<StopFunction> start({double volume = 1}) async {
    starts++;
    if (failStart) throw StateError('backend refused start');
    if (pendingStart != null) return pendingStart!.future;
    return () async {};
  }

  @override
  Future<void> dispose() async {
    disposals++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeOneShot implements AudioPlayer {
  @override
  double playbackRate = 1;
  Completer<void>? pendingRate;
  @override
  Future<void> setPlaybackRate(double value) async {
    playbackRate = value;
    await pendingRate?.future;
  }

  final completed = StreamController<void>.broadcast();
  int disposals = 0;
  @override
  double volume = 1;
  @override
  Future<void> setVolume(double value) async {
    volume = value;
  }

  @override
  Stream<void> get onPlayerComplete => completed.stream;
  @override
  PlayerState state = PlayerState.playing;
  @override
  Future<void> dispose() async {
    disposals++;
    await completed.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  test('attack and hurt are included in preloaded effects', () {
    expect(GameSounds.effects, contains(GameSounds.attack));
    expect(GameSounds.effects, contains(GameSounds.hurt));
  });

  test('repeated and overlapping effects reuse the prepared pool', () async {
    final pool = FakePool();
    var creations = 0;
    var coldStarts = 0;
    final audio = GameAudioPlayer(
        useAudioPools: true,
        createSfxPool: (_) async {
          creations++;
          return pool;
        },
        startDirectSfx: (_, __) async {
          coldStarts++;
          return FakeOneShot();
        });
    await audio.initSfxPool(['hit', 'hit']);
    await audio.initSfxPool(['hit']);
    for (var i = 0; i < 20; i++) {
      audio.playSoundFx('hit');
    }
    await flush();
    expect(creations, 1);
    expect(
        pool.starts, 20); // no sound completion was needed for the next request
    expect(coldStarts, 0);
    await audio.dispose();
    expect(pool.disposals, 1);
  });

  test('a pointer gesture does not play a cascade of warm-up effects',
      () async {
    final pool = FakePool();
    final audio =
        GameAudioPlayer(useAudioPools: true, createSfxPool: (_) async => pool);
    await audio.initSfxPool([GameSounds.impact]);
    audio.notifyUserGesture();
    await flush();
    expect(pool.starts, 0);
    await audio.dispose();
  });

  test('pool failures fall back and direct players are disposed on completion',
      () async {
    final pool = FakePool()..failStart = true;
    final player = FakeOneShot();
    var directStarts = 0;
    final audio = GameAudioPlayer(
        useAudioPools: true,
        createSfxPool: (_) async => pool,
        startDirectSfx: (_, __) async {
          directStarts++;
          return player;
        });
    await audio.initSfxPool(['hit']);
    audio.playSoundFx('hit');
    await flush();
    expect(directStarts, 1);
    player.completed.add(null);
    await flush();
    expect(player.disposals, 1);
    await audio.dispose();
    expect(player.disposals, 1);
  });

  test('disposing during a pending one-shot start releases its eventual player',
      () async {
    final start = Completer<AudioPlayer>();
    final player = FakeOneShot();
    final audio = GameAudioPlayer(
        useAudioPools: false, startDirectSfx: (_, __) => start.future);
    audio.playSoundFx('hit');
    await audio.dispose();
    start.complete(player);
    await flush();
    expect(player.disposals, 1);
  });

  test('a failed effect pool is retired instead of retried for every pickup',
      () async {
    final pool = FakePool()..failStart = true;
    final players = <FakeOneShot>[];
    final audio = GameAudioPlayer(
      useAudioPools: true,
      createSfxPool: (_) async => pool,
      startDirectSfx: (_, __) async {
        final player = FakeOneShot();
        players.add(player);
        return player;
      },
    );
    await audio.initSfxPool([GameSounds.jump]);
    audio.playSoundFx(GameSounds.jump);
    await flush();
    audio.playSoundFx(GameSounds.jump);
    await flush();
    expect(pool.starts, 1);
    expect(pool.disposals, 1);
    expect(players, hasLength(2));
    await audio.dispose();
    expect(players.every((player) => player.disposals == 1), isTrue);
  });

  test('a stalled effect pool times out and late playback is stopped',
      () async {
    final pending = Completer<StopFunction>();
    final pool = FakePool()..pendingStart = pending;
    final players = <FakeOneShot>[];
    final audio = GameAudioPlayer(
      useAudioPools: true,
      createSfxPool: (_) async => pool,
      startDirectSfx: (_, __) async {
        final player = FakeOneShot();
        players.add(player);
        return player;
      },
    );
    await audio.initSfxPool([GameSounds.jump]);
    audio.playSoundFx(GameSounds.jump);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(players, hasLength(1));
    audio.playSoundFx(GameSounds.jump);
    await flush();
    expect(pool.starts, 1);
    expect(players, hasLength(2));
    var lateStops = 0;
    pending.complete(() async {
      lateStops++;
    });
    await flush();
    expect(lateStops, 1);
    expect(pool.disposals, greaterThanOrEqualTo(1));
    await audio.dispose();
  });

  test('disposing during a stalled pool start prevents fallback playback',
      () async {
    final pending = Completer<StopFunction>();
    final pool = FakePool()..pendingStart = pending;
    var directStarts = 0;
    final audio = GameAudioPlayer(
      useAudioPools: true,
      createSfxPool: (_) async => pool,
      startDirectSfx: (_, __) async {
        directStarts++;
        return FakeOneShot();
      },
    );
    await audio.initSfxPool(['coin']);
    audio.playSoundFx('coin');
    await audio.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(directStarts, 0);
    var stops = 0;
    pending.complete(() async {
      stops++;
    });
    await flush();
    expect(stops, 1);
  });

  test('a pooled start that succeeds after disposal is stopped immediately',
      () async {
    final pending = Completer<StopFunction>();
    final pool = FakePool()..pendingStart = pending;
    final audio =
        GameAudioPlayer(useAudioPools: true, createSfxPool: (_) async => pool);
    await audio.initSfxPool(['coin']);
    audio.playSoundFx('coin');
    await audio.dispose();
    var stops = 0;
    pending.complete(() async {
      stops++;
    });
    await flush();
    expect(stops, 1);
  });

  test('audio pools belong to their game instance', () async {
    final firstPool = FakePool();
    final secondPool = FakePool();
    final first = GameAudioPlayer(
        useAudioPools: true, createSfxPool: (_) async => firstPool);
    final second = GameAudioPlayer(
        useAudioPools: true, createSfxPool: (_) async => secondPool);
    await first.initSfxPool(['hit']);
    await second.initSfxPool(['hit']);
    await first.dispose();
    second.playSoundFx('hit');
    await flush();
    expect(firstPool.disposals, 1);
    expect(secondPool.disposals, 0);
    expect(secondPool.starts, 1);
    await second.dispose();
  });
  test('music and walking loop independently with explicit release modes',
      () async {
    final players = <FakeOneShot>[];
    final requests = <(String, bool, double)>[];
    final audio = GameAudioPlayer(
        useAudioPools: false,
        startChannel: (path, loop, volume) async {
          requests.add((path, loop, volume));
          final player = FakeOneShot();
          players.add(player);
          return player;
        });
    await audio.playMusic(GameSounds.logo);
    await audio.playWalking(GameSounds.walk);
    expect(requests[0].$2, isFalse);
    expect(requests[1].$2, isTrue);
    expect(players[0].playbackRate, 1);
    expect(players[1].playbackRate, GameSounds.walkPlaybackRate);
    await audio.stopWalking();
    expect(players[1].disposals, 1);
    expect(players[0].disposals, 0);
    await audio.playMusic(GameSounds.lore, loop: true);
    expect(players[0].disposals, 1);
    expect(requests.last.$2, isTrue);
    await audio.dispose();
    await audio.dispose();
    expect(players.last.disposals, 1);
  });

  test('stopping while walking rate is applied releases the late player',
      () async {
    final rateApplied = Completer<void>();
    final player = FakeOneShot()..pendingRate = rateApplied;
    final audio = GameAudioPlayer(
        useAudioPools: false, startChannel: (_, __, ___) async => player);
    final playback = audio.playWalking(GameSounds.walk);
    await flush();
    expect(player.playbackRate, GameSounds.walkPlaybackRate);
    await audio.stopWalking();
    rateApplied.complete();
    await playback;
    expect(player.disposals, 1);
    await audio.dispose();
    expect(player.disposals, 1);
  });

  test('leaving a screen releases late music and walking starts', () async {
    final pending = <Completer<AudioPlayer>>[];
    final audio = GameAudioPlayer(
        useAudioPools: false,
        startChannel: (_, __, ___) {
          final completer = Completer<AudioPlayer>();
          pending.add(completer);
          return completer.future;
        });
    final music = audio.playMusic(GameSounds.lore, loop: true);
    final walking = audio.playWalking(GameSounds.walk);
    await audio.stopMusic();
    await audio.stopWalking();
    final musicPlayer = FakeOneShot(), walkingPlayer = FakeOneShot();
    pending[0].complete(musicPlayer);
    pending[1].complete(walkingPlayer);
    await Future.wait([music, walking]);
    expect(musicPlayer.disposals, 1);
    expect(walkingPlayer.disposals, 1);
    audio.notifyUserGesture();
    await flush();
    expect(pending, hasLength(2));
    await audio.dispose();
  });

  test('only the current autoplay-blocked music retries on a gesture',
      () async {
    var starts = 0;
    final players = <FakeOneShot>[];
    final audio = GameAudioPlayer(
        useAudioPools: false,
        startChannel: (_, __, ___) async {
          starts++;
          if (starts.isOdd) {
            throw StateError('NotAllowedError: user gesture required');
          }
          final player = FakeOneShot();
          players.add(player);
          return player;
        });
    await audio.playMusic(GameSounds.logo);
    audio.notifyUserGesture();
    await flush();
    expect(starts, 2);
    await audio.playMusic(GameSounds.lore, loop: true);
    expect(starts, 3);
    await audio.stopMusic();
    audio.notifyUserGesture();
    await flush();
    expect(starts, 3); // A previous Lore request cannot revive after Back.
    await audio.dispose();
    expect(players.single.disposals, 1);
  });

  test('stopping SFX invalidates direct and pooled starts still in flight',
      () async {
    final pendingPool = Completer<StopFunction>();
    final pool = FakePool()..pendingStart = pendingPool;
    final pendingDirect = Completer<AudioPlayer>();
    final direct = FakeOneShot();
    final audio = GameAudioPlayer(
        useAudioPools: true,
        createSfxPool: (_) async => pool,
        startDirectSfx: (_, __) => pendingDirect.future);
    await audio.initSfxPool(['hit']);
    audio.playSoundFx('hit');
    audio.playSoundFx('missing');
    await audio.stopSfx();
    var stops = 0;
    pendingPool.complete(() async {
      stops++;
    });
    pendingDirect.complete(direct);
    await flush();
    expect(stops, 1);
    expect(direct.disposals, 1);
    await audio.dispose();
  });
  test('web channels defer context creation until the first gesture', () async {
    var starts = 0;
    final channel = PlaybackChannel((_, __, ___) async {
      starts++;
      return FakeOneShot();
    }, deferUntilGesture: true);
    await channel.play(GameSounds.logo, loop: false, volume: 1);
    expect(starts, 0);
    channel.retryFromGesture();
    await flush();
    expect(starts, 1);
    channel.retryFromGesture();
    await flush();
    expect(starts, 1);
    await channel.stop();
    final cancelled = PlaybackChannel((_, __, ___) async {
      starts++;
      return FakeOneShot();
    }, deferUntilGesture: true);
    await cancelled.play(GameSounds.lore, loop: true, volume: 1);
    await cancelled.stop();
    cancelled.retryFromGesture();
    await flush();
    expect(starts, 1);
  });
  test('volume controls update current music and walking without restarting',
      () async {
    final channels = <FakeOneShot>[];
    final startVolumes = <double>[];
    final audio = GameAudioPlayer(
        useAudioPools: false,
        startChannel: (_, __, volume) async {
          startVolumes.add(volume);
          final player = FakeOneShot();
          channels.add(player);
          return player;
        });
    await audio.playMusic(GameSounds.lore, loop: true);
    expect(startVolumes.single, closeTo(1 / 6, .0001));
    await audio.playWalking(GameSounds.walk);
    await audio.setMusicVolume(0);
    expect(channels[0].volume, 0);
    await audio.setMusicVolume(.33);
    expect(channels[0].volume, closeTo(.165, .0001));
    await audio.setSoundFxVolume(.33);
    expect(channels[1].volume, closeTo(.165, .0001));
    expect(channels, hasLength(2));
    expect(channels[0].disposals, 0);
    expect(channels[1].disposals, 0);
    await audio.playMusic(GameSounds.logo);
    expect(startVolumes.last, .33);
    await audio.dispose();
  });

  test('volume change during channel preparation uses the latest value',
      () async {
    final pending = Completer<AudioPlayer>();
    final audio = GameAudioPlayer(
        useAudioPools: false, startChannel: (_, __, ___) => pending.future);
    final playback = audio.playMusic(GameSounds.lore, loop: true);
    await audio.setMusicVolume(0);
    final player = FakeOneShot();
    pending.complete(player);
    await playback;
    expect(player.volume, 0);
    await audio.dispose();
  });
}
