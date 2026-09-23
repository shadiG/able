import 'package:able/able.dart';
import 'package:able/src/progressable/progressable.dart';

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
    }
  }

  Fetchable<ND> mapSuccess<ND>(ND Function(D data) mapper) {
    switch (state) {
      case AbleState.idle:
        return Fetchable.idle();
      case AbleState.busy:
        return Fetchable.busy();
      case AbleState.success:
        return SuccessFetchable<ND>(data: mapper((this as SuccessFetchable<D>).data));
      case AbleState.error:
        return Fetchable.error((this as ErrorFetchable).exception);
    }
  }

  Fetchable<ND> cast<ND>() {
    switch (state) {
      case AbleState.idle:
        return Fetchable.idle();
      case AbleState.busy:
        return Fetchable.busy();
      case AbleState.success:
        return SuccessFetchable<ND>(data: (this as SuccessFetchable<D>).data as ND);
      case AbleState.error:
        return Fetchable.error((this as ErrorFetchable).exception);
    }
  }

  /// Equal when the state and payload are equal. The type argument is
  /// ignored, so `Fetchable<int?>.success(null) == Fetchable<Null>.success(null)`.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Fetchable || other.state != state) return false;

    switch (state) {
      case AbleState.success:
        return (this as SuccessFetchable).data == (other as SuccessFetchable).data;
      case AbleState.error:
        return (this as ErrorFetchable).exception == (other as ErrorFetchable).exception;
      case AbleState.idle:
      case AbleState.busy:
        return true;
    }
  }

  @override
  int get hashCode {
    switch (state) {
      case AbleState.idle:
      case AbleState.busy:
        return state.hashCode;
      case AbleState.success:
        return Object.hash(state, (this as SuccessFetchable).data);
      case AbleState.error:
        return Object.hash(state, (this as ErrorFetchable).exception);
    }
  }

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
    }
  }

  AbleState get state {
    if (this is IdleFetchable<D>) {
      return AbleState.idle;
    } else if (this is BusyFetchable<D>) {
      return AbleState.busy;
    } else if (this is SuccessFetchable<D>) {
      return AbleState.success;
    } else if (this is ErrorFetchable<D>) {
      return AbleState.error;
    }
    throw StateError('Unknown Fetchable state for $runtimeType');
  }
}

Fetchable<D> toFetchable<D>({required AbleState state, D? data, dynamic exception}) {
  switch (state) {
    case AbleState.idle:
      return IdleFetchable<D>();
    case AbleState.busy:
      return BusyFetchable<D>();
    case AbleState.success:
      return SuccessFetchable<D>(data: data as D);
    case AbleState.error:
      // The exception may legitimately be null (`Fetchable.error(null)`).
      return ErrorFetchable<D>(exception: exception);
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
