import 'dart:async';

import 'package:able/able.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

class AbleCubit<State> extends Cubit<State> {
  final _compositeSubscription = CompositeSubscription();

  AbleCubit(super.initialState);

  /// closes StreamSubscription together with Cubit
  StreamSubscription closeWithCubit(StreamSubscription subscription) {
    if (!_compositeSubscription.isDisposed) {
      _compositeSubscription.add(subscription);
    }
    return subscription;
  }

  @override
  Future<void> close() {
    if (!_compositeSubscription.isDisposed) {
      _compositeSubscription.dispose();
    }
    return super.close();
  }

  Stream<Progressable> doIf({
    required Stream<Progressable> ifP,
    required Stream<Fetchable<bool>> condition,
    Stream<Progressable>? elseP,
  }) {
    return futureAsProgressable(
      () async {
        final doIt = await condition.asFuture(this);
        if (doIt) {
          return ifP.asFuture(this);
        } else {
          return elseP?.asFuture(this) ?? Future.value(null);
        }
      },
    );
  }

  Stream<Fetchable<T>> mapFStream<T>(Fetchable<T> Function(State m) s) =>
      stream.startWith(state).map(s);

  Stream<Progressable> mapPStream(Progressable Function(State m) s) =>
      stream.startWith(state).map(s);

  /// Emits [state]. Ignored once the cubit is closed, so async work that
  /// finishes after its screen is gone does not throw.
  void rebuild(State state) {
    if (isClosed) return;
    emit(state);
  }
}

extension AbleCubitFStreamExtensions<T> on Stream<Fetchable<T>> {
  /// Wraps Stream errors with Fetchable.error(e). If error is unexpected one
  /// then throws it into our error handler [mainErrorHandler]
  StreamSubscription presentF(
    AbleCubit cubit,
    Function(Fetchable<T> F)? onData, {
    void Function(dynamic e, StackTrace s)? onUnexpectedError,
    bool Function(dynamic e)? isExpectedError,
  }) {
    return cubit.closeWithCubit(listen(onData, onError: (e, s) {
      final isExpected = isExpectedError != null && isExpectedError(e);
      onData?.call(Fetchable.error(e));
      if (!isExpected) {
        onUnexpectedError?.call(e, s);
        ExceptionHandler().handleException(e, s, AbleType.fetchable);
      }
    }));
  }

  @Deprecated('Ignores the stream it is called on. Call executeF on the cubit instead.')
  StreamSubscription executeF<SP>(
    AbleCubit cubit,
    Future<SP> Function() future, {
    void Function(Fetchable<SP> resultF)? then,
    void Function(dynamic e, StackTrace s)? onUnexpectedError,
    bool Function(dynamic e)? isExpectedError,
  }) =>
      futureAsFetchable(future).presentF(
        cubit,
        then,
        onUnexpectedError: onUnexpectedError,
        isExpectedError: isExpectedError,
      );

  Stream<Fetchable<T>> takeOnceSuccess() =>
      takeWhileInclusive((m) => !m.success);

  Future<T> asFuture(
    AbleCubit cubit,
  ) async {
    final completer = Completer<T>();

    // Stops at the first success or error, so a later value can't complete twice.
    takeWhileInclusive((f) => !f.success && !f.hasError).presentF(cubit, (F) {
      if (completer.isCompleted) return;
      if (F.success) {
        return completer.complete(F.data);
      }
      if (F.hasError) {
        return completer.completeError(F.error);
      }
    });
    return completer.future;
  }
}

extension AbleCubitPStreamExtension on Stream<Progressable> {
  /// Wraps Stream errors with Progressable.error(e). If error is unexpected one
  /// then throws it into our error handler [mainErrorHandler]
  StreamSubscription presentP(
    AbleCubit cubit,
    void Function(Progressable P)? onData, {
    void Function(dynamic e, StackTrace s)? onUnexpectedError,
    bool Function(dynamic e)? isExpectedError,
  }) {
    return cubit.closeWithCubit(listen(onData, onError: (e, s) {
      final isExpected = isExpectedError != null && isExpectedError(e);
      onData?.call(Progressable.error(e));
      if (!isExpected) {
        onUnexpectedError?.call(e, s);
        ExceptionHandler().handleException(e, s, AbleType.progressable);
      }
    }));
  }

  @Deprecated('Ignores the stream it is called on. Call executeP on the cubit instead.')
  StreamSubscription executeP(
    AbleCubit cubit,
    Future Function() future, {
    void Function(Progressable resultP)? then,
    void Function(dynamic e, StackTrace s)? onUnexpectedError,
    bool Function(dynamic e)? isExpectedError,
  }) =>
      futureAsProgressable(future).presentP(
        cubit,
        then,
        onUnexpectedError: onUnexpectedError,
        isExpectedError: isExpectedError,
      );

  Stream<Progressable> takeOnceSuccess() =>
      takeWhileInclusive((m) => !m.success);

  Future<bool> asFuture(
    AbleCubit cubit,
  ) async {
    final completer = Completer<bool>();

    // Stops at the first success or error, so a later value can't complete twice.
    distinct().takeWhileInclusive((p) => !p.success && !p.hasError).presentP(cubit, (P) {
      if (completer.isCompleted) return;
      if (P.success) {
        return completer.complete(true);
      }
      if (P.hasError) {
        return completer.completeError(P.error);
      }
    });
    return completer.future;
  }
}

extension AbleCubitExt<T> on AbleCubit<T> {
  StreamSubscription executeF<SP>(
    Future<SP> Function() future, {
    void Function(Fetchable<SP> resultF)? then,
    void Function(dynamic e, StackTrace s)? onUnexpectedError,
    bool Function(dynamic e)? isExpectedError,
    bool takeOnce = true,
  }) =>
      (takeOnce
              ? futureAsFetchable(future).takeOnceSuccess()
              : futureAsFetchable(future))
          .presentF(
        this,
        then,
        onUnexpectedError: onUnexpectedError,
        isExpectedError: isExpectedError,
      );

  StreamSubscription executeSF<SP>(
    Stream<Fetchable<SP>> fetchable, {
    void Function(Fetchable<SP> resultF)? then,
    void Function(dynamic e, StackTrace s)? onUnexpectedError,
    bool Function(dynamic e)? isExpectedError,
    bool takeOnce = true,
  }) =>
      (takeOnce ? fetchable.takeOnceSuccess() : fetchable).presentF(
        this,
        then,
        onUnexpectedError: onUnexpectedError,
        isExpectedError: isExpectedError,
      );

  StreamSubscription executeP(
    Future Function() future, {
    void Function(Progressable resultP)? then,
    void Function(dynamic e, StackTrace s)? onUnexpectedError,
    bool Function(dynamic e)? isExpectedError,
    bool takeOnce = true,
  }) =>
      (takeOnce
              ? futureAsProgressable(future).takeOnceSuccess()
              : futureAsProgressable(future))
          .presentP(
        this,
        then,
        onUnexpectedError: onUnexpectedError,
        isExpectedError: isExpectedError,
      );

  StreamSubscription executeSP(
    Stream<Progressable> progressable, {
    void Function(Progressable resultP)? then,
    Stream<Progressable> Function()? onSuccessP,
    void Function(dynamic e, StackTrace s)? onUnexpectedError,
    bool Function(dynamic e)? isExpectedError,
    bool takeOnce = true,
  }) {
    if (onSuccessP != null) {
      // onSuccessP starts only once the first action succeeds.
      return (takeOnce ? progressable.takeOnceSuccess() : progressable)
          .switchMap((p) => p.success ? onSuccessP() : Stream.value(p))
          .presentP(
        this,
        then,
        onUnexpectedError: onUnexpectedError,
        isExpectedError: isExpectedError,
      );
    } else {
      return (takeOnce ? progressable.takeOnceSuccess() : progressable)
          .presentP(
        this,
        then,
        onUnexpectedError: onUnexpectedError,
        isExpectedError: isExpectedError,
      );
    }
  }
}
