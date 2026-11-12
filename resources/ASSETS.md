# Imported assets

Runtime images stay in `resources/images/`. Editable Aseprite sources and unused
exports live in the project-root `art/` directory, outside the Flutter bundle.

`buttonstart.png` is copied unchanged from RevaliaObscura's resources. The shared
button cache retains its original colors and transparency. `GameButton` uses its border with
nine-slice rendering and supplies the action label in place of its baked START
text. Menu, Lore, Pause, Score and End use these cached sprite buttons; FlutterGen
supplies the asset reference.

Images originate from the user's existing GameMaker sprite frames from:
`../../KuradiSaased-5/KuradiSaased-5/sprites/images/` (relative to this file).

Current runtime animations use horizontal sheets:

- `new-jan-animationwalking-46x58-7.png`: Jaan walk.
- `new-jan-mpunch-46x58-5.png`: Jaan punch and idle stance.
- `new-jan-animation-jump-46x58-2.png`: Jaan jump.
- `spr_mosquito_96x96-4.png`: mosquito flying.

Idle uses the opening stance from the punch sheet. The walk and jump sheets'
alpha-1 backgrounds are cleared at load time. The jump uses the first frame at
takeoff and near landing, and the second through the middle of the arc. The
previous strips and the individual frames in `art/` are reference exports.

Left-facing presentation mirrors the right-facing frames. PNG transparency is
preserved. The original archives and source images are untouched.

`fonts/PressStart2P-Regular.ttf` is copied from the user's RevaliaObscura
`resources/fonts/` directory. No new artwork has been generated.

## Street scenario

The static street uses scenariot-wide-front-street-house_640x320-1.png.
The stars strip scenariot-wide-stars_640x320-3.png is 2560x320: an empty first
cell followed by three 640x320 frames. The empty cell is skipped.
ScenarioSheet reads the WIDTHxHEIGHT-FRAMES filename suffix. All original PNGs
are unchanged; black is drawn in code behind the transparent layers.


Jaan's frames draw at native size. The 46x58 cells place the foot line 12 pixels
above the bottom, so the renderer aligns that line with the ground. Regular
and veteran mosquito flight frames draw at 32x32 game pixels.


CGA-game-intro-logos_256x256-2.png contains two horizontal 256x256 menu frames:
the title/input prompt, then the Alien Retro Games logo. Both use native-size
presentation without stretching or automatic sprite animation.


The two kicks use `new-jan-mkick-46x58-3.png` and `new-jan-hkick-46x58-5.png`
for 2 and 3 damage respectively. The cache validates the horizontal cells
using dimensions and frame count from the filename. Both kicks use their final
two frames for contact and reverse the
windup during recovery. Punch uses frames 0–1 for windup, 2–3 for contact,
and 4–1–0 for recovery. The death sequences use 24x24 cells. Combat timings are independent of frame
count. When re-exporting, keep the filename's frame-count suffix accurate
and regenerate FlutterGen references with `flutter pub run build_runner build`.
Restart a running game after replacing cached sprite assets.

## Mosquito reactions

`mosquito-hit-32x32-5.png` (5 frames) and `mosquito-dead_32x32t-7.png`
(7 frames) use native 32x32 cells, rendered at 32x32 game pixels. Flight uses
older 96x96 source art normalized to the same size. The sheet parser accepts
hyphen/underscore separators and the optional `t` after dimensions. The original
files keep their names. `mosquito-hit-5.png` is not loaded because the version
with dimensions provides the metadata needed for slicing.

Hurt plays once over .25s, holding the final frame during longer stun. Death
plays once over .56s before disappearing. Both use the fighter FSM state clock,
including a fresh recoil on repeated damage. Native reaction art is not squashed
or blinked. Launch motion still comes from combat elevation.

## Lore background

`CGA-intro-256x256-6.png` contains six horizontal 256x256 frames. `MenuCacheService`
validates and preloads them; the separate `LoreView` loops at four frames per
second behind solid story panels. Source art is unchanged.

## Jaan death

`jann_death_24x24-7.png` and `jann_death-wound_24x24-7.png`: seven horizontal 24x24 frames each, played once
over .84s from the fighter's dead-state time. The canvas renders at native 24x24
size; the lying pose retains its original canvas and is not squashed. Final frame holds while
the result popup is visible. Source PNG unchanged.
The model chooses either variant with equal probability on entering Dead and
keeps that choice for the full sequence and final pose.

## Sound assets

`resources/sound/` is bundled by pubspec.yaml. Recorded assignments:
`alien_retro_logo_mfx.ogg` (opening one-shot), `alien_retro_intro.ogg` (Lore loop),
`sfx_jaan_jump_1.wav` (accepted takeoff), `sfx_kurat_jaan_walk.ogg` (walking loop),
`blockHit1.mp3` (attack start), `blockHit2.mp3` (enemy contact), and `blockHit3.mp3`
(damage to Jaan). Other imported tracks/jump variants are unassigned.
Walking plays at 1.3x speed; music and other effects retain their normal rate.
Original sound files and codecs are preserved. In MIDI mode, web uses only the two music
recordings at runtime. Its effects and footsteps use authored MIDI note
phrases in `lib/audio/midi/midi_cues.dart`, rendered by the original procedural
patches in `web/midi_synth.js`. There is no bank, WASM binary or third-party
synthesizer to bundle or license. The JS file is copied by Flutter's web build,
loaded relative to the application base URL, and needs no FlutterGen entry.
The existing effect assets support the selectable MP3 mode on web and the
native recording adapter;
no generated asset names or source recordings changed.

## Shared settings art and shader

Copied unchanged from `coolorburn_pixel_warnings/resources/images`:
`soundfx-volume.png` and `musicfx-volume.png` (four 34x34 cells each), and
`crton-32x32-8.png` (eight 32x32 cells). Volume frames match full/medium/low/mute.
These appear on Main Menu and Pause, with current values below the icons.
`SettingsCacheService` loads the original PNGs directly, preserving their colors
and transparency. Sprites are not palette-converted or tinted.

`resources/shaders/crt.frag` adapts CoolorBurn's shared `test.frag` RGB offsets
and scanlines to Flutter's portable fragment coordinates. It is declared under
pubspec's shaders, compiled by Flutter, and applied only while CRT is enabled.
All original sprite art stays unchanged.


## Mosquito grunts

Grunts use `grunt-idle-47x58-7.png`,
`grunt-attack-light-47x58-4.png`, `grunt-attack-heavy-47x58-4.png`,
`grunt-mosquito-dead-47x58-7.png` and `grunt-fatal-47x58-15.png` through FlutterGen.
All five sheets face left and draw at their native frame sizes. Idle, knockdown,
and fatal frames are 47x58. The 190x58 light attack sheet is divided at whole
pixel boundaries into 48, 47, 48, and 47px wide frames. The 188x59 heavy attack
sheet has four 47x59 frames.
It clears the alpha-1 background on the knockdown and fatal sheets. The source
PNGs are preserved.

Ordinary hits sample the first three knockdown frames over .25s. A surviving
critical finisher plays all seven frames over .56s, holds the fallen pose,
then reverses them during the final .35s of the 1.2s stun. Lethal hits play all
15 fatal frames over .96s and hold the final pose until the entity is hidden.
Jaan's temporary knockdown uses `new-jan-animationko-48x56-6.png`. The PNG is
276x58, so the cache slices six native 46x58 frames and clears the alpha-1
background. Jaan falls, holds the last pose on the ground, then plays the
same frames in reverse to stand up.


## Veteran marker

Level 2 promotes one random small mosquito to veteran rank; level 3 promotes three. `MosquitoEntity`
draws a five-by-five yellow pixel asterisk on a black backing beside its health
bar while alive, following elevation during launches. The marker uses native
game pixels and needs no new sprite or font glyph. Veterans share their flight
and reaction artwork with ordinary mosquitoes.
