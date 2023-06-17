import 'package:able/able.dart';
import 'package:flutter/foundation.dart';

abstract class Progressable {
  Progressable._();

  factory Progressable.idle() {
    return IdleProgressable();
  }

  factory Progressable.success() {
    return SuccessProgressable();
  }

  factory Progressable.busy() {
    return BusyProgressable();
  }

  factory Progressable.error(dynamic exception) {
    return ErrorProgressable(exception: exception);
  }

  Progressable toBusy() {
    return BusyProgressable();
  }

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
      default:
        throw StateError('no case for ${describeEnum(this)}');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Progressable && runtimeType == other.runtimeType && state == other.state && error == other.error;

  @override
  String toString() {
    switch (state) {
      case AbleState.idle:
        return 'Progressable(Idle)';
      case AbleState.busy:
        return 'Progressable(Busy)';
      case AbleState.success:
        return 'Progressable(Success)';
      case AbleState.error:
        return 'Progressable(Error) : ${(this as ErrorProgressable).exception}';
      default:
        throw StateError('no case for ${describeEnum(state)}');
    }
  }

  AbleState get state => () {
        if (this is IdleProgressable) {
          return AbleState.idle;
        } else if (this is BusyProgressable) {
          return AbleState.busy;
        } else if (this is SuccessProgressable) {
          return AbleState.success;
        } else if (this is ErrorProgressable) {
          return AbleState.error;
        }

        throw StateError('no case for ${describeEnum(this)}');
      }();
}

Progressable toProgressable({dynamic exception, required AbleState state}) {
  switch (state) {
    case AbleState.idle:
      return IdleProgressable();
    case AbleState.busy:
      return BusyProgressable();
    case AbleState.success:
      return SuccessProgressable();
    case AbleState.error:
      if (exception == null) {
        throw StateError('Progressable(Error): must specify the error');
      }
      return ErrorProgressable(exception: exception);
    default:
      throw StateError('no case for ${describeEnum(state)}');
  }
}

class IdleProgressable<D> extends Progressable {
  IdleProgressable() : super._();
}

class SuccessProgressable<D> extends Progressable {
  SuccessProgressable() : super._();
}

class BusyProgressable<D> extends Progressable {
  BusyProgressable() : super._();
}

class ErrorProgressable<D> extends Progressable {
  final dynamic exception;

  ErrorProgressable({required this.exception}) : super._();
}
