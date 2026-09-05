---
name: using-superpowers
description: Use when starting any conversation - establishes how to find and use skills, requiring skill invocation before ANY response including clarifying questions
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, ignore this skill.
</SUBAGENT-STOP>

<EXTREMELY-IMPORTANT>
If you think there is even a 1% chance a skill might apply to what you are doing, you ABSOLUTELY MUST invoke the skill.

IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.

This is not negotiable. You cannot rationalize your way out of this.
</EXTREMELY-IMPORTANT>

## The Rule

**Invoke relevant or requested skills BEFORE any response or action** — including clarifying questions, exploring the codebase, or checking files. If it turns out wrong for the situation, you don't have to use it.

**Before entering plan mode:** if you haven't already brainstormed, invoke the brainstorming skill first.

Then announce "Using [skill] to [purpose]" and follow the skill exactly. If it has a checklist, create a todo per item.

## Skill Priority

When multiple skills apply, process skills come first — they set the approach, then implementation skills (frontend-design, etc.) carry it out. Brainstorming and systematic-debugging are Superpowers' most common process skills, but the rule holds for any of them.

- "Let's build X" → superpowers-flutter:brainstorming first, then implementation skills.
- "Fix this bug" → superpowers-flutter:systematic-debugging first, then domain skills.

## Red Flags

These thoughts mean STOP—you're rationalizing:

| Thought | Reality |
|---------|---------|
| "This is just a simple question" | Questions are tasks. Check for skills. |
| "I need more context first" | Skill check comes BEFORE clarifying questions. |
| "Let me explore the codebase first" | Skills tell you HOW to explore. Check first. |
| "I can check git/files quickly" | Files lack conversation context. Check for skills. |
| "Let me gather information first" | Skills tell you HOW to gather information. |
| "This doesn't need a formal skill" | If a skill exists, use it. |
| "I remember this skill" | Skills evolve. Read current version. |
| "This doesn't count as a task" | Action = task. Check for skills. |
| "The skill is overkill" | Simple things become complex. Use it. |
| "I'll just do this one thing first" | Check BEFORE doing anything. |
| "This feels productive" | Undisciplined action wastes time. Skills prevent this. |
| "I know what that means" | Knowing the concept ≠ using the skill. Invoke it. |

## Platform Adaptation

If your harness appears here, read its reference file for special instructions:

- Codex: `references/codex-tools.md`
- Pi: `references/pi-tools.md`
- Antigravity: `references/antigravity-tools.md`
- Hermes Agent: `references/hermes-tools.md`

## User Instructions

User instructions (CLAUDE.md, AGENTS.md, GEMINI.md, etc, direct requests) take precedence over skills, which in turn override default behavior. Only skip skill workflows or instructions when your human partner has explicitly told you to.

## Skills Catalog

All available skills — invoke with the `Skill` tool using the `name` value.

### Process & Workflow

| Name | When to Use |
|------|-------------|
| `superpowers-flutter:brainstorming` | When starting any creative work — new features, components, or behavior changes (**REQUIRED**) |
| `superpowers-flutter:test-driven-development` | When implementing any feature or bugfix — before writing implementation code (**REQUIRED**) |
| `superpowers-flutter:systematic-debugging` | When diagnosing a bug or unexpected behavior |
| `superpowers-flutter:writing-plans` | When planning a multi-step implementation |
| `superpowers-flutter:executing-plans` | When executing an existing plan |
| `superpowers-flutter:dispatching-parallel-agents` | When parallelizing independent work across subagents |
| `superpowers-flutter:subagent-driven-development` | When using subagents to implement and review code |
| `superpowers-flutter:verification-before-completion` | When finishing a task — before marking it done |
| `superpowers-flutter:finishing-a-development-branch` | When wrapping up a feature branch for PR |
| `superpowers-flutter:using-git-worktrees` | When needing isolated git worktrees for parallel work |
| `superpowers-flutter:compound` | When a non-trivial problem has just been solved — capture the solution |
| `superpowers-flutter:consulting-an-oracle` | When stuck after multiple debug attempts and escalating to a stronger one-shot model |

### Session Continuity

| Name | When to Use |
|------|-------------|
| `superpowers-flutter:handoff` | When capturing session state before switching context, ending a session, or manually preserving progress |
| `superpowers-flutter:handoff-resume` | When starting a new session and wanting to continue from a previous handoff |
| `superpowers-flutter:handoff-list` | When viewing available handoff documents |

### Flutter & Dart

| Name | When to Use |
|------|-------------|
| `superpowers-flutter:dart` | When writing, reviewing, or debugging any Dart code — Effective Dart, Dart 3 features (records, patterns, sealed classes), error handling, async idioms |
| `superpowers-flutter:flutter-clean-architecture` | When creating or restructuring a feature, adding a repository, use case, data source, or wiring dependency injection (**REQUIRED** for new features) |
| `superpowers-flutter:bloc` | When adding or changing state management — any Bloc, Cubit, event, or state class |
| `superpowers-flutter:riverpod` | When adding or changing state management and `flutter_riverpod`, `hooks_riverpod`, or `riverpod_annotation` is in pubspec.yaml |
| `superpowers-flutter:flutter-widget-rules` | When writing or reviewing any widget — build size, extraction, const, keys, BuildContext safety |
| `superpowers-flutter:flutter-analyze` | Before committing or requesting review, when analyzer warnings appear, when setting up lints |
| `superpowers-flutter:go-router` | When working on navigation and `go_router` is in pubspec.yaml |
| `superpowers-flutter:auto-route` | When working on navigation and `auto_route` is in pubspec.yaml |
| `superpowers-flutter:fpdart` | When writing domain or data code and `fpdart` is in pubspec.yaml |
| `superpowers-flutter:flutter-docs` | When any Flutter or Dart framework/API question comes up — topic map to official docs |
| `superpowers-flutter:flutter-upgrade` | When bumping the Flutter/Dart SDK or a major package version |
| `superpowers-flutter:dart-commit-message` | When committing changes in a Flutter or Dart project |

### Code Review & Quality

| Name | When to Use |
|------|-------------|
| `superpowers-flutter:requesting-code-review` | When submitting code for review |
| `superpowers-flutter:receiving-code-review` | When processing incoming code review feedback |

### Meta

| Name | When to Use |
|------|-------------|
| `superpowers-flutter:writing-skills` | When authoring a new skill or improving an existing one |
| `superpowers-flutter:compound` | When capturing a non-trivial solution for compound knowledge |
| `superpowers-flutter:compound-refresh` | When docs/solutions/ learnings may be stale — after refactors, migrations, or dependency upgrades |
