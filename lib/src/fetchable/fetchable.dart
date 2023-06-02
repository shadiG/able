import 'package:able/src/common/able_state.dart';
import 'package:able/src/progressable/progressable.dart';
import 'package:flutter/foundation.dart';

abstract class Fetchable<D> {
  Fetchable._();

  factory Fetchable.idle() {
    return IdleFetchable<D>();
  }

  factory Fetchable.success(D data) {
    return SuccessFetchable<D>(data: data);
  }

  factory Fetchable.busy() {
    return BusyFetchable<D>();
  }

  factory Fetchable.error(Exception exception) {
    return ErrorFetchable<D>(exception: exception);
  }

  Fetchable<D> toBusy() {
    return BusyFetchable<D>();
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
        return IdleFetchable<ND>();
      case AbleState.busy:
        return BusyFetchable<ND>();
      case AbleState.success:
        return SuccessFetchable<ND>(data: mapper((this as SuccessFetchable<ND>).data as D));
      case AbleState.error:
        return ErrorFetchable<ND>(exception: (this as ErrorFetchable).exception);
      default:
        throw StateError('no case for ${describeEnum(state)}');
    }
  }

  Fetchable<ND> cast<ND>() {
    switch (state) {
      case AbleState.idle:
        return IdleFetchable<ND>();
      case AbleState.busy:
        return BusyFetchable<ND>();
      case AbleState.success:
        return SuccessFetchable<ND>(data: (this as SuccessFetchable<ND>).data);
      case AbleState.error:
        return ErrorFetchable<ND>(exception: (this as ErrorFetchable).exception);
      default:
        throw StateError('no case for ${describeEnum(state)}');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Fetchable && runtimeType == other.runtimeType;

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

  @override
  int get hashCode => super.hashCode;

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

Fetchable<D> toFetchable<D>({D? data, Exception? exception, required AbleState state}) {
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
  final Exception exception;

  ErrorFetchable({required this.exception}) : super._();
}
