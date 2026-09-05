// Complete implementation of condition-based waiting utilities.
// Adapted from: test infrastructure improvements (2025-10-03).
// Context: Fixed 15 flaky tests by replacing arbitrary delays.

import 'dart:async';

/// A single recorded event, e.g. emitted by a fake repository, a mocktail
/// spy, or a bloc's recorded state transitions.
class DebugEvent {
  const DebugEvent(this.type, [this.data]);

  final String type;
  final Object? data;
}

/// Anything that exposes a growing log of [DebugEvent]s to poll against.
abstract class EventSource {
  List<DebugEvent> get events;
}

/// Waits for [condition] to return a non-null value, polling every
/// [interval] until [timeout] elapses.
///
/// Returns the truthy value produced by [condition].
/// Throws a [TimeoutException] labelled with [description] if the
/// deadline passes first.
Future<T> waitFor<T>(
  FutureOr<T?> Function() condition, {
  String description = 'condition',
  Duration timeout = const Duration(seconds: 5),
  Duration interval = const Duration(milliseconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (true) {
    final result = await condition();
    if (result != null) return result;
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException(
        'Timeout after ${timeout.inSeconds}s waiting for: $description',
      );
    }
    await Future<void>.delayed(interval);
  }
}

DebugEvent? _firstEventOfType(List<DebugEvent> events, String eventType) {
  for (final event in events) {
    if (event.type == eventType) return event;
  }
  return null;
}

/// Waits for a specific event type to appear in [source].
Future<DebugEvent> waitForEvent(
  EventSource source,
  String eventType, {
  Duration timeout = const Duration(seconds: 5),
}) {
  return waitFor(
    () => _firstEventOfType(source.events, eventType),
    description: 'event $eventType',
    timeout: timeout,
  );
}

/// Waits until at least [count] events of [eventType] have been emitted.
///
/// Returns all matching events once the count is reached.
Future<List<DebugEvent>> waitForEventCount(
  EventSource source,
  String eventType, {
  required int count,
  Duration timeout = const Duration(seconds: 5),
}) {
  return waitFor(
    () {
      final matches =
          source.events.where((e) => e.type == eventType).toList();
      return matches.length >= count ? matches : null;
    },
    description: '${count}x event $eventType',
    timeout: timeout,
  );
}

/// Waits for an event matching both [eventType] and [predicate].
Future<DebugEvent> waitForEventMatch(
  EventSource source,
  String eventType,
  bool Function(DebugEvent event) predicate, {
  Duration timeout = const Duration(seconds: 5),
}) {
  return waitFor(
    () {
      for (final event in source.events) {
        if (event.type == eventType && predicate(event)) return event;
      }
      return null;
    },
    description: 'event $eventType matching predicate',
    timeout: timeout,
  );
}
