// Adapted from coolorburn_pixel_warnings/lib/utils/flame_audio_player.dart.
// Retains its tested pool timeout/retirement, direct fallback and late cleanup.
// Kuradi adds per-instance caching, real music/walk loops and cancellation.
import 'dart:async';

import 'audio_player_wrapper.dart';
import 'game_sounds.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

class GameAudioPlayer extends AudioPlayerWrapper {
  static const bool verboseAudioLogs = false;
  final Map<String, AudioPool> _audioPools = {};
  final Set<String> _failedPoolPaths = {};
  static const Duration _poolInitTimeout = Duration(seconds: 3);
  static const Duration _poolStartTimeout = Duration(seconds: 1);
  final AudioCache _cache = AudioCache(prefix: '');
  late final PlaybackChannel _music;
  late final PlaybackChannel _walking;
  final Set<StopFunction> _poolStops = {};
  int _sfxGeneration = 0;
  final bool useAudioPools;
  late final Future<AudioPool> Function(String) _createSfxPool;
  late final Future<AudioPlayer> Function(String, double) _startDirectSfx;
  final Set<AudioPlayer> _directPlayers = {};
  final Map<AudioPlayer, StreamSubscription<void>> _directSubscriptions = {};
  bool _disposed = false;
  int _sfxRequestId = 0;

  double soundFxVolume = 1.0;
  double musicVolume = 1 / 3;
  double _musicTrackGain = 1;

  GameAudioPlayer(
      {this.useAudioPools = true,
      Future<AudioPool> Function(String)? createSfxPool,
      Future<AudioPlayer> Function(String, double)? startDirectSfx,
      Future<AudioPlayer> Function(String, bool, double)? startChannel}) {
    _createSfxPool = createSfxPool ??
        (path) => AudioPool.create(
            source: AssetSource(path),
            audioCache: _cache,
            minPlayers: 1,
            maxPlayers: 5);
    _startDirectSfx =
        startDirectSfx ?? (path, volume) => _startPlayer(path, false, volume);
    final channel = startChannel ?? _startPlayer;
    _music = PlaybackChannel(channel, deferUntilGesture: kIsWeb);
    _walking = PlaybackChannel(channel,
        deferUntilGesture: kIsWeb, playbackRate: GameSounds.walkPlaybackRate);
  }

  Future<AudioPlayer> _startPlayer(
      String path, bool loop, double volume) async {
    final player = AudioPlayer()..audioCache = _cache;
    try {
      await player
          .setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.release);
      await player.play(AssetSource(path), volume: volume);
      return player;
    } catch (_) {
      await player.dispose();
      rethrow;
    }
  }

  // Initialize an AudioPool for a given sound
  @override
  Future<void> initSfxPool(List<String> soundPaths) async {
    if (_disposed) return;
    if (!useAudioPools) {
      _log('preload skipped: direct SFX playback enabled');
      return;
    }

    final uniqueSoundPaths = soundPaths.toSet();
    _log('preload start: ${uniqueSoundPaths.length} pooled sounds');
    for (var path in uniqueSoundPaths) {
      if (!_audioPools.containsKey(path)) {
        try {
          final creation = _createSfxPool(path);
          late AudioPool pool;
          try {
            pool = await creation.timeout(_poolInitTimeout);
          } catch (_) {
            // A timeout doesn't cancel creation; release a late result too.
            unawaited(creation.then((latePool) => latePool.dispose(),
                onError: (Object _, StackTrace __) {}));
            rethrow;
          }
          if (_disposed) {
            await pool.dispose();
            return;
          }
          _audioPools[path] = pool;
          _failedPoolPaths.remove(path);
          _log('pool ready: $path');
        } catch (e) {
          _failedPoolPaths.add(path);
          _log('pool failed: $path -> $e');
        }
      }
    }
    _log(
      'preload done: pools=${_audioPools.length}, '
      'failed=${_failedPoolPaths.length}',
    );
  }

  // Play a sound effect
  @override
  void playSoundFx(String path) {
    if (_disposed || soundFxVolume <= 0) return;
    final requestId = ++_sfxRequestId;
    final generation = _sfxGeneration;
    if (!useAudioPools) {
      unawaited(_playDirectSoundFx(path, requestId, generation));
      return;
    }

    if (_audioPools.containsKey(path)) {
      unawaited(_playPooledSoundFx(path, requestId, generation));
    } else {
      if (_failedPoolPaths.add(path)) {
        _log("pool missing: $path; using direct play");
      }
      unawaited(_playDirectSoundFx(path, requestId, generation));
    }
  }

  Future<void> _playPooledSoundFx(
      String path, int requestId, int generation) async {
    final pool = _audioPools[path];
    if (pool == null) {
      if (!_disposed && generation == _sfxGeneration) {
        await _playDirectSoundFx(path, requestId, generation);
      }
      return;
    }
    final timer = Stopwatch()..start();
    try {
      _log('SFX #$requestId pooled request: $path volume=$soundFxVolume');
      final start = pool.start(volume: soundFxVolume);
      try {
        final stop = await start.timeout(_poolStartTimeout);
        if (_disposed || generation != _sfxGeneration) {
          await stop();
          if (_disposed) await _disposeFailedPool(pool);
          return;
        }
        _poolStops.add(stop);
      } on TimeoutException {
        // A timeout does not cancel a backend start. Ask any late result to
        // stop immediately, then release its player back through the pool.
        unawaited(start.then<void>((stop) async {
          try {
            await stop();
          } finally {
            await _disposeFailedPool(pool);
          }
        }, onError: (Object _, StackTrace __) {}).catchError((Object error) =>
            _log('late pooled start cleanup failed: $error')));
        rethrow;
      }
      _log(
          'SFX #$requestId start acknowledged after ${timer.elapsedMilliseconds}ms: $path');
    } catch (e) {
      _failedPoolPaths.add(path);
      // Retire the failed pool. Retrying it can keep every later request for
      // this effect behind the same stuck AudioPool lock.
      if (identical(_audioPools[path], pool)) {
        _audioPools.remove(path);
        unawaited(_disposeFailedPool(pool));
      }
      _log('SFX #$requestId pool retired: $path -> $e; using direct play');
      if (!_disposed && generation == _sfxGeneration) {
        await _playDirectSoundFx(path, requestId, generation);
      }
    }
  }

  Future<void> _disposeFailedPool(AudioPool pool) async {
    try {
      await pool.dispose();
    } catch (error) {
      _log('failed pool disposal: $error');
    }
  }

  Future<void> _playDirectSoundFx(
      String path, int requestId, int generation) async {
    final timer = Stopwatch()..start();
    try {
      _log(
          'SFX #$requestId direct fallback request: $path volume=$soundFxVolume');
      final requestedVolume = soundFxVolume;
      final player = await _startDirectSfx(path, requestedVolume);
      if (_disposed || generation != _sfxGeneration) {
        await player.dispose();
        return;
      }
      if (requestedVolume != soundFxVolume) {
        await player.setVolume(soundFxVolume);
      }
      _directPlayers.add(player);
      _directSubscriptions[player] = player.onPlayerComplete.listen((_) {
        unawaited(_releaseDirectPlayer(player));
      }, onError: (Object error, StackTrace stack) {
        _log('SFX #$requestId stream failure: $path -> $error');
        unawaited(_releaseDirectPlayer(player));
      });
      if (player.state == PlayerState.completed) {
        await _releaseDirectPlayer(player);
      }
      _log(
          'SFX #$requestId start acknowledged after ${timer.elapsedMilliseconds}ms: $path');
    } catch (e) {
      _log("play direct failed: $path -> $e");
    }
  }

  Future<void> _releaseDirectPlayer(AudioPlayer player) async {
    if (!_directPlayers.remove(player)) return;
    await _directSubscriptions.remove(player)?.cancel();
    await player.dispose();
  }

  @override
  Future<void> playMusic(String path, {bool loop = false}) {
    if (_disposed) return Future.value();
    // Balance the louder Lore recording beneath the user's music setting.
    _musicTrackGain = path == GameSounds.lore ? .5 : 1;
    return _music.play(path, loop: loop, volume: musicVolume * _musicTrackGain);
  }

  @override
  Future<void> setMusicVolume(double volume) async {
    musicVolume = volume.clamp(0.0, 1.0);
    await _music.setVolume(musicVolume * _musicTrackGain);
  }

  @override
  Future<void> setSoundFxVolume(double volume) async {
    soundFxVolume = volume.clamp(0.0, 1.0);
    await _walking.setVolume(.5 * soundFxVolume);
    // Changing SFX level stops short voices already in flight. New voices use
    // the new gain; this also invalidates pending starts without pool internals.
    await stopSfx();
  }

  @override
  Future<void> stopMusic() => _music.stop();

  @override
  Future<void> playWalking(String path) => _disposed
      ? Future.value()
      : _walking.play(path, loop: true, volume: .5 * soundFxVolume);

  @override
  Future<void> stopWalking() => _walking.stop();

  @override
  Future<void> stopSfx() async {
    _sfxGeneration++;
    final stops = _poolStops.toList();
    _poolStops.clear();
    await Future.wait(stops.map((stop) async {
      try {
        await stop();
      } catch (error) {
        _log('SFX stop failed: $error');
      }
    }));
    await Future.wait(_directPlayers.toList().map(_releaseDirectPlayer));
  }

  @override
  void notifyUserGesture() {
    if (_disposed) return;
    _music.retryFromGesture();
    _walking.retryFromGesture();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await Future.wait([_music.stop(), _walking.stop(), stopSfx()]);
    for (final pool in _audioPools.values) {
      await pool.dispose();
    }
    _audioPools.clear();
    await _cache.clearAll();
  }

  static void _log(String message) {
    if (verboseAudioLogs) debugPrint('GameAudioPlayer: $message');
  }
}

/// Generation checks release late starts and prevent old music resuming after
/// leaving Lore, pausing, or disposing. Only blocked current tracks are retried.
class PlaybackChannel {
  PlaybackChannel(this.start,
      {bool deferUntilGesture = false, this.playbackRate = 1})
      : _gestureReady = !deferUntilGesture;
  final double playbackRate;
  bool _gestureReady;
  final Future<AudioPlayer> Function(String, bool, double) start;
  AudioPlayer? _player;
  int _generation = 0;
  String? _path;
  bool _loop = false;
  double _volume = 1;
  bool _pending = false;

  Future<void> play(String path,
      {required bool loop, required double volume}) async {
    final generation = ++_generation;
    _path = path;
    _loop = loop;
    _volume = volume;
    _pending = false;
    final previous = _player;
    _player = null;
    if (previous != null) await _disposePlayer(previous);
    if (generation != _generation) return;
    // Creating/resuming a browser AudioContext before a gesture can leave a
    // future suspended instead of throwing NotAllowedError. Defer that start.
    if (!_gestureReady) {
      _pending = true;
      return;
    }
    AudioPlayer? startedPlayer;
    try {
      final player = startedPlayer = await start(path, loop, volume);
      if (generation != _generation) {
        await _disposePlayer(player);
        return;
      }
      if (playbackRate != 1) await player.setPlaybackRate(playbackRate);
      if (volume != _volume) await player.setVolume(_volume);
      // stop/replacement may occur while the backend applies rate or volume.
      if (generation != _generation) {
        await _disposePlayer(player);
        return;
      }
      _player = player;
    } catch (error) {
      if (startedPlayer != null) await _disposePlayer(startedPlayer);
      if (generation != _generation) return;
      final message = error.toString().toLowerCase();
      _pending = message.contains('notallowed') ||
          message.contains('user gesture') ||
          message.contains('user interaction') ||
          message.contains('interact with');
      if (!_pending) {
        debugPrint('GameAudioPlayer channel failed: $path: $error');
      }
    }
  }

  Future<void> setVolume(double value) async {
    _volume = value.clamp(0.0, 1.0);
    await _player?.setVolume(_volume);
  }

  Future<void> stop() async {
    _generation++;
    _path = null;
    _pending = false;
    final player = _player;
    _player = null;
    if (player != null) await _disposePlayer(player);
  }

  Future<void> _disposePlayer(AudioPlayer player) async {
    try {
      await player.dispose();
    } catch (error) {
      debugPrint('GameAudioPlayer channel disposal failed: $error');
    }
  }

  void retryFromGesture() {
    _gestureReady = true;
    final path = _path;
    if (_pending && path != null) {
      unawaited(play(path, loop: _loop, volume: _volume));
    }
  }
}
