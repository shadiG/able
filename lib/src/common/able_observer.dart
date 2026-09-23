import 'package:able/able.dart';

/// Watches every `AbleCubit` in the app, for logging, analytics or debugging.
///
/// Set one with `Able.initialize(observer: ...)` or `Able.observer = ...`.
/// Override only the hooks you need.
///
/// ```dart
/// class LogObserver extends AbleObserver {
///   @override
///   void onRebuild(AbleCubit cubit, Object? previous, Object? next) =>
///       debugPrint('${cubit.runtimeType}: $next');
/// }
/// ```
abstract class AbleObserver {
  const AbleObserver();

  /// A cubit's state changed through `rebuild`. Not called when the new state
  /// equals the previous one.
  void onRebuild(AbleCubit cubit, Object? previous, Object? next) {}

  /// An `execute*` call on [cubit] failed. [expected] is true when the call's
  /// `isExpectedError` matched, in which case the global `handleException`
  /// is not called.
  void onError(AbleCubit cubit, Object? error, StackTrace stackTrace, AbleType type, {required bool expected}) {}
}
