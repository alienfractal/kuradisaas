---
name: ub-mode
description: Implement, debug, review, and refactor Kuradi Saased Dart/Flutter/Flame code with explicit domain models, clear ownership, and behavior verification. Use for game code and architecture changes, including new fighter types; explanations alone do not trigger a refactor.
---

# UB Mode for Kuradi Saased

Project adaptation informed by [unclebob/ub-mode](https://github.com/unclebob/ub-mode/blob/master/SKILL.md), not an installation of the upstream skill. Read the repository's `AGENTS.md` and relevant parts of `docs/architecture.md`. Keep the workflow within the requested task.

## First make it work

- Establish the observable outcome and reproduce a reported bug. For a logic bug or new combat rule, add a failing behavior test before the production change when practical; verify why it fails. For a visual defect, capture a representative scene instead of inventing an assertion that cannot detect the defect.
- Inspect the data model before extending its conditions. Identify where the new decision belongs. Reconsider a repeated failed premise rather than adding another patch around it.
- Choose the smallest coherent change. Remove obsolete paths when replacing them; avoid speculative abstractions and tools for one-off edits. Validate external values at input boundaries, use explicit types for exclusive alternatives, and do not suppress type errors to accommodate an invalid model.

## Make this game's responsibilities clear

- A new enemy needs identity/configuration, combat behavior, and presentation ownership. An enum identifies a category; it does not justify scattering enemy-specific switches through unrelated services.
- Choose configuration, composition, or a specialized model/entity based on what differs. Share common position, health, and proven mechanics. Keep distinct player control and enemy decisions separate. Do not require a subclass just because a sprite differs, or force every behavior into one class to avoid subclasses.
- Keep `CombatLogicService` independent of Flutter/Flame. Damage, cooldowns, knockdown, and recovery must be testable without loading images. Rendering reads simulation state; animation completion must not grant actions, deal damage, or finish a level.
- For art adjustments, distinguish source dimensions, prepared image resolution, draw size/component scale, and camera/viewport scale. Identify which the request concerns. Keep experimental scale percentages in presentation, separate from asset decoding. Explain deliberate pixel-data or collision changes.
- Use established caches and generated asset references. Validate sheet layout before slicing, preserve source artwork, and make transformed-image ownership/disposal explicit. Failed cached loads must remain retryable.

## Then make it right

- Establish observable behavior before restructuring. Complete and verify one unit before proceeding to the next.
- Exercise attacks through combat update/input when checking game rules. Include interruption and recovery when relevant, rather than testing only preselected states or private field assignments.
- Review responsibilities as well as test results. Ask whether the next enemy would require unrelated edits, whether decisions are duplicated, and whether each abstraction isolates a reason to change.
- Run focused checks first. Broader combat, campaign, or shared rendering changes require the full Flutter suite. Analyze and format changed Dart files. Inspect art changes in a render at the actual game viewport scale.
- Upstream CRAP below 10, duplication similarity below 0.8, and mutation testing are conditional quality goals. Use compatible, configured tools when available. The linked tools do not currently advertise Dart support: report an unavailable measurement rather than a passing score. Do not install another toolchain just to satisfy these gates.

## Practice

- For substantial changes, update relevant architecture/asset documentation with decisions and verification evidence. Routine progress belongs in conversation, not a permanent log of every command.
- Before compaction or handoff, summarize the objective, changed files, decisions, checks, and remaining work.
- Preserve unrelated working-tree changes. Keep requested commits small and ordered, with verification. This skill does not direct automatic commits, pushes to main, or worktree deletion.
- Report resulting behavior, material design decisions, checks actually run, and limitations. Distinguish proposed architecture from implemented code.
