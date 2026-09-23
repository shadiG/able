import 'package:able/able.dart';

abstract class Progressable {
  Progressable._();

  factory Progressable.idle() {
    return IdleProgressable();
  }

  factory Progressable.success() {
    return SuccessProgressable();
  }

  /// Busy. [progress], from 0 to 1, is optional: set it when the work can
  /// report how far along it is (an upload), leave it null otherwise.
  factory Progressable.busy({double? progress}) {
    return BusyProgressable(progress: progress);
  }

  factory Progressable.error(dynamic exception) {
    return ErrorProgressable(exception: exception);
  }

  Progressable toBusy() {
    return BusyProgressable();
  }

  /// How far along a busy action is, from 0 to 1; null when unknown or not busy.
  double? get progress => null;

  /// Calls the callback matching the current state. Every state must be
  /// handled. `busy` receives [progress].
  R when<R>({
    required R Function() idle,
    required R Function(double? progress) busy,
    required R Function() success,
    required R Function(dynamic error) error,
  }) =>
      switch (this) {
        IdleProgressable() => idle(),
        BusyProgressable(:final progress) => busy(progress),
        SuccessProgressable() => success(),
        ErrorProgressable(:final exception) => error(exception),
        _ => throw StateError('no case for $this'),
      };

  /// Like [when], with [orElse] for the states you don't pass.
  R maybeWhen<R>({
    required R Function() orElse,
    R Function()? idle,
    R Function(double? progress)? busy,
    R Function()? success,
    R Function(dynamic error)? error,
  }) =>
      when(
        idle: idle ?? orElse,
        busy: busy ?? (_) => orElse(),
        success: success ?? orElse,
        error: error ?? (_) => orElse(),
      );

  Fetchable<D> asFetchable<D>(D data) {
    switch (state) {
      case AbleState.idle:
        return Fetchable.idle();
      case AbleState.busy:
        return Fetchable.busy();
      case AbleState.success:
        return Fetchable<D>.success(data);
      case AbleState.error:
        return Fetchable.error((this as ErrorProgressable).exception);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Progressable &&
          runtimeType == other.runtimeType &&
          state == other.state &&
          error == other.error &&
          progress == other.progress;

  @override
  int get hashCode => Object.hash(runtimeType, state, error, progress);

  @override
  String toString() {
    switch (state) {
      case AbleState.idle:
        return 'Progressable(Idle)';
      case AbleState.busy:
        return progress == null ? 'Progressable(Busy)' : 'Progressable(Busy ${(progress! * 100).round()}%)';
      case AbleState.success:
        return 'Progressable(Success)';
      case AbleState.error:
        return 'Progressable(Error) : ${(this as ErrorProgressable).exception}';
    }
  }

  AbleState get state {
    return () {
      if (this is IdleProgressable) {
        return AbleState.idle;
      } else if (this is BusyProgressable) {
        return AbleState.busy;
      } else if (this is SuccessProgressable) {
        return AbleState.success;
      } else if (this is ErrorProgressable) {
        return AbleState.error;
      }

      throw StateError('no case for $this');
    }();
  }

  dynamic get error {
    if (this is ErrorProgressable) {
      return (this as ErrorProgressable).exception;
    }
    return null;
  }
}

Progressable toProgressable({required AbleState state, dynamic exception}) {
  switch (state) {
    case AbleState.idle:
      return IdleProgressable();
    case AbleState.busy:
      return BusyProgressable();
    case AbleState.success:
      return SuccessProgressable();
    case AbleState.error:
      // The exception may legitimately be null (`Progressable.error(null)`).
      return ErrorProgressable(exception: exception);
  }
}

class IdleProgressable extends Progressable {
  IdleProgressable() : super._();
}

class SuccessProgressable extends Progressable {
  SuccessProgressable() : super._();
}

class BusyProgressable extends Progressable {
  @override
  final double? progress;

  BusyProgressable({this.progress}) : super._();
}

class ErrorProgressable extends Progressable {
  final dynamic exception;

  ErrorProgressable({required this.exception}) : super._();
}
