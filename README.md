# Kuradi Sääsed

A real-time CGA karate brawler in Flutter + Flame, using the original Jaan and
man-sized mosquito sprites. This playable slice is a scrolling night street
campaign with three encounters. Level 2 marks one randomly chosen small mosquito
with a yellow asterisk: this veteran attacks with a shorter windup and recovery.
Level 3 mixes three veteran and two regular small mosquitoes with two tougher
grunt mosquitoes. Grunts now have dedicated KO/get-up and death animations;
lethal hits play all 12 death frames before disappearing. The archived GameMaker project remains
untouched alongside this folder.

## Run

From this directory:

```powershell
flutter pub get
flutter run -d chrome
```

Or serve for any browser:

```powershell
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8765
```

Open `http://127.0.0.1:8765`. The app uses Flutter 3.38.2 / Dart 3.10.0 in this
workspace and pins Flame 1.23.0, the baseline used by RevaliaObscura.

## Publish to itch.io

From this project directory in PowerShell:

```powershell
.\publish_itch.bat
```

Like CoolorBurn/Revalia, this builds the web release, then asks for your itch.io
API token with hidden input. It uploads to **lienthealien/kuradi-saased:HTML5**,
using the version from `pubspec.yaml`. Future runs update that same channel.
The helper also accepts a token argument or `ITCH_API_KEY` / `BUTLER_API_KEY`
environment variables. Tokens are not written to disk or passed to the build.

Flutter and Python must be on PATH. `butler.exe` is included locally beside the
scripts (copied from Revalia and ignored by Git). No Python packages are needed.
The build uses a relative base URL so assets work inside itch.io's game frame.
Only `build/web` is uploaded; editable `art/` files are outside that bundle.

To build without a token or upload:

```powershell
.\publish_itch.bat --build-only
```

If this is the first Butler upload to this channel, check the game's itch.io
edit page: set the project kind to HTML and mark the HTML5 upload as playable
in the browser. See the [Butler HTML game instructions](https://itch.io/docs/butler/pushing.html#html-playable-in-browser-games).

## Play

The combat FSM documentation is a standalone HTML page, separate from the game
menu. With a web build running, type `combat-diagram.html` after the game's base
URL—for example, `http://127.0.0.1:8765/combat-diagram.html`. You can also open
`web/combat-diagram.html` directly from disk without a server.

The page includes its Pele-rendered Mermaid diagrams, retro font and CSS, so it
works offline. It covers combat states, the kick combo, hit reactions, jump motion,
frame flow and level endings. Editable sources and regeneration instructions are
in [docs/combat/README.md](docs/combat/README.md).

The [fighter arena UML](docs/fighter-arena-uml.md) has its own retro browser page
at `fighter-arena.html` on the same server. Open `web/fighter-arena.html` directly
for offline viewing. It shows model/entity inheritance, ownership and animation
handlers, and construction/frame flow, with zoom, class-member details, and SVG
downloads. Regenerate it from the canonical Markdown using
`node tool/render_fighter_arena.mjs C:\path\to\pele.mjs` (Pele 1.6.0).

| Control | Action |
| --- | --- |
| WASD / arrow keys | Walk horizontally and across depth lanes |
| Space | Jump (one press per jump) |
| E | Punch |
| R | Kick; repeat quickly on connected hits for a three-stage combo |
| Enter | Start / resume / continue through Score and End |
| P / Escape | Pause / resume |
| F1 | Show ground bounds, body guides, attack range, and combat state |
| Onscreen arrows / JUMP / PUNCH / KICK | Touch or mouse controls |

Line up your feet with an enemy and punch toward it. The magenta warning above a
mosquito signals its sting windup. Step away or interrupt it. Clear all five
mosquitoes to clear the level. Jaan has eight health points; mosquitoes have six
each. The first test level has five mosquitoes and the second has seven. Jaan's
health resets for each level, and the score carries through the run.

The global flow mirrors RevaliaObscura:

```text
Main Menu -> Loading -> Level -> Score -> Loading -> next Level
                                  |
                         final clear or defeat
                                  |
                                 End -> Main Menu
```

Score awards 10 points per landed attack, 100 per mosquito defeated, and a 25-point
bonus per remaining health point on a clear. The Score screen shows the level
breakdown and running total before advancing. End shows the final total and
returns to Main Menu. Starting again resets the campaign.

## Structure

The project follows RevaliaObscura's game FSM / models / services / views /
animation-handler organization. Combat is a separate pure-Dart simulation with
per-fighter states: idle, walking, startup, active, recovery, hurt, dead. It runs
at 120 Hz; animations display the results and never control damage or recovery.

- `lib/kuradi_saased.dart`: composition, simulation clock, camera, input routing.
- `lib/gamefsm/`: global Menu / Loading / Level / Score / End transitions.
- `lib/game/model/`: level definitions, results, and cumulative campaign score.
- `lib/game/states/arena/model/`: fighter data, attack timing, arena bounds.
- `lib/game/states/arena/services/`: combat rules, inputs, sprite cache.
- Each screen's `services/` directory owns that state's sprites and button roles;
  `KuradiSaased.stateSpriteServices` lists every global state's asset service.
- `lib/utils/game_button.dart`: reusable cached sprite buttons with press/cancel
  handling, shared by Menu, Lore, Pause, Score and End.
- `lib/game/states/arena/handlers/`: visual mapping from combat states.
- `lib/utils/`: shared `SpriteSpec`, `SpriteSheetSpec`, `SpriteAnimationSpec`,
  and `SpriteAnimatorCache` loading/caching abstraction.
- `lib/game/states/arena/view/`: layered street scenery and fighter components.
- `lib/game/states/main_menu/views/`: `MainMenuView`, a Flame World.
- `lib/game/states/loading/views/`: `LoadingView`, a Flame World.
- `lib/game/states/score/view/`: `GameScoreView`, a Flame World.
- `lib/game/states/end/views/`: `GameEndView`, a Flame World.
- `lib/game/states/pause/views/`: `PauseView`, a Flame World.
- `lib/game/view/`: shared Flame screen drawing/buttons, touch controls, HUD.
- `test/`: combat and session regression tests.

Start with the [architecture and extension guide](docs/architecture-guide.md)
for adding assets, characters, handlers, levels, views and cache services.
The [whole-app UML](docs/app-architecture-uml.md) maps each state's views and
models; open `app-architecture.html` beside the web game to explore it.
See [the architecture notes](docs/architecture.md) for runtime design decisions
and current limitations; [asset notes](resources/ASSETS.md)
record what was imported. The included runner targets web.

## Street scenery and camera

Gameplay shows a **256×128** window of a **640×320** map. The camera follows Jaan
on both axes and stops at the map edges. Menu, score, and pause screens retain
their 320×200 layouts. The HUD stays fixed to the gameplay viewport.

The street uses `scenariot-wide-front-street-house_640x320-1.png` as one static
frame. Stars use `scenariot-wide-stars_640x320-3.png`, looping three frames at
0.3 seconds each behind the street with slower sky scrolling. This particular
export has an empty first cell, which is skipped. A solid black sky is drawn in
code. The original images are unchanged; nearest-neighbor sampling is used.

`ArenaConfig.minY = 236` is the upper floor line for feet; `maxY = 310` is the
lower street limit. These bounds control both player and enemy movement, rather
than deriving collisions from image pixels. Adjust them in
`lib/game/states/arena/model/arena_config.dart`; F1 displays the boundary.

For a headless visual check without starting a browser:
`flutter test tool/render_street_preview.dart`. It writes street, jump and kick previews to `build/`.

Each global state enters its own Flame view, as in RevaliaObscura. Menu, Loading,
Level, Score, End, and Pause are separate `World` classes. The camera switches
between them through `switchToWorld`. The Flutter overlay handles only touch
controls and focus events; it does not render the global screens. Screen text
and buttons share the same 320×200 logical resolution as gameplay.

## Verify / build

Assets and font families use FlutterGen 5.12.0, matching the reference project.
Use `Assets.resources...`, `FontFamily.arcade`, and `ShaderAssets` from `lib/gen/`; generated
asset paths are complete bundle paths and must not receive an extra Flame prefix.
After adding, removing, or renaming an asset, regenerate and include the generated
files with the change:

```powershell
dart run build_runner build --delete-conflicting-outputs
```

```powershell
flutter analyze
flutter test
flutter build web
```

### Pixel grid

Jaan's imported frames use mostly 4x4 source blocks and mosquitoes use 3x3.
Presentation normalizes those to the street's 1-pixel grid: Jaan's idle frame
is about 20x25 game pixels, and a mosquito is 32x32. Source PNGs are unchanged.
Sprite bounds, camera positions, shadows, and health bars use whole game pixels.
The viewport chooses a whole-number physical display scale using device pixel
ratio, and letterboxes spare screen space rather than stretching the artwork.
The gameplay view remains 256x128; resizing the window does not reveal more map.


## Opening sequence

The outer Menu state contains GameMenuFsm: intro frame -> any key/click/tap ->
logo frame for 2 seconds -> the existing main menu. The two frames come from
CGA-game-intro-logos_256x256-2.png and display at native 256x256 resolution.
Returning from a game skips the intro; restarting the app shows it again.
See docs/menu-flow.md. The logo duration is configurable in game_menu_fsm.dart.



## Jump and kick balance

Jump is simulated elevation above the street: a roughly 0.6-second arc with
a 20-pixel peak. Ground position, shadow, depth order and camera anchoring remain
on the street. No double jump or jump-cancelling an attack; moving and attacking
while airborne are supported. Stings can miss while Jaan is high in the air,
but takeoff and landing remain vulnerable.

Punch: 1 damage, 9px knockback, 0.09/0.075/0.19s startup/active/recovery.
R chains low -> frontal -> high, using native 24x24 sheets with 6/7/7 frames.
Each follow-up requires a hit on the same surviving enemy and another R press
within 0.42s of contact. Inputs buffer for 0.16s, so press near contact or recovery;
holding R does not repeat. Missing, waiting too long, punching or taking damage
resets the chain. A kick can hit several enemies, but the chain tracks the first
survivor hit.

| Kick | Damage | Knockback | Launch speed | Startup / active / recovery |
| --- | --- | --- | --- | --- |
| Low | 1 | 12px | none | .14 / .10 / .48s |
| Frontal | 2 | 5px | 90px/s | .12 / .10 / .50s |
| High | 3 (critical) | 3px | 120px/s | .16 / .10 / .65s |

Kick reach uses center distances of 34/38/42 game pixels: a modest 4px
reduction from the original 38/42/46 ranges. Original 12/5/3px knockback is
preserved for regular mosquitoes; all three hits connect at normal 23-25px enemy
engagement spacing. Grunts take only 25% of incoming horizontal knockback
(3 / 1.25 / .75px from the three kicks), helping follow-ups connect even at the
first kick's outer reach. Grunt resistance affects horizontal push only. Kick launches stay within 24 game pixels of the ground, including repeated airborne hits.

A confirmed, buffered follow-up can begin after .08s of front recovery or .10s
of high recovery. Otherwise the entire recovery applies. High kicks stun for
.70s; very-high kicks stun surviving enemies for 1.2s (white star indicator).
Launched enemies cannot recover until they land. Mosquitoes now have 6 health,
so a full 1+2+3 combo is lethal. The simulation selects the impact pose while
active; no animation-completion callbacks unlock attacks.
Regular mosquito sting: 0.30/0.10/0.45s. A level-2 veteran's sting uses
0.24/0.10/0.36s: 20% shorter windup/recovery, with the same 1 damage and reach.
One small mosquito is promoted at random on level 2; three are promoted on level 3;
the asterisk remains visible beside its health bar while it is alive.
All attack timings and hit decisions remain in the pure combat simulation.



## Mosquito hit and death reactions

Mosquitoes now recoil using the five-frame native 32x32 hit sheet. High/very-high
kicks carry that reaction upward; its final pose holds until stun ends. Lethal
hits use the seven-frame burst sheet (.56s), and the final kill finishes its burst
before the result popup appears. Hit/death frames follow FSM state time, never an independent
animation-completion callback. All mosquito animations stay 32x32 game pixels.

## Lore

Choose **LORE** from the main menu (or press **L**) to read Jaan's story against
the six-frame `CGA-intro-256x256-6.png` background, looping at four frames per
second. Jaan is an ex-cop and ex-karate man seeking revenge on the mutant
mosquitoes that ruined his summer. **Back to Menu**, **Escape**, or **Enter**
returns directly to the main menu. Lore is its own Flame World inside the menu
FSM; it does not start combat or change campaign progress.

## Level endings

After victory or defeat, new combat actions stop while existing attacks, recoil,
death animation and airborne motion finish. Jaan uses the seven-frame death
sheet over .84 seconds, then remains lying down. The ending holds for at least
.9 seconds, shows **YOU WON!** or **JAAN IS DOWN** for 1.6 seconds, then opens
Score automatically. Pause freezes the sequence. Each new level resets it.
The updated Combat Guide explains the ending phases.

## Audio

Kuradi reuses the hardened `GameAudioPlayer` from the newer CoolorBurn copy,
with Flame Audio 2.10.3 / Audioplayers 6.1.0 and the same pool-failure fallback.
All sounds are registered under `resources/sound/`.

| Trigger | Sound |
| --- | --- |
| App opening | `alien_retro_logo_mfx.ogg`, once; may finish on Main Menu |
| Lore view | `alien_retro_intro.ogg`, looping; stops on Back |
| Accepted jump | `sfx_jaan_jump_1.wav` |
| Ground movement | `sfx_kurat_jaan_walk.ogg`, separate loop; stops when motion stops |
| Accepted punch/kick | `blockHit1.mp3` |
| Jaan hits an enemy | `blockHit2.mp3` |
| Jaan takes damage | `blockHit3.mp3` |

The simulation emits accepted action/hit events; `GameAudioService` routes them
once per fixed step. Animation callbacks do not trigger sounds or combat. The
walk loop stops on jump, attack, hurt, pause or ending, and does not play when
pushing against a boundary. Music and walking use independent players.

On web, startup audio waits for the first key press or tap. Only the
current blocked music/walk request retries; leaving Lore, pausing or disposing
cancels pending starts. Old impacts are not queued to replay on a later gesture.
Pause stops current sound; Lore music restarts after returning from app suspension.
No gameplay music has been assigned. For details see [docs/audio.md](docs/audio.md).

## Shared sound and CRT controls

The main menu and pause screen reuse the SFX, music and animated CRT icons from
CoolorBurn/Revalia. Tap an audio icon to cycle **100% -> 67% -> 33% -> OFF**.
Music defaults to **33%**; players can raise it using the music control.
Drawn HUD/text/controls use black, bright cyan, magenta and white. Sprite buttons
and settings icons retain their original artwork colors and transparency. Touch buttons
use solid fills, and empty health cells use cyan outlines.
The percentage under each icon shows its current value. Music updates while
playing without restarting; the walking loop follows the SFX setting. Changing
SFX volume stops current short effects; subsequent effects use the new level.

CRT starts **OFF** to retain the original pixel-perfect output. Tap the CRT icon
to toggle the shared scanline/RGB-offset shader across all Flame views and HUDs.
The setting does not change camera coordinates or button hit testing. Settings
survive Lore, levels, pause and new runs within the current app instance;
refreshing/restarting restores defaults.
