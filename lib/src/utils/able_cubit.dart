import 'dart:async';

import 'package:able/src/common/able_type.dart';
import 'package:able/src/fetchable/export.dart';
import 'package:able/src/progressable/export.dart';
import 'package:able/src/utils/exception_handler.dart';
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
}

extension AbleCubitFStreamExtensions<T> on Stream<Fetchable<T>> {
  /// Wraps Stream errors with Fetchable.error(e). If error is unexpected one
  /// then throws it into our error handler [mainErrorHandler]
  StreamSubscription presentF(
    AbleCubit cubit,
    void Function(Fetchable<T> F) onData, {
    void Function(dynamic e, StackTrace s)? onUnexpectedError,
    bool Function(dynamic e)? isExpectedError,
  }) {
    return cubit.closeWithCubit(listen(onData, onError: (e, s) {
      final isExpected = isExpectedError != null && isExpectedError(e);
      onData(Fetchable.error(e));
      if (!isExpected) {
        onUnexpectedError?.call(e, s);
        ExceptionHandler().handleException(e, s, AbleType.fetchable);
      }
    }));
  }
}

extension AbleCubitPStreamExtension on Stream<Progressable> {
  /// Wraps Stream errors with Progressable.error(e). If error is unexpected one
  /// then throws it into our error handler [mainErrorHandler]
  StreamSubscription presentP(
    AbleCubit cubit,
    void Function(Progressable P) onData, {
    void Function(dynamic e, StackTrace s)? onUnexpectedError,
    bool Function(dynamic e)? isExpectedError,
  }) {
    return cubit.closeWithCubit(listen(onData, onError: (e, s) {
      final isExpected = isExpectedError != null && isExpectedError(e);
      onData(Progressable.error(e));
      if (!isExpected) {
        onUnexpectedError?.call(e, s);
        ExceptionHandler().handleException(e, s, AbleType.fetchable);
      }
    }));
  }
}

extension AbleCubitExt<T> on AbleCubit<T> {
  StreamSubscription executeF(
    Future<T> Function() future, {
    required void Function(Fetchable<T> resultF) then,
    void Function(dynamic e, StackTrace s)? onUnexpectedError,
    bool Function(dynamic e)? isExpectedError,
  }) =>
      futureAsFetchable(future).presentF(
        this,
        then,
        onUnexpectedError: onUnexpectedError,
        isExpectedError: isExpectedError,
      );

  StreamSubscription executeP(
    Future Function() future, {
    required void Function(Progressable resultP) then,
    void Function(dynamic e, StackTrace s)? onUnexpectedError,
    bool Function(dynamic e)? isExpectedError,
  }) =>
      futureAsProgressable(future).presentP(
        this,
        then,
        onUnexpectedError: onUnexpectedError,
        isExpectedError: isExpectedError,
      );
}
