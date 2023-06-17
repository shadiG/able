import 'package:able/able.dart';
import 'package:able/src/progressable/progressable.dart';
import 'package:flutter/foundation.dart';

abstract class Fetchable<D> {
  Fetchable._();

  factory Fetchable.idle() {
    return IdleFetchable();
  }

  factory Fetchable.success(D data) {
    return SuccessFetchable<D>(data: data);
  }

  factory Fetchable.busy() {
    return BusyFetchable();
  }

  factory Fetchable.error(dynamic exception) {
    return ErrorFetchable(exception: exception);
  }

  Fetchable<D> toBusy() {
    return BusyFetchable();
  }

  Progressable asProgressable() {
    switch (state) {
      case AbleState.idle:
        return IdleProgressable();
      case AbleState.busy:
        return BusyProgressable();
      case AbleState.success:
        return SuccessProgressable();
      case AbleState.error:
        return ErrorProgressable(exception: (this as ErrorFetchable).exception);
      default:
        throw StateError('no case for ${describeEnum(this)}');
    }
  }

  Fetchable<ND> mapSuccess<ND>(Function(D data) mapper) {
    switch (state) {
      case AbleState.idle:
        return Fetchable.idle();
      case AbleState.busy:
        return Fetchable.busy();
      case AbleState.success:
        return SuccessFetchable<ND>(data: mapper((this as SuccessFetchable<ND>).data as D));
      case AbleState.error:
        return Fetchable.error((this as ErrorFetchable).exception);
      default:
        throw StateError('no case for ${describeEnum(state)}');
    }
  }

  Fetchable<ND> cast<ND>() {
    switch (state) {
      case AbleState.idle:
        return Fetchable.idle();
      case AbleState.busy:
        return Fetchable.busy();
      case AbleState.success:
        return SuccessFetchable<ND>(data: (this as SuccessFetchable<ND>).data);
      case AbleState.error:
        return Fetchable.error((this as ErrorFetchable).exception);
      default:
        throw StateError('no case for ${describeEnum(state)}');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Fetchable &&
          runtimeType == other.runtimeType &&
          this.state == other.state &&
          success == other.success &&
          ((this is SuccessFetchable && other is SuccessFetchable) && data == other.data) &&
          hasError == other.hasError &&
          error == other.error;

  @override
  String toString() {
    switch (state) {
      case AbleState.idle:
        return 'Fetchable(Idle)';
      case AbleState.busy:
        return 'Fetchable(Busy)';
      case AbleState.success:
        return 'Fetchable(Success) : ${(this as SuccessFetchable<D>).data}';
      case AbleState.error:
        return 'Fetchable(Error) : ${(this as ErrorFetchable<D>).exception}';
      default:
        throw StateError('no case for ${describeEnum(this)}');
    }
  }

  AbleState get state => () {
        if (this is IdleFetchable<D>) {
          return AbleState.idle;
        } else if (this is BusyFetchable<D>) {
          return AbleState.busy;
        } else if (this is SuccessFetchable<D>) {
          return AbleState.success;
        } else if (this is ErrorFetchable<D>) {
          return AbleState.error;
        }

        throw StateError('no case for ${describeEnum(runtimeType)}');
      }();
}

Fetchable<D> toFetchable<D>({D? data, dynamic exception, required AbleState state}) {
  switch (state) {
    case AbleState.idle:
      return IdleFetchable<D>();
    case AbleState.busy:
      return BusyFetchable<D>();
    case AbleState.success:
      if (data == null) {
        throw StateError('Fetchable(Success): must specify the data');
      }
      return SuccessFetchable<D>(data: data);
    case AbleState.error:
      if (exception == null) {
        throw StateError('Fetchable(Error): must specify the error');
      }
      return ErrorFetchable<D>(exception: exception);
    default:
      throw StateError('no case for ${describeEnum(state)}');
  }
}

class IdleFetchable<D> extends Fetchable<D> {
  IdleFetchable() : super._();
}

class SuccessFetchable<D> extends Fetchable<D> {
  final D data;

  SuccessFetchable({required this.data}) : super._();
}

class BusyFetchable<D> extends Fetchable<D> {
  BusyFetchable() : super._();
}

class ErrorFetchable<D> extends Fetchable<D> {
  final dynamic exception;

  ErrorFetchable({required this.exception}) : super._();
}
