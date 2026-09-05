# Oracle Prompt Template

Copy this structure verbatim into `tmp/oracle/<date>-<slug>.md`. Section order is intentional — oracles weight the top of long prompts most.

---

# Oracle Consultation: <one-line problem statement>

> Snapshot: `<git rev-parse --short HEAD>` on branch `<git branch --show-current>` at `<UTC timestamp>`

## Your Role and Desired Output

You are a senior Flutter/Dart engineer reviewing this brief cold. You have no prior context and no memory of earlier consultations. Please return:

1. **Ranked hypotheses** — most likely root cause first, with the reasoning that distinguishes it from the alternatives
2. **Patch plan** — specific files and changes, including any new tests that would prove the fix
3. **Risky assumptions** — things you're inferring from the brief that, if wrong, would invalidate your answer
4. (Optional) **Three options with tradeoffs** if the fix is a judgment call

Be direct. If the brief is missing something critical, say what and why.

## Project Briefing

- **Language/Framework:** Dart <X.Y.Z>, Flutter <X.Y.Z> (channel <stable/beta>)
- **State management:** flutter_bloc (Bloc/Cubit) <version>
- **Architecture:** feature-first clean architecture (`lib/features/<feature>/{data,domain,presentation}` + `lib/core`)
- **Routing:** <go_router/auto_route/none>, version `<X.Y.Z>`
- **Functional core:** <fpdart/none>
- **DI:** get_it, registered by hand in `lib/core/di/injection.dart`
- **Test framework:** flutter_test + bloc_test + mocktail, run with `<command>`
- **Codegen:** <build_runner + freezed/json_serializable/go_router_builder/auto_route_generator/none>
- **Linter:** flutter_lints / custom `analysis_options.yaml`
- **Target platforms:** <iOS/Android/web/desktop>, min SDK `<value>`
- **Flutter version manager:** <FVM/asdf/none>

## Where Things Live

- Feature directory for this bug: `lib/features/<feature>/{data,domain,presentation}`
- Relevant entrypoints for this bug: `<file>`, `<file>`
- Relevant DI registration: `lib/core/di/injection.dart` or `lib/features/<feature>/<feature>_injection.dart` (or: none)
- Packages/plugins that touch this code path: <list or "none">

## The Question

**One-line question:** <what do you want the oracle to answer>

**Failing command:**
```
<exact command, e.g. flutter test test/features/user/user_test.dart>
```

**Verbatim error / stack trace:**
```
<paste full output, do not summarize>
```

**Expected behavior:** <one sentence>
**Actual behavior:** <one sentence>

**Reproduction steps** (if not just running the command):
1. <step>
2. <step>
3. <step>

## What I Already Tried

- **Hypothesis:** <one line>
  **Action:** <change made or command run>
  **Outcome:** <what happened, including partial wins>

- **Hypothesis:** <one line>
  **Action:** <...>
  **Outcome:** <...>

(Repeat for each attempt — typically 3–7. Include partial successes; they're high-signal.)

## Constraints

- <e.g. "Public API of `AuthRepository.signIn` must not change — it's called from three features">
- <e.g. "Must work on Dart 3.x with sound null safety">
- <e.g. "No new packages">
- <e.g. "Cold start must stay under 2s on the target device">
- <e.g. "Cannot hand-edit generated `*.g.dart`/`*.gr.dart` files">

## Flutter/Dart-Specific Context

(Include only items that might be relevant — don't pad.)

- **Generated code:** `<file>.g.dart`/`.gr.dart`/`.freezed.dart` <is/is not> in sync with its source; `build_runner` last run on `<date/commit>`.
- **Null safety:** Failing path <does/does not> use `late` or `!` on `<field>`.
- **Async:** Failing code <awaits/does not await> `<call>`; Bloc/Cubit <does/does not> check `isClosed` before `emit` after the `await`.
- **State management:** `<Bloc/Cubit>` owns this state; `copyWith` on `<State>` <does/does not> include `<field>`.
- **Recent pubspec.lock changes:** `<package>` bumped from `<old>` to `<new>` in commit `<sha>`.
- **Platform channel:** `<plugin>` version `<X.Y.Z>`; behavior <does/does not> diverge between iOS and Android.
- **DI:** `<Type>` <is/is not> registered in `lib/core/di/injection.dart` (or feature injection file); registered as <singleton/factory>.
- **Build mode:** Bug occurs in `<debug/profile/release>`. Relevant `kReleaseMode`/`kDebugMode` branch: `<code>`.
- **Routing:** Failing route `<path>` <is/is not> present in the generated router table; guard/redirect involved: `<name>`.

## Attached Files

Files included below: `<list of paths>` (total: <N> lines)

### `<path/to/failing_file.dart>`
```dart
<full contents or relevant excerpt with line numbers>
```

### `<path/to/collaborator.dart>`
```dart
<...>
```

### `<path/to/test_test.dart>`
```dart
<...>
```

### `<path/to/model.dart>` (entity/model involved)
```dart
<...>
```

### `lib/core/di/injection.dart` (relevant excerpt)
```dart
<...>
```

## Safety / Redactions

The following were redacted from this brief and the attached files:

- `<count>` instances of API keys / tokens / passwords (replaced with `[REDACTED:credential]`)
- `<count>` connection strings with embedded credentials (replaced with `[REDACTED:db-url]`)
- Excluded entirely: `.env`, `android/key.properties`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, signing keys (`*.jks`, `*.keystore`, `*.p12`)

If the answer depends on the redacted values, please flag what you'd need to know in non-secret form (e.g. "is the API key the staging or production format?") rather than asking for the value itself.

---

*End of brief. The oracle has no memory of prior runs — re-running this prompt with the same file produces the same context.*
