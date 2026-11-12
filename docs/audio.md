# Audio ownership and verification

`GameAudioService` consumes pure simulation events and menu lifecycle changes.
It sends typed `SoundCue` / `MusicCue` requests to `GameAudioBackend`. Playback
never changes combat timing, outcomes or screen transitions. Tests explicitly
inject `SilentAudioBackend` or a recording fake.

## Composition and platform support

`createGameAudio()` in `lib/audio/platform_game_audio.dart` creates one
`PlatformGameAudio` per game, with a recorded music transport and an independent
`SelectableEffects` owner containing the available `EffectsBackend` renderers.
Conditional imports choose the available modes:

| Platform | Effects / footsteps | Logo / Lore music |
| --- | --- | --- |
| Web | MIDI (default) or original recordings (MP3 label) | Existing OGG recordings |
| Native composition | `RecordedEffects` | Existing OGG recordings |

Only the web runner is currently supplied. The native adapter retains the
previous behavior but has not been verified in a native platform build.
Main Menu and Pause have the same **SFX MODE** button above the volume icons.
Its label shows **MIDI** or **MP3**; tapping toggles the renderer. MP3 means the
original recordings, including their existing MP3, WAV and OGG files. Native
composition only offers recorded effects and hides the unavailable mode switch.
The selected mode belongs to the game lifetime and survives screens, levels and
new campaigns; restarting restores the platform default.

`GameAudioPlayer` is the internal recording transport inherited from CoolorBurn,
using Flame Audio 2.10.3 and Audioplayers 6.1.0. Its cache/pool timeouts,
direct fallback and stale-player cleanup remain covered by regression tests.
MIDI mode never preloads or plays recorded effects. The web recording mode uses
direct playback instead of effect pools, so selecting it does not block the UI
on pool initialization. Recording assets load when an effect is first played.
`GameSounds` uses generated FlutterGen paths, with an empty recording cache prefix.
Original effect assets remain bundled for native composition.

## Mode switching

`SelectableEffects` owns selection, current volume and requested walking state.
It stops the old renderer immediately, drops short cues during the transition,
prepares the selected renderer, transfers volume and resumes only current walking
intent. Music continues independently. Rapid toggles invalidate obsolete starts;
pause clears walking intent even during preparation; disposal prevents any late
activation. A failed selection returns to the working renderer and can retry.
Both renderers receive the current user-gesture unlock. Mute stays in effect when
switching, and old hits are never replayed. The original recording transport's
generation checks also cancel already-starting recorded sounds.

## MIDI cues and renderer

`lib/audio/midi/midi_cues.dart` owns the short generated phrases:

| Cue | MIDI data (zero-based programs/channels) |
| --- | --- |
| Jump | Channel 0, program 80 (Square), notes 60 then 72 |
| Attack | Channel 0, program 81 (Sawtooth), notes 55 then 43 |
| Impact | Percussion channel 9, notes 36 (Bass Drum 1) and 38 (Acoustic Snare) |
| Hurt | Channel 0, program 81, notes 48 then 36 |
| Walking | Percussion channel 9, note 76 (High Wood Block), quiet velocity |

These GM names identify slots, not sampled acoustic timbres. The renderer uses
original procedural square/saw oscillators and short pitched percussion envelopes.
It implements only these two melodic slots and three drum notes; unsupported
slots stay silent. It is not a complete GM bank, MIDI-file sequencer or external
Web MIDI device client. It uses no OPL3/libADLMIDI, third-party synth or downloaded
sound bank, so no additional synthesizer licenses are required.

`MidiNote` validates channel 0–15, note/program 0–127, velocity 1–127, duration
0–2 seconds (strictly positive) and delay 0–1 second. Validation runs in release
builds too. To edit a cue, change its note list; to add a new instrument, implement
and verify its patch in `web/midi_synth.js` as well as choosing its program here.
All chosen notes currently use implemented patches.

`MidiSynth` isolates scheduling and resource ownership from cue policy.
`WebMidiSynth` is a small `dart:js_interop` bridge. The browser owns one AudioContext
and master effects gain per game. It schedules every note's release using the
audio clock, including delayed phrase notes, and bounds polyphony to 24 voices.
Oldest voices are released during bursts. Ended oscillators/gains disconnect;
disposal closes the context. Walking and short effects have separate voice groups.

`web/index.html` loads `midi_synth.js` before Flutter starts. Flutter copies it
into `build/web`; the relative script URL supports itch.io subdirectory hosting.
No asset changes were made, so FlutterGen regeneration is unnecessary.

## Timing and lifecycle

Accepted jump takeoff, player attack startup and confirmed contacts emit one cue
per simulation event. Rejected/expired input stays silent. Walking observes actual
grounded movement, with one cancellable timer at 360 ms per footfall. Idle,
boundary pushing, jumping, attacks, hurt and level endings stop it.

AudioContext creation/resume happens only after a key or pointer gesture. Short
cues before unlock, during suspension or while muted are dropped, never replayed.
Only the recording transport's current blocked music request retries on a gesture.
Pause/screen exit stop both effect groups and cancel the footstep timer. Normal
play determines when walking starts again. Muting releases all current/scheduled
notes; unmuting permits future footsteps only if walking is still requested.
Changing SFX volume stops short effects and updates walking gain in place.
Disposal is idempotent and prevents subsequent cue/gesture requests from restarting
sound. Audio failures do not block gameplay readiness.

Logo remains a one-shot on initial Intro entry and may finish on Main Menu.
Entering Lore replaces it with the loop; Back/start/pause cancels music.
Music volume uses its existing independent control and Lore track balancing.
No gameplay music has been assigned.

## Verification

Run from the project directory:

```powershell
flutter analyze --no-pub
flutter test --no-pub
node tool/midi_synth_test.mjs
flutter build web --no-pub --no-web-resources-cdn
```

The JS test requires Node 18 or newer (the bundled Codex runtime also works).
Dart tests cover event routing, recording recovery, typed composition, cue data,
walk timer ownership, mute/unmute and stop/disposal. The JS checks cover gesture
unlock, cancellation of delayed notes, separate walking/impact groups, muted cue
drops, bounded polyphony, natural note-off cleanup and per-game disposal.

`tool/web_audio_smoke.cjs` additionally runs the built game in headless Edge,
checks actual keyboard gameplay MIDI events and pause cleanup, verifies that
MIDI mode requests only Logo/Lore recordings and MP3 mode requests the original
effects after using the visible switch, and renders all five patches
through OfflineAudioContext to check nonzero output and silence after note-off.
It requires Playwright and Edge. First prepare a relative-base release with
`.\publish_itch.bat --build-only`, then run:

```powershell
node tool/web_audio_smoke.cjs C:\path\to\node_modules\playwright
```

For a listening pass, serve `build/web` and exercise Intro, Lore/Back, start,
walk/stop/jump, punch/kick, contact/hurt, pause/resume and the SFX/music controls.
Confirm MIDI mode makes no gameplay WAV/MP3/OGG effect requests; then select
MP3 and confirm the original jump/attack/walking recordings play. Toggle again
from Pause and check that no walking resumes until gameplay resumes. A listening pass on the target
browser/device remains useful for subjective timbre and gain balance.
