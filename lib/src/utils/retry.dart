import 'dart:async';
import 'dart:math' as math;

/// Runs [task], retrying on failure with exponential backoff.
///
/// Tries at most [maxAttempts] times. The waits are [initialDelay], then
/// multiplied by [backoffFactor] each time, capped at [maxDelay]. [retryIf]
/// decides which errors are worth retrying (default: all); the last error is
/// rethrown when attempts run out or [retryIf] says no.
///
/// Composes with the rest of Able:
/// `futureAsFetchable(() => withRetry(() => repository.fetchAll()))`.
Future<T> withRetry<T>(
  Future<T> Function() task, {
  int maxAttempts = 3,
  Duration initialDelay = const Duration(milliseconds: 500),
  double backoffFactor = 2,
  Duration maxDelay = const Duration(seconds: 30),
  bool Function(Object error)? retryIf,
}) async {
  assert(maxAttempts >= 1, 'maxAttempts must be at least 1');
  var delay = initialDelay;
  for (var attempt = 1;; attempt++) {
    try {
      return await task();
    } catch (e) {
      final canRetry = attempt < maxAttempts && (retryIf?.call(e) ?? true);
      if (!canRetry) rethrow;
      await Future<void>.delayed(delay);
      delay = Duration(
        microseconds: math.min(delay.inMicroseconds * backoffFactor, maxDelay.inMicroseconds.toDouble()).round(),
      );
    }
  }
}
