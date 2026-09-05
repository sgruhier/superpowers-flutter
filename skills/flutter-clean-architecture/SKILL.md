---
name: flutter-clean-architecture
description: Use when creating or restructuring a Flutter feature, adding a repository, use case, data source, entity, or wiring dependency injection — feature-first clean architecture with Bloc and get_it
---

# Flutter Clean Architecture

## Overview

Feature-first layout, three layers per feature, dependencies point inward. Presentation depends on domain. Data depends on domain. Domain depends on nothing.

## Directory Layout

```
lib/
  main.dart                      # runApp only
  app.dart                       # MaterialApp/router, global BlocProviders
  core/
    di/injection.dart            # getIt + configureDependencies()
    error/failure.dart           # sealed Failure
    error/result.dart            # sealed Result<T> (only without fpdart)
    network/                     # http client, interceptors
    router/                      # see go-router / auto-route skill
    theme/
  features/
    <feature>/
      domain/
        entities/<name>.dart
        repositories/<name>_repository.dart   # abstract
        usecases/<verb_noun>.dart
      data/
        models/<name>_model.dart              # fromJson/toJson, toEntity()
        datasources/<name>_remote_data_source.dart
        datasources/<name>_local_data_source.dart
        repositories/<name>_repository_impl.dart
      presentation/
        bloc/ or cubit/
        pages/<name>_page.dart
        widgets/
      <feature>_injection.dart   # register<Feature>Feature() — Bloc/get_it form
      <feature>_providers.dart   # Provider/NotifierProvider bindings — Riverpod form, see superpowers-flutter:riverpod
test/                            # mirrors lib/
```

## Layer Rules

1. `domain/` imports only Dart SDK, `package:equatable` (optional), `package:fpdart` (if present). Never `package:flutter`.
2. `data/` imports `domain/` and infrastructure packages (http, dio, sqflite, shared_preferences). Never `presentation/`.
3. `presentation/` imports `domain/` (entities, use cases, repository interfaces) and Flutter. Never `data/`. Widgets never call a repository or use case directly: they go through a Bloc/Cubit (see `superpowers-flutter:bloc`).
4. Cross-feature access goes through `domain/` interfaces registered in the DI container (get_it, or providers under Riverpod), never through another feature's `data/` or `presentation/`.

Check with: `grep -rn "package:flutter" lib/features/*/domain` must print nothing.

## Domain

### Entity

Immutable, value equality, no JSON.

```dart
class User extends Equatable {
  const User({required this.id, required this.email});
  final String id;
  final String email;
  @override
  List<Object?> get props => [id, email];
}
```

Without equatable, a Dart 3 record or a class with manual `==`/`hashCode` is fine.

### Repository interface

```dart
abstract interface class AuthRepository {
  Future<Result<User>> signIn({required String email, required String password});
  Future<Result<void>> signOut();
  Stream<User?> watchCurrentUser();
}
```

With fpdart: `TaskEither<Failure, User>` instead of `Future<Result<User>>` (see `superpowers-flutter:fpdart`).

### Use case

A use case earns its place when it does something: composes more than one repository, enforces a domain rule, transforms or aggregates data, or is called from more than one place. One class, one `call`, taking primitives or a small params record:

```dart
class SignIn {
  const SignIn(this._repository);
  final AuthRepository _repository;

  Future<Result<User>> call({required String email, required String password}) =>
      _repository.signIn(email: email.trim().toLowerCase(), password: password);
}
```

`SignIn` earns its place here by normalizing the email before delegating — not by only forwarding.

When a use case would only forward a single call — no validation, no composition, called from exactly one Bloc — skip it. Let the Bloc or Cubit depend on the domain repository *interface* directly instead:

```dart
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this._authRepository) : super(const OnboardingInitial());
  final AuthRepository _authRepository;

  Future<void> submit(String email, String password) async {
    emit(const OnboardingLoading());
    final result = await _authRepository.signIn(email: email, password: password);
    emit(switch (result) {
      Ok(:final value) => OnboardingSuccess(value),
      Err(:final failure) => OnboardingFailure(failure),
    });
  }
}
```

This does not weaken the layer rule: `AuthRepository` is an *interface* declared in `domain/repositories/`, so `OnboardingCubit` above still depends only on `domain/`. What stays forbidden is a Bloc importing `data/`, a concrete `*RepositoryImpl`, a data source, `BuildContext`, or Flutter.

## Data

### Model

```dart
class UserModel {
  const UserModel({required this.id, required this.email});
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      UserModel(id: json['id'] as String, email: json['email'] as String);
  final String id;
  final String email;
  Map<String, dynamic> toJson() => {'id': id, 'email': email};
  User toEntity() => User(id: id, email: email);
}
```

### Data source

Talks to one external thing. Throws typed exceptions, never returns `Failure`.

```dart
abstract interface class AuthRemoteDataSource {
  Future<UserModel> signIn(String email, String password); // throws ApiException
}
```

### Repository implementation

The only place exceptions become failures.

```dart
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote);
  final AuthRemoteDataSource _remote;

  @override
  Future<Result<User>> signIn({required String email, required String password}) async {
    try {
      final model = await _remote.signIn(email, password);
      return Ok(model.toEntity());
    } on ApiException catch (e) {
      return Err(e.statusCode == 401 ? const InvalidCredentialsFailure() : ServerFailure(e.message));
    } on SocketException {
      return const Err(NetworkFailure());
    }
  }
}
```

## Core error types (without fpdart)

`lib/core/error/failure.dart`:
```dart
sealed class Failure extends Equatable {
  const Failure([this.message]);
  final String? message;
  @override
  List<Object?> get props => [message];
}
final class ServerFailure extends Failure { const ServerFailure([super.message]); }
final class NetworkFailure extends Failure { const NetworkFailure(); }
final class CacheFailure extends Failure { const CacheFailure(); }
final class InvalidCredentialsFailure extends Failure { const InvalidCredentialsFailure(); }
```

`Equatable` compares `runtimeType` as well as `props`, so distinct failure types with the same message are never equal — this is what lets tests assert on failures directly.

`lib/core/error/result.dart`:
```dart
sealed class Result<T> {
  const Result();
}
class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}
class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}
```

Consume with a switch expression:
```dart
final message = switch (result) {
  Ok(:final value) => 'Hello ${value.email}',
  Err(failure: NetworkFailure()) => 'No connection',
  Err(:final failure) => failure.message ?? 'Something went wrong',
};
```

## Dependency Injection (get_it, by hand)

`lib/core/di/injection.dart`:
```dart
final getIt = GetIt.instance;

void configureDependencies() {
  getIt.registerLazySingleton<http.Client>(http.Client.new);
  registerAuthFeature();
  registerProfileFeature();
}
```

`lib/features/auth/auth_injection.dart`:
```dart
void registerAuthFeature() {
  getIt
    ..registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(getIt()))
    ..registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(getIt()))
    ..registerFactory(() => SignIn(getIt()))
    ..registerFactory(() => LoginBloc(signIn: getIt()));
}
```

Rules: singletons for repositories and data sources, factories for use cases and Blocs. Register against the interface type. `main.dart` calls `configureDependencies()` before `runApp`. Widgets obtain Blocs via `BlocProvider(create: (_) => getIt<LoginBloc>())`, never `getIt` inside `build`.

This whole section is the Bloc form. Under Riverpod, providers are the dependency-injection container instead: there is no `injection.dart` and no `register<Feature>Feature()` functions. The equivalent wiring — one `Provider` per data source, repository and use case — lives in `superpowers-flutter:riverpod`.

## Detecting project options

Before writing code for a feature, read `pubspec.yaml`:

| Dependency present | Do |
|---|---|
| `go_router` | Use `superpowers-flutter:go-router` for pages and navigation |
| `auto_route` | Use `superpowers-flutter:auto-route` |
| neither | Propose adding `go_router`; do not write raw `Navigator.push` chains |
| `fpdart` | Return `TaskEither<Failure, T>` from repositories and use cases (`superpowers-flutter:fpdart`); do not create `result.dart` |
| no `fpdart` | Use `Result<T>` from `lib/core/error/result.dart` |
| `freezed` | Allowed for states/models; not required |
| `injectable` | Follow it if already used; otherwise register by hand as above |
| `flutter_riverpod`, `hooks_riverpod`, or `riverpod_annotation` | Use `superpowers-flutter:riverpod` for state management; providers replace get_it for dependency injection |
| `flutter_bloc` | Use `superpowers-flutter:bloc` for state management, with get_it as described above |
| neither Riverpod nor Bloc package | Propose Bloc, the plugin's default |

## New Feature Checklist

1. `domain/entities`, `domain/repositories` (abstract), `domain/usecases` — with unit tests.
2. `data/models`, `data/datasources`, `data/repositories/*_impl.dart` — with unit tests mocking the data source.
3. `presentation/bloc` or `cubit` — with `blocTest`.
4. `presentation/pages`, `presentation/widgets` — with widget tests.
5. `<feature>_injection.dart` registered in `configureDependencies()` (Bloc/get_it), or `<feature>_providers.dart` (Riverpod — see `superpowers-flutter:riverpod`).
6. Route added (go-router / auto-route skill).
7. `flutter analyze` clean, `flutter test` green.

## Common Mistakes

| Mistake | Fix |
|---|---|
| `fromJson` in an entity | Move to a model in `data/models` |
| Bloc imports `data/`, a concrete `*RepositoryImpl`, or a data source | Depend on the domain repository interface (or a use case) instead |
| Widget calls `getIt<SignIn>()` | Provide a Bloc; widget dispatches an event |
| `try/catch` in a Bloc mapping exceptions | Catch in repository impl, return `Failure` |
| One giant `AppBloc` | One Bloc per screen or bounded concern |
| `data/` imported from another feature | Expose a domain interface and register it |
