import 'package:able/able.dart';
import 'package:flutter/widgets.dart';

/// A builder function for creating a widget to display an error.
/// This is used to avoid name collision with Flutter's [ErrorWidget].
typedef AbleErrorWidgetBuilder = Widget Function(BuildContext context, dynamic error);

/// Global configuration for the Able package.
///
/// This class is a singleton, configured via [Able.initialize] and accessed
/// statically via [Able.configs].
class AbleConfigs {
  /// The global widget to display during loading states. Can be null.
  final Widget? loadingWidget;

  /// The global builder function to create a widget for error states. Can be null.
  final AbleErrorWidgetBuilder? errorWidget;

  /// Private constructor to ensure this class is only instantiated internally.
  AbleConfigs._({
    this.loadingWidget,
    this.errorWidget,
  });
}

/// Main entry point and configuration holder for the Able package.
class Able {
  static AbleConfigs? _configs;

  /// Access the global configurations for the Able package.
  ///
  /// Throws an assertion error if [Able.initialize] has not been called.
  /// It is recommended to call [Able.initialize] in your `main()` function
  /// before `runApp()`.
  static AbleConfigs get configs {
    assert(_configs != null, 'Able has not been initialized. Please call Able.initialize() in your main() function before using this.');
    return _configs!;
  }

  /// Initializes the Able package with global configurations.
  ///
  /// This should be called once, typically in your app's `main()` function,
  /// before `runApp()` is called.
  static void initialize({
    Widget? loadingWidget,
    AbleErrorWidgetBuilder? errorWidget,
    HandleException? handleException,
    OnError? onError,
  }) {
    if (_configs != null) {
      debugPrint('Warning: Able.initialize() was called more than once. The original configuration will be kept.');
      return;
    }

    _configs = AbleConfigs._(
      loadingWidget: loadingWidget,
      errorWidget: errorWidget,
    );

    // Configure the exception handler as per the original logic.
    ExceptionHandler(onError: onError);
    if (handleException != null) {
      ExceptionHandler().subscribe(handleException);
    }
  }
}
