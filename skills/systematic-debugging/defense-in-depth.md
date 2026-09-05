# Defense-in-Depth Validation

## Overview

When you fix a bug caused by invalid data, adding validation at one place feels sufficient. But that single check can be bypassed by different code paths, refactoring, or mocks.

**Core principle:** Validate at EVERY layer data passes through. Make the bug structurally impossible.

## Why Multiple Layers

Single validation: "We fixed the bug"
Multiple layers: "We made the bug impossible"

Different layers catch different cases:
- Entry validation catches most bugs
- Business logic catches edge cases
- Environment guards prevent context-specific dangers
- Debug logging helps when other layers fail

## The Four Layers

### Layer 1: Entry Point Validation
**Purpose:** Reject obviously invalid input at API boundary

```dart
void createProject(String name, String workingDirectory) {
  if (workingDirectory.trim().isEmpty) {
    throw ArgumentError('workingDirectory cannot be empty');
  }
  if (!Directory(workingDirectory).existsSync()) {
    throw ArgumentError('workingDirectory does not exist: $workingDirectory');
  }
  if (FileSystemEntity.typeSync(workingDirectory) !=
      FileSystemEntityType.directory) {
    throw ArgumentError('workingDirectory is not a directory: $workingDirectory');
  }
  // ... proceed
}
```

### Layer 2: Business Logic Validation
**Purpose:** Ensure data makes sense for this operation

```dart
void initializeWorkspace(String projectDir, String sessionId) {
  if (projectDir.trim().isEmpty) {
    throw ArgumentError('projectDir required for workspace initialization');
  }
  // ... proceed
}
```

### Layer 3: Environment Guards
**Purpose:** Prevent dangerous operations in specific contexts

```dart
Future<void> gitInit(String directory) async {
  // In tests, refuse git init outside the system temp directory.
  // `flutter test` sets FLUTTER_TEST=true for every test run.
  if (Platform.environment['FLUTTER_TEST'] == 'true') {
    final tmp = Directory.systemTemp.path;
    final resolved = Directory(directory).absolute.path;
    if (!resolved.startsWith(tmp)) {
      throw StateError('Refusing git init outside system temp during tests: $directory');
    }
  }
  // ... proceed
}
```

### Layer 4: Debug Instrumentation
**Purpose:** Capture context for forensics

```dart
Future<void> gitInit(String directory) async {
  debugPrint(
    'About to git init: directory=$directory cwd=${Directory.current.path} '
    'caller=${StackTrace.current}',
  );
  // ... proceed
}
```

## Applying the Pattern

When you find a bug:

1. **Trace the data flow** - Where does bad value originate? Where used?
2. **Map all checkpoints** - List every point data passes through
3. **Add validation at each layer** - Entry, business, environment, debug
4. **Test each layer** - Try to bypass layer 1, verify layer 2 catches it

## Example from Session

Bug: Empty `projectDir` caused `git init` in source code

**Data flow:**
1. Test setup → empty string
2. `Project.create(name, '')`
3. `WorkspaceManager.createWorkspace('')`
4. `git init` runs in `process.cwd()`

**Four layers added:**
- Layer 1: `Project.create()` validates not empty/exists/writable
- Layer 2: `WorkspaceManager` validates projectDir not empty
- Layer 3: `WorktreeManager` refuses git init outside tmpdir in tests
- Layer 4: Stack trace logging before git init

**Result:** All 1847 tests passed, bug impossible to reproduce

## Key Insight

All four layers were necessary. During testing, each layer caught bugs the others missed:
- Different code paths bypassed entry validation
- Mocks bypassed business logic checks
- Edge cases on different platforms needed environment guards
- Debug logging identified structural misuse

**Don't stop at one validation point.** Add checks at every layer.
