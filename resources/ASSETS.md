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

- `jann_idle_80x99-4.png`: Jaan idle.
- `jann_walk_92x99-8.png`: Jaan walk.
- `jaan_punch_108x98-4.png`: Jaan punch.
- `jaan_jump_61x99-5.png`: Jaan jump.
- `spr_mosquito_96x96-4.png`: mosquito flying.

Idle, walk and punch were supplied with 61x99 suffixes; those filenames were
corrected to match their actual PNG cell dimensions without resizing the art.
The replaced individual frames are archived in `art/`.

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


Fighter presentation normalizes Jaan's mostly 4x4 source-pixel blocks at 1/4
scale and mosquito 3x3 blocks at 1/3 scale, rounded to whole game pixels. This
replaces the common half-size rendering, which gave them mismatched pixel grids.


CGA-game-intro-logos_256x256-2.png contains two horizontal 256x256 menu frames:
the title/input prompt, then the Alien Retro Games logo. Both use native-size
presentation without stretching or automatic sprite animation.


Jump uses the five-frame sheet listed above. The older nine
jann_kick2_right exports are now in `art/`; combat uses the three kick sheets
described below. Current kick cells are native 24x24 game pixels and render 1:1.



Three-stage kicks use `jann_low_kick_24x24-6.png`,
`jann_frontal_kick_24x24-7.png`, and
`jann_high_kick_24x24-7.png`, in that order for 1/2/3 damage. Existing combat
IDs `frontKick`, `highKick`, `veryHighKick` retain their timing and hit effects.
The suffix declares cell dimensions and
frame count; the cache validates the image and slices horizontally. No blank
leading cells. Original source PNGs and archived individual kick frames remain
unchanged. The FSM chooses startup/impact/recovery poses from each sheet:
low has six frames: wind up through 0-3, contact on 4-5, and retract through 3-0.
Frontal/high have seven frames: wind up through 0-4, contact on 5-6, and
retract through 4-0. The handler derives these poses from the loaded count,
reserving the final two frames for contact. Combat timings are independent of
frame count. When re-exporting, keep the filename's frame-count suffix accurate
and regenerate FlutterGen references with `flutter pub run build_runner build`.
Renaming a sheet updates metadata only; do not resize artwork to match a stale
suffix. Restart a running game after replacing cached sprite assets.
The current frontal stage loads `jann_frontal_kick_24x24-7.png`; the older
similarly named `jann_front_kick_24x24-7.png` export has been removed.

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

`resources/sound/` is bundled by pubspec.yaml. Current assignments:
`alien_retro_logo_mfx.ogg` (opening one-shot), `alien_retro_intro.ogg` (Lore loop),
`sfx_jaan_jump_1.wav` (accepted takeoff), `sfx_kurat_jaan_walk.ogg` (walking loop),
`blockHit1.mp3` (attack start), `blockHit2.mp3` (enemy contact), and `blockHit3.mp3`
(damage to Jaan). Other imported tracks/jump variants are unassigned.
Walking plays at 1.3x speed; music and other effects retain their normal rate.
Original sound files and codecs are preserved.

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


## Level 3 mosquito grunts

Idle and attacks use the three
`mosquito-grunt-animation-{idle,light-attack,heavy-attack}-small-47x58-*.png`
exports through FlutterGen: 7 idle frames and 4 frames per attack. They face
left and render at the filename's 47x58 frame dimensions without component
downscaling. The cache reads width, height and frame count from the suffix.
Idle already matches that layout. The attack exports are 190x59 and 760x236;
the cache fits their four complete frames to the declared 47x58 cells once at
load time using nearest-neighbor sampling. This avoids rejecting the exports
or cropping their frames. Pure green background pixels become transparent;
source PNGs are unchanged. Older idle/attack exports are not loaded.

`mosquito-grunt-ko-95x119-7.png` (665x119) and
`mosquito-grunt-death1-95x119-12.png` (1140x119) retain their existing 32x40 prepared
frame size and preserve their exported transparency. Ordinary hits sample the
first three KO frames over .25s. A surviving critical finisher plays all seven
KO frames over .56s, holds the fallen pose, then reverses them during the final
.35s of the existing 1.2s stun to stand up. Lethal hits play the 12-frame death
once over .96s; the final pose holds until the death window ends and the entity
is hidden. The old rotated-idle death placeholder is removed.
Jaan's temporary knockdown plays the fall death sheet, holds on the ground,
and reverses the same seven frames to stand up. Lethal hits retain actual death.


## Veteran marker

Level 2 promotes one random small mosquito to veteran rank; level 3 promotes three. `MosquitoEntity`
draws a five-by-five yellow pixel asterisk on a black backing beside its health
bar while alive, following elevation during launches. The marker uses native
game pixels and needs no new sprite or font glyph. Veteran flight/reaction
artwork and health match ordinary mosquitoes; only sting windup/recovery differ.
