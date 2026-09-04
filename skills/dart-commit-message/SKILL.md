---
name: dart-commit-message
description: Use when committing changes in a Flutter or Dart project — Conventional Commits with feature-directory scopes and a body that explains why, written for the developer debugging it later
---

# Dart Commit Message

## Overview

Conventional Commits. The subject says what, the body says why. Scope is the feature directory or `core`.

## Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

## Types

| Type | Purpose |
|---|---|
| `feat` | new user-visible behaviour |
| `fix` | bug fix |
| `refactor` | no behaviour change |
| `perf` | performance |
| `test` | tests only |
| `docs` | docs only |
| `build` | pubspec, codegen config, Gradle/Xcode |
| `ci` | CI config |
| `chore` | maintenance, upgrades (`chore(sdk)`, `chore(deps)`) |
| `style` | formatting only |
| `revert` | reverts a commit |

## Scope

- Feature directory name: `feat(auth): ...`, `fix(cart): ...`.
- `core` for `lib/core/**`: `refactor(core): ...`.
- `router`, `theme`, `di` when the change is confined to that core folder.
- `sdk`, `deps` for upgrades.
- Omit only for repo-wide changes (`chore: run dart format`).

## Subject rules

- Imperative, lowercase, no period, ≤ 72 characters.
- Say what changed in the product or the code, not the file: `feat(auth): add biometric unlock` not `feat(auth): update login_page.dart`.

## Body

Explain why, and anything non-obvious a developer bisecting to this commit needs:

- the bug's symptom and root cause for `fix`
- the constraint that forced the design for `feat`/`refactor`
- migration notes for `chore(deps)` major bumps
- which `dart fix` rules were applied for mechanical commits

Wrap at 72. Bullet points are fine. No "this commit".

## Footer

`BREAKING CHANGE: <what breaks and how to migrate>` for public packages. `Closes #123` / `Refs #123` for issues.

## Examples

```
fix(auth): keep session after app restart on iOS

The token was stored with `SharedPreferences`, which iOS purges when the
app is offloaded. Move it to `flutter_secure_storage` and migrate existing
values on first launch.

Closes #214
```

```
feat(search): debounce query input by 300ms

SearchBloc now uses a debounce transformer so the API is hit once per
pause, not once per keystroke. Test covers rapid typing emitting one
loading state.
```

```
chore(deps): upgrade go_router 13 -> 14

- `GoRouterState.location` removed; use `matchedLocation`/`uri`.
- `ShellRoute` builder signature unchanged.
Regenerated routes.g.dart.
```

## Anti-patterns

| Bad | Why |
|---|---|
| `fix: bug` | says nothing |
| `feat(login_page.dart): ...` | file, not scope |
| `WIP`, `more fixes` | squash before pushing |
| Emoji or ticket id in subject | goes in footer |
