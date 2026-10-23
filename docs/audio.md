# Audio ownership and verification

The source reused here is `coolorburn_pixel_warnings/lib/utils/flame_audio_player.dart`
in the parent workspace, rather than the older `coolorburn/lib/utils/audio_player.dart`
checkout. Its pool regression tests were ported with the implementation. The
obsolete FlutterSound-based WebAudioPlayer is not used.

The pinned dependencies match that tested copy: Flame Audio 2.10.3 and
Audioplayers 6.1.0. The resolved web backend is Audioplayers Web 5.2.1. The same
adapter supports web and native platforms; Kuradi currently has a web runner.

## Files

- `lib/audio/audio_player_wrapper.dart`: injectable backend contract and explicit
  silent implementation for headless tests.
- `lib/audio/game_audio_player.dart`: the adapted pool/fallback backend, independent
  music/walk channels, gesture retry, cancellation and disposal.
- `lib/audio/game_sounds.dart`: asset mapping.
- `lib/audio/game_audio_service.dart`: game/menu events to audio requests.
- `lib/game/states/arena/model/combat_event.dart`: pure simulation facts.

Each game instance owns an AudioCache with an empty prefix; paths already contain
`resources/sound/`. Audioplayers resolves the Flutter asset location. There are no
relative `../../assets` paths and no global FlameAudio cache-prefix mutation.
Music/walk use actual ReleaseMode.loop; logo and one-shots use ReleaseMode.release.
Pools use four preloaded effect files: jump and the three block hits.

## Timing

Jump sound is emitted only when a jump actually starts. Rejected Space or expired
attack input stays silent. BlockHit1 plays once at accepted attack startup; BlockHit2
plays on each confirmed enemy contact; BlockHit3 plays on damage to Jaan. Attack
and hit can overlap. Walking is one loop during actual grounded movement, not a
new asynchronous player on every update; moving in the air or against a boundary
is silent. Pause/screen changes stop current voices. The ending stops walking and
allows the last impact to finish before Score stops remaining SFX.

Logo is a one-shot on initial intro entry; it can finish on Main Menu and is
cancelled on entering Lore or starting the campaign. Lore loops and cancels on
Back. On web, startup channel creation is deferred until pointer-down or key-down
notifies the backend, avoiding a suspended pre-gesture AudioContext. Only current autoplay-blocked channels retry, and stopped/obsolete tracks
cannot revive after a later tap. Effects are not queued for delayed replay.

The hardened SFX path waits at most three seconds for pool creation or one second
for a pooled start, retires failures and falls back to direct playback. Late
results are cleaned up. Audio failures never decide combat readiness.

## Checks

`flutter test test/game_audio_player_test.dart test/audio_routing_test.dart`
verifies the inherited recovery cases plus event routing, real loop requests,
late-start cancellation, walking stops, menu lifetime and game disposal. The
headless game tests/render helper explicitly inject a silent adapter. A web
release build verifies plugin compilation and sound packaging.

A manual listening pass is still needed for volume and timing on the target
browser/device: startup after a gesture; open/close Lore; walk/stop/jump;
missed and connected punch/kick; take a hit; pause/resume; win/lose/restart.

## User volume controls

Main Menu and Pause share SFX/music buttons. `GameSettings` cycles full, two-thirds,
one-third, mute (defaults: full effects, two-thirds music). Music and walking
channels update their current gains without restarting, even if their players
are still preparing. SFX volume changes stop current short voices and invalidate
in-flight starts; subsequent requests use the selected gain. Muted short effects
are dropped, never queued for later unmuting. These settings belong to the game
instance and survive level resets; they are not saved across app restarts.
