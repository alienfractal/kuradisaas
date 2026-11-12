# Kuradi Sääsed architecture

View the [whole-app UML](app-architecture-uml.md) or open
`app-architecture.html` beside the running web game for a diagram of views,
models and services in every application state.

## How to extend the application

Follow the [architecture and extension guide](architecture-guide.md) when adding
assets, characters, animations, levels, screens or cache services. It defines
class placement, ownership boundaries, reuse decisions, implementation steps
and verification. This file describes the runtime details; the
[fighter arena UML](fighter-arena-uml.md) maps the concrete relationships.

## Relationship to the reference projects

RevaliaObscura supplies the organizing pattern: a Flame game as composition root,
a game-level FSM, worlds for screens/scenarios, models for data, services for
rules and cached assets, entities for presentation, and animation handlers.
The inspected CoolorBurn checkout contains its card-game implementation. No
historical fighting implementation was recovered or copied.

This is a fresh implementation of those patterns, rather than a copy of the
adventure game. It has no dialogue, quest, board, or turn dependencies. There are
no static shared state instances; a restart creates a fresh simulation and world.

## Ownership and data flow

```
Keyboard / touch
      |
 InputService (direction + punch/kick/jump intent)
      |
 KuradiSaased.update: fixed 120 Hz simulation
      |
 CombatLogicService -> FighterModel + AttackSpec
      |                       |
 ArenaView               FighterAnimationHandler
      |                       |
 FighterEntity <---- FighterCacheService (preloaded original PNGs)

 GlobalGameFsm -> menu / loading / level / pause / score / end
      |
 Separate Flame World views + Flame ArenaHud
 (Flutter overlay: touch controls and focus handling only)
```

`CombatLogicService` has no Flutter or Flame imports. The simulation owns damage,
movement, facing, knockback, invulnerability, and state transitions. Entity and
animation code only read these results. Animation callbacks never unlock a
fighter, deal damage, or advance a combat phase.

## Fighter types and presentation

See [Fighter arena UML](fighter-arena-uml.md) for Mermaid diagrams of the model
and entity hierarchy, ownership, animation handlers, and construction/frame flow.
Its offline [retro browser edition](../web/fighter-arena.html) is served at
`fighter-arena.html` alongside the web game; regeneration instructions live in
the UML document.

`FighterModel` is the sealed, abstract domain base. Its library is split into
`player_model.dart`, `enemy_model.dart`, `mosquito_model.dart`, and
`grunt_model.dart` using Dart parts. Import `fighter_model.dart` to access them.
`FighterKind` identifies the category; independently writable `isPlayer` and
`isGrunt` flags are removed. Common state includes health, position, attacks,
jump motion, and hit/death phases. `PlayerModel` owns combo confirmation,
death-variant selection, knockdown recovery, and air steering permission.
`EnemyModel` exposes attack choice, movement speed, and optional sidestep direction.
`GruntModel` advances light/heavy alternation only when a windup reaches its strike phase. Incoming
horizontal push uses the target's `knockbackMultiplier`: 1 normally, .25 for
grunts. Attack damage, reach, and launch are unaffected.

`MosquitoRank` configures regular/veteran mosquitoes without another identity
flag, model subclass, or factory branch. `LevelDefinition.veteranCount` is one
on level 2, three on level 3, and zero on level 1. Combat randomly selects unique
small-mosquito slots (excluding grunts); an optional injected `Random` makes
selection reproducible in tests. Veteran sting startup/recovery are .18/.28s,
versus .24/.36s normally. Veterans move at 34px/s versus 25px/s for regulars.
A free veteran in front of a grounded swing sidesteps to a lane outside its
depth tolerance when arena bounds permit. It resumes pursuit as Jaan enters
recovery. `MosquitoEntity` draws the yellow asterisk beside the health bar.

`FighterEntity<M extends FighterModel>` is an abstract `PositionComponent` with
a final typed model and a `FighterAnimationHandler<M>`. `PlayerEntity`,
`MosquitoEntity`, and `GruntEntity` bind their corresponding model and animation
handler at construction. `EnemyEntity` shares enemy overlays and disappearance;
the fighter base shares positioning, shadows, sprite drawing, and debug bounds.
Player blinking and grunt source facing belong to their concrete entities.
Each animation handler owns its character's frame selection and draw size.

`createFighterEntity` in `fighter_entity_factory.dart` is the presentation
composition boundary: an exhaustive switch over model subtypes chooses an
entity. Adding a model requires connecting its entity there, without putting
character checks back into the renderer. The simulation creates concrete models
and uses enemy capabilities rather than checking for grunts during combat.
Shared combat phases, cache ownership, and pixel preparation remain independent
of model variants.

## Global game lifecycle

### Sprite and animation caches

`lib/utils/sprite_spec.dart` defines `SpriteSheetSpec` (horizontal sheet metadata
and validation), `SpriteSpec` (a loaded sprite and its display size), and
`SpriteAnimationSpec` (shared frames, frame timing, and loop/hold behavior).
Animation specs create fresh Flame animations for independently ticking views,
or sample a supplied clock through `frameAt` for simulation-driven presentation.

`lib/utils/animator_cache_service.dart` supplies `SpriteAnimatorCache`, the base
for `FighterCacheService`, `ScenarioCacheService`, `MenuCacheService`, and
`SettingsCacheService`. It deduplicates repeated and concurrent sheet requests,
validates image dimensions, and lets failed requests retry. Each service belongs
to one game instance; there is no global cache registry. Flame caches the source
images. UI caches retain those source images and their original colors/alpha.
FlutterGen 5.12.0 generates `lib/gen/assets.gen.dart` and `fonts.gen.dart` from
`pubspec.yaml`. All runtime asset references use `Assets.resources...`; font
families use `FontFamily.arcade`. Generated paths include their resource directory,
so the shared sheet loader uses an empty Flame image prefix. Source paths belong
in the manifest and generated files. FlutterGen 5.12 does not read `shaders`, so
the same build-runner command also generates `ShaderAssets` from that manifest
section via `tool/shader_assets_builder.dart`. Shaders stay exclusively in
`shaders` so Flutter compiles them correctly.

Scenario stars declare their skipped leading cell explicitly. Settings sheets
without filename metadata declare their layout explicitly. Fighter loops use
animation specs, while attacks and hit/death poses remain sampled from combat
state time in `FighterAnimationHandler`. Completing an animation never advances
combat. The compatibility name `ScenarioSheet` aliases `SpriteSheetSpec`.

### State asset ownership and sprite buttons

`KuradiSaased.stateSpriteServices` maps every `GlobalGameState` to its service.
Boot preloads these services; entering a state passes that service into its view.
Add new screen-specific assets to the corresponding service, using FlutterGen
references. The initial Loading service is prepared first so its own animation
can remain visible while the other state services load.

| Global state | Service | Assets owned by the state |
| --- | --- | --- |
| Menu | `MenuCacheService` | Intro/logo frames, Lore animation, Start/Lore/Back buttons |
| Loading | `LoadingCacheService` | Flying mosquito loading animation |
| Level | `LevelCacheService` | `FighterCacheService` and `ScenarioCacheService` |
| Paused | `PauseCacheService` | Resume and Back to Menu buttons |
| Score | `ScoreCacheService` | Continue/next-level button |
| End | `EndCacheService` | Back to Menu button |

`ButtonSpriteCacheService` shares the reference project's unmodified button artwork. Each state's service declares its button roles. Views
create independent `GameButton` components, which extend Flame's
`SpriteButtonComponent`: cached artwork is shared, pressed/enabled/input state is
per button. Nine-slice rendering preserves the pixel border, covers the baked
START text and renders each action's own label. A canceled or disabled press
cannot invoke the action. Settings icons retain their separate shared cache.

The reference project's outer `GameMenu` maps to `GlobalGameState.menu` here.
Entering it activates `GameMenuFsm`; its Intro/Logo/Main/Lore entries select the
corresponding worlds and use `MenuCacheService`. Substate transitions call exit
then enter, clearing input on exit. Leaving the outer Menu calls `menuFsm.leave`,
stopping its logo clock and rejecting menu input until the next `begin`.

`GlobalGameState` and `GlobalGameFsm` own the application flow, separate from every
fighter's `FighterState`. Boot preloads shared sprites and opens Main Menu.
Starting a run resets `CampaignModel`, enters Loading, constructs the configured
arena off-camera, and waits for Flame's component tree to load and mount before
entering Level. `LoadingView` stays the camera's visible world during that work.
Loading errors return to Menu with an error message.

`GlobalGameFsm` calls its entry handler after a valid transition. That handler
selects a separate Flame `World`: `MainMenuView`, `LoadingView`, `ArenaView`,
`GameScoreView`, `GameEndView`, or `PauseView`. `switchToWorld` attaches the selected
world to the camera and resets its screen coordinates. Menu/Score/Loading/End
are independent views, not branches in a single Flutter widget. They use shared
Flame text and tap-button primitives in `ScreenView`; each owns its own contents.
The Flutter `GameControlsOverlay` is limited to touch controls and focus handling.
Pause holds the current arena instance and resumes it with the same fighter data
and camera position. Other screens remove the old arena.

Level completion or defeat latches one immutable `LevelResult` in `LevelEndingModel`.
The existing arena stays active while current animations settle, with new input,
AI and damage disabled. After at least .9s and all motion/phases/deaths finish,
a result popup stays for 1.6s before recording the result and entering Score.
The simulation freezes while the player reviews the breakdown and running total.
Continuing from a cleared level enters Loading for the next level if one exists;
otherwise it enters End. Defeat also leads from Score to End. End returns to Menu.
Pause resumes the same level, or abandons it to Menu without recording a result.

The three street encounters have 5, 7, and 5 small mosquitoes and 1, 2, and 4
grunts, respectively. Levels 2 and 3 promote one and three small mosquitoes to
veterans.
Definitions live in `CampaignModel`; each receives a fresh arena and full player
health. Scores survive world replacement, but reset when starting a new run.
Scoring is 10 per landed attack, 100 per defeated mosquito, and 25 per remaining health
point on a clear. `recordResult` refuses duplicate accounting for a level.

The full flow has a widget test using real sprite loading and Flame world mounts,
including next level, pause, victory, defeat, End, Menu, and run reset.

## Fighter lifecycle

```
idle <-> walking
  |         |
  +--- startup -> active -> recovery -> idle
          |         |          |
          +---------+---------- hurt -> idle
                                |
                     lethal damage -> dead
```

Idle/walking can start an attack; a confirmed kick combo can also transition
from its explicitly permitted recovery window. Attack direction is locked until recovery
finishes. Hurt cancels the current attack and input buffer. Dead is terminal.
The next attack can be buffered for 160 ms during recovery. Keyboard repeats do
not queue attacks; tapping E/PUNCH, R/KICK, or Space/JUMP creates one matching intent.

Punch uses 70/75/190 ms of startup, active time, and recovery. Regular stings
use 240/100/360 ms and veteran stings use 180/100/280 ms. `AttackSpec` owns these timings.
The mosquito's magenta warning appears during startup. Flight art is used for movement and sting. Hurt plays the new five-frame recoil
once in .25s, then holds its final pose during extended stun/launch. Dead plays
the seven-frame burst once over .56s, with no blinking or squash. These are read
from stateTime; finishing a sheet never changes combat. The final enemy's death
window completes before the ending popup (`endingAnimationsFinished`); `won`
still means every enemy has zero health. Grunts override the death window to
.96s for their 15-frame death sheet. Their animation handler samples the first
three KO frames for ordinary recoil; surviving critical finishers play the full
seven-frame KO, hold, then reverse it in the last .35s of stun. These poses use
the existing Hurt state and do not change combat recovery or add immunity. Both win and defeat use the same
settlement/popup flow before Score.

An attack can hit multiple opponents, once each. Range is checked in front of
the attacker, and feet must be within a 10-pixel depth band. Visual overlap alone
does not cause damage. Player attacks resolve first on simultaneous contact.
Hits interrupt opponents and add short invulnerability. There is no body
separation yet, so enemies can overlap during a swarm.

## Space and time

Gameplay uses a 256×128 logical view of a 640×320 street map. The camera follows
Jaan in both axes and clamps to the map. Feet remain in the 236–310 depth band;
ground Y still controls drawing order. Black sky, three animated star frames,
and a static street layer render behind fighters. Distant stars scroll more
slowly than the street. Camera and sprite positions are rounded to pixels and
nearest-neighbor sampling is used. The viewport uses integer physical-pixel
scaling and letterboxes spare space. Other global screens retain 320×200 layouts.

The game uses an accumulator with 1/120-second simulation steps, and accepts at
most 100 ms per rendered frame. Excess long-frame time is discarded to prevent
unbounded catch-up. Pause clears input and accumulated time; focus/lifecycle loss
pauses a running session. Presentation is frozen outside play.

## Adding the next feature

- **Scenery:** add background/foreground components in `ArenaView`. Keep movement
  bounds in `ArenaConfig`, independent of painted scenery.
- **More enemies:** move spawn definitions out of the service constructor into
  scenario data; give AI its own service when there is more than one behavior.
- **More levels:** create scenario configuration and a loader like Revalia's,
  preserving the same combat service and actor components.

## Boundaries of this first slice

Three street encounters, punch, jump, two-stage kick combo, keyboard/touch controls, health,
pause/resume, cumulative scoring, and the global Menu/Loading/Level/Score/End flow.
There is no save data, mobile packaging, or controller support yet.
Web is the generated runner. Flutter/Flame code can be reused for desktop/mobile
when those platform runners are added and tested.




## Jump motion and attack selection

Jump elevation/velocity are separate from ground x/y and the attack FSM.
The fixed simulation step applies gravity, determines landing, and checks attack
height tolerance. Rendering lifts only the sprite; the shadow and depth lane
stay on the street. Jump art follows simulated jump time, not a completion callback.
Punch and kick use the same startup/active/recovery states with different immutable
AttackSpec values. A buffered intent chooses the next attack after recovery, except for a confirmed
kick follow-up in its permitted recovery window. Jumping cannot bypass recovery.


## Hit-confirmed kick combo

Mid and high kicks have 38px and 42px of center-distance reach. Regression
checks require both to connect from normal 23–25px enemy engagement spacing
in either direction without player movement.


`AttackKind` distinguishes mid and high kicks within the same
startup/active/recovery FSM. `AttackSpec` stores timing, damage, knockback,
launch speed, stun duration and the earliest permitted combo recovery time.

R queues a kick intent. `CombatLogicService._beginPlayerAttack` resolves it to
the mid kick or a confirmed high kick. A punch that hits a surviving grounded
target while Jaan is grounded can link to the mid kick 70 ms into recovery.
The punch pushes 1px before enemy resistance to keep the target in range.
The punch link expires at the end of punch recovery. A mid kick must hit the
confirmed punch target to link to high. A mid kick that starts from neutral
confirms the first surviving enemy it hits. Its confirmation lasts .42 seconds
from contact, and the high kick can begin after .10 seconds of mid kick recovery.
Timeout, taking damage, or starting another kind of attack clears the chain.
A single buffered press cannot queue multiple stages. Follow-ups require a fresh
R press near contact/recovery (input buffer 0.16 seconds).

The mid kick deals 2 damage, pushes 5px, and launches at 90px/s. The high kick
deals 3 damage, pushes 32px, and launches at 120px/s. The high kick's horizontal
push decelerates to a stop over 220 ms and stops early at the arena boundary.
`FighterModel.launch`
limits repeated launches to 24px above ground. The mid kick stuns for .70s and
the high kick stuns for 1.2s. Launched victims remain hurt until both
the stun expires and they land. The runtime defaults to 6-health mosquitoes.

`FighterCacheService` slices both kick sheets using their filename metadata.
`FighterAnimationHandler` maps startup, active and recovery to explicit poses:
each kick reserves its final two loaded frames for contact; preceding frames
provide windup and reversed recovery.
Animation completion never changes the FSM or confirms a hit. Launch rendering
lifts the sprite and health indicators while leaving shadow and depth order on
the ground. A white pixel star marks a surviving critical victim's stun.

## Player death and ending popup

`jann_death_24x24-7.png` is sliced into seven 24x24 frames (case-insensitive
filename metadata). Jaan's dead state reads its own .84s duration, renders at
native 24x24 game pixels, and holds the final lying pose. Invulnerability blinking and
the former squashed sprite are disabled for death.
`jann_death-wound_24x24-7.png` uses the same layout and timing. On entering Dead,
the model chooses fall/wound with equal probability once; rendering reads that
stored choice throughout the sequence. The model accepts a seeded random source
for deterministic tests. Walking audio uses a separate 1.3x playback rate, retained
on gesture retries; applying that rate cannot revive a stopped channel.

`LevelEndingModel` phases: playing -> finishing -> popup -> complete. The first
outcome is captured once. Combat settlement advances gravity, hurt and attack
phases, and death time; it never starts new actions, AI movement or damage. After
at least .9s and all fighters settle, `LevelResultPopup` draws YOU WON! or JAAN IS
DOWN for 1.6s above the gameplay viewport. The arena then transitions to Score.
The existing Score -> Loading/End flow remains. Pause freezes the ending;
loading a fresh level resets the model and restores controls. No delayed
callbacks or animation completion handlers decide these transitions.

## Audio events

`CombatLogicService` emits `CombatEvent` facts for accepted jump takeoff, player
attack start and actual contact. `KuradiSaased.update` forwards each step's events
to `GameAudioService` immediately, including when multiple simulation steps happen
in one rendered frame. The service observes ground movement for a separate walk
loop; it does not mutate fighters. Sound completion never advances combat.

`GameAudioBackend` is the typed game boundary (`SoundCue`, `MusicCue`, walking
intent and lifecycle). `GameAudioService` owns event routing; its backend remains
private. `PlatformGameAudio` composes recorded music with an `EffectsBackend`.
A conditional platform factory offers `MidiEffects` and `RecordedEffects` on web
(default MIDI), and recorded effects on native. `SelectableEffects` owns switching,
volume transfer, current walking intent, and cancellation of obsolete selection
work. MIDI mode never preloads or plays recorded effect paths. Main Menu and
Pause share a Flame **SFX MODE** button showing the selected MIDI/MP3 label.
The mode survives screen and campaign replacement within the game instance. `GameSounds` maps
FlutterGen paths only inside the recording adapters.

`MidiEffects` owns cue selection and the single cancellable 360 ms footstep timer.
`MidiNote` validates channel, program, pitch, velocity, duration and delay at
runtime. `MidiSynth` isolates browser interop. `WebMidiSynth` owns one JS synth
per game; `web/midi_synth.js` creates its AudioContext only after a user gesture,
schedules a note-off for every note-on, bounds polyphony to 24 voices, and releases
scheduled as well as sounding voices. Walking and one-shots stop independently.
This original Web Audio renderer uses procedural square/saw and percussion
patches, not OPL3/libADLMIDI or a sampled bank. It implements the GM slots used
by the game, not a general MIDI-file player. See `docs/audio.md` for the patch map.

`GameAudioPlayer` remains the internal recording transport, adapted from
CoolorBurn. It owns recording cache/pools, fallback, late-player cleanup, and
generation checks for cancelled music starts. Web uses it for Logo/Lore music and optional recorded effects;
native composition retains the original effects. All resources belong
to one game instance and are disposed by `PlatformGameAudio`.
Headless tests inject `SilentAudioBackend` or recording fakes.

## Shared settings UI and CRT

`GameSettings` holds per-instance SFX/music indices and the CRT flag. The four
volume steps map directly to the shared 4-frame sheets. `SettingsControls` is
reused by MainMenuView and PauseView. The original orange volume art and animated
CRT sheet are copied unchanged from CoolorBurn. No delayed tap callbacks are used.
`SettingsCacheService` loads the original sheets without palette conversion.
Button and settings sprites retain their source colors and transparency; no
pressed/disabled tint is applied. `CgaPalette` supplies colors only for drawn
HUD, text and touch controls. Touch fills are opaque and direction/pause
glyphs use integer pixel rectangles; empty health cells have cyan outlines.

Volume callbacks update the real audio backend: music and MIDI walking gains
change in place. The recording adapter also updates pending channel starts. SFX changes stop short voices and
invalidate pending effects, then later requests use the new gain. Settings survive
world and campaign replacement but are not persisted across app restarts.

`CrtRenderer` loads `resources/shaders/crt.frag`, adapted from CoolorBurn's
`test.frag` using FlutterFragCoord for portable local coordinates. Enabled rendering
captures `super.render` exactly once, applies the shader and releases obsolete
images/pictures. Disabled rendering bypasses capture/shader completely. It affects
Flame worlds/HUD, not Flutter touch widgets. The shader is off by default; camera
viewport sizing and hit testing are unchanged. Headless rendering checks verify
shader loading, a changed output pixel, single capture, and identical restored
output when toggled off.
