---
name: fpdart
description: Use when writing domain or data code in a Flutter app whose pubspec.yaml depends on fpdart — Either and TaskEither for failures, Option at boundaries, mapping exceptions once in the data layer, consuming in Blocs with fold or patterns
---

# fpdart

## Overview

When `fpdart` is present, `Either<Failure, T>` replaces the hand-written `Result<T>`. Do not create `lib/core/error/result.dart`. `Failure` stays a sealed class in `lib/core/error/failure.dart`.

## Where each type lives

| Layer | Return type |
|---|---|
| data source | plain `Future<T>`, throws typed exceptions |
| repository (domain interface + data impl) | `Future<Either<Failure, T>>` or `TaskEither<Failure, T>` |
| use case | same as repository |
| Bloc | consumes with `fold` or pattern matching, emits states |
| widgets | never see `Either` |

Pick `TaskEither` when use cases chain several async steps; `Future<Either>` when one call is enough. Do not mix within one feature.

## Repository implementation: map exceptions once

```dart
@override
Future<Either<Failure, User>> signIn({required String email, required String password}) async {
  try {
    final model = await _remote.signIn(email, password);
    return right(model.toEntity());
  } on ApiException catch (e) {
    return left(e.statusCode == 401 ? const InvalidCredentialsFailure() : ServerFailure(e.message));
  } on SocketException {
    return left(const NetworkFailure());
  }
}
```

With `TaskEither`:
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
      .flatMap((cart) => cart.isEmpty ? TaskEither.left(const EmptyCartFailure()) : TaskEither.right(cart))
      .flatMap(_payment.charge)
      .map(Receipt.fromPayment);
}
```

Run it in the Bloc with `.run()`.

## Consuming in a Bloc

```dart
Future<void> load(String id) async {
  emit(const ProfileLoading());
  final result = await _getProfile(id); // Either<Failure, User>
  emit(result.fold(ProfileError.new, ProfileLoaded.new));
}
```

Or with patterns (fpdart `Either` is sealed as `Left`/`Right`):
```dart
emit(switch (await _getProfile(id)) {
  Right(:final value) => ProfileLoaded(value),
  Left(:final value) => ProfileError(value),
});
```

## Option

Use `Option<T>` only at a boundary where "absent" is a domain concept the caller must handle (cached token, last-known location). Everywhere else nullable types are clearer. Never return `Option` from widgets or Blocs.

```dart
Option<Token> cachedToken() => Option.fromNullable(_storage.read('token')).map(Token.new);
```

## Rules

1. `Failure` on the left, always. Never `Either<Exception, T>` or `Either<String, T>`.
2. Exceptions become failures in the repository implementation and nowhere else.
3. No `getOrElse(() => throw ...)`, no `.getRight().toNullable()!`. Fold or match.
4. No fpdart imports in `presentation/widgets` or `presentation/pages`.
5. No `Task`, `Reader`, `State` monads unless the team already uses them; `Either`, `TaskEither`, `Option` cover this architecture.
6. Do not wrap simple synchronous getters that cannot fail.

## Testing

```dart
test('returns InvalidCredentialsFailure on 401', () async {
  when(() => api.signIn(any(), any())).thenThrow(const ApiException(401));
  final result = await repo.signIn(email: 'a@b.c', password: 'bad');
  expect(result, const Left<Failure, User>(InvalidCredentialsFailure()));
});

test('returns user on success', () async {
  when(() => api.signIn(any(), any())).thenAnswer((_) async => const UserModel(id: '1', email: 'a@b.c'));
  final result = await repo.signIn(email: 'a@b.c', password: 'x');
  expect(result, const Right<Failure, User>(User(id: '1', email: 'a@b.c')));
});
```

`Left`/`Right` have value equality when `Failure` and the entity do (Equatable or manual `==`). For `TaskEither`, `await te.run()` then assert the same way.

## Common Mistakes

| Mistake | Fix |
|---|---|
| `try/catch` around a use case in a Bloc | use case already returns `Either` |
| Both `result.dart` and fpdart | delete `result.dart` |
| `Either<String, T>` | sealed `Failure` |
| `Option` for a nullable field on an entity | `T?` |
| `.run()` called in a widget | call in the Bloc |
