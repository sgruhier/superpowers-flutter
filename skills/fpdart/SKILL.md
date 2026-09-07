---
name: fpdart
description: Use when writing domain or data code in a Flutter app whose pubspec.yaml depends on fpdart — TaskEither for failures, Option for absence everywhere in domain, mapping exceptions once in the data layer, consuming in Blocs with match/map/run
---

# fpdart

## Overview

When `fpdart` is present, `Either<Failure, T>` replaces the hand-written `Result<T>`. Do not create `lib/core/error/result.dart`. `Failure` stays a sealed class in `lib/core/error/failure.dart`.

## Where each type lives

| Layer | Return type |
|---|---|
| data source | plain `Future<T>`, throws typed exceptions |
| repository (domain interface + data impl) | `TaskEither<Failure, T>` |
| use case | same as repository |
| Bloc | consumes with `match` or pattern matching, emits states |
| widgets | never see `Either` |

Every repository and use case returns `TaskEither<Failure, T>` — never `Future<Either<Failure, T>>`. There is no per-feature choice here. For an operation with nothing to return, that return type is `TaskEither<Failure, Unit>`, not `void`: `Unit` (fpdart's own type, one value, `unit`) keeps the result composable with `.map`/`.flatMap` the same way any other `TaskEither` is.

## Repository implementation: map exceptions once

```dart
@override
TaskEither<Failure, User> signIn({required String email, required String password}) =>
    TaskEither.tryCatch(
      () async => (await _remote.signIn(email, password)).toEntity(),
      (error, _) => switch (error) {
        ApiException(statusCode: 401) => const InvalidCredentialsFailure(),
        ApiException(:final message) => ServerFailure(message),
        SocketException() => const NetworkFailure(),
        _ => ServerFailure(error.toString()),
      },
    );
```

## Chaining in a use case

```dart
class Checkout {
  const Checkout(this._cart, this._payment);
  final CartRepository _cart;
  final PaymentRepository _payment;

  TaskEither<Failure, Receipt> call() => _cart
      .current()
      .flatMap((cart) => cart.isEmpty ? TaskEither<Failure, Cart>.left(const EmptyCartFailure()) : TaskEither<Failure, Cart>.right(cart))
      .flatMap(_payment.charge)
      .map(Receipt.fromPayment);
}
```

Consume it in the Bloc with `.match(...).map(emit).run()` — see below.

## Consuming in a Bloc

```dart
Future<void> load(String id) async {
  emit(const ProfileLoading());
  await _getProfile(id)
      .match(ProfileError.new, ProfileLoaded.new)
      .map(emit)
      .run();
}
```

The state carries the `Failure` object, not a message string — see `ProfileError` in the bloc skill. Turn a `Failure` into user-facing text in the widget, where you have context for localisation and can inspect the error type; `ErrorView` in the bloc skill shows this pattern. When a particular failure deserves genuinely different UI, add another state to the sealed hierarchy instead of putting a string in the error state.

`match` on a `TaskEither<L, R>` returns a `Task<A>` (verified against fpdart 1.2.0: `Task<A> match<A>(A Function(L l) onLeft, A Function(R r) onRight)`), so `.map(emit)` yields `Task<void>` and `.run()` executes it — nothing happens until `.run()`. The branches of `match` build states, they do not emit; `.map(emit)` performs the single emission. Emitting inside the branches is how you end up emitting twice, and forgetting `.run()` is how you end up emitting nothing at all — see Common Mistakes.

Real Blocs have work to do after the await: a generation guard against a stale reload, a `_busy` flag to reset, an `isClosed` check. That work goes in the `.map`, which is the one place that runs after the result is known — it does not push the emit back into the branches:

```dart
Future<void> load(String id) async {
  final generation = ++_generation;
  emit(const ProfileLoading());
  await _getProfile(id)
      .match(ProfileError.new, ProfileLoaded.new)
      .map((next) {
        if (generation == _generation && !isClosed) emit(next);
      })
      .run();
}
```

When the next state depends on the state *after* the await — an optimistic mutation that keeps the current detail on failure, a "load more" that appends to whatever the list is by then — the branches cannot see it yet. Then each branch returns a builder, and `.map` applies it to the re-read state. Still one emission, still nothing in the branches:

```dart
typedef _Build = FeedState Function(FeedLoaded current);

await _repository
    .feed(offset: loaded.items.length)
    .match<_Build>(
      (failure) => (current) => FeedNotice(current.copyWith(loadingMore: false), failure),
      (page) => (current) => current.copyWith(items: [...current.items, ...page], loadingMore: false),
    )
    .map((build) {
      final current = _loaded();
      if (current != null && generation == _generation) emit(build(current));
    })
    .run();
```

The chain is the rule whenever each branch produces exactly one state. When a branch has to do more than build a state — the success path triggers another async call (a silent re-fetch, a retry after a pseudo dialog), or one branch emits nothing at all — run the `TaskEither` first and match on the `Either`:

```dart
final result = await _repository.join(id).run();
_busy = false;
await result.match(
  (failure) async => _rollback(failure, before),
  (_) => _refresh(),
);
```

Reach for this second form only for that reason. If both branches turn out to be plain constructors, it is the chain.

## Option

Nullable is banned from domain signatures: entity fields, repository interface returns and parameters, use case signatures. Where a domain value may be absent, the type is `Option<T>`, not `T?`.

Nullable stays where the platform hands it to you: Flutter widget parameters (`Key?`, a form validator's return), a raw JSON map before it becomes a model, and third-party APIs. Convert at the boundary — `Option.fromNullable` inbound, `toNullable()` outbound.

```dart
class UserProfile extends Equatable {
  const UserProfile({required this.id, required this.avatarUrl});
  final String id;
  final Option<String> avatarUrl;
  @override
  List<Object?> get props => [id, avatarUrl];
}

Option<Token> cachedToken() => Option.fromNullable(_storage.read('token')).map(Token.new);
```

`Option` never reaches widgets or Blocs: presentation receives a resolved value or a state, not an `Option`. Resolve it before emitting — pattern match, `map`/`match` into a concrete value — never `getOrElse(() => throw ...)`.

## Rules

1. `Failure` on the left, always. Never `Either<Exception, T>`, `Either<String, T>`, or a `Future<Either<...>>` in place of `TaskEither`.
2. Exceptions become failures in the repository implementation and nowhere else.
3. No `getOrElse(() => throw ...)`, no `.getRight().toNullable()!`. Fold or match.
4. No fpdart imports in `presentation/widgets` or `presentation/pages`.
5. No `Task`, `Reader`, `State` monads unless the team already uses them; `Either`, `TaskEither`, `Option` cover this architecture (the `Task` that `.match()` hands back when consuming a `TaskEither` in a Bloc doesn't count — that's the standard chain, not a deliberate reach for the monad).
6. Do not wrap simple synchronous getters that cannot fail.
7. No `T?` in domain signatures — entity fields, repository interfaces, use case signatures. Use `Option<T>`.

## Testing

A repository or use case now returns a `TaskEither`, not a `Future`, so a test runs it first:

```dart
test('returns InvalidCredentialsFailure on 401', () async {
  when(() => api.signIn(any(), any())).thenThrow(const ApiException(401));
  final result = await repo.signIn(email: 'a@b.c', password: 'bad').run();
  expect(result, const Left<Failure, User>(InvalidCredentialsFailure()));
});

test('returns user on success', () async {
  when(() => api.signIn(any(), any())).thenAnswer((_) async => const UserModel(id: '1', email: 'a@b.c'));
  final result = await repo.signIn(email: 'a@b.c', password: 'x').run();
  expect(result, const Right<Failure, User>(User(id: '1', email: 'a@b.c')));
});
```

`Left`/`Right` have value equality when `Failure` and the entity do (Equatable or manual `==`), so `expect` compares them directly once `.run()` has resolved the `Future<Either<Failure, T>>`.

## Common Mistakes

| Mistake | Fix |
|---|---|
| `try/catch` around a use case in a Bloc | use case already returns `TaskEither` |
| Both `result.dart` and fpdart | delete `result.dart` |
| `Either<String, T>` | sealed `Failure` |
| `Future<Either<Failure, T>>` on a repository or use case | `TaskEither<Failure, T>` |
| `T?` on a domain entity field, repository signature, or use case signature | `Option<T>` |
| `.run()` called in a widget | call in the Bloc |
| Emitting inside a `match` branch, or forgetting `.run()` | branches build the state, `.map(emit)` emits once, `.run()` executes the chain |
| `await x.run()` then `match` with `emit` in both branches, copied from an older feature | the chain, with the post-await guard in `.map`; the older feature is a precedent for layout, not for style |
