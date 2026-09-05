---
name: flutter-upgrade
description: Use when bumping the Flutter or Dart SDK, or upgrading a package across a major version — ordered upgrade workflow, changelog and breaking-change reading, dart fix, deprecation triage, verification
---

# Flutter Upgrade

## Overview

Upgrades are done one axis at a time: SDK first, then packages, each on its own branch with a green baseline before and after. Read changelogs; do not guess migrations.

## Before starting

```bash
flutter --version
flutter doctor -v
flutter analyze && flutter test        # baseline must be green
git switch -c chore/flutter-upgrade
```

If the baseline is red, stop and fix first (`superpowers-flutter:systematic-debugging`).

## SDK upgrade

1. Read `references/breaking-changes.md` and open the breaking-changes page for every minor release between current and target.
2. If the project pins the SDK (`fvm`, `.fvmrc`, `asdf`), change the pin (`fvm use <version>`). Otherwise `flutter upgrade` for the latest stable; for a specific older version, pin it per-project with `fvm use <version>` instead — do not check out a tag inside the global SDK install, which is shared by every project on the machine.
3. Update `environment.sdk` in `pubspec.yaml` to the new floor.
4. `flutter pub get`, then `dart fix --apply`, then `flutter analyze`.
5. Grep for known deprecations listed in the breaking-changes page and migrate by hand.
6. `flutter test`, then run the app on one iOS simulator and one Android emulator; check platform folders (`android/build.gradle` AGP/Kotlin versions, `ios/Podfile` platform floor) against `flutter create --platforms=ios,android .` output on a scratch project of the same name.
7. Commit: `chore(sdk): upgrade Flutter to X.Y.Z`.

## Package upgrades

```bash
flutter pub outdated                     # see Resolvable vs Latest
scripts/fetch-changelogs.sh go_router flutter_bloc   # read what changed
flutter pub upgrade                      # within constraints
flutter pub upgrade --major-versions     # cross majors, rewrites pubspec
flutter pub get
dart run build_runner build  # if codegen is used
dart fix --apply && flutter analyze && flutter test
```

Upgrade in this order, one commit each: lints (`flutter_lints`) → core (`flutter_bloc`, `equatable`, `get_it`, `fpdart`) → routing (`go_router` / `auto_route`) → data (`dio`/`http`, storage) → codegen (`build_runner`, generators) → everything else. Read the changelog section between the old and new version for every major bump before touching code.

## Deprecation triage

| Analyzer says | Do |
|---|---|
| `deprecated_member_use` with a replacement named in the message | replace now |
| Deprecated with no replacement yet | leave, add a `// TODO(upgrade): <rule> — removed in <version>` and open an issue |
| Deprecation inside a dependency | upgrade that dependency; if none available, pin and note |

Never turn off `deprecated_member_use`.

## Verification

- `flutter analyze` → `No issues found!`
- `flutter test` green
- App boots on both platforms; the two or three most-used flows clicked through
- `flutter build apk --debug` and `flutter build ios --simulator --debug` succeed
- `pubspec.lock` committed

Use `superpowers-flutter:verification-before-completion` before claiming done.

## Common Mistakes

| Mistake | Fix |
|---|---|
| SDK and 15 packages in one commit | one axis per commit |
| `--major-versions` without reading changelogs | read first, script above |
| Forgetting `build_runner` after codegen package bump | regenerate, commit `.g.dart` |
| Ignoring `flutter doctor` warnings about Xcode/AGP | fix toolchain first |
| Trusting memory for migrations | open the breaking-changes page |
