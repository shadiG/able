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

  void subscribe(HandleException handler) {
    _exceptionHandlers.add(handler);
  }
}
