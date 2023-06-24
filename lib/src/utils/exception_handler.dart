import 'package:able/src/common/able_type.dart';

typedef HandleException = void Function(dynamic exception, StackTrace stackTrace, AbleType type);
typedef OnError = void Function(dynamic e, String? message);

class ExceptionHandler {
  OnError? onError;

  static final ExceptionHandler _handler = ExceptionHandler._internal();

  factory ExceptionHandler({OnError? onError}) {
    _handler.onError = onError;
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
