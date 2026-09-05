# superpowers-flutter

A Flutter/Dart-focused fork of [obra/superpowers](https://github.com/obra/superpowers), modeled on [lucianghinda/superpowers-ruby](https://github.com/lucianghinda/superpowers-ruby): the composable workflow skills (brainstorm → plan → TDD → review → finish) plus an opinionated Flutter layer.

## Opinions

- **Bloc / Cubit** by default; **Riverpod** supported, selected by reading `pubspec.yaml`
- **Clean architecture, feature-first**: `lib/features/<feature>/{data,domain,presentation}` + `lib/core`
- **get_it** registered by hand
- **Effective Dart**, Dart 3 (records, patterns, sealed classes), no mandatory codegen
- **flutter_test + bloc_test + mocktail**
- **go_router or auto_route**, detected from `pubspec.yaml`
- **fpdart** optional, detected from `pubspec.yaml`

## Install (Claude Code)

```
/plugin marketplace add sgruhier/superpowers-flutter
/plugin install superpowers-flutter@superpowers-flutter
```

From a local clone:
```
/plugin marketplace add /path/to/superpowers-flutter
/plugin install superpowers-flutter@superpowers-flutter
```

## Skills

### Flutter & Dart

| Skill | When to reach for it |
|---|---|
| `dart` | Writing, reviewing, or debugging any Dart code — style, Dart 3 features, error handling, null safety, async |
| `flutter-clean-architecture` | Creating or restructuring a feature, a repository, a use case, a data source, or dependency injection |
| `bloc` | Adding or changing state management with Bloc/Cubit — states, events, wiring, and `bloc_test` |
| `riverpod` | Adding or changing state management on a project using `flutter_riverpod`/`hooks_riverpod`/`riverpod_annotation` |
| `flutter-widget-rules` | Writing or reviewing any widget — build size, extraction, `const`, keys, `BuildContext` safety |
| `flutter-analyze` | Before committing or requesting review, when warnings appear, or when setting up lints |
| `go-router` | Navigation when `go_router` is in `pubspec.yaml` |
| `auto-route` | Navigation when `auto_route` is in `pubspec.yaml` |
| `fpdart` | Domain or data code when `fpdart` is in `pubspec.yaml` |
| `flutter-docs` | Any Flutter/Dart framework, widget, or API question — points to the official docs |
| `flutter-upgrade` | Bumping the Flutter/Dart SDK or a package across a major version |
| `dart-commit-message` | Committing changes in a Flutter or Dart project |

### Process (from superpowers)

| Skill | When to reach for it |
|---|---|
| `using-superpowers` | At the start of any conversation — how to find and use the other skills |
| `brainstorming` | Before any creative work — new features, components, or behavior changes |
| `writing-plans` | Turning a spec or set of requirements into a multi-step plan, before touching code |
| `executing-plans` | Executing a written implementation plan in a separate session, with review checkpoints |
| `subagent-driven-development` | Executing an implementation plan's independent tasks via subagents in the current session |
| `dispatching-parallel-agents` | Two or more independent tasks that can run without shared state or sequencing |
| `test-driven-development` | Implementing any feature or bugfix — before writing implementation code |
| `systematic-debugging` | Any bug, test failure, or unexpected behavior, before proposing a fix |
| `verification-before-completion` | Before claiming work is complete, fixed, or passing |
| `requesting-code-review` | Completing a task or feature, or before merging |
| `receiving-code-review` | Processing incoming review feedback |
| `finishing-a-development-branch` | Implementation is done and tests pass — deciding how to integrate the work |
| `using-git-worktrees` | Starting feature work that needs isolation, or before executing a plan |
| `handoff` | Capturing session state before switching context or ending a session |
| `handoff-list` | Viewing available handoff documents |
| `handoff-resume` | Starting a new session and continuing from a previous handoff |
| `compound` | A non-trivial problem was just solved and verified — capture it for reuse |
| `compound-refresh` | Captured learnings may be stale — after a refactor, migration, or dependency upgrade |
| `consulting-an-oracle` | Stuck after multiple debug attempts — escalate to a stronger one-shot model |
| `writing-skills` | Creating or editing a skill, or verifying one works before deployment |

## How it works

The agent checks for a relevant skill before any task: brainstorming refines the idea, a worktree isolates the work, a plan splits it into small tasks, each task is implemented test-first, reviewed against the plan, and the branch is finished cleanly. The Flutter skills tell the agent how code must be shaped inside that workflow.

## Development

```
bash tests/validate-skills.sh
```

Vendored docs are refreshed with `skills/dart/scripts/refresh-effective-dart.sh` and `skills/flutter-docs/scripts/refresh-architecture-docs.sh`.

## Credits

Jesse Vincent for superpowers, Lucian Ghinda for superpowers-ruby. MIT.
