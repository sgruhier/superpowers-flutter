# superpowers-flutter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `superpowers-flutter`, a Claude Code plugin: obra/superpowers process skills plus an opinionated Flutter/Dart skill layer (Bloc, clean architecture, Effective Dart, go_router/auto_route, fpdart).

**Architecture:** A plugin is a directory of Markdown skills plus a manifest, hooks and one agent. Process skills are copied from lucianghinda/superpowers-ruby and renamed. Two are adapted (TDD, worktrees). Eleven Flutter skills are written new. One bash validator is the project's test.

**Tech Stack:** Markdown, bash, Claude Code plugin format (`.claude-plugin/plugin.json`, `skills/*/SKILL.md`, `hooks/hooks.json`, `agents/*.md`).

**Spec:** `docs/superpowers/specs/2026-09-04-superpowers-flutter-design.md`

## Global Constraints

- Plugin name: `superpowers-flutter`. Skill references use the `superpowers-flutter:` prefix.
- Version `0.1.0`. License MIT with credits to obra/superpowers and lucianghinda/superpowers-ruby.
- Claude Code only. Do not create `.codex-plugin`, `.cursor-plugin`, `.agents`, `.opencode`, `gemini-extension.json`, `commands/`.
- Skill frontmatter: `name:` equals the directory name; `description:` is one line starting with "Use when".
- Opinions (never contradict in any skill): Bloc/Cubit; feature-first clean architecture `lib/features/<feature>/{data,domain,presentation}` + `lib/core`; get_it registered by hand; no mandatory freezed/injectable; tests with flutter_test + bloc_test + mocktail; routing go_router or auto_route detected from `pubspec.yaml`; fpdart optional detected from `pubspec.yaml`.
- Every SKILL.md written new: 100–300 lines, English, code blocks in Dart with `dart` fence.
- After every task: `bash tests/validate-skills.sh` must pass before committing.
- Source of copied material: a shallow clone of superpowers-ruby. Set once per shell:
  `RUBY_SRC=/private/tmp/claude-502/-Users-seb-Developer-async-superpowers-flutter/7cf81900-8077-4cb4-878d-4993110b9025/scratchpad/superpowers-ruby`. If the directory is missing: `git clone -q --depth 1 https://github.com/lucianghinda/superpowers-ruby "$RUBY_SRC"`.
- Portable sed: use `sed -i.bak ... && find . -name '*.bak' -delete` (macOS `sed -i` needs a suffix).
- Commit messages: Conventional Commits, end with `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Skill-writing convention for this plan: each "new skill" task gives the frontmatter, headings, rules, and code blocks verbatim. Write them into the file as given; add only short connective sentences between them. Do not invent extra sections.

---

## File map

| Path | Responsibility |
|---|---|
| `.claude-plugin/plugin.json` | plugin manifest |
| `.claude-plugin/marketplace.json` | single-plugin local marketplace |
| `hooks/hooks.json`, `hooks/run-hook.cmd`, `hooks/session-start`, `hooks/handoff-create`, `hooks/handoff-restore` | session start context injection, handoff on compact |
| `agents/code-reviewer.md` | reviewer subagent used by requesting-code-review |
| `tests/validate-skills.sh` | the single check |
| `skills/<name>/SKILL.md` | one skill each, 31 total |
| `skills/dart/references/effective-dart-*.md` | vendored Effective Dart |
| `skills/flutter-docs/references/flutter-architecture-*.md` | vendored architecture guide |
| `skills/flutter-upgrade/scripts/fetch-changelogs.sh` | pub.dev changelog fetcher |
| `README.md`, `LICENSE`, `CHANGELOG.md`, `.gitattributes` | repo metadata |

---

### Task 1: Skeleton, manifests and validator

**Files:**
- Create: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `LICENSE`, `.gitattributes`, `CHANGELOG.md`, `tests/validate-skills.sh`

**Interfaces:**
- Produces: `bash tests/validate-skills.sh` exits 0 on a valid plugin, 1 with `FAIL:` lines otherwise. Every later task runs it.

- [ ] **Step 1: Write the validator**

```bash
#!/usr/bin/env bash
# Validates plugin structure. Exit 1 on any FAIL line.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
err() { echo "FAIL: $*"; fail=1; }

# 1. JSON manifests parse
for j in .claude-plugin/plugin.json .claude-plugin/marketplace.json hooks/hooks.json; do
  [ -f "$ROOT/$j" ] || { err "$j missing"; continue; }
  python3 -m json.tool "$ROOT/$j" >/dev/null 2>&1 || err "$j is not valid JSON"
done

# 2. Skills
count=0
for dir in "$ROOT"/skills/*/; do
  [ -d "$dir" ] || continue
  name="$(basename "$dir")"
  f="$dir/SKILL.md"
  [ -f "$f" ] || { err "$name: missing SKILL.md"; continue; }
  count=$((count + 1))
  head -1 "$f" | grep -q '^---$' || err "$name: no frontmatter"
  fm_name="$(sed -n '2,12p' "$f" | grep -m1 '^name:' | sed 's/^name:[[:space:]]*//')"
  [ "$fm_name" = "$name" ] || err "$name: frontmatter name is '$fm_name'"
  desc="$(sed -n '2,12p' "$f" | grep -m1 '^description:' | sed 's/^description:[[:space:]]*//')"
  [ -n "$desc" ] || err "$name: empty description"
  for rel in $(grep -oE '(references|scripts)/[A-Za-z0-9_./-]+' "$f" | sort -u); do
    [ -e "$dir$rel" ] || err "$name: link to missing $rel"
  done
done
echo "checked $count skills"

# 3. No Ruby leftovers
if [ -d "$ROOT/skills" ]; then
  leftovers="$(grep -rnE 'superpowers-ruby|bin/rails|Minitest|Gemfile' "$ROOT/skills" "$ROOT/hooks" "$ROOT/agents" 2>/dev/null || true)"
  [ -z "$leftovers" ] || err "Ruby leftovers:
$leftovers"
fi

# 4. session-start emits valid JSON mentioning Flutter
if [ -f "$ROOT/hooks/session-start" ]; then
  out="$(CLAUDE_PLUGIN_ROOT="$ROOT" bash "$ROOT/hooks/session-start" 2>&1)"
  printf '%s' "$out" | python3 -m json.tool >/dev/null 2>&1 || err "session-start output is not valid JSON"
  printf '%s' "$out" | grep -q 'superpowers for Flutter' || err "session-start does not mention Flutter"
fi

[ "$fail" -eq 0 ] && echo OK
exit "$fail"
```

Save as `tests/validate-skills.sh`, then `chmod +x tests/validate-skills.sh`.

- [ ] **Step 2: Run it, expect failure**

Run: `bash tests/validate-skills.sh`
Expected: `FAIL: .claude-plugin/plugin.json missing` (and the other two manifests), exit 1.

- [ ] **Step 3: Write manifests**

`.claude-plugin/plugin.json`:
```json
{
  "name": "superpowers-flutter",
  "description": "Flutter/Dart skills library for Claude Code: TDD with flutter_test and bloc_test, Bloc/Cubit, clean architecture, Effective Dart, go_router, auto_route, fpdart, and proven development workflows based on Jesse Vincent's superpowers",
  "version": "0.1.0",
  "author": { "name": "Sébastien Gruhier", "email": "sgruhier@gmail.com" },
  "homepage": "https://github.com/sgruhier/superpowers-flutter",
  "repository": "https://github.com/sgruhier/superpowers-flutter",
  "license": "MIT",
  "keywords": ["skills", "flutter", "dart", "bloc", "cubit", "clean-architecture", "tdd", "go_router", "auto_route", "fpdart", "debugging", "workflows"]
}
```

`.claude-plugin/marketplace.json`:
```json
{
  "name": "superpowers-flutter",
  "description": "Marketplace for Superpowers Flutter/Dart skills library",
  "owner": { "name": "Sébastien Gruhier", "email": "sgruhier@gmail.com" },
  "plugins": [
    {
      "name": "superpowers-flutter",
      "description": "Flutter/Dart skills library for Claude Code: TDD, Bloc/Cubit, clean architecture, Effective Dart, routing, fpdart, and proven development workflows",
      "version": "0.1.0",
      "source": "./",
      "author": { "name": "Sébastien Gruhier", "email": "sgruhier@gmail.com" }
    }
  ]
}
```

- [ ] **Step 4: LICENSE, .gitattributes, CHANGELOG**

`LICENSE`: MIT text, copyright line `Copyright (c) 2026 Sébastien Gruhier`, followed by two lines:
```
Based on superpowers by Jesse Vincent (https://github.com/obra/superpowers, MIT)
and superpowers-ruby by Lucian Ghinda (https://github.com/lucianghinda/superpowers-ruby, MIT).
```

`.gitattributes`: copy `$RUBY_SRC/.gitattributes` verbatim.

`CHANGELOG.md`:
````markdown
# Changelog

## 0.1.0 - 2026-09-04

Initial release. Process skills from superpowers-ruby 7.5.0; new Flutter skills:
dart, flutter-docs, flutter-clean-architecture, bloc, flutter-widget-rules,
flutter-analyze, go-router, auto-route, fpdart, flutter-upgrade, dart-commit-message.
````

- [ ] **Step 5: Run validator, expect only hooks.json missing**

Run: `bash tests/validate-skills.sh`
Expected: `FAIL: hooks/hooks.json missing`, `checked 0 skills`, exit 1.

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "chore: plugin skeleton, manifests, validator"
```

---

### Task 2: Hooks and code-reviewer agent

**Files:**
- Create: `hooks/hooks.json`, `hooks/run-hook.cmd`, `hooks/session-start`, `hooks/handoff-create`, `hooks/handoff-restore`, `agents/code-reviewer.md`

**Interfaces:**
- Produces: `hooks/session-start` prints JSON with the content of `skills/using-superpowers/SKILL.md` (Task 3 provides that file; until then the hook prints an error string inside valid JSON, which the validator accepts).

- [ ] **Step 1: Copy hooks**

```bash
mkdir -p hooks agents
cp "$RUBY_SRC"/hooks/{hooks.json,run-hook.cmd,session-start,handoff-create,handoff-restore} hooks/
cp "$RUBY_SRC"/agents/code-reviewer.md agents/
chmod +x hooks/session-start hooks/handoff-create hooks/handoff-restore
```

- [ ] **Step 2: Rename in hooks and agent**

```bash
sed -i.bak -e 's/superpowers-ruby/superpowers-flutter/g' -e 's/superpowers for Ruby and Rails/superpowers for Flutter and Dart/g' -e 's/Ruby and Rails/Flutter and Dart/g' hooks/session-start hooks/handoff-create hooks/handoff-restore agents/code-reviewer.md && find . -name '*.bak' -delete
grep -n "Flutter" hooks/session-start
```
Expected: the `session_context=` line reads `You have superpowers for Flutter and Dart.` and the skill name reads `superpowers-flutter:using-superpowers`.

- [ ] **Step 3: Add Flutter paragraph to the reviewer agent**

Append to the end of `agents/code-reviewer.md`:

````markdown

## Flutter-Specific Checks

When the project is a Flutter app, also verify:

- **Layer rule**: files under `domain/` import nothing from `package:flutter` or from `data/`/`presentation/`. `data/` implements interfaces declared in `domain/`. Widgets talk to `domain/` only through a Bloc or Cubit.
- **Bloc rules**: business logic lives in Bloc/Cubit or use cases, never in `build`. States and events are sealed classes. No `emit` after `close`. Blocs depend on use cases, not repositories.
- **Widget rules**: `build` under 40 lines; extraction into widget classes, not helper methods; `const` constructors where possible; no `BuildContext` used across an `await` without a `mounted` check.
- **Tests**: every Bloc/Cubit has a `blocTest`; every use case has a unit test; changed widgets have a widget test. Mocks use `mocktail`.
- **Analysis**: `flutter analyze` reports zero issues.
````

- [ ] **Step 4: Run validator**

Run: `bash tests/validate-skills.sh`
Expected: `checked 0 skills`, `OK`, exit 0. (session-start prints "Error reading using-superpowers skill" inside valid JSON; that is fine until Task 3.)

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "chore: hooks and code-reviewer agent from superpowers-ruby"
```

---

### Task 3: Copy and rename the 18 process skills

**Files:**
- Create: `skills/{using-superpowers,brainstorming,writing-plans,executing-plans,subagent-driven-development,dispatching-parallel-agents,systematic-debugging,verification-before-completion,requesting-code-review,receiving-code-review,finishing-a-development-branch,handoff,handoff-list,handoff-resume,compound,compound-refresh,consulting-an-oracle,writing-skills}/` (whole directories, including sub-files)
- Create: `skills/test-driven-development/`, `skills/using-git-worktrees/` (copied now, adapted in Tasks 5 and 6)

**Interfaces:**
- Produces: 20 skill directories referencing `superpowers-flutter:*` names. `using-superpowers` skill catalog still lists Ruby skills; Task 4 rewrites it.

- [ ] **Step 1: Copy**

```bash
mkdir -p skills
for s in using-superpowers brainstorming writing-plans executing-plans subagent-driven-development dispatching-parallel-agents systematic-debugging verification-before-completion requesting-code-review receiving-code-review finishing-a-development-branch handoff handoff-list handoff-resume compound compound-refresh consulting-an-oracle writing-skills test-driven-development using-git-worktrees; do
  cp -R "$RUBY_SRC/skills/$s" skills/
done
ls skills | wc -l
```
Expected: `20`.

- [ ] **Step 2: Rename plugin references**

```bash
grep -rl 'superpowers-ruby\|Superpowers Ruby\|Ruby and Rails\|Ruby/Rails' skills | xargs sed -i.bak \
  -e 's/superpowers-ruby/superpowers-flutter/g' \
  -e 's/Superpowers Ruby/Superpowers Flutter/g' \
  -e 's/Ruby and Rails/Flutter and Dart/g' \
  -e 's#Ruby/Rails#Flutter/Dart#g'
find . -name '*.bak' -delete
```

- [ ] **Step 3: Find remaining Ruby leftovers**

Run: `bash tests/validate-skills.sh`
Expected: `FAIL: Ruby leftovers:` listing lines in `test-driven-development/`, `using-git-worktrees/`, and possibly `systematic-debugging/`, `verification-before-completion/`, `finishing-a-development-branch/`.

For each listed line **outside** `test-driven-development/` and `using-git-worktrees/` (those two are rewritten in Tasks 5–6), replace the Ruby command with its Flutter equivalent in place:

| Ruby text | Replace with |
|---|---|
| `bin/rails test` | `flutter test` |
| `bin/rails test test/models/foo_test.rb` | `flutter test test/features/foo/foo_test.dart` |
| `Minitest` | `flutter_test` |
| `Gemfile` | `pubspec.yaml` |
| `bundle install` | `flutter pub get` |

Illustrative `.rb` sample files inside `systematic-debugging/` (`condition-based-waiting-example.rb`) are kept; only the four grep'd strings matter.

- [ ] **Step 4: Temporarily satisfy the validator for the two pending skills**

In `skills/test-driven-development/SKILL.md`, `skills/test-driven-development/testing-strategy.md`, `skills/test-driven-development/testing-anti-patterns.md`, and `skills/using-git-worktrees/SKILL.md`, apply the same table above with sed so the validator passes now (Tasks 5–6 rewrite the content properly anyway):

```bash
sed -i.bak -e 's#bin/rails test#flutter test#g' -e 's/Minitest/flutter_test/g' -e 's/Gemfile/pubspec.yaml/g' skills/test-driven-development/*.md skills/using-git-worktrees/SKILL.md && find . -name '*.bak' -delete
```

- [ ] **Step 5: Run validator**

Run: `bash tests/validate-skills.sh`
Expected: `checked 20 skills`, `OK`, exit 0.

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "feat: import process skills from superpowers-ruby"
```

---

### Task 4: Rewrite the skills catalog in using-superpowers

**Files:**
- Modify: `skills/using-superpowers/SKILL.md` (sections `### Ruby & Rails` and `### Hotwire & Stimulus` under `## Skills Catalog`)

**Interfaces:**
- Produces: the catalog names every skill in this plan with its `superpowers-flutter:` name. Later tasks must use exactly these directory names.

- [ ] **Step 1: Replace the two Ruby tables**

Delete from the line `### Ruby & Rails` through the end of the `### Hotwire & Stimulus` table (the last `| ... |` row of that table). Insert instead:

````markdown
### Flutter & Dart

| Name | When to Use |
|------|-------------|
| `superpowers-flutter:dart` | When writing, reviewing, or debugging any Dart code — Effective Dart, Dart 3 features (records, patterns, sealed classes), error handling, async idioms |
| `superpowers-flutter:flutter-clean-architecture` | When creating or restructuring a feature, adding a repository, use case, data source, or wiring dependency injection (**REQUIRED** for new features) |
| `superpowers-flutter:bloc` | When adding or changing state management — any Bloc, Cubit, event, or state class |
| `superpowers-flutter:flutter-widget-rules` | When writing or reviewing any widget — build size, extraction, const, keys, BuildContext safety |
| `superpowers-flutter:flutter-analyze` | Before committing or requesting review, when analyzer warnings appear, when setting up lints |
| `superpowers-flutter:go-router` | When working on navigation and `go_router` is in pubspec.yaml |
| `superpowers-flutter:auto-route` | When working on navigation and `auto_route` is in pubspec.yaml |
| `superpowers-flutter:fpdart` | When writing domain or data code and `fpdart` is in pubspec.yaml |
| `superpowers-flutter:flutter-docs` | When any Flutter or Dart framework/API question comes up — topic map to official docs |
| `superpowers-flutter:flutter-upgrade` | When bumping the Flutter/Dart SDK or a major package version |
| `superpowers-flutter:dart-commit-message` | When committing changes in a Flutter or Dart project |
````

- [ ] **Step 2: Check nothing else in the file mentions Ruby**

Run: `grep -n -i 'ruby\|rails\|hotwire\|stimulus' skills/using-superpowers/SKILL.md`
Expected: no output. Fix any hit by hand.

- [ ] **Step 3: Run validator and hook**

Run: `bash tests/validate-skills.sh && CLAUDE_PLUGIN_ROOT=$PWD bash hooks/session-start | grep -o 'superpowers-flutter:bloc'`
Expected: `OK` then `superpowers-flutter:bloc`.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat(using-superpowers): Flutter skills catalog"
```

---

### Task 5: Adapt test-driven-development to Flutter

**Files:**
- Modify: `skills/test-driven-development/SKILL.md` (sections `### RED`, `### Verify RED`, `### GREEN`, `### Verify GREEN`, `## Example: Bug Fix`, `## Testing Anti-Patterns`)
- Replace: `skills/test-driven-development/testing-strategy.md` (whole file)
- Modify: `skills/test-driven-development/testing-anti-patterns.md` (all Ruby code blocks)

**Interfaces:**
- Consumes: directory layout from Global Constraints (`lib/features/<f>/{data,domain,presentation}`), test mirror `test/features/<f>/...`.
- Produces: the canonical test commands other skills quote: `flutter test`, `flutter test <path>`, `flutter test --name "<pattern>"`.

- [ ] **Step 1: Update frontmatter description**

```yaml
description: Use when implementing any feature or bugfix in a Flutter or Dart project, before writing implementation code — RED-GREEN-REFACTOR with flutter_test, bloc_test and mocktail
```

- [ ] **Step 2: Replace the RED example**

Replace the Ruby `<Good>` block with:

```dart
test('retries failed operations 3 times', () async {
  var attempts = 0;
  Future<String> operation() async {
    attempts++;
    if (attempts < 3) throw Exception('fail');
    return 'success';
  }

  final result = await retryOperation(operation);

  expect(result, 'success');
  expect(attempts, 3);
});
```

Replace the Ruby `<Bad>` block with:

```dart
test('retry works', () async {
  var callCount = 0;
  Future<void> stubOp() async { callCount++; }
  await retryOperation(stubOp);
  expect(callCount, 3); // tests call count, not behavior
});
```

- [ ] **Step 3: Replace both Verify commands**

In `### Verify RED` and `### Verify GREEN`, replace the `bin/rails test ...` block with:

```bash
flutter test test/core/utils/retry_test.dart
```

Add one bullet under the Verify RED "Confirm:" list:

```
- Pure Dart package (no Flutter dependency)? Use `dart test` instead of `flutter test`
```

- [ ] **Step 4: Replace the GREEN example**

`<Good>`:
```dart
Future<T> retryOperation<T>(Future<T> Function() fn, {int maxAttempts = 3}) async {
  var attempts = 0;
  while (true) {
    try {
      return await fn();
    } catch (_) {
      attempts++;
      if (attempts >= maxAttempts) rethrow;
    }
  }
}
```

`<Bad>`:
```dart
Future<T> retryOperation<T>(
  Future<T> Function() fn, {
  int maxAttempts = 3,
  Backoff backoff = Backoff.linear,
  void Function(int)? onRetry,
  bool jitter = false,
  Duration? timeout,
}) async {
  // YAGNI
}
```

- [ ] **Step 5: Replace `## Example: Bug Fix`**

````markdown
## Example: Bug Fix

**Bug:** Empty email accepted by the sign-up form Cubit

**RED**
```dart
blocTest<SignUpCubit, SignUpState>(
  'rejects empty email',
  build: () => SignUpCubit(signUp: MockSignUp()),
  act: (cubit) => cubit.emailChanged(''),
  expect: () => [const SignUpState(email: '', emailError: 'Email is required')],
);
```

**Verify RED**
```bash
$ flutter test test/features/auth/presentation/cubit/sign_up_cubit_test.dart
Expected: [SignUpState(email: , emailError: Email is required)]
  Actual: [SignUpState(email: , emailError: null)]
```

**GREEN**
```dart
void emailChanged(String value) {
  emit(state.copyWith(
    email: value,
    emailError: value.isEmpty ? 'Email is required' : null,
  ));
}
```

**Verify GREEN**
```bash
$ flutter test test/features/auth/presentation/cubit/sign_up_cubit_test.dart
00:01 +1: All tests passed!
```

**REFACTOR**
Move the rule into a `validateEmail` function in `domain/` when a second screen needs it.
````

- [ ] **Step 6: Update the `## Testing Anti-Patterns` pointer line**

Replace `read @testing-strategy.md for Rails-specific patterns.` with `read @testing-strategy.md for Flutter layer-by-layer patterns.`

- [ ] **Step 7: Rewrite testing-strategy.md**

Overwrite the file with this content (expand each bullet into one or two sentences, keep every code block):

````markdown
# Test Strategy for Flutter Apps

Which layer gets which kind of test, and what each test may touch.

## Test pyramid by layer

| Layer | Directory | Test type | Package | Mocks allowed |
|---|---|---|---|---|
| domain | `lib/features/<f>/domain/` | pure unit | `flutter_test` (or `test`) | repository interfaces only |
| data | `lib/features/<f>/data/` | unit | `flutter_test` + `mocktail` | data sources (HTTP client, DB, storage) |
| presentation / logic | `lib/features/<f>/presentation/{bloc,cubit}/` | `blocTest` | `bloc_test` + `mocktail` | use cases |
| presentation / UI | `lib/features/<f>/presentation/{pages,widgets}/` | widget test | `flutter_test` + `mocktail` | Bloc/Cubit |
| core | `lib/core/` | unit | `flutter_test` | as needed |

Test files mirror `lib/`: `lib/features/auth/domain/usecases/sign_in.dart` → `test/features/auth/domain/usecases/sign_in_test.dart`.

## Domain: use cases and entities

No Flutter imports, no mocks except repository interfaces.

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
    when(() => repo.signIn(any(), any())).thenAnswer((_) async => const User(id: '1'));
    final result = await signIn(email: 'a@b.c', password: 'x');
    expect(result, const User(id: '1'));
    verify(() => repo.signIn('a@b.c', 'x')).called(1);
  });
}
```

## Data: repository implementations

Mock the data source, assert the mapping and the error translation.

```dart
class MockAuthApi extends Mock implements AuthApi {}

test('maps 401 to InvalidCredentialsFailure', () async {
  when(() => api.signIn(any(), any())).thenThrow(const ApiException(401));
  final result = await repo.signIn('a@b.c', 'bad');
  expect(result, isA<Failure>()); // or Left<Failure, User> with fpdart
});
```

Use `registerFallbackValue` in `setUpAll` for any custom type passed to `any()`.

## Presentation logic: blocTest

```dart
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
      .thenAnswer((_) async => const User(id: '1')),
  act: (bloc) => bloc.add(const LoginSubmitted()),
  expect: () => [
    const LoginState(email: 'a@b.c', password: 'x', status: LoginStatus.loading),
    const LoginState(email: 'a@b.c', password: 'x', status: LoginStatus.success),
  ],
  verify: (_) => verify(() => signIn(email: 'a@b.c', password: 'x')).called(1),
);
```

Rules: one `blocTest` per transition; `expect` lists every emitted state; use `errors` for thrown errors; never assert on the initial state (it is not emitted).

## Presentation UI: widget tests

Inject a mocked Bloc with `BlocProvider.value`; assert on what the user sees.

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

Rules: `pump()` after a state change, `pumpAndSettle()` only when animations must finish; find by `Key` for interactive elements, by text for what the user reads; wrap in `MaterialApp` (or the app's router shell) for `Theme`/`Navigator`.

## Golden tests (optional)

Only for design-system widgets that must not drift visually. `matchesGoldenFile('goldens/primary_button.png')`, update with `flutter test --update-goldens`. Never for whole pages.

## What we do not test

- Generated code (`*.g.dart`, `*.gr.dart`).
- Third-party widgets' internals.
- Private helpers directly: test through the public widget or class.

## Running

```bash
flutter test                         # everything
flutter test test/features/auth      # one feature
flutter test --name "rejects empty"  # one test by name
flutter test --coverage              # lcov to coverage/lcov.info
```
````

- [ ] **Step 8: Translate testing-anti-patterns.md code blocks to Dart**

For each ` ```ruby ` block, replace with a ` ```dart ` block expressing the same anti-pattern:

Anti-Pattern 1 (testing mock behavior) BAD:
```dart
// ❌ BAD: asserts the stub was called, not what the user gets
final api = MockAuthApi();
when(() => api.signIn(any(), any())).thenAnswer((_) async => user);
await repo.signIn('a@b.c', 'x');
verify(() => api.signIn(any(), any())).called(1); // and nothing else
```
GOOD:
```dart
// ✅ GOOD: assert the subject's observable result
final result = await repo.signIn('a@b.c', 'x');
expect(result, Right(user));
```

Anti-Pattern 2 (test-only methods in production) BAD:
```dart
// ❌ BAD: resetForTest exists only for tests
class SessionCubit extends Cubit<SessionState> {
  void resetForTest() => emit(const SessionState.initial());
}
```
GOOD:
```dart
// ✅ GOOD: build a fresh instance per test in setUp
setUp(() => cubit = SessionCubit(repo));
tearDown(() => cubit.close());
```

Anti-Pattern 3 (mocking without understanding) BAD:
```dart
// ❌ BAD: stubbing the repository hides that the use case never calls it
when(() => repo.save(any())).thenAnswer((_) async {});
await saveProfile(profile);
// test passes even if saveProfile has an early return before repo.save
```
GOOD:
```dart
// ✅ GOOD: verify the interaction the behavior depends on
await saveProfile(profile);
verify(() => repo.save(profile)).called(1);
```

Keep the prose and the "Gate Function" sections; only swap code and any `Minitest`/`fixtures`/`teardown` wording to `flutter_test`/`setUp`/`tearDown`.

- [ ] **Step 9: Validate and commit**

Run: `bash tests/validate-skills.sh && grep -c 'ruby' skills/test-driven-development/*.md`
Expected: `OK`, then `0` for each file.

```bash
git add -A && git commit -m "feat(tdd): Flutter examples, layer test strategy, Dart anti-patterns"
```

---

### Task 6: Adapt using-git-worktrees to Flutter

**Files:**
- Modify: `skills/using-git-worktrees/SKILL.md` (sections `### 3. Run Project Setup`, `### 4. Verify Clean Baseline`, the situations table, `## Example Workflow`, `## Integration`)

**Interfaces:**
- Produces: setup commands `flutter pub get`, optional `dart run build_runner build -d`; baseline `flutter analyze && flutter test`.

- [ ] **Step 1: Replace the setup block in `### 3. Run Project Setup`**

```bash
# Flutter / Dart (primary)
if [ -f pubspec.yaml ]; then
  flutter pub get
  # Code generation (auto_route, json_serializable, freezed, ...) if configured
  if grep -q 'build_runner' pubspec.yaml; then dart run build_runner build -d; fi
fi

# Node.js
if [ -f package.json ]; then npm install; fi

# Rust
if [ -f Cargo.toml ]; then cargo build; fi

# Python
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi

# Go
if [ -f go.mod ]; then go mod download; fi
```

Delete the whole SQLite paragraph and its failure contract.

- [ ] **Step 2: Replace the baseline block in `### 4. Verify Clean Baseline`**

```bash
# Flutter / Dart (primary)
flutter analyze && flutter test

# Other project types
npm test      # Node.js
cargo test    # Rust
pytest        # Python
go test ./... # Go
```

- [ ] **Step 3: Fix the situations table**

Remove the two rows `Rails + SQLite project` and `using-sqlite-worktrees fails`. Change `No package.json/Cargo.toml` to `No pubspec.yaml/package.json/Cargo.toml`. Add row: `| build_runner in pubspec.yaml | Run `dart run build_runner build -d` after `flutter pub get` |`.

- [ ] **Step 4: Fix the example workflow**

Replace the three bracketed Ruby lines with:
```
[Run flutter pub get]
[Run flutter analyze - No issues found!]
[Run flutter test - 47 passing]
```

- [ ] **Step 5: Fix Integration**

Delete the `using-sqlite-worktrees` bullet under **Pairs with:**.

- [ ] **Step 6: Validate and commit**

Run: `bash tests/validate-skills.sh && grep -n -i 'sqlite\|rails\|bundle' skills/using-git-worktrees/SKILL.md`
Expected: `OK` then no grep output.

```bash
git add -A && git commit -m "feat(worktrees): Flutter setup and baseline commands"
```

---

### Task 7: New skill — flutter-clean-architecture

**Files:**
- Create: `skills/flutter-clean-architecture/SKILL.md`

**Interfaces:**
- Produces: the names every other skill reuses: `lib/core/di/injection.dart` with `final getIt = GetIt.instance;` and `void configureDependencies()`; per-feature `void register<Feature>Feature()`; `lib/core/error/failure.dart` with sealed `Failure`; `lib/core/error/result.dart` with sealed `Result<T>` (used only when fpdart is absent).

- [ ] **Step 1: Write the skill**

````markdown
---
name: flutter-clean-architecture
description: Use when creating or restructuring a Flutter feature, adding a repository, use case, data source, entity, or wiring dependency injection — feature-first clean architecture with Bloc and get_it
---

# Flutter Clean Architecture

## Overview

Feature-first layout, three layers per feature, dependencies point inward. Presentation depends on domain. Data depends on domain. Domain depends on nothing.

## Directory Layout

```
lib/
  main.dart                      # runApp only
  app.dart                       # MaterialApp/router, global BlocProviders
  core/
    di/injection.dart            # getIt + configureDependencies()
    error/failure.dart           # sealed Failure
    error/result.dart            # sealed Result<T> (only without fpdart)
    network/                     # http client, interceptors
    router/                      # see go-router / auto-route skill
    theme/
  features/
    <feature>/
      domain/
        entities/<name>.dart
        repositories/<name>_repository.dart   # abstract
        usecases/<verb_noun>.dart
      data/
        models/<name>_model.dart              # fromJson/toJson, toEntity()
        datasources/<name>_remote_data_source.dart
        datasources/<name>_local_data_source.dart
        repositories/<name>_repository_impl.dart
      presentation/
        bloc/ or cubit/
        pages/<name>_page.dart
        widgets/
      <feature>_injection.dart   # register<Feature>Feature()
test/                            # mirrors lib/
```

## Layer Rules

1. `domain/` imports only Dart SDK, `package:equatable` (optional), `package:fpdart` (if present). Never `package:flutter`.
2. `data/` imports `domain/` and infrastructure packages (http, dio, sqflite, shared_preferences). Never `presentation/`.
3. `presentation/` imports `domain/` (entities, use cases) and Flutter. Never `data/`. Widgets never call a repository or use case directly: they go through a Bloc/Cubit (see `superpowers-flutter:bloc`).
4. Cross-feature access goes through `domain/` interfaces registered in get_it, never through another feature's `data/` or `presentation/`.

Check with: `grep -rn "package:flutter" lib/features/*/domain` must print nothing.

## Domain

### Entity

Immutable, value equality, no JSON.

```dart
class User extends Equatable {
  const User({required this.id, required this.email});
  final String id;
  final String email;
  @override
  List<Object?> get props => [id, email];
}
```

Without equatable, a Dart 3 record or a class with manual `==`/`hashCode` is fine.

### Repository interface

```dart
abstract interface class AuthRepository {
  Future<Result<User>> signIn({required String email, required String password});
  Future<Result<void>> signOut();
  Stream<User?> watchCurrentUser();
}
```

With fpdart: `Future<Either<Failure, User>>` instead of `Future<Result<User>>` (see `superpowers-flutter:fpdart`).

### Use case

One class, one `call`. Takes primitives or a small params record.

```dart
class SignIn {
  const SignIn(this._repository);
  final AuthRepository _repository;

  Future<Result<User>> call({required String email, required String password}) =>
      _repository.signIn(email: email, password: password);
}
```

A use case that only forwards is still worth having: Blocs depend on use cases, so the repository interface can change without touching presentation.

## Data

### Model

```dart
class UserModel {
  const UserModel({required this.id, required this.email});
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      UserModel(id: json['id'] as String, email: json['email'] as String);
  final String id;
  final String email;
  Map<String, dynamic> toJson() => {'id': id, 'email': email};
  User toEntity() => User(id: id, email: email);
}
```

### Data source

Talks to one external thing. Throws typed exceptions, never returns `Failure`.

```dart
abstract interface class AuthRemoteDataSource {
  Future<UserModel> signIn(String email, String password); // throws ApiException
}
```

### Repository implementation

The only place exceptions become failures.

```dart
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote);
  final AuthRemoteDataSource _remote;

  @override
  Future<Result<User>> signIn({required String email, required String password}) async {
    try {
      final model = await _remote.signIn(email, password);
      return Ok(model.toEntity());
    } on ApiException catch (e) {
      return Err(e.statusCode == 401 ? const InvalidCredentialsFailure() : ServerFailure(e.message));
    } on SocketException {
      return const Err(NetworkFailure());
    }
  }
}
```

## Core error types (without fpdart)

`lib/core/error/failure.dart`:
```dart
sealed class Failure {
  const Failure([this.message]);
  final String? message;
}
class ServerFailure extends Failure { const ServerFailure([super.message]); }
class NetworkFailure extends Failure { const NetworkFailure(); }
class CacheFailure extends Failure { const CacheFailure(); }
class InvalidCredentialsFailure extends Failure { const InvalidCredentialsFailure(); }
```

`lib/core/error/result.dart`:
```dart
sealed class Result<T> {
  const Result();
}
class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}
class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}
```

Consume with a switch expression:
```dart
final message = switch (result) {
  Ok(:final value) => 'Hello ${value.email}',
  Err(failure: NetworkFailure()) => 'No connection',
  Err(:final failure) => failure.message ?? 'Something went wrong',
};
```

## Dependency Injection (get_it, by hand)

`lib/core/di/injection.dart`:
```dart
final getIt = GetIt.instance;

void configureDependencies() {
  getIt.registerLazySingleton<http.Client>(http.Client.new);
  registerAuthFeature();
  registerProfileFeature();
}
```

`lib/features/auth/auth_injection.dart`:
```dart
void registerAuthFeature() {
  getIt
    ..registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(getIt()))
    ..registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(getIt()))
    ..registerFactory(() => SignIn(getIt()))
    ..registerFactory(() => LoginBloc(signIn: getIt()));
}
```

Rules: singletons for repositories and data sources, factories for use cases and Blocs. Register against the interface type. `main.dart` calls `configureDependencies()` before `runApp`. Widgets obtain Blocs via `BlocProvider(create: (_) => getIt<LoginBloc>())`, never `getIt` inside `build`.

## Detecting project options

Before writing code for a feature, read `pubspec.yaml`:

| Dependency present | Do |
|---|---|
| `go_router` | Use `superpowers-flutter:go-router` for pages and navigation |
| `auto_route` | Use `superpowers-flutter:auto-route` |
| neither | Propose adding `go_router`; do not write raw `Navigator.push` chains |
| `fpdart` | Return `Either<Failure, T>` / `TaskEither` from repositories and use cases (`superpowers-flutter:fpdart`); do not create `result.dart` |
| no `fpdart` | Use `Result<T>` from `lib/core/error/result.dart` |
| `freezed` | Allowed for states/models; not required |
| `injectable` | Follow it if already used; otherwise register by hand as above |

## New Feature Checklist

1. `domain/entities`, `domain/repositories` (abstract), `domain/usecases` — with unit tests.
2. `data/models`, `data/datasources`, `data/repositories/*_impl.dart` — with unit tests mocking the data source.
3. `presentation/bloc` or `cubit` — with `blocTest`.
4. `presentation/pages`, `presentation/widgets` — with widget tests.
5. `<feature>_injection.dart` registered in `configureDependencies()`.
6. Route added (go-router / auto-route skill).
7. `flutter analyze` clean, `flutter test` green.

## Common Mistakes

| Mistake | Fix |
|---|---|
| `fromJson` in an entity | Move to a model in `data/models` |
| Bloc calls repository directly | Inject a use case |
| Widget calls `getIt<SignIn>()` | Provide a Bloc; widget dispatches an event |
| `try/catch` in a Bloc mapping exceptions | Catch in repository impl, return `Failure` |
| One giant `AppBloc` | One Bloc per screen or bounded concern |
| `data/` imported from another feature | Expose a domain interface and register it |
````

- [ ] **Step 2: Validate**

Run: `bash tests/validate-skills.sh && grep -c '^## ' skills/flutter-clean-architecture/SKILL.md`
Expected: `OK` then `10`.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat(skill): flutter-clean-architecture"
```

---

### Task 8: New skill — bloc

**Files:**
- Create: `skills/bloc/SKILL.md`

**Interfaces:**
- Consumes: use case shape `Future<Result<T>> call(...)` from Task 7; get_it registration pattern.
- Produces: naming `<Feature>Bloc` / `<Feature>Cubit`, sealed `<Feature>State` and `<Feature>Event`, test file `test/features/<f>/presentation/bloc/<feature>_bloc_test.dart`.

- [ ] **Step 1: Write the skill**

````markdown
---
name: bloc
description: Use when adding or changing state management in a Flutter app — choosing Cubit vs Bloc, designing sealed states and events, wiring BlocProvider/BlocBuilder/BlocListener, and testing with bloc_test
---

# Bloc and Cubit

## Overview

`flutter_bloc` is the only state-management library in this stack. Widgets render state and dispatch intents; Blocs hold logic and call use cases; use cases call repositories.

## Cubit or Bloc?

| Use | When |
|---|---|
| `Cubit` | Default. Methods map 1:1 to user intents, no event transformation needed. |
| `Bloc` | Events need `transformer` (debounce search input, `sequential()` for queued writes, `restartable()` for cancellable loads), or you want an event log for tracing. |

Start with a Cubit. Promote to a Bloc only when a transformer is needed.

## State Design

Sealed class per screen, one subclass per UI situation. Widgets switch exhaustively.

```dart
sealed class ProfileState {
  const ProfileState();
}
final class ProfileInitial extends ProfileState { const ProfileInitial(); }
final class ProfileLoading extends ProfileState { const ProfileLoading(); }
final class ProfileLoaded extends ProfileState {
  const ProfileLoaded(this.user);
  final User user;
}
final class ProfileError extends ProfileState {
  const ProfileError(this.failure);
  final Failure failure;
}
```

Use a single data class with a `status` enum and `copyWith` only for forms, where several fields change independently:

```dart
enum LoginStatus { initial, loading, success, failure }

final class LoginState extends Equatable {
  const LoginState({this.email = '', this.password = '', this.status = LoginStatus.initial, this.failure});
  final String email;
  final String password;
  final LoginStatus status;
  final Failure? failure;
  LoginState copyWith({String? email, String? password, LoginStatus? status, Failure? failure}) =>
      LoginState(email: email ?? this.email, password: password ?? this.password, status: status ?? this.status, failure: failure);
  @override
  List<Object?> get props => [email, password, status, failure];
}
```

States must have value equality (`Equatable`, `freezed`, or manual `==`): identical consecutive states are not re-emitted.

## Event Design (Bloc only)

```dart
sealed class LoginEvent {
  const LoginEvent();
}
final class LoginEmailChanged extends LoginEvent {
  const LoginEmailChanged(this.email);
  final String email;
}
final class LoginSubmitted extends LoginEvent { const LoginSubmitted(); }
```

Name events in past tense from the user's point of view (`SearchQueryChanged`, `RefreshRequested`), not as commands to the Bloc (`FetchData`).

## Writing a Cubit

```dart
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({required GetProfile getProfile})
      : _getProfile = getProfile,
        super(const ProfileInitial());
  final GetProfile _getProfile;

  Future<void> load(String userId) async {
    emit(const ProfileLoading());
    final result = await _getProfile(userId);
    emit(switch (result) {
      Ok(:final value) => ProfileLoaded(value),
      Err(:final failure) => ProfileError(failure),
    });
  }
}
```

## Writing a Bloc

```dart
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc({required SearchProducts search})
      : _search = search,
        super(const SearchState.initial()) {
    on<SearchQueryChanged>(_onQueryChanged, transformer: debounce(const Duration(milliseconds: 300)));
  }
  final SearchProducts _search;

  Future<void> _onQueryChanged(SearchQueryChanged event, Emitter<SearchState> emit) async {
    if (event.query.isEmpty) return emit(const SearchState.initial());
    emit(const SearchState.loading());
    final result = await _search(event.query);
    emit(switch (result) {
      Ok(:final value) => SearchState.loaded(value),
      Err(:final failure) => SearchState.error(failure),
    });
  }
}

EventTransformer<T> debounce<T>(Duration d) => (events, mapper) => events.debounceTime(d).switchMap(mapper);
```

`debounceTime`/`switchMap` come from `rxdart`; `bloc_concurrency` provides `sequential()`, `droppable()`, `restartable()`, `concurrent()`.

## Rules

1. A Bloc depends on use cases, never on repositories, data sources, `BuildContext`, or Flutter.
2. No `try/catch` for domain failures in a Bloc: use cases return `Result`/`Either`. Catch only truly unexpected errors with `onError` in a `BlocObserver`.
3. One Bloc per screen or per bounded concern (auth session, cart). Never one Bloc per widget.
4. No `emit` after an `await` without checking `isClosed` when the Bloc may be closed mid-flight.
5. Subscriptions (`Stream.listen`) are stored and cancelled in `close()`.
6. Never call another Bloc from a Bloc. Coordinate in the widget tree with `BlocListener`, or share a domain stream.
7. Never `Future` in the constructor; expose an explicit `load()`.

## Widget Wiring

```dart
BlocProvider(
  create: (_) => getIt<ProfileCubit>()..load(userId),
  child: const ProfileView(),
)
```

| Widget | Use for |
|---|---|
| `BlocBuilder` | render from state |
| `BlocSelector` | render from one field, avoid rebuilds |
| `BlocListener` | side effects: navigation, snackbar, dialog |
| `BlocConsumer` | both, when the same state drives both |
| `context.read<T>()` | dispatch in callbacks (`onPressed`) |
| `context.watch<T>()` | rebuild in `build`; prefer `BlocBuilder` for clarity |

Exhaustive rendering:
```dart
BlocBuilder<ProfileCubit, ProfileState>(
  builder: (context, state) => switch (state) {
    ProfileInitial() || ProfileLoading() => const Center(child: CircularProgressIndicator()),
    ProfileLoaded(:final user) => ProfileBody(user: user),
    ProfileErr(:final failure) => ErrorView(failure: failure, onRetry: () => context.read<ProfileCubit>().load(userId)),
  },
)
```

Scope providers at the narrowest subtree that needs them. App-wide Blocs (session, theme) go in `app.dart` via `MultiBlocProvider`.

## Testing

Every Bloc/Cubit has a `blocTest` per transition. Mock use cases with `mocktail`.

```dart
class MockGetProfile extends Mock implements GetProfile {}

void main() {
  late MockGetProfile getProfile;
  setUp(() => getProfile = MockGetProfile());

  blocTest<ProfileCubit, ProfileState>(
    'emits [loading, loaded] when use case succeeds',
    build: () => ProfileCubit(getProfile: getProfile),
    setUp: () => when(() => getProfile('1')).thenAnswer((_) async => const Ok(User(id: '1', email: 'a@b.c'))),
    act: (cubit) => cubit.load('1'),
    expect: () => [const ProfileLoading(), const ProfileLoaded(User(id: '1', email: 'a@b.c'))],
  );

  blocTest<ProfileCubit, ProfileState>(
    'emits [loading, error] when use case fails',
    build: () => ProfileCubit(getProfile: getProfile),
    setUp: () => when(() => getProfile('1')).thenAnswer((_) async => const Err(NetworkFailure())),
    act: (cubit) => cubit.load('1'),
    expect: () => [const ProfileLoading(), const ProfileError(NetworkFailure())],
  );
}
```

Widget tests inject `MockBloc`/`MockCubit` from `bloc_test` with `BlocProvider.value` (see `superpowers-flutter:test-driven-development`).

## Common Mistakes

| Mistake | Fix |
|---|---|
| Business logic in `build` or `onPressed` | Move to a Cubit method |
| `setState` and a Bloc for the same data | Pick the Bloc; `setState` only for purely local UI (expanded/collapsed) |
| God state with 20 nullable fields | Split into sealed subclasses or separate Blocs |
| `context.read` inside `build` to render | `BlocBuilder`/`context.watch` |
| Navigation inside a Bloc | `BlocListener` in the widget |
| Bloc created in `build` without `BlocProvider` | `BlocProvider(create: ...)` so it is closed automatically |
````

- [ ] **Step 2: Validate**

Run: `bash tests/validate-skills.sh && grep -c 'blocTest' skills/bloc/SKILL.md`
Expected: `OK` then a count ≥ 3.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat(skill): bloc"
```

---

### Task 9: New skill — dart (with vendored Effective Dart)

**Files:**
- Create: `skills/dart/SKILL.md`
- Create: `skills/dart/references/effective-dart-style.md`, `effective-dart-documentation.md`, `effective-dart-usage.md`, `effective-dart-design.md`
- Create: `skills/dart/scripts/refresh-effective-dart.sh`

**Interfaces:**
- Consumes: `Result<T>` / `Failure` from Task 7.
- Produces: the refresh script other tasks copy the pattern from.

- [ ] **Step 1: Write the refresh script and run it**

`skills/dart/scripts/refresh-effective-dart.sh`:
```bash
#!/usr/bin/env bash
# Re-vendors Effective Dart from dart-lang/site-www (CC BY 4.0).
set -euo pipefail
DIR="$(cd "$(dirname "$0")/../references" && pwd)"
BASE="https://raw.githubusercontent.com/dart-lang/site-www/main/src/content/effective-dart"
for page in style documentation usage design; do
  {
    echo "<!-- Vendored from $BASE/$page.md on $(date +%F). Source: https://dart.dev/effective-dart/$page (CC BY 4.0) -->"
    curl -fsSL "$BASE/$page.md"
  } > "$DIR/effective-dart-$page.md"
  echo "wrote effective-dart-$page.md"
done
```

Run: `chmod +x skills/dart/scripts/refresh-effective-dart.sh && mkdir -p skills/dart/references && skills/dart/scripts/refresh-effective-dart.sh && wc -l skills/dart/references/*.md`
Expected: four files, each several hundred lines.

- [ ] **Step 2: Write the skill**

````markdown
---
name: dart
description: Use when writing, reviewing, or debugging any Dart code — Effective Dart style and design, Dart 3 features (records, patterns, sealed classes, class modifiers), error handling, null safety, async idioms
---

# Dart Language Skill

## Overview

Effective Dart is the style guide; this skill adds the Dart 3 patterns agents skip by default and the error-handling conventions used by `superpowers-flutter:flutter-clean-architecture`. Run `dart format` and `flutter analyze` on everything.

## Effective Dart (vendored)

Read the relevant section when unsure; do not answer from memory.

- `references/effective-dart-style.md` — identifiers, ordering, formatting
- `references/effective-dart-documentation.md` — doc comments, `///`, what to document
- `references/effective-dart-usage.md` — libraries, null, strings, collections, functions, variables, members, constructors, error handling, asynchrony
- `references/effective-dart-design.md` — names, libraries, classes and mixins, constructors, members, types, parameters, equality

Refresh with `scripts/refresh-effective-dart.sh`.

Non-negotiable highlights:
- `UpperCamelCase` types, `lowerCamelCase` members and constants (no `SCREAMING_CAPS`), `lowercase_with_underscores` files and imports.
- Imports ordered `dart:`, `package:`, relative; no relative imports across `lib/` boundaries.
- Prefer `final` locals; annotate public API types; never `var` for public fields.
- `///` doc comments on public members; first sentence is a one-line summary.
- Prefer named constructors and `factory` over static "create" methods.

## Dart 3 Features to Use

### Records

For returning two or three values without a class.
```dart
(int min, int max) range(List<int> xs) => (xs.reduce(math.min), xs.reduce(math.max));
final (lo, hi) = range([3, 1, 2]);
```
Promote to a class when the record crosses a public API boundary or needs methods.

### Sealed classes and exhaustive switch

```dart
sealed class Shape { const Shape(); }
final class Circle extends Shape { const Circle(this.r); final double r; }
final class Square extends Shape { const Square(this.s); final double s; }

double area(Shape s) => switch (s) {
  Circle(:final r) => math.pi * r * r,
  Square(:final s) => s * s,
};
```
The analyzer errors when a case is missing. Use `sealed` for state, events, failures, results. Use `final class` for leaves so nobody extends them outside the library.

### Patterns

```dart
if (json case {'id': final String id, 'tags': [final String first, ...]}) { ... }
switch (response) {
  case (status: 200, :final body): ...
  case (status: >= 500): ...
}
final [first, ...rest] = items;
```

### Class modifiers

| Modifier | Use |
|---|---|
| `abstract interface class` | repository and data source contracts |
| `sealed class` | closed hierarchies |
| `final class` | leaves, value objects |
| `base class` | when subclasses must inherit, not implement |
| `mixin` / `mixin class` | shared behaviour without state ownership |

### Extension types

Zero-cost wrappers for IDs and units:
```dart
extension type const UserId(String value) {}
```

### Other

- `switch` expressions over `if/else` chains returning values.
- `enhanced enums` with fields and methods instead of `Map<Enum, X>` lookups.
- Wildcards `_` for unused params.
- `late final` only for lifecycle-initialised fields; never `late` to silence the analyzer.

## Error Handling

1. **Exceptions are for bugs and infrastructure**, never for control flow. Throw `ArgumentError`/`StateError` for programmer errors; throw typed `Exception` subclasses from data sources (`ApiException`, `CacheException`).
2. **Expected failures are values**: repositories and use cases return `Result<T>` (or `Either<Failure, T>` with fpdart). See `superpowers-flutter:flutter-clean-architecture`.
3. `catch` the narrowest type: `on SocketException catch (e)`. Never bare `catch (_)` that swallows; never `catch (e)` on `Error` subclasses (`RangeError`, `TypeError`) — those are bugs to fix.
4. `rethrow`, not `throw e`, to keep the stack trace.
5. Custom exceptions implement `Exception`, are `final`, carry a `message`, and override `toString`.

```dart
final class ApiException implements Exception {
  const ApiException(this.statusCode, [this.message]);
  final int statusCode;
  final String? message;
  @override
  String toString() => 'ApiException($statusCode${message == null ? '' : ': $message'})';
}
```

## Null Safety

- Model absence with `?`, never with sentinels (`-1`, `''`).
- `!` only right after a check the analyzer cannot see; prefer `if (x case final x?)`, `?.`, `??`.
- `required` named parameters over positional nullable ones.
- Avoid `late` for values that can be passed in the constructor.

## Async

- Return `Future<T>` from functions that do async work; never `async` without `await` inside.
- `Stream` for values over time; expose `Stream` not `StreamController` from public API.
- Mark fire-and-forget calls with `unawaited(...)` (from `dart:async`); the `unawaited_futures` lint is on.
- Cancel every `StreamSubscription`; dispose every `StreamController`.
- No `Future.then` chains; use `async`/`await`.
- `Future.wait` for independent calls; sequential `await` only when order matters.
- Never block on `Future` in `main` isolate loops; use `compute`/`Isolate.run` for CPU work over ~16ms.

## Collections and Strings

- `const []`/`const {}` for empty literals; collection `if`/`for` over `addAll` chains.
- `List.unmodifiable` or `UnmodifiableListView` when exposing internal lists.
- String interpolation over `+`; `StringBuffer` in loops.
- `Iterable` return types when callers only iterate; `List` when they index.

## Review Checklist

- [ ] `dart format` clean, `flutter analyze` clean
- [ ] Public API documented with `///`
- [ ] No `dynamic` in public signatures (`avoid_dynamic_calls`, `strict-raw-types` on)
- [ ] Sealed hierarchies switched exhaustively, no `default:` hiding new cases
- [ ] Exceptions only for bugs/infrastructure; failures returned as values
- [ ] Subscriptions and controllers disposed
````

- [ ] **Step 3: Validate**

Run: `bash tests/validate-skills.sh && ls skills/dart/references | wc -l`
Expected: `OK` then `4`.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat(skill): dart with vendored Effective Dart"
```

---

### Task 10: New skill — flutter-widget-rules

**Files:**
- Create: `skills/flutter-widget-rules/SKILL.md`

**Interfaces:**
- Consumes: Bloc wiring names from Task 8.
- Produces: the numbered rules the code-reviewer agent (Task 2) cites.

- [ ] **Step 1: Write the skill**

````markdown
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
````

- [ ] **Step 2: Validate**

Run: `bash tests/validate-skills.sh && grep -c '^[0-9]*\. \*\*' skills/flutter-widget-rules/SKILL.md`
Expected: `OK` then `12`.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat(skill): flutter-widget-rules"
```

---

### Task 11: New skill — go-router

**Files:**
- Create: `skills/go-router/SKILL.md`

**Interfaces:**
- Consumes: `lib/core/router/` location from Task 7; `SessionCubit` naming convention (an app-wide Cubit exposing `state.isAuthenticated`).
- Produces: `lib/core/router/app_router.dart` exporting `GoRouter createRouter(SessionCubit session)`; route classes `<Name>Route` under `lib/core/router/routes.dart`.

- [ ] **Step 1: Write the skill**

````markdown
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
class HomeRoute extends GoRouteData {
  const HomeRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => const HomePage();
}

class ProfileRoute extends GoRouteData {
  const ProfileRoute({required this.userId});
  final String userId;
  @override
  Widget build(BuildContext context, GoRouterState state) => ProfilePage(userId: userId);
}

@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData {
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

Wire in `app.dart`:
```dart
class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    final router = createRouter(context.read<SessionCubit>());
    return MaterialApp.router(routerConfig: router);
  }
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
````

- [ ] **Step 2: Validate**

Run: `bash tests/validate-skills.sh && grep -c 'GoRouterRefreshStream' skills/go-router/SKILL.md`
Expected: `OK` then a count ≥ 3.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat(skill): go-router"
```

---

### Task 12: New skill — auto-route

**Files:**
- Create: `skills/auto-route/SKILL.md`

**Interfaces:**
- Consumes: same `SessionCubit` convention and `lib/core/router/` location as Task 11.
- Produces: `lib/core/router/app_router.dart` with `@AutoRouterConfig() class AppRouter extends RootStackRouter`; `AuthGuard` in `lib/core/router/auth_guard.dart`.

- [ ] **Step 1: Write the skill**

````markdown
---
name: auto-route
description: Use when working on navigation in a Flutter app whose pubspec.yaml depends on auto_route — @RoutePage pages, generated router, guards driven by a Bloc, nested tab routers, path parameters, and route tests
---

# auto_route

## Overview

Code-generated, strongly typed routing. One `AppRouter` in `lib/core/router/`, every page annotated with `@RoutePage()`, guards for auth. Never mix with `go_router` or raw `Navigator.push` for screens.

## Setup

`pubspec.yaml`: `auto_route` in dependencies; `auto_route_generator` and `build_runner` in dev_dependencies. Generate with `dart run build_runner build -d`; commit the generated `app_router.gr.dart`.

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
    resolver.redirectUntil(const LoginRoute());
  }
}
```
`redirectUntil` re-evaluates the guard when the login page pops, so a successful login continues to the originally requested route. Re-run guards after logout with `router.reevaluateGuards()` from a `BlocListener` on `SessionCubit`.

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
````

- [ ] **Step 2: Validate**

Run: `bash tests/validate-skills.sh && grep -c 'AutoRouteGuard' skills/auto-route/SKILL.md`
Expected: `OK` then `1`.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat(skill): auto-route"
```

---

### Task 13: New skill — fpdart

**Files:**
- Create: `skills/fpdart/SKILL.md`

**Interfaces:**
- Consumes: `Failure` sealed hierarchy from Task 7 (`lib/core/error/failure.dart`).
- Produces: repository/use case signatures `Future<Either<Failure, T>>` and `TaskEither<Failure, T>`; replaces `Result<T>` when fpdart is present.

- [ ] **Step 1: Write the skill**

````markdown
---
name: fpdart
description: Use when writing domain or data code in a Flutter app whose pubspec.yaml depends on fpdart — Either and TaskEither for failures, Option at boundaries, mapping exceptions once in the data layer, consuming in Blocs with fold or patterns
---

# fpdart

## Overview

When `fpdart` is present, `Either<Failure, T>` replaces the hand-written `Result<T>`. Do not create `lib/core/error/result.dart`. `Failure` stays a sealed class in `lib/core/error/failure.dart`.

## Where each type lives

| Layer | Return type |
|---|---|
| data source | plain `Future<T>`, throws typed exceptions |
| repository (domain interface + data impl) | `Future<Either<Failure, T>>` or `TaskEither<Failure, T>` |
| use case | same as repository |
| Bloc | consumes with `fold` or pattern matching, emits states |
| widgets | never see `Either` |

Pick `TaskEither` when use cases chain several async steps; `Future<Either>` when one call is enough. Do not mix within one feature.

## Repository implementation: map exceptions once

```dart
@override
Future<Either<Failure, User>> signIn({required String email, required String password}) async {
  try {
    final model = await _remote.signIn(email, password);
    return right(model.toEntity());
  } on ApiException catch (e) {
    return left(e.statusCode == 401 ? const InvalidCredentialsFailure() : ServerFailure(e.message));
  } on SocketException {
    return left(const NetworkFailure());
  }
}
```

With `TaskEither`:
```dart
@override
TaskEither<Failure, User> signIn({required String email, required String password}) =>
    TaskEither.tryCatch(
      () async => (await _remote.signIn(email, password)).toEntity(),
      (error, _) => switch (error) {
        ApiException(statusCode: 401) => const InvalidCredentialsFailure(),
        ApiException(:final message) => ServerFailure(message),
        SocketException() => const NetworkFailure(),
        _ => ServerFailure(error.toString()),
      },
    );
```

## Chaining in a use case

```dart
class Checkout {
  const Checkout(this._cart, this._payment);
  final CartRepository _cart;
  final PaymentRepository _payment;

  TaskEither<Failure, Receipt> call() => _cart
      .current()
      .flatMap((cart) => cart.isEmpty ? TaskEither.left(const EmptyCartFailure()) : TaskEither.right(cart))
      .flatMap(_payment.charge)
      .map(Receipt.fromPayment);
}
```

Run it in the Bloc with `.run()`.

## Consuming in a Bloc

```dart
Future<void> load(String id) async {
  emit(const ProfileLoading());
  final result = await _getProfile(id); // Either<Failure, User>
  emit(result.fold(ProfileError.new, ProfileLoaded.new));
}
```

Or with patterns (fpdart `Either` is sealed as `Left`/`Right`):
```dart
emit(switch (await _getProfile(id)) {
  Right(:final value) => ProfileLoaded(value),
  Left(:final value) => ProfileError(value),
});
```

## Option

Use `Option<T>` only at a boundary where "absent" is a domain concept the caller must handle (cached token, last-known location). Everywhere else nullable types are clearer. Never return `Option` from widgets or Blocs.

```dart
Option<Token> cachedToken() => Option.fromNullable(_storage.read('token')).map(Token.new);
```

## Rules

1. `Failure` on the left, always. Never `Either<Exception, T>` or `Either<String, T>`.
2. Exceptions become failures in the repository implementation and nowhere else.
3. No `getOrElse(() => throw ...)`, no `.getRight().toNullable()!`. Fold or match.
4. No fpdart imports in `presentation/widgets` or `presentation/pages`.
5. No `Task`, `Reader`, `State` monads unless the team already uses them; `Either`, `TaskEither`, `Option` cover this architecture.
6. Do not wrap simple synchronous getters that cannot fail.

## Testing

```dart
test('returns InvalidCredentialsFailure on 401', () async {
  when(() => api.signIn(any(), any())).thenThrow(const ApiException(401));
  final result = await repo.signIn(email: 'a@b.c', password: 'bad');
  expect(result, const Left<Failure, User>(InvalidCredentialsFailure()));
});

test('returns user on success', () async {
  when(() => api.signIn(any(), any())).thenAnswer((_) async => const UserModel(id: '1', email: 'a@b.c'));
  final result = await repo.signIn(email: 'a@b.c', password: 'x');
  expect(result, const Right<Failure, User>(User(id: '1', email: 'a@b.c')));
});
```

`Left`/`Right` have value equality when `Failure` and the entity do (Equatable or manual `==`). For `TaskEither`, `await te.run()` then assert the same way.

## Common Mistakes

| Mistake | Fix |
|---|---|
| `try/catch` around a use case in a Bloc | use case already returns `Either` |
| Both `result.dart` and fpdart | delete `result.dart` |
| `Either<String, T>` | sealed `Failure` |
| `Option` for a nullable field on an entity | `T?` |
| `.run()` called in a widget | call in the Bloc |
````

- [ ] **Step 2: Validate**

Run: `bash tests/validate-skills.sh && grep -c 'TaskEither' skills/fpdart/SKILL.md`
Expected: `OK` then a count ≥ 6.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat(skill): fpdart"
```

---

### Task 14: New skill — flutter-analyze

**Files:**
- Create: `skills/flutter-analyze/SKILL.md`
- Create: `skills/flutter-analyze/references/analysis_options.yaml`

**Interfaces:**
- Produces: the baseline `analysis_options.yaml` other skills assume (`strict-casts`, `unawaited_futures`, const lints as errors).

- [ ] **Step 1: Write the reference analysis_options.yaml**

`skills/flutter-analyze/references/analysis_options.yaml`:
```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    prefer_const_constructors: error
    prefer_const_literals_to_create_immutables: error
    unawaited_futures: error
    use_build_context_synchronously: error
    avoid_dynamic_calls: error
    missing_required_param: error
    missing_return: error
  exclude:
    - "**/*.g.dart"
    - "**/*.gr.dart"
    - "**/*.freezed.dart"
    - build/**

linter:
  rules:
    - always_declare_return_types
    - avoid_dynamic_calls
    - avoid_print
    - avoid_redundant_argument_values
    - avoid_unused_constructor_parameters
    - cancel_subscriptions
    - close_sinks
    - directives_ordering
    - prefer_final_locals
    - prefer_final_in_for_each
    - prefer_single_quotes
    - require_trailing_commas
    - sort_pub_dependencies
    - unawaited_futures
    - unnecessary_await_in_return
    - unnecessary_lambdas
    - unnecessary_parenthesis
    - use_super_parameters
```

- [ ] **Step 2: Write the skill**

````markdown
---
name: flutter-analyze
description: Use before committing or requesting review, when analyzer warnings appear, or when setting up lints in a Flutter project — strict analysis_options baseline, flutter analyze / dart fix workflow, warning triage, zero-warning policy
---

# Flutter Analyze

## Overview

Static analysis is the first reviewer. The bar is zero issues from `flutter analyze` on every commit, with the strict baseline in `references/analysis_options.yaml`.

## Setup

1. Copy `references/analysis_options.yaml` to the project root (merge if one exists; keep the project's stricter choices).
2. `flutter pub add --dev flutter_lints` if missing.
3. Run `flutter analyze`. If the project is old and the count is large, fix mechanically first (`dart fix --apply`), then triage the rest by rule (see below) rather than by file.

`very_good_analysis` is an acceptable stricter drop-in: `include: package:very_good_analysis/analysis_options.yaml`. Do not stack both includes.

## Workflow

```bash
dart format .                 # formatting is not negotiable
flutter analyze               # list issues
dart fix --dry-run            # preview mechanical fixes
dart fix --apply              # apply them
flutter analyze               # must print "No issues found!"
```

Run this sequence before `superpowers-flutter:requesting-code-review` and before every commit. Add it to CI:

```yaml
- run: dart format --output=none --set-exit-if-changed .
- run: flutter analyze --fatal-infos
```

## Triage rules

| Situation | Action |
|---|---|
| `dart fix` can fix it | apply, no discussion |
| Real bug (`use_build_context_synchronously`, `unawaited_futures`, `cancel_subscriptions`) | fix the code |
| Style rule the team disagrees with | disable the rule project-wide in `analysis_options.yaml` with a comment saying why; never suppress per-line |
| Generated code | already excluded; if not, add the glob to `analyzer.exclude` |
| Genuine one-off (platform API that must use `dynamic`) | `// ignore: <rule>` on that line with a trailing reason: `// ignore: avoid_dynamic_calls, platform channel returns untyped map` |

`// ignore_for_file:` is allowed only in generated or vendored files.

## Reading the output

```
   info • Prefer const with constant constructors • lib/features/auth/presentation/pages/login_page.dart:42:12 • prefer_const_constructors
```
Columns: severity, message, `file:line:col`, rule name. Group by rule name to decide once per rule.

## Metrics worth watching

- `flutter analyze` count: must be 0.
- `dart pub outdated` count of major-behind packages (see `superpowers-flutter:flutter-upgrade`).
- `flutter test --coverage` + `lcov --summary coverage/lcov.info` if coverage is tracked; do not gate on a number without agreeing it first.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Suppressing with `// ignore` to get green | fix or disable the rule globally with a reason |
| Running analyze only in CI | run locally before commit |
| Not excluding generated files | add globs, otherwise `dart fix` edits them |
| `flutter analyze` on a pure Dart package | `dart analyze` |
````

- [ ] **Step 3: Validate**

Run: `bash tests/validate-skills.sh && grep -c 'strict-casts: true' skills/flutter-analyze/references/analysis_options.yaml`
Expected: `OK` then `1`.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat(skill): flutter-analyze with strict analysis_options baseline"
```

---

### Task 15: New skill — flutter-upgrade

**Files:**
- Create: `skills/flutter-upgrade/SKILL.md`
- Create: `skills/flutter-upgrade/scripts/fetch-changelogs.sh`
- Create: `skills/flutter-upgrade/references/breaking-changes.md`

**Interfaces:**
- Consumes: analyze workflow from Task 14, test commands from Task 5.
- Produces: `scripts/fetch-changelogs.sh <package> [<package>...]` printing each package's CHANGELOG from pub.dev.

- [ ] **Step 1: Write the changelog script**

```bash
#!/usr/bin/env bash
# Prints the CHANGELOG of each pub.dev package given as argument.
# Usage: fetch-changelogs.sh go_router flutter_bloc
set -euo pipefail
[ $# -gt 0 ] || { echo "usage: $0 <package>..." >&2; exit 2; }
for pkg in "$@"; do
  echo "===== $pkg ====="
  url="https://pub.dev/api/packages/$pkg"
  latest="$(curl -fsSL "$url" | python3 -c 'import json,sys; print(json.load(sys.stdin)["latest"]["version"])')"
  echo "latest: $latest"
  # pub.dev serves the raw changelog of the package archive under /documentation; the API exposes the archive URL.
  archive="$(curl -fsSL "$url" | python3 -c 'import json,sys; print(json.load(sys.stdin)["latest"]["archive_url"])')"
  tmp="$(mktemp -d)"
  curl -fsSL "$archive" | tar -xz -C "$tmp" 2>/dev/null || true
  if [ -f "$tmp/CHANGELOG.md" ]; then
    sed -n '1,120p' "$tmp/CHANGELOG.md"
  else
    echo "(no CHANGELOG.md in archive; see https://pub.dev/packages/$pkg/changelog)"
  fi
  rm -rf "$tmp"
  echo
done
```

Run: `chmod +x skills/flutter-upgrade/scripts/fetch-changelogs.sh && skills/flutter-upgrade/scripts/fetch-changelogs.sh flutter_bloc | head -20`
Expected: `===== flutter_bloc =====`, a `latest:` line, and changelog text.

- [ ] **Step 2: Write references/breaking-changes.md**

````markdown
# Flutter and Dart breaking-change sources

Read the page for the target release before upgrading. Do not rely on memory.

| Release line | Page |
|---|---|
| All Flutter breaking changes, by release | https://docs.flutter.dev/release/breaking-changes |
| Flutter release notes | https://docs.flutter.dev/release/release-notes |
| Dart language evolution and breaking changes | https://dart.dev/resources/language/evolution |
| Dart SDK changelog | https://github.com/dart-lang/sdk/blob/main/CHANGELOG.md |
| Deprecated Flutter APIs and their replacements | https://docs.flutter.dev/release/breaking-changes#deprecations |
| flutter_bloc migration guide | https://bloclibrary.dev/migration/ |
| go_router changelog | https://pub.dev/packages/go_router/changelog |
| auto_route migration | https://pub.dev/packages/auto_route/changelog |
| fpdart changelog | https://pub.dev/packages/fpdart/changelog |

Recurring themes to check in every SDK bump: Material 3 defaults, `TextScaler` vs `textScaleFactor`, `WillPopScope` → `PopScope`, `Color` component API, deprecated `MediaQuery.of` sub-getters, Gradle/AGP and Xcode minimums, `flutter_lints` new rules.
````

- [ ] **Step 3: Write the skill**

````markdown
---
name: flutter-upgrade
description: Use when bumping the Flutter or Dart SDK, or upgrading a package across a major version — ordered upgrade workflow, changelog and breaking-change reading, dart fix, deprecation triage, verification
---

# Flutter Upgrade

## Overview

Upgrades are done one axis at a time: SDK first, then packages, each on its own branch with a green baseline before and after. Read changelogs; do not guess migrations.

## Before starting

```bash
flutter --version
flutter doctor -v
flutter analyze && flutter test        # baseline must be green
git switch -c chore/flutter-upgrade
```

If the baseline is red, stop and fix first (`superpowers-flutter:systematic-debugging`).

## SDK upgrade

1. Read `references/breaking-changes.md` and open the breaking-changes page for every minor release between current and target.
2. If the project pins the SDK (`fvm`, `.fvmrc`, `asdf`), change the pin (`fvm use <version>`). Otherwise `flutter upgrade` to the latest stable; for a specific older version, `git -C "$(dirname "$(dirname "$(which flutter)")")" checkout <tag>` then `flutter doctor`.
3. Update `environment.sdk` in `pubspec.yaml` to the new floor.
4. `flutter pub get`, then `dart fix --apply`, then `flutter analyze`.
5. Grep for known deprecations listed in the breaking-changes page and migrate by hand.
6. `flutter test`, then run the app on one iOS simulator and one Android emulator; check platform folders (`android/build.gradle` AGP/Kotlin versions, `ios/Podfile` platform floor) against `flutter create --platforms=ios,android .` output on a scratch project of the same name.
7. Commit: `chore(sdk): upgrade Flutter to X.Y.Z`.

## Package upgrades

```bash
flutter pub outdated                     # see Resolvable vs Latest
scripts/fetch-changelogs.sh go_router flutter_bloc   # read what changed
flutter pub upgrade                      # within constraints
flutter pub upgrade --major-versions     # cross majors, rewrites pubspec
flutter pub get
dart run build_runner build -d           # if codegen is used
dart fix --apply && flutter analyze && flutter test
```

Upgrade in this order, one commit each: lints (`flutter_lints`) → core (`flutter_bloc`, `equatable`, `get_it`, `fpdart`) → routing (`go_router` / `auto_route`) → data (`dio`/`http`, storage) → codegen (`build_runner`, generators) → everything else. Read the changelog section between the old and new version for every major bump before touching code.

## Deprecation triage

| Analyzer says | Do |
|---|---|
| `deprecated_member_use` with a replacement named in the message | replace now |
| Deprecated with no replacement yet | leave, add a `// TODO(upgrade): <rule> — removed in <version>` and open an issue |
| Deprecation inside a dependency | upgrade that dependency; if none available, pin and note |

Never turn off `deprecated_member_use`.

## Verification

- `flutter analyze` → `No issues found!`
- `flutter test` green
- App boots on both platforms; the two or three most-used flows clicked through
- `flutter build apk --debug` and `flutter build ios --simulator --debug` succeed
- `pubspec.lock` committed

Use `superpowers-flutter:verification-before-completion` before claiming done.

## Common Mistakes

| Mistake | Fix |
|---|---|
| SDK and 15 packages in one commit | one axis per commit |
| `--major-versions` without reading changelogs | read first, script above |
| Forgetting `build_runner` after codegen package bump | regenerate, commit `.g.dart` |
| Ignoring `flutter doctor` warnings about Xcode/AGP | fix toolchain first |
| Trusting memory for migrations | open the breaking-changes page |
````

- [ ] **Step 4: Validate**

Run: `bash tests/validate-skills.sh`
Expected: `OK`.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat(skill): flutter-upgrade with changelog script"
```

---

### Task 16: New skill — dart-commit-message

**Files:**
- Create: `skills/dart-commit-message/SKILL.md`

**Interfaces:**
- Produces: scope convention `<feature-dir>` or `core`, used by all later commits in projects using this plugin.

- [ ] **Step 1: Write the skill**

````markdown
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
````

- [ ] **Step 2: Validate**

Run: `bash tests/validate-skills.sh`
Expected: `OK`.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat(skill): dart-commit-message"
```

---

### Task 17: New skill — flutter-docs (with vendored architecture guide)

**Files:**
- Create: `skills/flutter-docs/SKILL.md`
- Create: `skills/flutter-docs/references/flutter-architecture-guide.md`, `flutter-architecture-recommendations.md`, `flutter-architecture-concepts.md`
- Create: `skills/flutter-docs/scripts/refresh-architecture-docs.sh`

**Interfaces:**
- Consumes: nothing.
- Produces: the topic map other skills point to for API questions.

- [ ] **Step 1: Write and run the refresh script**

```bash
#!/usr/bin/env bash
# Re-vendors the Flutter app-architecture pages from flutter/website (CC BY 4.0).
set -euo pipefail
DIR="$(cd "$(dirname "$0")/../references" && pwd)"
BASE="https://raw.githubusercontent.com/flutter/website/main/sites/docs/src/content/app-architecture"
for page in guide recommendations concepts; do
  {
    echo "<!-- Vendored from $BASE/$page.md on $(date +%F). Source: https://docs.flutter.dev/app-architecture/$page (CC BY 4.0) -->"
    curl -fsSL "$BASE/$page.md"
  } > "$DIR/flutter-architecture-$page.md"
  echo "wrote flutter-architecture-$page.md"
done
```

Run: `mkdir -p skills/flutter-docs/references && chmod +x skills/flutter-docs/scripts/refresh-architecture-docs.sh && skills/flutter-docs/scripts/refresh-architecture-docs.sh && wc -l skills/flutter-docs/references/*.md`
Expected: three files; `guide` around 400+ lines.

- [ ] **Step 2: Write the skill**

````markdown
---
name: flutter-docs
description: Use when any Flutter or Dart framework, widget, API, tooling, or package question comes up — topic map to official documentation to fetch before answering, plus the vendored Flutter architecture guide
---

# Flutter Docs

## Overview

Fetch the page; do not answer API questions from memory. Signatures, defaults, and deprecations change every release.

## Vendored

- `references/flutter-architecture-guide.md` — official layered architecture (UI / logic / data), the basis for `superpowers-flutter:flutter-clean-architecture`
- `references/flutter-architecture-recommendations.md` — one-page do/consider list
- `references/flutter-architecture-concepts.md` — separation of concerns, unidirectional data flow

Refresh with `scripts/refresh-architecture-docs.sh`.

## Topic map

### Flutter framework — https://docs.flutter.dev
| Topic | URL |
|---|---|
| Widget catalog | https://docs.flutter.dev/ui/widgets |
| Layout | https://docs.flutter.dev/ui/layout |
| Constraints ("unbounded height" errors) | https://docs.flutter.dev/ui/layout/constraints |
| Navigation overview | https://docs.flutter.dev/ui/navigation |
| Deep linking | https://docs.flutter.dev/ui/navigation/deep-linking |
| State management options | https://docs.flutter.dev/data-and-backend/state-mgmt/options |
| Networking | https://docs.flutter.dev/data-and-backend/networking |
| JSON serialization | https://docs.flutter.dev/data-and-backend/serialization/json |
| Local persistence | https://docs.flutter.dev/cookbook/persistence |
| Animations | https://docs.flutter.dev/ui/animations |
| Accessibility | https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility |
| Internationalization | https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization |
| Testing overview | https://docs.flutter.dev/testing/overview |
| Widget tests | https://docs.flutter.dev/cookbook/testing/widget/introduction |
| Golden tests | https://api.flutter.dev/flutter/flutter_test/matchesGoldenFile.html |
| Performance best practices | https://docs.flutter.dev/perf/best-practices |
| DevTools | https://docs.flutter.dev/tools/devtools |
| Platform channels | https://docs.flutter.dev/platform-integration/platform-channels |
| Isolates | https://docs.flutter.dev/perf/isolates |
| Build and release Android | https://docs.flutter.dev/deployment/android |
| Build and release iOS | https://docs.flutter.dev/deployment/ios |
| Flavors | https://docs.flutter.dev/deployment/flavors |
| Breaking changes | https://docs.flutter.dev/release/breaking-changes |
| API reference | https://api.flutter.dev |

### Dart — https://dart.dev
| Topic | URL |
|---|---|
| Language tour | https://dart.dev/language |
| Patterns | https://dart.dev/language/patterns |
| Records | https://dart.dev/language/records |
| Class modifiers | https://dart.dev/language/class-modifiers |
| Extension types | https://dart.dev/language/extension-types |
| Null safety | https://dart.dev/null-safety/understanding-null-safety |
| Async programming | https://dart.dev/libraries/async/async-await |
| Streams | https://dart.dev/libraries/async/using-streams |
| Isolates | https://dart.dev/language/isolates |
| Effective Dart | vendored in `superpowers-flutter:dart` |
| Linter rules | https://dart.dev/tools/linter-rules |
| `dart fix` | https://dart.dev/tools/dart-fix |
| pub workspaces / monorepo | https://dart.dev/tools/pub/workspaces |
| Core libraries | https://dart.dev/libraries |

### Packages used by this stack
| Package | Docs |
|---|---|
| flutter_bloc / bloc | https://bloclibrary.dev — concepts: https://bloclibrary.dev/bloc-concepts/ — testing: https://bloclibrary.dev/testing/ |
| bloc_test | https://pub.dev/packages/bloc_test |
| bloc_concurrency | https://pub.dev/packages/bloc_concurrency |
| equatable | https://pub.dev/packages/equatable |
| get_it | https://pub.dev/packages/get_it |
| go_router | https://pub.dev/packages/go_router — https://pub.dev/documentation/go_router/latest/topics/Get%20started-topic.html |
| go_router_builder | https://pub.dev/packages/go_router_builder |
| auto_route | https://pub.dev/packages/auto_route |
| fpdart | https://pub.dev/packages/fpdart — https://github.com/SandroMaglione/fpdart |
| mocktail | https://pub.dev/packages/mocktail |
| freezed (optional) | https://pub.dev/packages/freezed |
| json_serializable (optional) | https://pub.dev/packages/json_serializable |
| dio | https://pub.dev/packages/dio |
| flutter_secure_storage | https://pub.dev/packages/flutter_secure_storage |
| rxdart | https://pub.dev/packages/rxdart |

## How to use

1. Find the row; fetch the URL.
2. For a class or method, append the symbol to the api.flutter.dev search: `https://api.flutter.dev/flutter/search.html?q=<Symbol>` or open the library page directly, e.g. `https://api.flutter.dev/flutter/widgets/ListView-class.html`.
3. For a pub package's API, use `https://pub.dev/documentation/<package>/latest/`.
4. Quote the version the doc applies to when the answer depends on it.
````

- [ ] **Step 3: Validate**

Run: `bash tests/validate-skills.sh && ls skills | wc -l`
Expected: `OK` then `31`.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat(skill): flutter-docs with vendored architecture guide"
```

---

### Task 18: README and local install smoke test

**Files:**
- Create: `README.md`
- Modify: `.gitignore` (create) with `.worktrees/`, `docs/superpowers/handoffs/`

**Interfaces:**
- Consumes: everything.

- [ ] **Step 1: Write README.md**

````markdown
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
````

- [ ] **Step 2: .gitignore**

```
.worktrees/
docs/superpowers/handoffs/
```

- [ ] **Step 3: Full validation**

Run: `bash tests/validate-skills.sh && git status --short | wc -l`
Expected: `checked 31 skills`, `OK`, then the number of uncommitted files (README, .gitignore).

- [ ] **Step 4: Install locally and smoke test**

In an interactive Claude Code session (the executor cannot do this from a non-interactive shell; if that is the case, record the commands in the task notes and mark the step for the human):

```
/plugin marketplace add /Users/seb/Developer/async/superpowers-flutter
/plugin install superpowers-flutter@superpowers-flutter
```
Start a new session in any Flutter project and check that the session-start context says "You have superpowers for Flutter and Dart" and lists `superpowers-flutter:bloc`. Then ask "add a profile feature" and confirm the agent announces `superpowers-flutter:brainstorming` first and later reads `pubspec.yaml` to pick the router skill.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "docs: README, gitignore"
```
