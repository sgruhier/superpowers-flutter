---
name: go-router
description: Use when working on navigation in a Flutter app whose pubspec.yaml depends on go_router — typed routes, shell routes for tabs, auth redirects driven by a Bloc, path parameters, deep links, and route tests
---

# go_router

## Overview

Declarative, URL-based routing. One router in `lib/core/router/`, typed route classes, redirects driven by the session Bloc. Never mix with `auto_route` or raw `Navigator.push` for screens.

## Files

```
lib/core/router/
  app_router.dart   # createRouter(SessionCubit)
  routes.dart       # GoRouteData classes (+ routes.g.dart if using go_router_builder)
  go_router_refresh_stream.dart
```

## Typed routes

With `go_router_builder` (recommended; add to dev_dependencies with `build_runner`):

```dart
part 'routes.g.dart';

@TypedGoRoute<HomeRoute>(path: '/', routes: [
  TypedGoRoute<ProfileRoute>(path: 'profile/:userId'),
])
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => const HomePage();
}

class ProfileRoute extends GoRouteData with $ProfileRoute {
  const ProfileRoute({required this.userId});
  final String userId;
  @override
  Widget build(BuildContext context, GoRouterState state) => ProfilePage(userId: userId);
}

@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData with $LoginRoute {
  const LoginRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => const LoginPage();
}
```

Navigate: `const ProfileRoute(userId: '42').go(context)` (replace stack) or `.push(context)`.

Without the builder, declare `GoRoute(path: 'profile/:userId', builder: (context, state) => ProfilePage(userId: state.pathParameters['userId']!))` and navigate with `context.go('/profile/42')`. Prefer the builder: string paths in feature code are a bug source.

## Router with auth redirect

```dart
GoRouter createRouter(SessionCubit session) => GoRouter(
      initialLocation: '/',
      routes: $appRoutes, // generated
      refreshListenable: GoRouterRefreshStream(session.stream),
      redirect: (context, state) {
        final loggedIn = session.state.isAuthenticated;
        final onLogin = state.matchedLocation == '/login';
        if (!loggedIn && !onLogin) return '/login?from=${Uri.encodeComponent(state.matchedLocation)}';
        if (loggedIn && onLogin) return state.uri.queryParameters['from'] ?? '/';
        return null;
      },
      errorBuilder: (context, state) => NotFoundPage(uri: state.uri),
    );
```

`go_router_refresh_stream.dart`:
```dart
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;
  @override
  void dispose() { _sub.cancel(); super.dispose(); }
}
```

Wire in `app.dart`, with `SessionCubit` provided above the widget that reads it and the router built once:
```dart
class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SessionCubit>(),
      child: const _AppView(),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView();
  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  late final _router = createRouter(context.read<SessionCubit>());
  @override
  Widget build(BuildContext context) => MaterialApp.router(routerConfig: _router);
}
```
Create the router once (a `StatefulWidget` holding it, or a `late final` in a top-level provider); recreating it on every build resets navigation.

## Tabs with StatefulShellRoute

```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, shell) => ScaffoldWithNavBar(shell: shell),
  branches: [
    StatefulShellBranch(routes: [GoRoute(path: '/home', builder: ...)]),
    StatefulShellBranch(routes: [GoRoute(path: '/search', builder: ...)]),
  ],
)
```
Switch tabs with `shell.goBranch(index)`. Each branch keeps its own stack.

## Passing data

| Need | Do |
|---|---|
| Identifier | path parameter `:id` |
| Optional filter | query parameter |
| Whole object | do not. Pass the id, load in the Bloc. `extra` breaks deep links and restoration. |
| Return value from a pushed page | `final result = await const EditRoute().push<bool>(context);` |

## Deep links

Paths are the deep links. Configure `android/app/src/main/AndroidManifest.xml` intent filter and iOS `FlutterDeepLinkingEnabled` + associated domains; no extra Dart code.

## Testing

```dart
testWidgets('unauthenticated user is redirected to /login', (tester) async {
  final session = MockSessionCubit();
  when(() => session.state).thenReturn(const SessionState.unauthenticated());
  when(() => session.stream).thenAnswer((_) => const Stream.empty());
  final router = createRouter(session);

  await tester.pumpWidget(BlocProvider<SessionCubit>.value(
    value: session,
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pumpAndSettle();

  expect(router.routerDelegate.currentConfiguration.uri.path, '/login');
});
```

## Common Mistakes

| Mistake | Fix |
|---|---|
| `Navigator.push(MaterialPageRoute(...))` for a screen | typed route `.push(context)` |
| Router rebuilt in `build` | create once |
| `extra` with an entity | pass id, load in Bloc |
| Redirect reads a repository | redirect reads only `session.state` |
| Forgetting `refreshListenable` | redirect never re-runs after login |
