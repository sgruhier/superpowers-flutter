# Test Strategy for Flutter Apps

Which layer gets which kind of test, and what each test may touch.

## Test pyramid by layer

Each layer of the clean-architecture, feature-first structure gets a different kind of test, backed by a different package, with a different rule for what it's allowed to mock. Use the table to pick the right shape of test before you write it.

| Layer | Directory | Test type | Package | Mocks allowed |
|---|---|---|---|---|
| domain | `lib/features/<f>/domain/` | pure unit | `flutter_test` (or `test`) | repository interfaces only |
| data | `lib/features/<f>/data/` | unit | `flutter_test` + `mocktail` | data sources (HTTP client, DB, storage) |
| presentation / logic | `lib/features/<f>/presentation/{bloc,cubit}/` | `blocTest` | `bloc_test` + `mocktail` | use cases, or the repository interface when the Bloc depends on one directly |
| presentation / UI | `lib/features/<f>/presentation/{pages,widgets}/` | widget test | `flutter_test` + `mocktail` | Bloc/Cubit |
| core | `lib/core/` | unit | `flutter_test` | as needed |

Test files mirror `lib/`, so the path alone tells you where a test belongs. `lib/features/auth/domain/usecases/sign_in.dart` maps to `test/features/auth/domain/usecases/sign_in_test.dart`, with the same directory structure repeated for data, presentation, and core.

## Domain: use cases and entities

Domain code has no Flutter imports and knows nothing about HTTP, storage, or widgets, so its tests should not either. The only thing a domain test may mock is the repository interface the use case depends on — never a concrete implementation, since domain never sees one.

```dart
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignIn signIn;
  late MockAuthRepository repo;

  setUp(() {
    repo = MockAuthRepository();
    signIn = SignIn(repo);
  });

  test('returns user on success', () async {
    when(() => repo.signIn(email: any(named: 'email'), password: any(named: 'password')))
        .thenAnswer((_) async => const Ok(User(id: '1', email: 'a@b.c')));
    final result = await signIn(email: 'a@b.c', password: 'x');
    expect(result, const Ok(User(id: '1', email: 'a@b.c')));
    verify(() => repo.signIn(email: 'a@b.c', password: 'x')).called(1);
  });
}
```

## Data: repository implementations

Data-layer tests exist to prove two things: that the repository maps a raw data-source response onto the domain model correctly, and that it translates data-source errors into the `Result`/`Either` failures the rest of the app expects. Mock only the data source itself (the HTTP client, the local database, the storage plugin) — never the repository under test.

```dart
class MockAuthApi extends Mock implements AuthApi {}

test('maps 401 to InvalidCredentialsFailure', () async {
  when(() => api.signIn(any(), any())).thenThrow(const ApiException(401));
  final result = await repo.signIn(email: 'a@b.c', password: 'bad');
  expect(result, isA<Err<User>>()); // or, with fpdart, `await repo.signIn(...).run()` then isA<Left<Failure, User>>()
});
```

Whenever a custom type is passed to `any()`, register a fallback value for it in `setUpAll` with `registerFallbackValue` — mocktail needs a stand-in instance to satisfy the matcher for non-primitive argument types.

## Presentation logic: blocTest

Blocs and Cubits are tested with `bloc_test`'s `blocTest`, which drives the bloc through an action and asserts on the exact sequence of states it emits. Mock the use case(s) the bloc depends on, or the repository interface when the bloc depends on one directly instead of a use case; never mock the bloc under test.

```dart
class MockSignIn extends Mock implements SignIn {}

void main() {
  late MockSignIn signIn;
  setUp(() => signIn = MockSignIn());

  blocTest<CounterCubit, int>(
    'emits [1] when increment is called',
    build: () => CounterCubit(),
    act: (cubit) => cubit.increment(),
    expect: () => [1],
  );

  blocTest<LoginBloc, LoginState>(
    'emits [loading, success] on valid submit',
    build: () => LoginBloc(signIn: signIn),
    seed: () => const LoginState(email: 'a@b.c', password: 'x'),
    setUp: () => when(() => signIn(email: any(named: 'email'), password: any(named: 'password')))
        .thenAnswer((_) async => const Ok(User(id: '1', email: 'a@b.c'))),
    act: (bloc) => bloc.add(const LoginSubmitted()),
    expect: () => [
      const LoginState(email: 'a@b.c', password: 'x', status: LoginStatus.loading),
      const LoginState(email: 'a@b.c', password: 'x', status: LoginStatus.success),
    ],
    verify: (_) => verify(() => signIn(email: 'a@b.c', password: 'x')).called(1),
  );
}
```

Keep to one `blocTest` per transition so a failure points at exactly one behavior. The `expect` list must include every state the bloc emits for that action, in order — omitting an intermediate state is a false pass, not a simplification. Use the `errors` parameter to assert on thrown errors rather than swallowing them. And never assert on the bloc's initial state inside `expect`: `blocTest` only records states emitted after `act` runs, so the seeded or default initial state never appears in that list.

## Presentation UI: widget tests

Widget tests exercise a page or widget against a real `MaterialApp` shell but a mocked Bloc, so the test controls exactly which state the widget renders without going through real business logic. Use `bloc_test`'s `MockBloc` (or a plain `mocktail` Mock implementing the bloc's interface) and inject it with `BlocProvider.value`.

```dart
class MockLoginBloc extends MockBloc<LoginEvent, LoginState> implements LoginBloc {}

testWidgets('shows error text when status is failure', (tester) async {
  final bloc = MockLoginBloc();
  when(() => bloc.state).thenReturn(const LoginState(status: LoginStatus.failure));

  await tester.pumpWidget(MaterialApp(
    home: BlocProvider<LoginBloc>.value(value: bloc, child: const LoginPage()),
  ));

  expect(find.text('Invalid credentials'), findsOneWidget);
});

testWidgets('tapping submit adds LoginSubmitted', (tester) async {
  final bloc = MockLoginBloc();
  when(() => bloc.state).thenReturn(const LoginState());
  await tester.pumpWidget(MaterialApp(
    home: BlocProvider<LoginBloc>.value(value: bloc, child: const LoginPage()),
  ));

  await tester.tap(find.byKey(const Key('login_submit')));
  verify(() => bloc.add(const LoginSubmitted())).called(1);
});
```

Call `pump()` after any state change that should trigger a rebuild, and reach for `pumpAndSettle()` only when an animation or transition genuinely needs to finish before the assertion — using it by default just hides timing bugs. Prefer finding interactive elements by `Key` (stable across copy changes) and finding what the user reads by text. Always wrap the widget under test in a `MaterialApp` (or the app's actual router/theme shell), since `Theme.of` and `Navigator.of` throw without an ancestor that provides them.

## Golden tests (optional)

Reserve golden tests for design-system widgets — buttons, chips, badges — whose pixel output must not drift silently; they are too brittle and too expensive to maintain for whole pages. Assert with `matchesGoldenFile('goldens/primary_button.png')` and regenerate the reference image with `flutter test --update-goldens` whenever a change is intentional.

## What we do not test

- Generated code (`*.g.dart`, `*.gr.dart`) — it's derived from the source you already tested, and it regenerates on every build.
- Third-party widgets' internals — trust the package's own test suite; test only how your code configures and reacts to it.
- Private helpers directly — go through the public widget or class API instead, so the test survives an internal refactor.

## Running

```bash
flutter test                         # everything
flutter test test/features/auth      # one feature
flutter test --name "rejects empty"  # one test by name
flutter test --coverage              # lcov to coverage/lcov.info
```
