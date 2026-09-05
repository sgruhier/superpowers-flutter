---
name: consulting-an-oracle
description: Use when stuck after multiple debug attempts and want to escalate to a stronger one-shot model (GPT-5 Pro, Opus, Gemini Pro) — packages a self-contained "oracle prompt" with Flutter/Dart project briefing, verbatim error, what-was-tried, constraints, and just-enough attached files. Triggers include "ask the oracle", "write a letter to GPT-5", "I'm stuck, draft a prompt for another model", "/tmp/letter.md".
---

# Consulting an Oracle

## Overview

When in-session debugging has stalled, package the failed investigation into a single self-contained markdown file that a stronger one-shot model can answer cold. The oracle has zero project knowledge and no memory of prior runs — the prompt must stand alone.

**Core principle:** Just-enough context beats whole-repo dumps. A focused 1500-line prompt outperforms a 30k-line dump every time.

**This skill produces a file. It does not call any model.** Print the path and suggested invocation; let the user run it. This separation is deliberate: keeping prompt-construction decoupled from model-orchestration keeps the skill model-agnostic (works with any oracle the user picks — Codex, Claude, Gemini, paste-into-chat), keeps the artifact re-runnable later, and avoids coupling the skill to credentials, CLI availability, or cost decisions that belong to the user.

**Announce at start:** "I'm using the consulting-an-oracle skill to package this investigation."

## When to Use

- 3+ failed fix attempts on the same symptom in this session
- User says "ask the oracle", "ask GPT-5", "write a letter to an expert", "draft a prompt for another model", "/tmp/letter.md"
- Investigation is consuming context with no convergence
- Before compaction, when the failed investigation should outlive this session as a one-shot prompt

**Don't use when:**
- You haven't actually tried to debug yet → use `superpowers-flutter:systematic-debugging`
- The bug is solved → use `superpowers-flutter:compound`
- Handing off to another Claude session with full plugin/tooling → use `superpowers-flutter:handoff`
- The user wants you to keep trying → keep trying

## Output

**Location:** `tmp/oracle/<YYYY-MM-DD>-<slug>.md` (most Flutter projects don't gitignore `tmp/` by default — add it if the user doesn't want the prompt committed).
**Fallback:** `/tmp/oracle-<slug>.md` if `tmp/` isn't writable.

**Slug:** short kebab-case description of the failing symptom — `bloc-emit-after-close`, `go-router-redirect-loop`, `freezed-copywith-stale-field`. Not the branch name, not the ticket ID.

After writing, print:

```
Oracle prompt: tmp/oracle/2026-05-06-<slug>.md
Suggested invocation:
  codex --model gpt-5-pro --file tmp/oracle/2026-05-06-<slug>.md
  # or paste into chat.openai.com / claude.ai / gemini.google.com
```

## The Process

### Step 1: Detect Project Shape

Run these in parallel and capture output:

```bash
flutter --version
dart --version
cat pubspec.yaml
test -f pubspec.lock && grep -E "^\s+(go_router|auto_route|fpdart|flutter_bloc|bloc_test|get_it|flutter_riverpod|hooks_riverpod|riverpod_annotation|riverpod_generator|freezed|injectable|build_runner|json_serializable) " pubspec.lock
git status --porcelain -- '*.g.dart' '*.gr.dart' '*.freezed.dart'
flutter doctor -v
test -f ios/Podfile.lock && grep -c "^  - " ios/Podfile.lock
test -f android/app/build.gradle.kts && grep -E "compileSdk|minSdk|targetSdk" android/app/build.gradle.kts
cat .fvmrc 2>/dev/null || cat .fvm/fvm_config.json 2>/dev/null
```

Extract: Flutter and Dart SDK versions, minimum/target platform SDK versions and toolchain state (Xcode, Android SDK, CocoaPods) from `flutter doctor -v`, key package versions from `pubspec.lock`, whether generated code (`*.g.dart`/`*.gr.dart`/`*.freezed.dart`) has pending regeneration, and which of go_router/auto_route/fpdart the project uses.

### Step 2: Pull the Failure

From recent session context (read recent tool results, do not re-run failing commands unless they're cheap):
- The exact failing command (test, request, rake task)
- Verbatim stack trace, top-to-bottom — do not summarize
- Expected vs actual behavior in one sentence each

### Step 3: Reconstruct What-Was-Tried

Walk recent session history (your own tool calls and edits in this conversation). Produce 3–7 entries, each:

```
- Hypothesis: <one line>
  Action:     <what you changed or ran>
  Outcome:    <what happened, including partial successes>
```

Include partial successes — "this fixed *one* of the failing tests but the other still fails" is high-signal for the oracle. Don't pad: if there were only 2 attempts, write 2.

### Step 4: Pick Attached Files

Start from the failing file and walk **one hop**:
- The failing file itself
- Classes it references (look at imports, constructor dependencies, use case/repository collaborators)
- The matching test file
- Any DI registration in `lib/core/di/` or the feature's `*_injection.dart` that wires this area
- The domain entity/model and its `fromJson`/`toJson` (or generated `*.g.dart`) if this is a data-mapping or serialization bug
- Relevant route definitions in `lib/core/router/` if this is a navigation bug

**Hard cap:** ≤8 files, ≤2000 total lines. If you'd exceed it, prefer fewer files with surrounding context over many files with no context.

### Step 5: Redact Secrets

**This step must run before Step 6, not after.** Redacting an already-written file is leak recovery, not prevention — once secrets are on disk, they may be in editor swap files, OS-level backups (Time Machine, Dropbox, iCloud, `tmp` autosync), shell history, or the user's clipboard before you get a chance to scrub them. Redaction operates on the in-memory prompt body and file contents *before* the Write tool persists anything.

Scan the prompt body and every attached file for:

- Files: `.env*`, `android/key.properties`, `**/google-services.json`, `**/GoogleService-Info.plist`, `*.jks`, `*.keystore`, `*.pem`, `*.p12` → **never include, even if asked**
- Patterns: `(?i)(api[_-]?key|secret|token|password|bearer|authorization)\s*[:=]\s*['"][^'"]+['"]`
- Patterns: connection strings with embedded credentials (`postgres://user:pass@...`)
- Patterns: long base64 / hex strings near words like "key", "token", "secret"

Replace with `[REDACTED:<reason>]` and keep enough surrounding context for the oracle to understand the structure. Note redactions in the safety footer.

### Step 6: Write the File

Use the structure in `template.md`. Section order matters — role and desired output go first because oracles weight the opening of long prompts most heavily.

### Step 7: Report

Print the file path, line count, and suggested invocation. Do not call any model. Do not open the file in an editor.

## Flutter/Dart-Specific Suspect List

Always include this section in the oracle prompt — these are the implicit-context items that bite Flutter projects and that an oracle cannot infer:

- **Generated code drift:** Are `*.g.dart`/`*.gr.dart`/`*.freezed.dart` committed and in sync with their source? Does `dart run build_runner build` produce a diff?
- **Null safety:** Any `late` field the failing path reads before it's assigned? A `!` bang operator hiding a null?
- **Async/Future gotchas:** Is a `Future` started in a constructor or `initState` without being awaited? Does the Bloc/Cubit check `isClosed` before `emit` after an `await`?
- **State-management path:** Which Bloc/Cubit owns this state? Does its `copyWith` silently fall back to the old value because a field is missing from the parameter list?
- **Platform channel:** Does the failing code call into a plugin with platform-specific behavior (iOS/Android divergence, missing permission entry, plugin version mismatch)?
- **Package version drift:** `git log -p pubspec.lock` for recently bumped packages on the failing path
- **DI wiring:** Is the failing type registered in `lib/core/di/injection.dart` or a feature's `*_injection.dart`? Singleton vs factory mismatch?
- **Build mode:** Debug-only assertion firing, or a bug that only appears in profile/release (tree-shaking, `kReleaseMode`/`kDebugMode` branches)?
- **Router/navigation:** If go_router/auto_route related — redirect loop, guard not resolving, route missing from the generated router table
- **Widget lifecycle:** `BuildContext` used across an `await` without a `mounted` check, a controller/subscription still listened to after `dispose()`

Include only the items that *might* be relevant. Don't pad.

## Anti-patterns

- ❌ Dumping the whole repo "to be safe" — destroys signal
- ❌ Summarizing the stack trace — oracles need the verbatim text
- ❌ Including `.env` "with secrets redacted by hand" — use the redaction step, never trust manual redaction of entire files
- ❌ Writing in second person to the user ("you should check...") — write in the voice of someone briefing a peer
- ❌ Asking the oracle an open-ended question ("what's wrong?") — specify the desired output format
- ❌ Including narrative about the session ("we first tried X, then Joe suggested Y") — the oracle doesn't know Joe; structure as hypothesis/action/outcome

## Re-runnability

Oracles are one-shot — the model has no memory of prior runs. Write the prompt so that re-running it later (with the same `--file` argument) reproduces the same context. That means:

- Absolute file paths, not "the file we were just looking at"
- Git SHA at the top so the oracle knows the snapshot
- No references to "earlier in the session" or "as I mentioned"

## Quick Reference

| Step | Action |
|------|--------|
| 1 | Detect Flutter/Dart project shape |
| 2 | Pull verbatim failure (command, stack trace, expected vs actual) |
| 3 | Reconstruct hypothesis → action → outcome from session |
| 4 | Pick ≤8 files / ≤2000 lines, one hop from failing file |
| 5 | Redact secrets aggressively |
| 6 | Write `tmp/oracle/<date>-<slug>.md` using `template.md` |
| 7 | Print path + suggested invocation; do not call any model |

See `template.md` for the exact section layout.
