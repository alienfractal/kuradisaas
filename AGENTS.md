# Kuradi Saased project guidance

This directory is the active Dart/Flutter/Flame game. Archived GameMaker assets and sibling CoolorBurn checkouts are references; do not modify them during ordinary game changes.

## Workflow

For implementation, debugging, code review, and refactoring, read and apply `.agents/skills/ub-mode/SKILL.md`, this project's adaptation of Uncle Bob's workflow. Explaining code or discussing architecture is not an instruction to refactor it.

Read relevant sections of `docs/architecture.md` and `resources/ASSETS.md` before changing their areas. Check the working-tree status and preserve changes outside the task.

## Architecture agreements

- Combat state, timing, movement, damage, and outcomes belong to the pure simulation/model layer. `CombatLogicService` must not depend on Flutter, Flame, loaded images, or animation callbacks.
- Views/entities own presentation and read combat state. Cache services own shared sprite resources. The game/FSM owns screen composition and lifecycle.
- Represent mutually exclusive fighter identities explicitly rather than accumulating boolean flags. For new types, evaluate configuration, composed behavior, and specialized models/entities. Share common mechanics without centralizing every character-specific decision. Use the typed `FighterModel`/`FighterEntity` hierarchy; do not reintroduce writable character-type flags or type branches in shared rendering.
- An enum identifies a category; switches are appropriate at deliberate selection boundaries. Repeated type switches across unrelated systems indicate responsibilities that need separation.
- Keep source dimensions, prepared pixel resolution, draw size, component scale, and camera/window scale distinct. A scale experiment should not silently resample assets or change combat reach/hurt regions. Preserve original PNGs unless editing them is requested.
- Reuse sprite specs, cache services, and FlutterGen asset/font references. Regenerate `lib/gen/` files rather than hand-editing them. Keep cache ownership, resource disposal, and failure retry explicit.
- Introduce a new layer, specialized class, or generalized framework only when the requested behavior gives it a concrete purpose.

## Verification

Run commands from this directory:

```text
dart format <changed Dart files>
flutter analyze --no-pub
flutter test --no-pub <relevant test files>
```

For changes spanning combat, campaign flow, or shared rendering, run `flutter test --no-pub`. Reproduce combat bugs with behavior tests where practical. Test gameplay outcomes, including relevant interruption/lifecycle cases, rather than duplicating implementation details.

Inspect actual renders for sprite/rendering changes. Existing entrypoints are `flutter test --no-pub tool/render_street_preview.dart` and `flutter test --no-pub tool/render_grunt_preview.dart`; output goes to `build/`. Label comparison previews with draw-size and pixel-preparation assumptions so they cannot be mistaken for current gameplay.

If the Flutter launcher stalls, its installed SDK's cached Dart executable and `flutter_tools.snapshot` can run the same commands directly. SDK cache/lock access may require filesystem approval; do not modify SDK files or bypass permission checks. Report checks that could not run.

## Delivery

Update relevant existing documentation for meaningful architecture or asset-pipeline changes. State what changed, why, and checks actually completed. Do not claim unsupported numeric quality metrics. Commit, push, and clean up worktrees only within user authorization, preserving unrelated work.
