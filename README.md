# superpowers-flutter

A Flutter/Dart-focused fork of [obra/superpowers](https://github.com/obra/superpowers) — a complete software development workflow for coding agents, built on composable "skills" — modeled on [lucianghinda/superpowers-ruby](https://github.com/lucianghinda/superpowers-ruby). It ships the same brainstorm → plan → TDD → review → finish workflow, plus an opinionated Flutter/Dart layer on top.

## Flutter/Dart Focus

This fork extends the core superpowers workflow with a Flutter/Dart skills library:

- **Dart language** idioms — Effective Dart style, Dart 3 features (records, patterns, sealed classes, class modifiers), error handling, null safety, async
- **Feature-first clean architecture** — `lib/features/<feature>/{data,domain,presentation}` + `lib/core`, dependencies pointing inward
- **Bloc/Cubit** by default; **Riverpod** supported, selected by reading `pubspec.yaml` — sealed states/events, `BlocProvider`/`BlocBuilder`/`BlocListener` or `Notifier`/`AsyncNotifier` with providers as the DI container
- **Widget rules** — numbered heuristics for build size, extracting to widget classes, `const`, keys, and `BuildContext` safety
- **flutter analyze** zero-warning baseline with a vendored strict `analysis_options.yaml`
- **go_router or auto_route**, detected from `pubspec.yaml` — typed routes, guards driven by a Bloc, route tests
- **fpdart**, optional and detected from `pubspec.yaml` — `TaskEither<Failure, T>` from every repository and use case, `Option<T>` everywhere a domain value may be absent (no `T?` in domain signatures)
- **Official Flutter/Dart docs** indexed for quick reference, plus a vendored Flutter layered-architecture guide
- **Flutter/Dart SDK and package upgrade workflow** — one axis at a time, changelogs read before migrating, verified against a green baseline
- **Commit messages** following Conventional Commits with feature-directory scopes, for Flutter/Dart projects

## How it works

It starts from the moment you fire up your coding agent. As soon as it sees that you're building something, it *doesn't* just jump into writing code. Instead, it steps back and asks what you're really trying to do, one question at a time.

Once it's teased a spec out of the conversation, it shows the design to you in chunks short enough to actually read and digest, and waits for you to approve it before doing anything else.

After you've signed off on the design, your agent puts together an implementation plan clear enough for an engineer with no context on the codebase to follow — every task has exact file paths, the code to write, and how to verify it. It's built around true red/green TDD with `flutter_test`, `bloc_test`, and `mocktail` (or `ProviderContainer` under Riverpod), YAGNI, and DRY.

Next, once you say "go", it launches subagent-driven development: a fresh subagent per task, each reviewed against the plan and against code quality before the agent moves to the next one. It's not uncommon for the agent to work through a whole plan unattended, without deviating from what you approved.

Because the skills trigger automatically, you don't need to do anything special — your coding agent just has Superpowers for Flutter and Dart.

## Installation

`superpowers-flutter` ships as a native plugin for **Claude Code**.

### Option 1: Install from GitHub

```
/plugin marketplace add sgruhier/superpowers-flutter
/plugin install superpowers-flutter@superpowers-flutter
```

### Option 2: Install from a local clone

```
git clone https://github.com/sgruhier/superpowers-flutter.git
/plugin marketplace add /path/to/superpowers-flutter
/plugin install superpowers-flutter@superpowers-flutter
```

### Verify installation

Start a new session. It should open by telling you it has "superpowers for Flutter and Dart" and naming the `using-superpowers` skill — that message comes from this plugin's session-start hook, so seeing it means the install worked. Running `/plugin` should list `superpowers-flutter` among your installed plugins.

## The Basic Workflow

1. **brainstorming** — Activates before writing any code. Refines a rough idea through one question at a time, explores alternatives, and presents the design in sections for approval before any implementation is allowed.

2. **using-git-worktrees** — Activates when feature work needs isolation. Creates an isolated worktree on a new branch with smart directory selection and a safety check before work starts.

3. **writing-plans** — Activates once a design is approved. Breaks the work into bite-sized tasks, each with exact file paths, the code to write, and how to verify it — written for an engineer with no context on this codebase.

4. **subagent-driven-development** (or **executing-plans** without subagent support) — Activates once a plan exists. Dispatches a fresh subagent per task with two-stage review — spec compliance, then code quality — before moving to the next task.

5. **test-driven-development** — Activates during implementation. Enforces RED-GREEN-REFACTOR with `flutter_test`, `bloc_test`, and `mocktail` (or `ProviderContainer` under Riverpod): write a failing test, watch it fail, write the minimal code to pass, then refactor.

6. **requesting-code-review** — Activates between tasks. Dispatches a general-purpose subagent filled with the code-reviewer template against the plan and coding standards, with precisely crafted context rather than the session's full history.

7. **finishing-a-development-branch** — Activates once all tasks are done and tests pass. Verifies the test suite, then presents options to merge, open a PR, keep, or discard the branch, and cleans up the worktree.

**The agent checks for a relevant skill before any task.** This is a mandatory workflow, not a suggestion.

## What's Inside

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

### Process

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

## Philosophy

- **Test-Driven Development** - Write tests first, always
- **Systematic over ad-hoc** - Process over guessing
- **Complexity reduction** - Simplicity as primary goal
- **Evidence over claims** - Verify before declaring success

## Contributing

Skills live directly in this repository.

1. Fork the repository
2. Create a branch for your skill
3. Follow the `writing-skills` skill for creating and testing new skills
4. Run `bash tests/validate-skills.sh` before opening a PR
5. Submit a PR

## Updating

```bash
/plugin update superpowers-flutter
```

## License

MIT License - see [LICENSE](LICENSE) for details.

Built on the work of [Jesse Vincent](https://blog.fsck.com) ([obra/superpowers](https://github.com/obra/superpowers)) and [Lucian Ghinda](https://github.com/lucianghinda) ([superpowers-ruby](https://github.com/lucianghinda/superpowers-ruby)). If this workflow — Jesse's original design — has helped you do stuff that makes money, consider [sponsoring his opensource work](https://github.com/sponsors/obra).
