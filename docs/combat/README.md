# Updating the combat guide

The FSM documentation is a standalone page at `web/combat-diagram.html`; it has
no entry in the game menu. Type `combat-diagram.html` after the running game's
base URL (for example `http://127.0.0.1:8765/combat-diagram.html`), or open the HTML
file directly from disk. It contains static SVGs rendered
with Pele 1.6.0, an embedded retro font, and all of its CSS. Viewing the page
requires no server-side renderer, JavaScript library, or network requests.

Each `.mmd` file here is an editable Mermaid source. The two `-mobile.mmd`
variants show the same flow without wide return loops or side-by-side branches;
the text explains the full transition rules at every screen size. Both source
variants are expandable in the guide.

Edit the sources and `tool/combat-guide-template.html`, then regenerate with a
current Node.js executable and a local Pele 1.6.0 ESM module:

```powershell
node tool/render_combat_guide.mjs C:\path\to\pele.mjs
```

If the `pele` package is installed locally, omit the module argument. The renderer
does not launch a browser or server. It writes only `web/combat-diagram.html`.
Flutter includes that page when building the web game; rebuild the web game to
update an existing release. An already-open guide tab also needs refreshing.

When combat changes, check the timing/effects tables and prose in the template
against `AttackSpec`, `FighterModel`, `CombatLogicService`,
`FighterAnimationHandler`, `LevelEndingModel`, and `KuradiSaased.update`. Numeric descriptions are
documentation, not values loaded automatically from Dart. Keep the template's
embedded font and original console styling when revising the content.

Verify desktop and phone layouts: all six diagrams should render, labels should
remain inside their SVGs, only the timing/effect tables may scroll horizontally,
and the page should load without network requests. Do not start a game server
just to regenerate this page.
