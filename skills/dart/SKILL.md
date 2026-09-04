---
name: dart
description: Use when writing, reviewing, or debugging any Dart code — Effective Dart style and design, Dart 3 features (records, patterns, sealed classes, class modifiers), error handling, null safety, async idioms
---

# Dart Language Skill

## Overview

Effective Dart is the style guide; this skill adds the Dart 3 patterns agents skip by default and the error-handling conventions used by `superpowers-flutter:flutter-clean-architecture`. Run `dart format` and `flutter analyze` on everything.

## Effective Dart (vendored)

Read the relevant section when unsure; do not answer from memory.

- `references/effective-dart-style.md` — identifiers, ordering, formatting
- `references/effective-dart-documentation.md` — doc comments, `///`, what to document
- `references/effective-dart-usage.md` — libraries, null, strings, collections, functions, variables, members, constructors, error handling, asynchrony
- `references/effective-dart-design.md` — names, libraries, classes and mixins, constructors, members, types, parameters, equality

Refresh with `scripts/refresh-effective-dart.sh`.

Non-negotiable highlights:
- `UpperCamelCase` types, `lowerCamelCase` members and constants (no `SCREAMING_CAPS`), `lowercase_with_underscores` files and imports.
- Imports ordered `dart:`, `package:`, relative; no relative imports across `lib/` boundaries.
- Prefer `final` locals; annotate public API types; never `var` for public fields.
- `///` doc comments on public members; first sentence is a one-line summary.
- Prefer named constructors and `factory` over static "create" methods.

## Dart 3 Features to Use

### Records

For returning two or three values without a class.
```dart
(int min, int max) range(List<int> xs) => (xs.reduce(math.min), xs.reduce(math.max));
final (lo, hi) = range([3, 1, 2]);
```
Promote to a class when the record crosses a public API boundary or needs methods.

### Sealed classes and exhaustive switch

```dart
sealed class Shape { const Shape(); }
final class Circle extends Shape { const Circle(this.r); final double r; }
final class Square extends Shape { const Square(this.s); final double s; }

double area(Shape s) => switch (s) {
  Circle(:final r) => math.pi * r * r,
  Square(:final s) => s * s,
};
```
The analyzer errors when a case is missing. Use `sealed` for state, events, failures, results. Use `final class` for leaves so nobody extends them outside the library.

### Patterns

```dart
if (json case {'id': final String id, 'tags': [final String first, ...]}) { ... }
switch (response) {
  case (status: 200, :final body): ...
  case (status: >= 500, body: _): ...
}
final [first, ...rest] = items;
```

### Class modifiers

| Modifier | Use |
|---|---|
| `abstract interface class` | repository and data source contracts |
| `sealed class` | closed hierarchies |
| `final class` | leaves, value objects |
| `base class` | when subclasses must inherit, not implement |
| `mixin` / `mixin class` | shared behaviour without state ownership |

### Extension types

Zero-cost wrappers for IDs and units:
```dart
extension type const UserId(String value) {}
```

### Other

- `switch` expressions over `if/else` chains returning values.
- `enhanced enums` with fields and methods instead of `Map<Enum, X>` lookups.
- Wildcards `_` for unused params.
- `late final` only for lifecycle-initialised fields; never `late` to silence the analyzer.

## Error Handling

1. **Exceptions are for bugs and infrastructure**, never for control flow. Throw `ArgumentError`/`StateError` for programmer errors; throw typed `Exception` subclasses from data sources (`ApiException`, `CacheException`).
2. **Expected failures are values**: repositories and use cases return `Result<T>` (or `Either<Failure, T>` with fpdart). See `superpowers-flutter:flutter-clean-architecture`.
3. `catch` the narrowest type: `on SocketException catch (e)`. Never bare `catch (_)` that swallows; never `catch (e)` on `Error` subclasses (`RangeError`, `TypeError`) — those are bugs to fix.
4. `rethrow`, not `throw e`, to keep the stack trace.
5. Custom exceptions implement `Exception`, are `final`, carry a `message`, and override `toString`.

```dart
final class ApiException implements Exception {
  const ApiException(this.statusCode, [this.message]);
  final int statusCode;
  final String? message;
  @override
  String toString() => 'ApiException($statusCode${message == null ? '' : ': $message'})';
}
```

## Null Safety

- Model absence with `?`, never with sentinels (`-1`, `''`).
- `!` only right after a check the analyzer cannot see; prefer `if (x case final x?)`, `?.`, `??`.
- `required` named parameters over positional nullable ones.
- Avoid `late` for values that can be passed in the constructor.

## Async

- Return `Future<T>` from functions that do async work; never `async` without `await` inside.
- `Stream` for values over time; expose `Stream` not `StreamController` from public API.
- Mark fire-and-forget calls with `unawaited(...)` (from `dart:async`); the `unawaited_futures` lint is on.
- Cancel every `StreamSubscription`; dispose every `StreamController`.
- No `Future.then` chains; use `async`/`await`.
- `Future.wait` for independent calls; sequential `await` only when order matters.
- Never block on `Future` in `main` isolate loops; use `compute`/`Isolate.run` for CPU work over ~16ms.

## Collections and Strings

- `const []`/`const {}` for empty literals; collection `if`/`for` over `addAll` chains.
- `List.unmodifiable` or `UnmodifiableListView` when exposing internal lists.
- String interpolation over `+`; `StringBuffer` in loops.
- `Iterable` return types when callers only iterate; `List` when they index.

## Review Checklist

- [ ] `dart format` clean, `flutter analyze` clean
- [ ] Public API documented with `///`
- [ ] No `dynamic` in public signatures (`avoid_dynamic_calls`, `strict-raw-types` on)
- [ ] Sealed hierarchies switched exhaustively, no `default:` hiding new cases
- [ ] Exceptions only for bugs/infrastructure; failures returned as values
- [ ] Subscriptions and controllers disposed
