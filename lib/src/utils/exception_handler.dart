import 'package:able/src/common/able_type.dart';

typedef HandleException = void Function(dynamic exception, StackTrace stackTrace, AbleType type);
typedef OnError = void Function(dynamic e, String? message);

class ExceptionHandler {
  OnError? onError;

  static final ExceptionHandler _handler = ExceptionHandler._internal();

  /// Returns the singleton. [onError] replaces the stored callback only when
  /// given, so obtaining the handler elsewhere never clears it.
  factory ExceptionHandler({OnError? onError}) {
    if (onError != null) {
      _handler.onError = onError;
    }
    return _handler;
  }

  ExceptionHandler._internal();

  void handleException(dynamic exception, StackTrace stackTrace, AbleType type) {
    for (final handler in _exceptionHandlers) {
      handler(exception, stackTrace, type);
    }
  }

  final _exceptionHandlers = <HandleException>[];

  /// Adds [handler]. Returns a function that removes it again.
  void Function() subscribe(HandleException handler) {
    _exceptionHandlers.add(handler);
    return () => unsubscribe(handler);
  }

  /// Removes [handler]; does nothing if it isn't subscribed.
  void unsubscribe(HandleException handler) {
    _exceptionHandlers.remove(handler);
  }

  /// Removes every handler and the [onError] callback. Called by
  /// `Able.resetForTest`; not meant for app code.
  void reset() {
    _exceptionHandlers.clear();
    onError = null;
  }
}
