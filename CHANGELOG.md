# Changelog

## 0.3.0 - 2026-10-10

Process skills rebased onto obra/superpowers v7.0.0 (from v6.3.0). Upstream notes: v6.4.1, v6.4.2, v7.0.0.

- `brainstorming` rewritten upstream: draws out intent before proposing, plays back what it heard, sizes the work (do it now / agree in chat / design doc), asks which how-it-gets-made choices you want to own, and replaces the spec reviewer with a builder check.
- `executing-plans` rebuilt as Native execution: runs the whole plan inline with the SDD workspace and ledger (`task-start`/`task-done`), then one whole-branch review. No more check-ins every few tasks.
- `writing-plans`: leaner plans that record decisions (signatures, assertions, spec values) instead of code; new Review Focus section; proportion self-review. Our spec-contradiction check is kept as item 6.
- `subagent-driven-development`: per-plan workspaces (same basename no longer collides), `review-package` rejects empty ranges, opt-in nested controller.
- `requesting-code-review`: `merge-base origin/main HEAD` for multi-commit ranges; reviewers judge unspecified behaviour by what a reasonable user expects. Flutter checklist kept in `code-reviewer.md`.
- `test-driven-development`: green means the project's `flutter test` suite, not just your file; report every failure by name.
- `systematic-debugging`: diagnostic example no longer prints the secret it checks.
- `using-superpowers`: Claude Code and Muse tool references.
- hooks: SessionStart survives a broken `PATH`; Windows `run-hook.cmd` finds per-user Git installs and passes exit codes.
- Not ported: `diagnosing-superpowers` (reads superpowers session transcripts; revisit if wanted).

## 0.3.0 - 2026-10-10

Process skills rebased onto obra/superpowers v7.0.0 (from v6.3.0). Upstream notes: v6.4.1, v6.4.2, v7.0.0.

- `brainstorming` rewritten upstream: draws out intent before proposing, plays back what it heard, sizes the work (do it now / agree in chat / design doc), asks which how-it-gets-made choices you want to own, and replaces the spec reviewer with a builder check.
- `executing-plans` rebuilt as Native execution: runs the whole plan inline with the SDD workspace and ledger (`task-start`/`task-done`), then one whole-branch review. No more check-ins every few tasks.
- `writing-plans`: leaner plans that record decisions (signatures, assertions, spec values) instead of code; new Review Focus section; proportion self-review. Our spec-contradiction check is kept as item 6.
- `subagent-driven-development`: per-plan workspaces (same basename no longer collides), `review-package` rejects empty ranges, opt-in nested controller.
- `requesting-code-review`: `merge-base origin/main HEAD` for multi-commit ranges; reviewers judge unspecified behaviour by what a reasonable user expects. Flutter checklist kept in `code-reviewer.md`.
- `test-driven-development`: green means the project's `flutter test` suite, not just your file; report every failure by name.
- `systematic-debugging`: diagnostic example no longer prints the secret it checks.
- `using-superpowers`: Claude Code and Muse tool references.
- hooks: SessionStart survives a broken `PATH`; Windows `run-hook.cmd` finds per-user Git installs and passes exit codes.
- Not ported: `diagnosing-superpowers` (reads superpowers session transcripts; revisit if wanted).

## 0.2.4 - 2026-09-07

- `fpdart`: the Bloc chain gains its "builder" form — when the next state depends on the state re-read after the await, branches return a function of the current state and `.map` applies it. Taken from the mp2ride meetups reference implementation.

## 0.2.3 - 2026-09-07

- `bloc` rule 9: no user-facing text in a Bloc — no `t.*`, no message-key strings. States carry the `Failure` or a notice enum; the widget translates.

## 0.2.2 - 2026-09-07

- `flutter-clean-architecture`: style rules win over a neighbouring feature's precedent. Layout, base classes, tooling and DI follow the codebase; how new code is written follows the skills.
- `fpdart`: the Bloc consumption chain now shows the post-await guard (generation, `isClosed`) inside `.map`, and names the one case where `await x.run()` then `match` is right — a branch that does more than build a state.

## 0.2.1 - 2026-09-06

- `writing-plans` self-review gains a spec-contradiction check: a task that overrides a spec decision must say so and update the spec first, so executors never have to guess which document wins.

## 0.2.0 - 2026-09-06

- New `riverpod` skill, selected from pubspec.yaml; providers replace get_it under Riverpod.
- `flutter-clean-architecture` now reads the existing codebase first and mirrors its dominant layout
  (feature-first clean, Very Good Ventures style, or layer-first) instead of imposing the greenfield one;
  house base classes (e.g. SafeBloc), injectable, fvm and custom_lint are respected.
- fpdart rulings: TaskEither always, Option in domain data, `.match(...).map(emit).run()` in Cubits,
  use cases only when they earn their place.
- Process skills rebased onto obra/superpowers 6.3.0. No Ruby/Rails traces remain; the validator enforces it.
- README rewritten with skill tables and a workflow walkthrough.

## 0.1.0 - 2026-09-04

Initial release. Process skills from superpowers-ruby 7.5.0; new Flutter skills:
dart, flutter-docs, flutter-clean-architecture, bloc, flutter-widget-rules,
flutter-analyze, go-router, auto-route, fpdart, flutter-upgrade, dart-commit-message.
