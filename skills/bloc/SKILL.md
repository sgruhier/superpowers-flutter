---
name: bloc
description: Use when adding or changing state management in a Flutter app — choosing Cubit vs Bloc, designing sealed states and events, wiring BlocProvider/BlocBuilder/BlocListener, and testing with bloc_test
---

# Bloc and Cubit

## Overview

`flutter_bloc` is the only state-management library in this stack. Widgets render state and dispatch intents; Blocs hold logic and call use cases; use cases call repositories.

## Cubit or Bloc?

| Use | When |
|---|---|
| `Cubit` | Default. Methods map 1:1 to user intents, no event transformation needed. |
| `Bloc` | Events need `transformer` (debounce search input, `sequential()` for queued writes, `restartable()` for cancellable loads), or you want an event log for tracing. |

Start with a Cubit. Promote to a Bloc only when a transformer is needed.

## State Design

Sealed class per screen, one subclass per UI situation. Widgets switch exhaustively.

```dart
sealed class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => const [];
}
final class ProfileInitial extends ProfileState { const ProfileInitial(); }
final class ProfileLoading extends ProfileState { const ProfileLoading(); }
final class ProfileLoaded extends ProfileState {
  const ProfileLoaded(this.user);
  final User user;
  @override
  List<Object?> get props => [user];
}
final class ProfileError extends ProfileState {
  const ProfileError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
```

Use a single data class with a `status` enum and `copyWith` only for forms, where several fields change independently:

```dart
enum LoginStatus { initial, loading, success, failure }

final class LoginState extends Equatable {
  const LoginState({this.email = '', this.password = '', this.status = LoginStatus.initial, this.failure});
  final String email;
  final String password;
  final LoginStatus status;
  final Failure? failure;
  LoginState copyWith({String? email, String? password, LoginStatus? status, Failure? failure}) =>
      LoginState(email: email ?? this.email, password: password ?? this.password, status: status ?? this.status, failure: failure);
  @override
  List<Object?> get props => [email, password, status, failure];
}
```

States must have value equality (`Equatable`, `freezed`, or manual `==`): identical consecutive states are not re-emitted.

## Event Design (Bloc only)

```dart
sealed class LoginEvent {
  const LoginEvent();
}
final class LoginEmailChanged extends LoginEvent {
  const LoginEmailChanged(this.email);
  final String email;
}
final class LoginSubmitted extends LoginEvent { const LoginSubmitted(); }
```

Name events in past tense from the user's point of view (`SearchQueryChanged`, `RefreshRequested`), not as commands to the Bloc (`FetchData`).

## Writing a Cubit

```dart
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({required GetProfile getProfile})
      : _getProfile = getProfile,
        super(const ProfileInitial());
  final GetProfile _getProfile;

  Future<void> load(String userId) async {
    emit(const ProfileLoading());
    final result = await _getProfile(userId);
    emit(switch (result) {
      Ok(:final value) => ProfileLoaded(value),
      Err(:final failure) => ProfileError(failure),
    });
  }
}
```

## Writing a Bloc

```dart
sealed class SearchState extends Equatable {
  const SearchState();
  @override
  List<Object?> get props => const [];
}
final class SearchInitial extends SearchState { const SearchInitial(); }
final class SearchLoading extends SearchState { const SearchLoading(); }
final class SearchLoaded extends SearchState {
  const SearchLoaded(this.products);
  final List<Product> products;
  @override
  List<Object?> get props => [products];
}
final class SearchError extends SearchState {
  const SearchError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}

sealed class SearchEvent {
  const SearchEvent();
}
final class SearchQueryChanged extends SearchEvent {
  const SearchQueryChanged(this.query);
  final String query;
}

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc({required SearchProducts search})
      : _search = search,
        super(const SearchInitial()) {
    on<SearchQueryChanged>(_onQueryChanged, transformer: debounce(const Duration(milliseconds: 300)));
  }
  final SearchProducts _search;

  Future<void> _onQueryChanged(SearchQueryChanged event, Emitter<SearchState> emit) async {
    if (event.query.isEmpty) return emit(const SearchInitial());
    emit(const SearchLoading());
    final result = await _search(event.query);
    emit(switch (result) {
      Ok(:final value) => SearchLoaded(value),
      Err(:final failure) => SearchError(failure),
    });
  }
}

EventTransformer<T> debounce<T>(Duration d) => (events, mapper) => events.debounceTime(d).switchMap(mapper);
```

`debounceTime`/`switchMap` come from `rxdart`; `bloc_concurrency` provides `sequential()`, `droppable()`, `restartable()`, `concurrent()`.

## Rules

1. A Bloc depends on use cases, never on repositories, data sources, `BuildContext`, or Flutter.
2. No `try/catch` for domain failures in a Bloc: use cases return `Result`/`Either`. Catch only truly unexpected errors with `onError` in a `BlocObserver`.
3. One Bloc per screen or per bounded concern (auth session, cart). Never one Bloc per widget.
4. No `emit` after an `await` without checking `isClosed` when the Bloc may be closed mid-flight.
5. Subscriptions (`Stream.listen`) are stored and cancelled in `close()`.
6. Never call another Bloc from a Bloc. Coordinate in the widget tree with `BlocListener`, or share a domain stream.
7. Never `Future` in the constructor; expose an explicit `load()`.

## Widget Wiring

```dart
BlocProvider(
  create: (_) => getIt<ProfileCubit>()..load(userId),
  child: const ProfileView(),
)
```

| Widget | Use for |
|---|---|
| `BlocBuilder` | render from state |
| `BlocSelector` | render from one field, avoid rebuilds |
| `BlocListener` | side effects: navigation, snackbar, dialog |
| `BlocConsumer` | both, when the same state drives both |
| `context.read<T>()` | dispatch in callbacks (`onPressed`) |
| `context.watch<T>()` | rebuild in `build`; prefer `BlocBuilder` for clarity |

Exhaustive rendering:
```dart
BlocBuilder<ProfileCubit, ProfileState>(
  builder: (context, state) => switch (state) {
    ProfileInitial() || ProfileLoading() => const Center(child: CircularProgressIndicator()),
    ProfileLoaded(:final user) => ProfileBody(user: user),
    ProfileError(:final failure) => ErrorView(failure: failure, onRetry: () => context.read<ProfileCubit>().load(userId)),
  },
)
```

Scope providers at the narrowest subtree that needs them. App-wide Blocs (session, theme) go in `app.dart` via `MultiBlocProvider`.

## Testing

Every Bloc/Cubit has a `blocTest` per transition. Mock use cases with `mocktail`.

```dart
class MockGetProfile extends Mock implements GetProfile {}

void main() {
  late MockGetProfile getProfile;
  setUp(() => getProfile = MockGetProfile());

  blocTest<ProfileCubit, ProfileState>(
    'emits [loading, loaded] when use case succeeds',
    build: () => ProfileCubit(getProfile: getProfile),
    setUp: () => when(() => getProfile('1')).thenAnswer((_) async => const Ok(User(id: '1', email: 'a@b.c'))),
    act: (cubit) => cubit.load('1'),
    expect: () => [const ProfileLoading(), const ProfileLoaded(User(id: '1', email: 'a@b.c'))],
  );

  blocTest<ProfileCubit, ProfileState>(
    'emits [loading, error] when use case fails',
    build: () => ProfileCubit(getProfile: getProfile),
    setUp: () => when(() => getProfile('1')).thenAnswer((_) async => const Err(NetworkFailure())),
    act: (cubit) => cubit.load('1'),
    expect: () => [const ProfileLoading(), const ProfileError(NetworkFailure())],
  );
}
```

Widget tests inject `MockBloc`/`MockCubit` from `bloc_test` with `BlocProvider.value` (see `superpowers-flutter:test-driven-development`).

## Common Mistakes

| Mistake | Fix |
|---|---|
| Business logic in `build` or `onPressed` | Move to a Cubit method |
| `setState` and a Bloc for the same data | Pick the Bloc; `setState` only for purely local UI (expanded/collapsed) |
| God state with 20 nullable fields | Split into sealed subclasses or separate Blocs |
| `context.read` inside `build` to render | `BlocBuilder`/`context.watch` |
| Navigation inside a Bloc | `BlocListener` in the widget |
| Bloc created in `build` without `BlocProvider` | `BlocProvider(create: ...)` so it is closed automatically |
