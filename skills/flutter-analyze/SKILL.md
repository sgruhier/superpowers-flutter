---
name: flutter-analyze
description: Use before committing or requesting review, when analyzer warnings appear, or when setting up lints in a Flutter project — strict analysis_options baseline, flutter analyze / dart fix workflow, warning triage, zero-warning policy
---

# Flutter Analyze

## Overview

Static analysis is the first reviewer. The bar is zero issues from `flutter analyze` on every commit, with the strict baseline in `references/analysis_options.yaml`.

## Setup

1. Copy `references/analysis_options.yaml` to the project root (merge if one exists; keep the project's stricter choices).
2. `flutter pub add --dev flutter_lints` if missing.
3. Run `flutter analyze`. If the project is old and the count is large, fix mechanically first (`dart fix --apply`), then triage the rest by rule (see below) rather than by file.

`very_good_analysis` is an acceptable stricter drop-in: `include: package:very_good_analysis/analysis_options.yaml`. Do not stack both includes.

## Workflow

If `.fvmrc` or `.fvm/` exists, prefix every command below with `fvm`.

```bash
dart format .                 # formatting is not negotiable
flutter analyze               # list issues
dart fix --dry-run            # preview mechanical fixes
dart fix --apply              # apply them
flutter analyze               # must print "No issues found!"
dart run custom_lint          # if custom_lint is a dev dependency — analyze does not run it
```

Run this sequence before `superpowers-flutter:requesting-code-review` and before every commit. Add it to CI:

```yaml
- run: dart format --output=none --set-exit-if-changed .
- run: flutter analyze --fatal-infos
```

## Triage rules

| Situation | Action |
|---|---|
| `dart fix` can fix it | apply, no discussion |
| Real bug (`use_build_context_synchronously`, `unawaited_futures`, `cancel_subscriptions`) | fix the code |
| Style rule the team disagrees with | disable the rule project-wide in `analysis_options.yaml` with a comment saying why; never suppress per-line |
| Generated code | already excluded; if not, add the glob to `analyzer.exclude` |
| Genuine one-off (platform API that must use `dynamic`) | `// ignore: <rule>` on that line with a trailing reason: `// ignore: avoid_dynamic_calls, platform channel returns untyped map` |

`// ignore_for_file:` is allowed only in generated or vendored files.

## Reading the output

```
   info • Prefer const with constant constructors • lib/features/auth/presentation/pages/login_page.dart:42:12 • prefer_const_constructors
```
Columns: severity, message, `file:line:col`, rule name. Group by rule name to decide once per rule.

## Metrics worth watching

- `flutter analyze` count: must be 0.
- `dart pub outdated` count of major-behind packages (see `superpowers-flutter:flutter-upgrade`).
- `flutter test --coverage` + `lcov --summary coverage/lcov.info` if coverage is tracked; do not gate on a number without agreeing it first.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Suppressing with `// ignore` to get green | fix or disable the rule globally with a reason |
| Running analyze only in CI | run locally before commit |
| Not excluding generated files | add globs, otherwise `dart fix` edits them |
| `flutter analyze` on a pure Dart package | `dart analyze` |
| Running only `flutter analyze` in a project with `custom_lint` | also run `dart run custom_lint` (or `fvm dart run custom_lint`) — analyze does not run it |
