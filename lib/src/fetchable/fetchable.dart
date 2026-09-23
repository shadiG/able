// The kept-data holder is private on purpose; these classes are hidden from the export.
// ignore_for_file: library_private_types_in_public_api

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

  /// Busy, but keeping this value's data (or the data it already kept) so a
  /// screen can keep showing it while reloading. See [latestData].
  Fetchable<D> toRefreshing() => BusyFetchable<D>().keepingDataOf(this);

  /// This value, carrying [previous]'s latest data when this one is busy or
  /// an error and [previous] has data. Success and idle are returned as is.
  ///
  /// Typical use in a `then:` callback, so a reload keeps the old list on
  /// screen: `b..itemsF = itemsF.keepingDataOf(state.itemsF)`.
  Fetchable<D> keepingDataOf(Fetchable<D> previous) {
    if (!previous.hasLatestData) return this;
    switch (state) {
      case AbleState.busy:
        return BusyFetchable<D>(latest: _Latest(previous.latestData));
      case AbleState.error:
        return ErrorFetchable<D>(exception: (this as ErrorFetchable).exception, latest: _Latest(previous.latestData));
      case AbleState.idle:
      case AbleState.success:
        return this;
    }
  }

  /// Whether [latestData] is available: this is a success, or a busy/error
  /// value that kept earlier data through [keepingDataOf] or [toRefreshing].
  bool get hasLatestData => switch (this) {
        SuccessFetchable() => true,
        BusyFetchable(:final latest) || ErrorFetchable(:final latest) => latest != null,
        _ => false,
      };

  /// The success data, or the data a busy/error value kept. Throws
  /// [StateError] when [hasLatestData] is false.
  D get latestData => switch (this) {
        SuccessFetchable<D>(:final data) => data,
        BusyFetchable<D>(latest: _Latest<D>(:final data)) => data,
        ErrorFetchable<D>(latest: _Latest<D>(:final data)) => data,
        _ => throw StateError('$this has no latest data'),
      };

  /// [latestData], or `null` when there is none.
  D? get latestDataOrNull => hasLatestData ? latestData : null;

  /// Busy while still holding earlier data: a reload, or a next page loading.
  bool get refreshing => this is BusyFetchable && hasLatestData;

  /// Calls the callback matching the current state. Every state must be
  /// handled, so adding a case is a compile error, not a silent fall-through.
  R when<R>({
    required R Function() idle,
    required R Function() busy,
    required R Function(D data) success,
    required R Function(dynamic error) error,
  }) =>
      switch (this) {
        IdleFetchable() => idle(),
        BusyFetchable() => busy(),
        SuccessFetchable<D>(:final data) => success(data),
        ErrorFetchable(:final exception) => error(exception),
        _ => throw StateError('Unknown Fetchable state for $runtimeType'),
      };

  /// Like [when], with [orElse] for the states you don't pass.
  R maybeWhen<R>({
    required R Function() orElse,
    R Function()? idle,
    R Function()? busy,
    R Function(D data)? success,
    R Function(dynamic error)? error,
  }) =>
      when(
        idle: idle ?? orElse,
        busy: busy ?? orElse,
        success: success ?? (_) => orElse(),
        error: error ?? (_) => orElse(),
      );

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

  /// Maps the success data (and any kept [latestData]); other states pass
  /// through.
  Fetchable<ND> mapSuccess<ND>(ND Function(D data) mapper) {
    switch (this) {
      case SuccessFetchable<D>(:final data):
        return SuccessFetchable<ND>(data: mapper(data));
      case BusyFetchable<D>(:final latest):
        return BusyFetchable<ND>(latest: latest == null ? null : _Latest(mapper(latest.data)));
      case ErrorFetchable<D>(:final exception, :final latest):
        return ErrorFetchable<ND>(exception: exception, latest: latest == null ? null : _Latest(mapper(latest.data)));
      default:
        return Fetchable.idle();
    }
  }

  Fetchable<ND> cast<ND>() => mapSuccess((data) => data as ND);

  /// Equal when the state, payload and kept data are equal. The type argument
  /// is ignored, so `Fetchable<int?>.success(null) == Fetchable<Null>.success(null)`.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return switch ((this, other)) {
      (final SuccessFetchable a, final SuccessFetchable b) => a.data == b.data,
      (final ErrorFetchable a, final ErrorFetchable b) => a.exception == b.exception && a.latest == b.latest,
      (final BusyFetchable a, final BusyFetchable b) => a.latest == b.latest,
      (IdleFetchable _, IdleFetchable _) => true,
      _ => false,
    };
  }

  @override
  int get hashCode {
    switch (state) {
      case AbleState.idle:
        return state.hashCode;
      case AbleState.busy:
        return Object.hash(state, (this as BusyFetchable).latest);
      case AbleState.success:
        return Object.hash(state, (this as SuccessFetchable).data);
      case AbleState.error:
        return Object.hash(state, (this as ErrorFetchable).exception, (this as ErrorFetchable).latest);
    }
  }

  @override
  String toString() {
    final kept = hasLatestData && state != AbleState.success ? ' (keeping $latestData)' : '';
    switch (state) {
      case AbleState.idle:
        return 'Fetchable(Idle)';
      case AbleState.busy:
        return 'Fetchable(Busy)$kept';
      case AbleState.success:
        return 'Fetchable(Success) : ${(this as SuccessFetchable<D>).data}';
      case AbleState.error:
        return 'Fetchable(Error) : ${(this as ErrorFetchable<D>).exception}$kept';
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

/// Data a busy or error [Fetchable] kept from an earlier success. A wrapper,
/// so a kept `null` (for a nullable `D`) is told apart from "nothing kept".
class _Latest<D> {
  const _Latest(this.data);

  final D data;

  @override
  bool operator ==(Object other) => other is _Latest && other.data == data;

  @override
  int get hashCode => data.hashCode;
}

class IdleFetchable<D> extends Fetchable<D> {
  IdleFetchable() : super._();
}

class SuccessFetchable<D> extends Fetchable<D> {
  final D data;

  SuccessFetchable({required this.data}) : super._();
}

class BusyFetchable<D> extends Fetchable<D> {
  final _Latest<D>? latest;

  BusyFetchable({this.latest}) : super._();
}

class ErrorFetchable<D> extends Fetchable<D> {
  final dynamic exception;

  final _Latest<D>? latest;

  ErrorFetchable({required this.exception, this.latest}) : super._();
}
