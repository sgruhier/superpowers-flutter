---
name: flutter-widget-rules
description: Use when writing or reviewing any Flutter widget — numbered rules for build size, extraction into widget classes, const constructors, keys, BuildContext safety, and where logic may not live
---

# Flutter Widget Rules

## Overview

Sandi Metz-style heuristics for widgets. Break a rule only with a one-line justification in the PR or a `// rule N: <why>` comment.

## The Rules

1. **`build` is at most 40 lines.** Longer: extract a widget class.
2. **Extract to widget classes, never to methods returning widgets.** `Widget _buildHeader()` defeats `const`, rebuild isolation, and DevTools naming.
3. **`const` wherever the analyzer allows.** `prefer_const_constructors` and `prefer_const_literals_to_create_immutables` are errors, not infos.
4. **`StatelessWidget` by default.** `StatefulWidget` only for controllers (`TextEditingController`, `AnimationController`, `ScrollController`, `FocusNode`) and purely local UI state (expanded, hovered). Screen or domain state lives in a Bloc.
5. **No business logic in widgets.** No calculations beyond formatting, no `if (user.isPremium && cart.total > 100)`. That is a Cubit method or a use case.
6. **No `BuildContext` across an `await` without `mounted`.**
   ```dart
   await Future<void>.delayed(const Duration(seconds: 1));
   if (!context.mounted) return;
   Navigator.of(context).pop();
   ```
7. **`Key` on every list item and every widget a test taps.** `ValueKey(item.id)` for lists, `Key('login_submit')` for test targets.
8. **One public widget per file above 50 lines.** Private helper widgets may share the file when under 30 lines each.
9. **Theme, not literals.** `Theme.of(context).colorScheme.primary`, `textTheme.titleMedium`, spacing constants from `lib/core/theme/spacing.dart`. No `Color(0xFF...)` or magic `EdgeInsets.all(13)` in feature code.
10. **Constructor parameters at most 6.** More: group into a small value object or split the widget.
11. **No `MediaQuery.of(context).size` for layout decisions.** Use `LayoutBuilder` constraints so the widget works in any parent.
12. **Dispose what you create.** Every controller created in `initState` is disposed in `dispose`, in reverse order.

## Extraction pattern

```dart
// Before
class OrderPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order')),
      body: Column(children: [
        // 60 lines of header, list, footer...
      ]),
    );
  }
}

// After
class OrderPage extends StatelessWidget {
  const OrderPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: _OrderAppBar(),
      body: Column(children: [_OrderHeader(), Expanded(child: _OrderLines()), _OrderFooter()]),
    );
  }
}
```

Private extracted widgets stay in the same file while under rule 8; promote to `widgets/` when reused.

## Page vs View

`<Feature>Page` creates the Bloc (`BlocProvider(create: ...)`) and nothing else. `<Feature>View` renders. Tests pump the view with a mocked Bloc.

```dart
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.userId});
  final String userId;
  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<ProfileCubit>()..load(userId),
        child: const ProfileView(),
      );
}
```

## Performance rules of thumb

- `ListView.builder` / `SliverList` for anything that can exceed a screen.
- `BlocSelector` or `context.select` when only one field drives a subtree.
- `RepaintBoundary` around expensive, independently animating widgets.
- Avoid `Opacity` on animated widgets; use `FadeTransition`.
- Images: `cacheWidth`/`cacheHeight`, `precacheImage` for hero shots.

## Accessibility minimums

- Every `IconButton` has a `tooltip`; every image has `semanticLabel` or `excludeFromSemantics`.
- Tap targets ≥ 48×48 (`kMinInteractiveDimension`).
- Text scales: no fixed-height containers around text; test with `textScaleFactor: 2.0` in a widget test.

## Review Checklist

- [ ] `build` ≤ 40 lines, no widget-returning helper methods
- [ ] `const` maximised
- [ ] No logic beyond formatting
- [ ] `mounted` checks after `await`
- [ ] Keys on list items and test targets
- [ ] Theme tokens only
- [ ] Controllers disposed
