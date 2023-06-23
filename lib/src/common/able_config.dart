import 'package:able/able.dart';
import 'package:flutter/widgets.dart';

typedef ErrorWidget = Widget Function(BuildContext context, dynamic error);

class AbleConfigs {
  Widget? loadingWidget;
  ErrorWidget? errorWidget;

  static final AbleConfigs _configs = AbleConfigs._internal();

  factory AbleConfigs({Widget? loadingWidget, ErrorWidget? errorWidget}) {
    _configs.loadingWidget = loadingWidget;
    _configs.errorWidget = errorWidget;
    return _configs;
  }

  AbleConfigs._internal();
}

initializeAble(
    {Widget? loadingWidget, ErrorWidget? errorWidget, HandleException? handleException, ShowError? showError}) {
  AbleConfigs(loadingWidget: loadingWidget, errorWidget: errorWidget);
  ExceptionHandler(showError: showError);
  if (handleException != null) {
    ExceptionHandler().subscribe(handleException);
  }
}
