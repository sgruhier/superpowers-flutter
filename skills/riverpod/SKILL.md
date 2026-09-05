---
name: riverpod
description: Use when adding or changing state management in a Flutter app whose pubspec.yaml depends on flutter_riverpod, hooks_riverpod or riverpod_annotation — Notifier and AsyncNotifier, providers as the DI container, ConsumerWidget wiring, and testing with ProviderContainer overrides
---

# Riverpod

## Overview

`flutter_riverpod` (or `hooks_riverpod`) is the state-management library for this project. A project uses either `bloc` or Riverpod, never both — read `pubspec.yaml`: `flutter_bloc` present means use `superpowers-flutter:bloc` instead; neither present means propose Bloc, the plugin's default.

Widgets render state and dispatch intents; Notifiers hold logic and call use cases, or a domain repository interface directly when there's no use case to call; use cases call repositories. Providers *are* the dependency-injection container here — there is no get_it. Domain and data are unchanged by any of this: entities, repository interfaces and use cases still know nothing about Riverpod, still ban `T?` in their signatures (use `Option<T>` under fpdart, see `superpowers-flutter:fpdart`), exactly as they know nothing about Bloc.

## Which provider type

| Provider | Reach for it when |
|---|---|
| `Provider` | A dependency (data source, repository, use case) or a value derived from other providers. |
| `NotifierProvider` | Mutable state that is built synchronously and changes in response to methods. |
| `AsyncNotifierProvider` | State that is loaded asynchronously and then mutated (refresh, retry, optimistic update). |
| `StreamNotifierProvider` | State driven by a stream source (a live query, a socket). |
| `FutureProvider` | A one-shot async read with no methods to call afterward. |

`StateProvider`, `StateNotifierProvider` and `ChangeNotifierProvider` are legacy. They still exist in the package for migration, but new code does not use them.

## Providers as dependency injection

One `Provider` per data source, per repository and per use case, each reading its dependencies with `ref.watch`. This is the direct equivalent of the get_it registration in `superpowers-flutter:flutter-clean-architecture`, one binding at a time instead of one function:

```dart
final httpClientProvider = Provider<http.Client>((ref) => http.Client());

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSourceImpl(ref.watch(httpClientProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider)),
);

final signInProvider = Provider<SignIn>(
  (ref) => SignIn(ref.watch(authRepositoryProvider)),
);
```

Rules:

1. Providers are declared at file scope as `final`, one per binding, in `lib/features/<feature>/<feature>_providers.dart`.
2. A repository provider's declared type is the domain interface (`AuthRepository`), never the concrete `*RepositoryImpl` — the same rule get_it follows, enforced here by the generic argument on `Provider<T>`.
3. Nothing in `domain/` or `data/` imports Riverpod. `ref` only appears in `<feature>_providers.dart` and in `presentation/`.
4. A use case gets a provider only when it earns its place (composes repositories, enforces a rule, transforms data, or has more than one caller — see `flutter-clean-architecture`). When it doesn't, skip the provider and have the notifier `ref.watch`/`ref.read` the repository provider directly instead — see `AuthNotifier.signOut` below.

## State design

Same sealed-class discipline as `superpowers-flutter:bloc`: one sealed class per screen, one subclass per UI situation, value equality throughout.

```dart
sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => const [];
}
final class AuthInitial extends AuthState { const AuthInitial(); }
final class AuthLoading extends AuthState { const AuthLoading(); }
final class AuthSuccess extends AuthState {
  const AuthSuccess(this.user);
  final User user;
  @override
  List<Object?> get props => [user];
}
final class AuthError extends AuthState {
  const AuthError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
```

Riverpod skips notifying listeners when a `Notifier`'s new state equals the old one, so without `Equatable` a state rebuilt with identical fields would still trigger a rebuild.

When the state is exactly "loading, data or error" and nothing more, don't write a sealed hierarchy for it — use `AsyncNotifier<T>` and let `AsyncValue<T>` be the state; see the next section.

## Writing a Notifier

Synchronous state: `build()` returns the initial value, intent methods call a use case (or, when none earns its place, the repository directly) and assign `state`.

```dart
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthInitial();

  Future<void> signIn(String email, String password) async {
    state = const AuthLoading();
    final result = await ref.read(signInProvider)(email: email, password: password);
    state = switch (result) {
      Ok(:final value) => AuthSuccess(value),
      Err(:final failure) => AuthError(failure),
    };
  }

  Future<void> signOut() async {
    // AuthRepository.signOut is a single pass-through call with no logic of its
    // own — no use case earns its place, so the notifier depends on the
    // repository provider directly instead (see Providers as DI, rule 4).
    await ref.read(authRepositoryProvider).signOut();
    state = const AuthInitial();
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
```

`ref` is available directly on the notifier, unlike in a `Provider` callback where it's a parameter.

With fpdart, `signInProvider` exposes a `SignIn` returning `TaskEither<Failure, User>` (never `Future<Either<Failure, User>>`), and `signIn` becomes:

```dart
Future<void> signIn(String email, String password) async {
  state = const AuthLoading();
  state = await ref
      .read(signInProvider)(email: email, password: password)
      .match(AuthError.new, AuthSuccess.new)
      .run();
}
```

Nothing runs until `.run()`. The two branches of `match` build the states; the assignment to `state` happens once — there's no separate `.map(emit)` step like in a Bloc, because assigning `state` *is* the notification.

## Writing an AsyncNotifier

`build()` awaits a use case and returns the unwrapped value; a mutating method sets `state = const AsyncValue.loading()` and then resolves it, either with an explicit `Ok`/`Err` switch or `AsyncValue.guard`.

```dart
class ProfileNotifier extends AsyncNotifier<User> {
  ProfileNotifier(this.userId);
  final String userId;

  @override
  Future<User> build() async {
    final result = await ref.watch(getProfileProvider)(userId);
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(getProfileProvider)(userId);
      return switch (result) {
        Ok(:final value) => value,
        Err(:final failure) => throw failure,
      };
    });
  }
}

final profileNotifierProvider = AsyncNotifierProvider<ProfileNotifier, User>(
  () => ProfileNotifier('1'),
);
```

`build()` throws the `Failure` on `Err` rather than returning it: a thrown error inside `build`/`AsyncValue.guard` is how `AsyncValue<User>` becomes an `AsyncError` — there's no separate error state to construct by hand. `build` uses `ref.watch` to keep reacting to its dependencies; `refresh` uses `ref.read` because it runs from a callback, not from `build`.

## Rules

1. A notifier depends on use cases, or directly on a domain repository *interface* when no use case earns its place. Never on a concrete repository implementation, a data source, `BuildContext`, or Flutter.
2. No `try/catch` for domain failures in a notifier: use cases and repositories return `Result`/`Either`/`TaskEither`. An `AsyncNotifier` still throws internally to reach `AsyncError` — that's Riverpod's error channel, not exception handling for a domain failure.
3. `ref.watch` inside `build()` and inside provider bodies, so the provider or notifier reacts when its dependency changes. `ref.read` only inside callbacks and intent methods — using `watch` there re-subscribes on every call for no benefit.
4. Never `ref.read` a provider whose changes should trigger a rebuild or a rebuilt `build()`. If you find yourself reading instead of watching to "avoid a rebuild," that's a `select` problem, not a `read` problem.
5. `ref.listen` is for side effects — navigation, snackbars, dialogs — never for rendering, and never called from inside a notifier. A notifier that wants to navigate is a notifier that has taken on a widget's job.
6. Default to `.autoDispose` for screen-scoped state (`NotifierProvider.autoDispose(...)`) so it's cleared when the last widget watching it unmounts. Keep a provider alive across navigations deliberately — `ref.keepAlive()` or omitting `.autoDispose` — not because nobody thought about it.
7. Use `.family` for state parameterised by an argument (a user id, a page). Don't pass the same argument through every method instead — that's what family exists to avoid.
8. Cancel subscriptions and timers with `ref.onDispose(...)`, the notifier/provider equivalent of a Bloc's `close()`.
9. Never mutate a `List`, `Map`, or other collection held in `state` in place. Assign a new value — `state = [...state, item]`, not `state.add(item)` — or downstream widgets and `==` comparisons won't see the change.

## Widget wiring

`ProviderScope` wraps the app once, at the root:

```dart
void main() {
  runApp(const ProviderScope(child: MyApp()));
}
```

| Use | For |
|---|---|
| `ConsumerWidget` | A stateless widget that reads providers; overrides `build(context, ref)`. |
| `ConsumerStatefulWidget` / `ConsumerState` | Same, when the widget also needs `initState`/`dispose`. |
| `ref.watch(provider)` | Render from state, inside `build`. |
| `ref.watch(provider.select((s) => ...))` | Render from one field, skip rebuilds when the rest of the state changes. |
| `ref.read(provider.notifier)` | Call a method in a callback (`onPressed`). |
| `ref.listen(provider, (prev, next) { ... })` | Side effects: navigation, snackbar, dialog. |

Exhaustive rendering of a sealed state, with a side effect wired through `ref.listen`:

```dart
class AuthPage extends ConsumerWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.failure.message ?? 'Something went wrong')),
        );
      }
    });

    return switch (ref.watch(authNotifierProvider)) {
      AuthInitial() || AuthLoading() => const Center(child: CircularProgressIndicator()),
      AuthSuccess(:final user) => Text('Signed in as ${user.email}'),
      AuthError() => ElevatedButton(
          onPressed: () => ref.read(authNotifierProvider.notifier).signIn('a@b.c', 'x'),
          child: const Text('Retry'),
        ),
    };
  }
}
```

Rendering an `AsyncValue` with `.when`, and narrowing a rebuild with `select`:

```dart
class ProfilePane extends ConsumerWidget {
  const ProfilePane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(profileNotifierProvider.select((value) => value.value?.email));
    return ref.watch(profileNotifierProvider).when(
          data: (user) => Text(email ?? user.email),
          loading: () => const CircularProgressIndicator(),
          error: (error, stackTrace) => ElevatedButton(
            onPressed: () => ref.read(profileNotifierProvider.notifier).refresh(),
            child: const Text('Retry'),
          ),
        );
  }
}
```

## Code generation (optional)

`riverpod_generator` and `@riverpod` are supported, not required — everything above works without them. The annotation buys shorter provider declarations and `.family` inferred from a `build()` parameter instead of written by hand:

```dart
part 'profile_notifier.g.dart';

@riverpod
class Profile extends _$Profile {
  @override
  Future<User> build(String userId) async { ... }
}
```

`part` names the file `build_runner` writes; regenerate with `dart run build_runner build --delete-conflicting-outputs`. `_$Profile` and `profileProvider` (family-aware, since `build` takes `userId`) come from the generated file. Prefer the hand-written form shown above unless the project already has `riverpod_generator` in `pubspec.yaml`.

## Testing

`ProviderContainer` with `overrides` stands in for `ProviderScope` in a test. Override the provider the notifier actually depends on — the use case provider when one exists, the repository provider directly when it doesn't (see `AuthNotifier.signOut`) — never the concrete implementation. Mock with `mocktail`, same as everywhere else in this plugin.

```dart
class MockSignIn extends Mock implements SignIn {}

void main() {
  late MockSignIn signIn;
  late ProviderContainer container;

  setUp(() {
    signIn = MockSignIn();
    container = ProviderContainer(overrides: [signInProvider.overrideWithValue(signIn)]);
    addTearDown(container.dispose);
  });

  test('emits AuthSuccess when sign-in succeeds', () async {
    when(() => signIn(email: any(named: 'email'), password: any(named: 'password')))
        .thenAnswer((_) async => const Ok(User(id: '1', email: 'a@b.c')));

    final states = <AuthState>[];
    container.listen<AuthState>(
      authNotifierProvider,
      (previous, next) => states.add(next),
      fireImmediately: true,
    );

    await container.read(authNotifierProvider.notifier).signIn('a@b.c', 'x');

    expect(states, [
      const AuthInitial(),
      const AuthLoading(),
      const AuthSuccess(User(id: '1', email: 'a@b.c')),
    ]);
  });
}
```

`fireImmediately: true` captures the initial state too, so the asserted list reads like a `blocTest`'s `expect`: every state in order, initial state included.

For an `AsyncNotifier`, await its first value with the provider's `.future` instead of reading `state` directly:

```dart
test('loads the profile on first read', () async {
  when(() => getProfile('1')).thenAnswer((_) async => const Ok(User(id: '1', email: 'a@b.c')));
  final user = await container.read(profileNotifierProvider.future);
  expect(user, const User(id: '1', email: 'a@b.c'));
});
```

Widget tests wrap the tree in `ProviderScope(overrides: [...], child: ...)` instead of `BlocProvider.value`:

```dart
await tester.pumpWidget(
  ProviderScope(
    overrides: [signInProvider.overrideWithValue(signIn)],
    child: const MaterialApp(home: AuthPage()),
  ),
);
```

See `superpowers-flutter:test-driven-development` for which layer gets which kind of test; only the presentation-logic row changes shape under Riverpod.

## Common mistakes

| Mistake | Fix |
|---|---|
| `ref.read` inside `build` | `ref.watch` — `read` there won't rebuild on change |
| Business logic in the widget | Move it to the notifier, dispatch a method call instead |
| A notifier calling a repository implementation or a data source | Depend on the domain repository interface, or a use case |
| get_it kept alongside providers | Pick one container; under Riverpod, providers are it |
| Mutating a `List`/`Map` in `state` in place | Assign a new collection |
| No `.autoDispose` on screen-scoped state | Leaks the notifier across navigations; add it deliberately or `.autoDispose` |
| `StateProvider` for anything with logic | `NotifierProvider` — `StateProvider` is legacy and has no room for methods |
| `ref.listen` used to render UI | `ref.watch` — `listen` is for side effects only |
