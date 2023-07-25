import 'dart:async';

import 'package:able/able.dart';
import 'package:rxdart/rxdart.dart';

Stream<Progressable> emptyP = futureAsProgressable(() async => null);

extension ProgressableStreamExtensions on Stream<Progressable> {
  Stream<Progressable> flatMapOnSuccessP(AbleCubit cubit, Stream<Progressable> Function() mapper) {
    return futureAsProgressable(() async {
      await asFuture(cubit);
      await mapper().asFuture(cubit);
    });
  }
}

extension FetchableExtensionOnType<T> on T {
  Fetchable<T> asFetchable() => Fetchable.success(this);
}

extension ProgressableFunctionExtensions on Function() {
  Stream<Progressable> asProgressable() => futureAsProgressable(() async => this);
}

extension FetchableFunctionExtensions<T> on T Function() {
  Stream<Fetchable<T>> asFetchable() => futureAsFetchable(() async => this());
}

extension AbleFutureExtensions<T> on Future<T> {
  Stream<Progressable> asProgressable() => futureAsProgressable(() async => this);
  Stream<Fetchable<T>> asFetchable() => futureAsFetchable(() async => this);
}

extension FetchableStreamExtensions<T> on Stream<Fetchable<T>> {
  Stream<Fetchable<S>> flatMapOnSuccessF<S>(Stream<Fetchable<S>> Function(T value) mapper) {
    return flatMap((f) {
      if (f.success) {
        return mapper(f.data);
      } else {
        return Stream.value(f.cast<S>());
      }
    });
  }

  Stream<Progressable> flatMapOnSuccessFToProgressable<S>(Stream<Progressable> Function(T value) mapper) {
    return flatMap((f) {
      if (f.success) {
        return mapper(f.data);
      } else {
        return Stream.value(f.asProgressable());
      }
    });
  }
}

extension FetchableListExtension on List<Fetchable> {
  bool get allSuccess => every((f) => f.success);
  bool get anySuccess => any((f) => f.success);
  bool get allFailure => every((f) => f.hasError);
  bool get anyFailure => any((f) => f.hasError);

  // idle
  bool get allIdle => every((f) => f.idle);
  bool get anyIdle => any((f) => f.idle);

  // idle or busy
  bool get allIdleOrBusy => every((f) => f.idle || f.busy);
  bool get anyIdleOrBusy => any((f) => f.idle || f.busy);
  bool get allIdleOrBusyOrSuccess => every((f) => f.idle || f.busy || f.success);
  bool get anyIdleOrBusyOrSuccess => any((f) => f.idle || f.busy || f.success);
}

extension ProgressableListExtension on List<Progressable> {
  bool get allSuccess => every((f) => f.success);
  bool get anySuccess => any((f) => f.success);
  bool get allFailure => every((f) => f.hasError);
  bool get anyFailure => any((f) => f.hasError);

  // idle
  bool get allIdle => every((f) => f.idle);
  bool get anyIdle => any((f) => f.idle);

  // busy
  bool get allBusy => every((f) => f.busy);
  bool get anyBusy => any((f) => f.busy);

  // idle or busy
  bool get allIdleOrBusy => every((f) => f.idle || f.busy);
  bool get anyIdleOrBusy => any((f) => f.idle || f.busy);
  bool get allIdleOrBusyOrSuccess => every((f) => f.idle || f.busy || f.success);
  bool get anyIdleOrBusyOrSuccess => any((f) => f.idle || f.busy || f.success);
}
