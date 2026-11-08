# Application UML: views and models in every state

These diagrams describe the implemented app. Select a state in the
[interactive browser page](../web/app-architecture.html) to inspect its views,
models and asset services. With the web game running, open
`app-architecture.html` beside its index page.

`*--` means lifecycle ownership, `-->` a held reference, `..>` a dependency or
value passed during construction, and `<|--` inheritance. A screen does not
automatically have its own model: several receive values and callbacks from the
game. Dashed arrows explicitly distinguish these snapshots from model fields.

## Application ownership

The game composes the application. State entry selects the visible Flame World.
Campaign/settings survive world changes; combat is replaced on level loading.
Pause retains the current arena and combat. Asset services last for the game
instance. The game owns LevelCacheService, which manages fighter/scenario caches.

```mermaid
classDiagram
    direction TB
    class KuradiSaased
    class GlobalGameFsm
    class GameMenuFsm
    class CampaignModel
    class GameSettings
    class CombatLogicService
    class LevelEndingModel
    class World
    class ScreenView
    class ArenaView
    class LevelCacheService
    class FighterCacheService
    class ScenarioCacheService
    KuradiSaased *-- GlobalGameFsm : application state
    KuradiSaased *-- GameMenuFsm : menu substate
    KuradiSaased *-- CampaignModel : run progress
    KuradiSaased *-- GameSettings : shared settings
    KuradiSaased *-- CombatLogicService : current combat
    KuradiSaased *-- LevelEndingModel : result phases
    KuradiSaased --> World : visible camera world
    World <|-- ScreenView
    World <|-- ArenaView
    ArenaView --> CombatLogicService : same simulation
    KuradiSaased *-- LevelCacheService : level assets
    LevelCacheService *-- FighterCacheService : managed disposal
    LevelCacheService *-- ScenarioCacheService : managed disposal
```

## Menu

Menu contains Intro, Logo, Main and Lore substates. Intro/Logo use the same view
class with a different frame index. MainMenuView receives callbacks, a loading
error value and settings controls; it has no dedicated MainMenuModel. Settings
controls reach shared settings and their cache through the game.

```mermaid
classDiagram
    direction TB
    class KuradiSaased
    class GameMenuFsm
    class ScreenView
    class MainMenuView
    class World
    class MenuIntroView
    class LoreView
    class SettingsControls
    class GameSettings
    class SettingsCacheService
    class MenuCacheService
    class ButtonSpriteCacheService
    KuradiSaased *-- GameMenuFsm : intro logo main lore
    KuradiSaased ..> MainMenuView : creates with callbacks and error
    KuradiSaased ..> MenuIntroView : creates with frames and index
    KuradiSaased ..> LoreView : creates with back callback
    ScreenView <|-- MainMenuView
    World <|-- ScreenView
    World <|-- MenuIntroView
    World <|-- LoreView
    MainMenuView *-- SettingsControls : child component
    SettingsControls --> KuradiSaased : game reference
    KuradiSaased *-- GameSettings : settings
    KuradiSaased *-- SettingsCacheService : settings art
    MainMenuView --> MenuCacheService : sprites
    LoreView --> MenuCacheService : sprites
    MenuIntroView ..> MenuCacheService : receives cached frames
    MenuCacheService --> ButtonSpriteCacheService : shared button art
```

## Loading

LoadingView gets a description string and LoadingCacheService. The game reads
the campaign's current LevelDefinition, creates combat and mounts the next arena
off-camera before entering Level. LoadingView does not construct those models.

```mermaid
classDiagram
    direction TB
    class KuradiSaased
    class CampaignModel
    class LevelDefinition
    class ScreenView
    class LoadingView
    class LoadingCacheService
    class CombatLogicService
    class ArenaView
    KuradiSaased --> CampaignModel : reads current level
    CampaignModel *-- LevelDefinition : configured levels
    ScreenView <|-- LoadingView
    KuradiSaased ..> LoadingView : creates with title snapshot
    LoadingView --> LoadingCacheService : loading animation
    KuradiSaased ..> CombatLogicService : creates from definition
    KuradiSaased ..> ArenaView : loads and mounts before Level
    ArenaView --> CombatLogicService : injected simulation
```

## Arena / Level

ArenaView holds combat and shared caches. Each entity references the exact model
updated by combat. Its handler selects frames from state/time. ArenaHud and
LevelResultPopup are camera viewport children, not ArenaView children; both hold
the game and read the relevant state through it. Animations cannot change rules.

```mermaid
classDiagram
    direction TB
    class KuradiSaased
    class ArenaView
    class CombatLogicService
    class InputService
    class FighterModel
    class PlayerModel
    class EnemyModel
    class MosquitoModel
    class GruntModel
    class FighterEntity
    class EnemyEntity
    class PlayerEntity
    class MosquitoEntity
    class GruntEntity
    class FighterAnimationHandler
    class FighterCacheService
    class ScenarioCacheService
    class StreetScenery
    class ArenaHud
    class LevelResultPopup
    class LevelEndingModel
    KuradiSaased --> ArenaView : active world
    KuradiSaased *-- CombatLogicService : simulation
    CombatLogicService ..> InputService : consumes intent
    CombatLogicService *-- PlayerModel : player
    CombatLogicService *-- EnemyModel : enemies
    FighterModel <|-- PlayerModel
    FighterModel <|-- EnemyModel
    EnemyModel <|-- MosquitoModel
    EnemyModel <|-- GruntModel
    ArenaView --> CombatLogicService : reads existing models
    ArenaView *-- FighterEntity : children created by factory
    FighterEntity <|-- PlayerEntity
    FighterEntity <|-- EnemyEntity
    EnemyEntity <|-- MosquitoEntity
    EnemyEntity <|-- GruntEntity
    PlayerEntity --> PlayerModel : typed model
    MosquitoEntity --> MosquitoModel : typed model
    GruntEntity --> GruntModel : typed model
    FighterEntity *-- FighterAnimationHandler : frame selection
    FighterAnimationHandler --> FighterCacheService : shared frames
    ArenaView --> FighterCacheService : injected cache
    ArenaView *-- StreetScenery : background child
    StreetScenery --> ScenarioCacheService : shared scenery
    ArenaHud --> KuradiSaased : reads combat and campaign
    LevelResultPopup --> KuradiSaased : reads ending result
    KuradiSaased *-- LevelEndingModel : settlement and popup
```

The detailed [fighter UML](fighter-arena-uml.md) expands each concrete animation
handler and its typed model contract.

## Pause

PauseView receives callbacks and SettingsControls. It does not contain combat or
copy fighter models. KuradiSaased retains the existing ArenaView and simulation,
stops combat updates, and restores that same world on resume.

```mermaid
classDiagram
    direction TB
    class KuradiSaased
    class ScreenView
    class PauseView
    class PauseCacheService
    class SettingsControls
    class GameSettings
    class ArenaView
    class CombatLogicService
    KuradiSaased ..> PauseView : creates with resume and menu callbacks
    ScreenView <|-- PauseView
    PauseView --> PauseCacheService : sprites
    PauseView *-- SettingsControls : child component
    SettingsControls --> KuradiSaased : settings actions
    KuradiSaased *-- GameSettings : shared settings
    KuradiSaased --> ArenaView : retains paused world
    ArenaView --> CombatLogicService : same frozen simulation
    KuradiSaased ..> ArenaView : restores on resume
```

## Score

CampaignModel records one LevelResult per encounter. GameScoreView holds that
result and scalar snapshots for totals, level numbers and next-level status.
It does not hold CampaignModel directly. Continue calls the game, which advances
the campaign and selects Loading or End. The old arena reference is cleared.

```mermaid
classDiagram
    direction TB
    class KuradiSaased
    class CampaignModel
    class LevelResult
    class ScreenView
    class GameScoreView
    class ScoreCacheService
    KuradiSaased --> CampaignModel : records and advances progress
    CampaignModel --> LevelResult : recorded result
    ScreenView <|-- GameScoreView
    KuradiSaased ..> GameScoreView : creates with totals and callback
    GameScoreView --> LevelResult : result field
    GameScoreView --> ScoreCacheService : continue button art
    GameScoreView ..> CampaignModel : receives scalar snapshots via game
```

## End

GameEndView receives completion and score snapshots plus a menu callback. There
is no EndModel and no direct CampaignModel field. The campaign remains owned
by the game; a new run resets it when the player starts from Menu.

```mermaid
classDiagram
    direction TB
    class KuradiSaased
    class CampaignModel
    class ScreenView
    class GameEndView
    class EndCacheService
    KuradiSaased --> CampaignModel : reads completed and totalScore
    ScreenView <|-- GameEndView
    KuradiSaased ..> GameEndView : creates with snapshots and menu callback
    GameEndView --> EndCacheService : menu button art
    GameEndView ..> CampaignModel : receives scalar snapshots via game
```

## Regenerating the browser diagram

Run `node tool/render_app_architecture.mjs build/pele-1.6.0.mjs` from the project
root, or supply another local path to Pele 1.6.0. The generator embeds SVGs,
Mermaid source and the existing retro font into `web/app-architecture.html`.
The output works offline and ships beside the web game on the next web build.
