import 'dart:async';

import 'package:able/able.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

class AbleCubit<State> extends Cubit<State> {
  final _compositeSubscription = CompositeSubscription();
  final _keyedSubscriptions = <Object, StreamSubscription>{};

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
    _keyedSubscriptions.clear();
    return super.close();
  }

  /// Cancels the running `execute*` call started with [key], if any. Its
  /// `then:` gets no further values.
  void cancelExecution(Object key) {
    final previous = _keyedSubscriptions.remove(key);
    if (previous != null && !_compositeSubscription.isDisposed) {
      _compositeSubscription.remove(previous);
    }
  }

  /// Starts a subscription; with a [key], first cancels the previous one
  /// started with the same key.
  StreamSubscription _startKeyed(Object? key, StreamSubscription Function() start) {
    if (key == null) return start();
    cancelExecution(key);
    final subscription = start();
    _keyedSubscriptions[key] = subscription;
    return subscription;
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
    final previous = this.state;
    emit(state);
    if (previous != state) {
      Able.observer?.onRebuild(this, previous, state);
    }
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
      Able.observer?.onError(cubit, e, s, AbleType.fetchable, expected: isExpected);
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
      Able.observer?.onError(cubit, e, s, AbleType.progressable, expected: isExpected);
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

/// The `execute*` methods, called unqualified inside a cubit.
///
/// Each takes an optional `key`: starting a call with a key first cancels the
/// running call with the same key, so only the latest one reaches `then:`.
/// Use it for actions a user can re-trigger before the last one finishes (a
/// search, a filter): `executeF(() => repo.search(q), key: #search, then: ...)`.
extension AbleCubitExt<T> on AbleCubit<T> {
  StreamSubscription executeF<SP>(
    Future<SP> Function() future, {
    void Function(Fetchable<SP> resultF)? then,
    void Function(dynamic e, StackTrace s)? onUnexpectedError,
    bool Function(dynamic e)? isExpectedError,
    bool takeOnce = true,
    Object? key,
  }) =>
      executeSF(
        futureAsFetchable(future),
        then: then,
        onUnexpectedError: onUnexpectedError,
        isExpectedError: isExpectedError,
        takeOnce: takeOnce,
        key: key,
      );

  StreamSubscription executeSF<SP>(
    Stream<Fetchable<SP>> fetchable, {
    void Function(Fetchable<SP> resultF)? then,
    void Function(dynamic e, StackTrace s)? onUnexpectedError,
    bool Function(dynamic e)? isExpectedError,
    bool takeOnce = true,
    Object? key,
  }) =>
      _startKeyed(
        key,
        () => (takeOnce ? fetchable.takeOnceSuccess() : fetchable).presentF(
          this,
          then,
          onUnexpectedError: onUnexpectedError,
          isExpectedError: isExpectedError,
        ),
      );

  StreamSubscription executeP(
    Future Function() future, {
    void Function(Progressable resultP)? then,
    void Function(dynamic e, StackTrace s)? onUnexpectedError,
    bool Function(dynamic e)? isExpectedError,
    bool takeOnce = true,
    Object? key,
  }) =>
      executeSP(
        futureAsProgressable(future),
        then: then,
        onUnexpectedError: onUnexpectedError,
        isExpectedError: isExpectedError,
        takeOnce: takeOnce,
        key: key,
      );

  StreamSubscription executeSP(
    Stream<Progressable> progressable, {
    void Function(Progressable resultP)? then,
    Stream<Progressable> Function()? onSuccessP,
    void Function(dynamic e, StackTrace s)? onUnexpectedError,
    bool Function(dynamic e)? isExpectedError,
    bool takeOnce = true,
    Object? key,
  }) {
    var source = takeOnce ? progressable.takeOnceSuccess() : progressable;
    if (onSuccessP != null) {
      // onSuccessP starts only once the first action succeeds.
      source = source.switchMap((p) => p.success ? onSuccessP() : Stream.value(p));
    }
    return _startKeyed(
      key,
      () => source.presentP(
        this,
        then,
        onUnexpectedError: onUnexpectedError,
        isExpectedError: isExpectedError,
      ),
    );
  }
}
