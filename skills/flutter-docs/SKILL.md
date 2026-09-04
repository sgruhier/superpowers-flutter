---
name: flutter-docs
description: Use when any Flutter or Dart framework, widget, API, tooling, or package question comes up — topic map to official documentation to fetch before answering, plus the vendored Flutter architecture guide
---

# Flutter Docs

## Overview

Fetch the page; do not answer API questions from memory. Signatures, defaults, and deprecations change every release.

## Vendored

- `references/flutter-architecture-guide.md` — official layered architecture (UI / logic / data), the basis for `superpowers-flutter:flutter-clean-architecture`
- `references/flutter-architecture-recommendations.md` — one-page do/consider list
- `references/flutter-architecture-concepts.md` — separation of concerns, unidirectional data flow

Refresh with `scripts/refresh-architecture-docs.sh`.

## Topic map

### Flutter framework — https://docs.flutter.dev
| Topic | URL |
|---|---|
| Widget catalog | https://docs.flutter.dev/ui/widgets |
| Layout | https://docs.flutter.dev/ui/layout |
| Constraints ("unbounded height" errors) | https://docs.flutter.dev/ui/layout/constraints |
| Navigation overview | https://docs.flutter.dev/ui/navigation |
| Deep linking | https://docs.flutter.dev/ui/navigation/deep-linking |
| State management options | https://docs.flutter.dev/data-and-backend/state-mgmt/options |
| Networking | https://docs.flutter.dev/data-and-backend/networking |
| JSON serialization | https://docs.flutter.dev/data-and-backend/serialization/json |
| Local persistence | https://docs.flutter.dev/cookbook/persistence |
| Animations | https://docs.flutter.dev/ui/animations |
| Accessibility | https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility |
| Internationalization | https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization |
| Testing overview | https://docs.flutter.dev/testing/overview |
| Widget tests | https://docs.flutter.dev/cookbook/testing/widget/introduction |
| Golden tests | https://api.flutter.dev/flutter/flutter_test/matchesGoldenFile.html |
| Performance best practices | https://docs.flutter.dev/perf/best-practices |
| DevTools | https://docs.flutter.dev/tools/devtools |
| Platform channels | https://docs.flutter.dev/platform-integration/platform-channels |
| Isolates | https://docs.flutter.dev/perf/isolates |
| Build and release Android | https://docs.flutter.dev/deployment/android |
| Build and release iOS | https://docs.flutter.dev/deployment/ios |
| Flavors | https://docs.flutter.dev/deployment/flavors |
| Breaking changes | https://docs.flutter.dev/release/breaking-changes |
| API reference | https://api.flutter.dev |

### Dart — https://dart.dev
| Topic | URL |
|---|---|
| Language tour | https://dart.dev/language |
| Patterns | https://dart.dev/language/patterns |
| Records | https://dart.dev/language/records |
| Class modifiers | https://dart.dev/language/class-modifiers |
| Extension types | https://dart.dev/language/extension-types |
| Null safety | https://dart.dev/null-safety/understanding-null-safety |
| Async programming | https://dart.dev/libraries/async/async-await |
| Streams | https://dart.dev/libraries/async/using-streams |
| Isolates | https://dart.dev/language/isolates |
| Effective Dart | vendored in `superpowers-flutter:dart` |
| Linter rules | https://dart.dev/tools/linter-rules |
| `dart fix` | https://dart.dev/tools/dart-fix |
| pub workspaces / monorepo | https://dart.dev/tools/pub/workspaces |
| Core libraries | https://dart.dev/libraries |

### Packages used by this stack
| Package | Docs |
|---|---|
| flutter_bloc / bloc | https://bloclibrary.dev — concepts: https://bloclibrary.dev/bloc-concepts/ — testing: https://bloclibrary.dev/testing/ |
| bloc_test | https://pub.dev/packages/bloc_test |
| bloc_concurrency | https://pub.dev/packages/bloc_concurrency |
| equatable | https://pub.dev/packages/equatable |
| get_it | https://pub.dev/packages/get_it |
| go_router | https://pub.dev/packages/go_router — https://pub.dev/documentation/go_router/latest/topics/Get%20started-topic.html |
| go_router_builder | https://pub.dev/packages/go_router_builder |
| auto_route | https://pub.dev/packages/auto_route |
| fpdart | https://pub.dev/packages/fpdart — https://github.com/SandroMaglione/fpdart |
| mocktail | https://pub.dev/packages/mocktail |
| freezed (optional) | https://pub.dev/packages/freezed |
| json_serializable (optional) | https://pub.dev/packages/json_serializable |
| dio | https://pub.dev/packages/dio |
| flutter_secure_storage | https://pub.dev/packages/flutter_secure_storage |
| rxdart | https://pub.dev/packages/rxdart |

## How to use

1. Find the row; fetch the URL.
2. For a class or method, append the symbol to the api.flutter.dev search: `https://api.flutter.dev/flutter/search.html?q=<Symbol>` or open the library page directly, e.g. `https://api.flutter.dev/flutter/widgets/ListView-class.html`.
3. For a pub package's API, use `https://pub.dev/documentation/<package>/latest/`.
4. Quote the version the doc applies to when the answer depends on it.
