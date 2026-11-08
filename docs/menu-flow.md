# Menu flow

Like Revalia Obscura and CoolorBurn, entering the outer Menu state selects a
Flame World for the camera. Kuradi now has a small `GameMenuFsm` inside that
outer state, so the intro screens do not become combat or campaign states.

The equivalent of the reference's outer `GameMenu` state is
`GlobalGameState.menu`. `GameMenuFsm` is its nested Intro/Logo/Main/Lore flow.
Each transition calls the old substate's exit before entering the new one.
Leaving the outer Menu calls `leave()`, disabling its timer and menu input;
returning calls `begin()` again. State entry selects a world and injects
`MenuCacheService`, including the sprite-button skins for Start, Lore and Back.

All outer states have explicit sprite-service entries in
`KuradiSaased.stateSpriteServices`; see the ownership table in architecture.md.

| Menu state | View | Transition |
| --- | --- | --- |
| intro | `MenuIntroView`, frame 0 | Any new key down, click, or tap |
| logo | `MenuIntroView`, frame 1 | Automatically after 2 seconds |
| main | `MainMenuView` | Start / Enter; LORE button / L opens lore |
| lore | `LoreView` | Back to Menu button, Escape, or Enter |

`MenuCacheService` loads `CGA-game-intro-logos_256x256-2.png` as two horizontal
256×256 frames. Both intro worlds use a 256×256 pixel-perfect viewport. The
main menu then returns to its existing 320×200 resolution.

The global game remains in `GlobalGameState.menu` throughout the intro, logo, main and lore sub-states.
`KuradiSaased.update(dt)` advances the menu FSM while in Menu. The FSM owns the
logo duration; the static sprite and view do not decide when the menu is ready.
There are no delayed callbacks that can arrive after leaving the intro.

Only the first frame accepts the input that advances the intro. Additional input
during the logo is ignored; it cannot skip the logo or start the level. Returning
to Menu after a game goes directly to the main menu. Restarting the application
plays the intro again.

Adjust `GameMenuFsm.logoDuration` in `lib/gamefsm/game_menu_fsm.dart` to change
the logo's display time.

## Lore view

The LORE menu item (or L key) enters `MenuState.lore`, selecting a separate
`LoreView` World. `CGA-intro-256x256-6.png` supplies six horizontal 256x256 frames.
They loop at 0.25 seconds per frame (4 fps), with nearest-neighbor sampling in a
native 256x256 pixel-perfect viewport. Solid black panels keep Jaan's story and
the return button readable while the background animates.

Jaan is an ex-cop and ex-karate man whose summer has been ruined by mutant
mosquitoes. He thought he was done fighting; now he wants revenge.

The background ticker is decorative only. Combat and campaign progress do not
advance in Lore. Start is guarded to Main Menu; Escape, Enter or the return button
re-enters Main directly without replaying the intro. Menu input is cleared when
opening or closing Lore. The FSM rejects Lore entry from Intro or Logo.
