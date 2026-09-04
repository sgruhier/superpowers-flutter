# superpowers-flutter

A Flutter/Dart-focused fork of [obra/superpowers](https://github.com/obra/superpowers), modeled on [lucianghinda/superpowers-ruby](https://github.com/lucianghinda/superpowers-ruby): the composable workflow skills (brainstorm → plan → TDD → review → finish) plus an opinionated Flutter layer.

## Opinions

- **Bloc / Cubit** for state management
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
`dart`, `flutter-clean-architecture`, `bloc`, `flutter-widget-rules`, `flutter-analyze`, `go-router`, `auto-route`, `fpdart`, `flutter-docs`, `flutter-upgrade`, `dart-commit-message`

### Process (from superpowers)
`using-superpowers`, `brainstorming`, `writing-plans`, `executing-plans`, `subagent-driven-development`, `dispatching-parallel-agents`, `test-driven-development`, `systematic-debugging`, `verification-before-completion`, `requesting-code-review`, `receiving-code-review`, `finishing-a-development-branch`, `using-git-worktrees`, `handoff`, `handoff-list`, `handoff-resume`, `compound`, `compound-refresh`, `consulting-an-oracle`, `writing-skills`

## How it works

The agent checks for a relevant skill before any task: brainstorming refines the idea, a worktree isolates the work, a plan splits it into small tasks, each task is implemented test-first, reviewed against the plan, and the branch is finished cleanly. The Flutter skills tell the agent how code must be shaped inside that workflow.

## Development

```
bash tests/validate-skills.sh
```

Vendored docs are refreshed with `skills/dart/scripts/refresh-effective-dart.sh` and `skills/flutter-docs/scripts/refresh-architecture-docs.sh`.

## Credits

Jesse Vincent for superpowers, Lucian Ghinda for superpowers-ruby. MIT.
