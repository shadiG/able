import 'package:able/src/common/able_type.dart';

typedef HandleException = void Function(dynamic exception, StackTrace stackTrace, AbleType type);
typedef ShowError = void Function(dynamic e, String? message);

class ExceptionHandler {
  ShowError? showError;

  static final ExceptionHandler _handler = ExceptionHandler._internal();

  factory ExceptionHandler({ShowError? showError}) {
    _handler.showError = showError;
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
