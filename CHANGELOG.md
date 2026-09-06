# Changelog

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
