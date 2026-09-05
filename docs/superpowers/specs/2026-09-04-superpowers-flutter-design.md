# superpowers-flutter — Design Spec

Date: 2026-09-04
Status: approved design, pending implementation plan

## Goal

A Flutter/Dart-focused fork of obra/superpowers, modeled on
lucianghinda/superpowers-ruby: keep the composable process skills
(brainstorming → plan → TDD → review → finish), replace the Ruby/Rails
layer with an opinionated Flutter layer.

Opinions baked in:

- State management: **Bloc / Cubit** (`flutter_bloc`).
- Architecture: **clean architecture, feature-first**
  (`lib/features/<feature>/{data,domain,presentation}`, `lib/core`).
- DI: **get_it**, registered by hand, no `injectable`.
- Style: **Effective Dart** (vendored), Dart 3 features (records, patterns,
  sealed classes), no mandatory `freezed`.
- Tests: **flutter_test + bloc_test + mocktail**. Golden tests optional.
  No integration_test / patrol skill.
- Routing: **go_router** or **auto_route**, chosen by reading `pubspec.yaml`.
- Functional errors: **fpdart** optional, chosen by reading `pubspec.yaml`.
  Without it: a hand-written sealed `Result`/`Failure`.

## Scope

- Platform: **Claude Code only** (`.claude-plugin/`). No Codex, Cursor,
  Copilot, Gemini, OpenCode manifests.
- Distribution: Claude Code plugin marketplace
  (`/plugin install superpowers-flutter@superpowers-flutter`).
- Docs: only Effective Dart and the official Flutter architecture guide are
  vendored. Everything else is a topic map with URLs the agent fetches on
  demand.

## Non-goals

- Multi-platform manifests and the polyglot hook wrapper for Windows/cmd
  (kept as-is only where already needed by Claude Code on Windows).
- Version-bump tooling, release notes, multi-platform docs.
- Deprecated `commands/` from the Ruby fork.
- Riverpod, Provider, GetX, or any non-Bloc state management.

## Skill inventory (31)

### A. Process skills — copied from superpowers-ruby, renamed only (18)

Text substitution `superpowers-ruby:` → `superpowers-flutter:`,
"Ruby and Rails" → "Flutter and Dart" in prose. Ruby code samples that are
merely illustrative (systematic-debugging, brainstorming) stay.

using-superpowers, brainstorming, writing-plans, executing-plans,
subagent-driven-development, dispatching-parallel-agents,
systematic-debugging, verification-before-completion,
requesting-code-review, receiving-code-review,
finishing-a-development-branch, handoff, handoff-list, handoff-resume,
compound, compound-refresh, consulting-an-oracle, writing-skills.

`using-superpowers` gets its skill table rewritten to list the Flutter
skills and their triggers (section D).

### B. Process skills — adapted (2)

**test-driven-development**
- RED/GREEN/REFACTOR prose kept.
- All Ruby/Minitest examples replaced: one pure-Dart unit test
  (`package:test`), one `blocTest` for a Cubit, one widget test with
  `WidgetTester`, one mocktail stub.
- Commands: `flutter test`, `flutter test path/to/file_test.dart`,
  `flutter test --name`.
- `testing-strategy.md` rewritten for the layered architecture: what to
  test at domain (pure unit), data (repo impl with mocked data source),
  presentation (blocTest for logic, widget test for rendering).
- `testing-anti-patterns.md` kept, Ruby snippets replaced by Dart
  equivalents (e.g. testing a mock instead of the subject, `pumpAndSettle`
  as a sleep substitute, asserting on implementation of a private widget).

**using-git-worktrees**
- Remove all SQLite/Rails sections and the `using-sqlite-worktrees`
  delegation.
- Post-create step: `flutter pub get`; if `build_runner` is in
  dev_dependencies, `dart run build_runner build -d`.
- Verification step: `flutter analyze && flutter test`.

### C. Removed from the Ruby fork (15)

ruby, rails-guides, rails-upgrade, ruby-upgrade, ruby-commit-message,
brakeman, sandi-metz-rules, 37signals-style, hwc-forms-validation,
hwc-media-content, hwc-navigation-content, hwc-realtime-streaming,
hwc-stimulus-fundamentals, hwc-ux-feedback, using-sqlite-worktrees.

### D. New Flutter skills (11)

Each is one `SKILL.md` with frontmatter `name` (== directory name) and a
`description` written as a trigger ("Use when …"). Length target 100–300
lines, following the Ruby fork's density. `references/` only where listed.

| Skill | Trigger (description) | Content |
|---|---|---|
| `dart` | Writing, reviewing or debugging any Dart code | Effective Dart summary and pointers into `references/effective-dart-{style,documentation,usage,design}.md` (vendored from dart.dev). Dart 3: records, patterns, `switch` expressions, sealed classes, class modifiers, extension types. Error handling: exceptions for bugs, sealed results for expected failures; never catch `Error`. Null safety idioms. `late` rules. Async: `Future` vs `Stream`, `unawaited`, cancellation. |
| `flutter-docs` | Any Flutter/Dart framework question | Topic map with URLs: docs.flutter.dev (widgets, layout, navigation, state, testing, performance, platform integration, deployment), dart.dev (language, libraries, tools), bloclibrary.dev, pub.dev pages for go_router, auto_route, fpdart, get_it, mocktail, bloc_test. Vendored `references/flutter-architecture-guide.md` (docs.flutter.dev/app-architecture). Instruction: fetch the URL, do not answer from memory when the topic is API-specific. |
| `flutter-clean-architecture` | Creating or restructuring a feature, adding a repository, use case, data source, or wiring DI | Directory layout. Layer rules: domain has no Flutter imports; data implements domain interfaces; presentation only talks to domain via Bloc. Entities vs models (`fromJson`/`toJson` live in data). Use case = one callable class. get_it registration pattern in `lib/core/di/injection.dart`, one `registerXFeature()` per feature. **pubspec detection**: read `pubspec.yaml`; if `go_router` → apply `go-router`; if `auto_route` → apply `auto-route`; neither → propose go_router; if `fpdart` → apply `fpdart` for domain/data return types, else hand-written sealed `Result<T>` / `Failure`. Checklist for a new feature. |
| `bloc` | Adding or changing state management, any file under presentation/bloc or presentation/cubit | Cubit by default, Bloc when events need transformation (debounce, sequential). Sealed `State` classes with pattern matching in widgets; no `copyWith`-everything god state unless justified. Events as sealed classes. One Bloc per screen or per bounded concern, not per widget. `BlocProvider` scoping, `BlocListener` for side effects, `BlocBuilder`/`BlocSelector` for rendering, `context.read` vs `context.watch`. Bloc depends on use cases, never on repositories or Flutter. `bloc_test` pattern with `seed`, `act`, `expect`, `verify`. Common mistakes: emitting after close, business logic in `build`, `Future` in constructors. |
| `flutter-widget-rules` | Writing or reviewing any widget | Numbered rules in the Sandi Metz spirit: `build` ≤ 40 lines; extract to widget classes, never to helper methods returning widgets; `const` everywhere possible; `Key` on list items and on anything tested; no `BuildContext` across `await` without `mounted` check; no business logic, no `setState` mixed with Bloc for the same state; StatelessWidget by default; one widget per file above ~50 lines; theme via `Theme.of(context)`, no hard-coded colors/sizes. When to break a rule and how to say so. |
| `flutter-analyze` | Before commit, before review, when warnings appear, when setting up lints | `analysis_options.yaml` baseline: `flutter_lints` + a listed set of stricter rules (`strict-casts`, `strict-raw-types`, `strict-inference`, `prefer_final_locals`, `avoid_dynamic_calls`, `unawaited_futures`, …). Workflow: `flutter analyze` → `dart fix --dry-run` → `dart fix --apply` → re-run. Triage: fix vs `// ignore:` with justification. `dart format`. Zero-warning policy before review. |
| `go-router` | Navigation when `go_router` is in pubspec | Router in `lib/core/router/`. Typed routes with `GoRouteData` (`go_router_builder` optional). `ShellRoute` / `StatefulShellRoute` for bottom nav. `redirect` driven by an auth Bloc via `refreshListenable` (`GoRouterRefreshStream`). Path params vs `extra`. Deep links. Testing routes with a pumped `MaterialApp.router`. |
| `auto-route` | Navigation when `auto_route` is in pubspec | `@RoutePage` + `@AutoRouterConfig`, `build_runner` step. Guards (`AutoRouteGuard`) driven by auth Bloc. Nested navigation with `AutoTabsRouter`. Path params. Testing. Do-not-mix rule with go_router. |
| `fpdart` | Domain/data code when `fpdart` is in pubspec | `Either<Failure, T>` for use cases and repos; `TaskEither` for async; `Option` only at boundaries. Sealed `Failure` hierarchy in `lib/core/error/`. Mapping exceptions to `Failure` once, in data layer. Consuming in Bloc with `fold` / pattern matching. When not to use it (UI code, simple value returns). |
| `flutter-upgrade` | Bumping Flutter/Dart SDK or a major package | Steps: `flutter --version`, `flutter upgrade`, `flutter pub outdated`, `pub upgrade --major-versions`, `dart fix --apply`, `flutter analyze`, `flutter test`. Deprecation handling. `scripts/fetch-changelogs.sh` that prints CHANGELOG sections from pub.dev for listed packages between two versions. `references/breaking-changes.md`: links to Flutter breaking-change pages per release. |
| `dart-commit-message` | Committing | Conventional Commits. Scope = feature directory name or `core`. Body explains why. Examples for feat/fix/refactor/test/chore. No emoji. |

## Repo layout

```
.claude-plugin/
  plugin.json          name superpowers-flutter, version 0.1.0, MIT
  marketplace.json     single-plugin marketplace pointing at ./
agents/
  code-reviewer.md     copied; add one paragraph: check layer rule, Bloc rules, widget rules
hooks/
  hooks.json           SessionStart / PreCompact / PostCompact, unchanged
  run-hook.cmd         unchanged (polyglot wrapper, needed on Windows Claude Code)
  session-start        text "You have superpowers for Flutter and Dart."
  handoff-create       unchanged
  handoff-restore      unchanged
skills/                31 directories listed above
tests/
  validate-skills.sh   see Testing
docs/superpowers/specs/  this file
README.md              what it is, install, skill list, credits
LICENSE                MIT, credits obra/superpowers and lucianghinda/superpowers-ruby
CHANGELOG.md           0.1.0 entry
.gitattributes         copied (LF for scripts)
```

Handoff docs continue to be written under `docs/handoffs/`
as in the Ruby fork.

## Testing

`tests/validate-skills.sh` (bash, no deps):

1. Every `skills/*/SKILL.md` exists.
2. Frontmatter `name:` equals the directory name.
3. `description:` is non-empty.
4. Every relative link `references/...` or `scripts/...` in a SKILL.md
   resolves to an existing file.
5. No remaining occurrence of `superpowers-ruby`, `bin/rails`, `Minitest`,
   `Gemfile` anywhere under `skills/`, `hooks/`, `agents/`.
6. `hooks/session-start` runs with `CLAUDE_PLUGIN_ROOT` set and emits valid
   JSON (checked with `python3 -m json.tool`).

Exit non-zero on any failure. This is the single check for the project.

## Build order

1. Skeleton: manifests, hooks, agent, README, LICENSE, `.gitattributes`,
   `validate-skills.sh`.
2. Copy the 19 process skills from superpowers-ruby, apply renames, run
   validator.
3. Adapt `test-driven-development` and `using-git-worktrees`.
4. New skills in this order: flutter-clean-architecture, bloc, dart
   (+ vendor Effective Dart), flutter-widget-rules, go-router, auto-route,
   fpdart, flutter-analyze, flutter-upgrade, dart-commit-message,
   flutter-docs (+ vendor architecture guide).
5. Rewrite the skill table in `using-superpowers`.
6. Run validator, install locally with `claude plugin` from the local
   marketplace, start a session, confirm the session-start context shows
   the Flutter skill list.

## Open decisions already made

- Skill names use the bare library name (`bloc`, `go-router`, `fpdart`)
  rather than `flutter-*` prefixes, matching the Ruby fork (`ruby`,
  `brakeman`).
- No `flutter-*-upgrade` split: one `flutter-upgrade` skill covers SDK and
  packages.
- `writing-skills` is kept unchanged so contributors can add skills the
  same way as upstream.
