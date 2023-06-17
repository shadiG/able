import 'package:able/able.dart';
import 'package:able/src/fetchable/fetchable.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

//fetchable extension
extension FetchableExtension<D> on Fetchable<D> {
  bool get success => state == AbleState.success;

  bool get hasError => state == AbleState.error;

  bool get idle => state == AbleState.idle;

  bool get busy => state == AbleState.busy;

  D get data => () {
        if (state != AbleState.success) {
          throw StateError('Fetchable(${describeEnum(state)}) : can not get data in this state ');
        }
        return (this as SuccessFetchable<D>).data;
      }();

  dynamic get error => () {
        if (state != AbleState.error) {
          return null;
        }
        return (this as ErrorFetchable<D>).exception;
      }();
}

/// represents Future<D> as Stream<Fetchable<D>>
Stream<Fetchable<D>> futureAsFetchable<D>(
  Future<D> Function() func,
) async* {
  yield Fetchable<D>.busy();
  final data = await func();
  yield Fetchable<D>.success(data);
  // errors are processed by a stream
}

/// represents Stream<D> as Stream<Fetchable<D>>
Stream<Fetchable<D>> streamAsFetchable<D>(Stream<D> Function() func) async* {
  yield Fetchable<D>.busy();
  yield* func().map((event) => Fetchable<D>.success(event));
  // errors are processed by a stream
}

Fetchable<(T1, T2)> combine2F<T1, T2>({required Fetchable<T1> f1, required Fetchable<T2> f2}) {
  return toFetchable<(T1, T2)>(
    data: f1.success && f2.success ? (f1.data, f2.data) : null,
    state: f1.state + f2.state,
    exception: f1.hasError || f2.hasError ? f1.error ?? f2.error : null,
  );
}

Fetchable<(T1, T2, T3)> combine3F<T1, T2, T3>({
  required Fetchable<T1> f1,
  required Fetchable<T2> f2,
  required Fetchable<T3> f3,
}) {
  return toFetchable<(T1, T2, T3)>(
    data: f1.success && f2.success && f3.success ? (f1.data, f2.data, f3.data) : null,
    state: f1.state + f2.state + f3.state,
    exception: f1.error ?? f2.error ?? f3.error,
  );
}

Fetchable<(T1, T2, T3, T4)> combine4F<T1, T2, T3, T4>({
  required Fetchable<T1> f1,
  required Fetchable<T2> f2,
  required Fetchable<T3> f3,
  required Fetchable<T4> f4,
}) {
  return toFetchable<(T1, T2, T3, T4)>(
    data: f1.success && f2.success && f3.success && f4.success ? (f1.data, f2.data, f3.data, f4.data) : null,
    state: f1.state + f2.state + f3.state + f4.state,
    exception:
        f1.hasError || f2.hasError || f3.hasError || f4.hasError ? f1.error ?? f2.error ?? f3.error ?? f4.error : null,
  );
}

Fetchable<(T1, T2, T3, T4, T5)> combine5F<T1, T2, T3, T4, T5>({
  required Fetchable<T1> f1,
  required Fetchable<T2> f2,
  required Fetchable<T3> f3,
  required Fetchable<T4> f4,
  required Fetchable<T5> f5,
}) {
  return toFetchable<(T1, T2, T3, T4, T5)>(
    data: f1.success && f2.success && f3.success && f4.success && f5.success
        ? (f1.data, f2.data, f3.data, f4.data, f5.data)
        : null,
    state: f1.state + f2.state + f3.state + f4.state + f5.state,
    exception: f1.hasError || f2.hasError || f3.hasError || f4.hasError || f5.hasError
        ? f1.error ?? f2.error ?? f3.error ?? f4.error ?? f5.error
        : null,
  );
}

Fetchable<(T1, T2, T3, T4, T5, T6)> combine6F<T1, T2, T3, T4, T5, T6>({
  required Fetchable<T1> f1,
  required Fetchable<T2> f2,
  required Fetchable<T3> f3,
  required Fetchable<T4> f4,
  required Fetchable<T5> f5,
  required Fetchable<T6> f6,
}) {
  return toFetchable<(T1, T2, T3, T4, T5, T6)>(
    data: f1.success && f2.success && f3.success && f4.success && f5.success && f6.success
        ? (f1.data, f2.data, f3.data, f4.data, f5.data, f6.data)
        : null,
    state: f1.state + f2.state + f3.state + f4.state + f5.state + f6.state,
    exception: f1.hasError || f2.hasError || f3.hasError || f4.hasError || f5.hasError || f6.hasError
        ? f1.error ?? f2.error ?? f3.error ?? f4.error ?? f5.error ?? f6.error
        : null,
  );
}

Fetchable<(T1, T2, T3, T4, T5, T6, T7)> combine7F<T1, T2, T3, T4, T5, T6, T7>({
  required Fetchable<T1> f1,
  required Fetchable<T2> f2,
  required Fetchable<T3> f3,
  required Fetchable<T4> f4,
  required Fetchable<T5> f5,
  required Fetchable<T6> f6,
  required Fetchable<T7> f7,
}) {
  return toFetchable<(T1, T2, T3, T4, T5, T6, T7)>(
    data: f1.success && f2.success && f3.success && f4.success && f5.success && f6.success && f7.success
        ? (f1.data, f2.data, f3.data, f4.data, f5.data, f6.data, f7.data)
        : null,
    state: f1.state + f2.state + f3.state + f4.state + f5.state + f7.state,
    exception: f1.hasError || f2.hasError || f3.hasError || f4.hasError || f5.hasError || f6.hasError || f7.hasError
        ? f1.error ?? f2.error ?? f3.error ?? f4.error ?? f5.error ?? f6.error ?? f7.error
        : null,
  );
}

Stream<Fetchable<(T1, T2)>> combine2FStreams<T1, T2>({
  required Stream<Fetchable<T1>> s1,
  required Stream<Fetchable<T2>> s2,
}) {
  return CombineLatestStream.combine2<Fetchable<T1>, Fetchable<T2>, Fetchable<(T1, T2)>>(
    s1,
    s2,
    (f1, f2) {
      return combine2F(f1: f1, f2: f2);
    },
  );
}

Stream<Fetchable<(T1, T2, T3)>> combine3FStreams<T1, T2, T3>({
  required Stream<Fetchable<T1>> s1,
  required Stream<Fetchable<T2>> s2,
  required Stream<Fetchable<T3>> s3,
}) {
  return CombineLatestStream.combine3<Fetchable<T1>, Fetchable<T2>, Fetchable<T3>, Fetchable<(T1, T2, T3)>>(
    s1,
    s2,
    s3,
    (f1, f2, f3) {
      return combine3F(f1: f1, f2: f2, f3: f3);
    },
  );
}

Stream<Fetchable<(T1, T2, T3, T4)>> combine4FStreams<T1, T2, T3, T4>({
  required Stream<Fetchable<T1>> s1,
  required Stream<Fetchable<T2>> s2,
  required Stream<Fetchable<T3>> s3,
  required Stream<Fetchable<T4>> s4,
}) {
  return CombineLatestStream.combine4<Fetchable<T1>, Fetchable<T2>, Fetchable<T3>, Fetchable<T4>,
      Fetchable<(T1, T2, T3, T4)>>(
    s1,
    s2,
    s3,
    s4,
    (f1, f2, f3, f4) {
      return combine4F(f1: f1, f2: f2, f3: f3, f4: f4);
    },
  );
}

Stream<Fetchable<(T1, T2, T3, T4, T5)>> combine5FStreams<T1, T2, T3, T4, T5>({
  required Stream<Fetchable<T1>> s1,
  required Stream<Fetchable<T2>> s2,
  required Stream<Fetchable<T3>> s3,
  required Stream<Fetchable<T4>> s4,
  required Stream<Fetchable<T5>> s5,
}) {
  return CombineLatestStream.combine5<Fetchable<T1>, Fetchable<T2>, Fetchable<T3>, Fetchable<T4>, Fetchable<T5>,
      Fetchable<(T1, T2, T3, T4, T5)>>(
    s1,
    s2,
    s3,
    s4,
    s5,
    (f1, f2, f3, f4, f5) {
      return combine5F(f1: f1, f2: f2, f3: f3, f4: f4, f5: f5);
    },
  );
}

Stream<Fetchable<(T1, T2, T3, T4, T5, T6)>> combine6FStreams<T1, T2, T3, T4, T5, T6>(
    {required Stream<Fetchable<T1>> s1,
    required Stream<Fetchable<T2>> s2,
    required Stream<Fetchable<T3>> s3,
    required Stream<Fetchable<T4>> s4,
    required Stream<Fetchable<T5>> s5,
    required Stream<Fetchable<T6>> s6}) {
  return CombineLatestStream.combine6<Fetchable<T1>, Fetchable<T2>, Fetchable<T3>, Fetchable<T4>, Fetchable<T5>,
      Fetchable<T6>, Fetchable<(T1, T2, T3, T4, T5, T6)>>(
    s1,
    s2,
    s3,
    s4,
    s5,
    s6,
    (f1, f2, f3, f4, f5, f6) {
      return combine6F(f1: f1, f2: f2, f3: f3, f4: f4, f5: f5, f6: f6);
    },
  );
}

Stream<Fetchable<(T1, T2, T3, T4, T5, T6, T7)>> combine7FStreams<T1, T2, T3, T4, T5, T6, T7>(
    {required Stream<Fetchable<T1>> s1,
    required Stream<Fetchable<T2>> s2,
    required Stream<Fetchable<T3>> s3,
    required Stream<Fetchable<T4>> s4,
    required Stream<Fetchable<T5>> s5,
    required Stream<Fetchable<T6>> s6,
    required Stream<Fetchable<T7>> s7}) {
  return CombineLatestStream.combine7<Fetchable<T1>, Fetchable<T2>, Fetchable<T3>, Fetchable<T4>, Fetchable<T5>,
      Fetchable<T6>, Fetchable<T7>, Fetchable<(T1, T2, T3, T4, T5, T6, T7)>>(
    s1,
    s2,
    s3,
    s4,
    s5,
    s6,
    s7,
    (f1, f2, f3, f4, f5, f6, f7) {
      return combine7F(f1: f1, f2: f2, f3: f3, f4: f4, f5: f5, f6: f6, f7: f7);
    },
  );
}
