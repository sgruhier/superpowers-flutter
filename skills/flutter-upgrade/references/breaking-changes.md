# Flutter and Dart breaking-change sources

Read the page for the target release before upgrading. Do not rely on memory.

| Release line | Page |
|---|---|
| All Flutter breaking changes, by release | https://docs.flutter.dev/release/breaking-changes |
| Flutter release notes | https://docs.flutter.dev/release/release-notes |
| Dart language evolution and breaking changes | https://dart.dev/resources/language/evolution |
| Dart SDK changelog | https://github.com/dart-lang/sdk/blob/main/CHANGELOG.md |
| Deprecated Flutter APIs and their replacements | https://docs.flutter.dev/release/breaking-changes#deprecations |
| flutter_bloc migration guide | https://bloclibrary.dev/migration/ |
| go_router changelog | https://pub.dev/packages/go_router/changelog |
| auto_route migration | https://pub.dev/packages/auto_route/changelog |
| fpdart changelog | https://pub.dev/packages/fpdart/changelog |

Recurring themes to check in every SDK bump: Material 3 defaults, `TextScaler` vs `textScaleFactor`, `WillPopScope` → `PopScope`, `Color` component API, deprecated `MediaQuery.of` sub-getters, Gradle/AGP and Xcode minimums, `flutter_lints` new rules.
