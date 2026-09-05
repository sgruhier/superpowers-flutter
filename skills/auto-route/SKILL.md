---
name: auto-route
description: Use when working on navigation in a Flutter app whose pubspec.yaml depends on auto_route — @RoutePage pages, generated router, guards driven by a Bloc, nested tab routers, path parameters, and route tests
---

# auto_route

## Overview

Code-generated, strongly typed routing. One `AppRouter` in `lib/core/router/`, every page annotated with `@RoutePage()`, guards for auth. Never mix with `go_router` or raw `Navigator.push` for screens.

## Setup

`pubspec.yaml`: `auto_route` in dependencies; `auto_route_generator` and `build_runner` in dev_dependencies. Generate with `dart run build_runner build`; commit the generated `app_router.gr.dart`.

```
lib/core/router/
  app_router.dart      # AppRouter
  app_router.gr.dart   # generated
  auth_guard.dart
```

## Pages

```dart
@RoutePage()
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, @PathParam('userId') required this.userId});
  final String userId;
  ...
}
```

The generator produces `ProfileRoute(userId: ...)`. Page class names must end in `Page`; the generated route drops the suffix and adds `Route`.

## Router

```dart
@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  AppRouter({required this.session});
  final SessionCubit session;

  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: LoginRoute.page, path: '/login'),
        AutoRoute(
          page: ShellRoute.page,
          path: '/',
          initial: true,
          guards: [AuthGuard(session)],
          children: [
            AutoRoute(page: HomeRoute.page, path: 'home', initial: true),
            AutoRoute(page: SearchRoute.page, path: 'search'),
            AutoRoute(page: ProfileRoute.page, path: 'profile/:userId'),
          ],
        ),
        RedirectRoute(path: '*', redirectTo: '/'),
      ];
}
```

Wire in `app.dart`; create the router once:
```dart
class App extends StatefulWidget { ... }
class _AppState extends State<App> {
  late final _router = AppRouter(session: context.read<SessionCubit>());
  @override
  Widget build(BuildContext context) => MaterialApp.router(routerConfig: _router.config());
}
```

## Auth guard

```dart
class AuthGuard extends AutoRouteGuard {
  AuthGuard(this._session);
  final SessionCubit _session;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (_session.state.isAuthenticated) return resolver.next();
    router.push(LoginRoute(onResult: resolver.next));
  }
}
```
```dart
@RoutePage()
class LoginPage extends StatelessWidget {
  const LoginPage({super.key, required this.onResult});
  final void Function(bool success) onResult;

  void _submit(BuildContext context) {
    // ... perform sign-in ...
    onResult(true);
    context.router.pop();
  }
  ...
}
```
The guarded route stays pending until something calls `resolver.next()`; `LoginRoute`'s `onResult` is that call, so a successful sign-in resumes navigation to the originally requested route. `redirectUntil` alone does not do this — nothing completes the resolver unless a route result or a listenable does. Re-run guards after logout with `router.reevaluateGuards()` from a `BlocListener` on `SessionCubit`. If several guards must react to the same session change, wire a `reevaluateListenable` into `router.config(...)` instead.

## Tabs with AutoTabsRouter

```dart
@RoutePage()
class ShellPage extends StatelessWidget {
  const ShellPage({super.key});
  @override
  Widget build(BuildContext context) => AutoTabsScaffold(
        routes: const [HomeRoute(), SearchRoute()],
        bottomNavigationBuilder: (_, tabsRouter) => NavigationBar(
          selectedIndex: tabsRouter.activeIndex,
          onDestinationSelected: tabsRouter.setActiveIndex,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          ],
        ),
      );
}
```

## Navigating

| Action | Code |
|---|---|
| push | `context.router.push(ProfileRoute(userId: '42'))` |
| replace | `context.router.replace(const HomeRoute())` |
| pop with result | `context.router.pop<bool>(true)` / `await context.router.push<bool>(const EditRoute())` |
| by path (deep link) | `context.router.pushPath('/profile/42')` |
| reset stack | `context.router.replaceAll([const HomeRoute()])` |

Pass ids in path params; never pass entities through constructor args to a routed page (breaks deep links and restoration). Load in the page's Bloc.

## Testing

```dart
testWidgets('guard redirects unauthenticated user to login', (tester) async {
  final session = MockSessionCubit();
  when(() => session.state).thenReturn(const SessionState.unauthenticated());
  final router = AppRouter(session: session);

  await tester.pumpWidget(BlocProvider<SessionCubit>.value(
    value: session,
    child: MaterialApp.router(routerConfig: router.config()),
  ));
  await tester.pumpAndSettle();

  expect(router.current.name, LoginRoute.name);
});
```

## Common Mistakes

| Mistake | Fix |
|---|---|
| Forgot `@RoutePage()` | generator skips the page; add it and rebuild |
| Edited `app_router.gr.dart` | regenerate; never edit generated files |
| Router created in `build` | `late final` in a State |
| Guard reads a repository | guard reads `session.state` only |
| Both go_router and auto_route in pubspec | pick one; this skill assumes auto_route |
