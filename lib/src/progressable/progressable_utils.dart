

import 'package:able/src/common/able_state.dart';
import 'package:able/src/progressable/progressable.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';



//progressable extension
extension ProgressableExtension on Progressable{
  bool get success => state == AbleState.success;
  bool get hasError => state == AbleState.error;
  bool get idle => state == AbleState.idle;
  bool get busy => state == AbleState.busy;
  

  dynamic get error => () {
    if (state != AbleState.error) {
      throw StateError('Fetchable(${describeEnum(state)}) : can not get data in this state');
    }
    return (this as ErrorProgressable).exception;
  }();
}

/// represents Future as Stream<Progressable>
Stream<Progressable> futureAsProgressable(
    Future Function() func,
    ) async* {
  yield Progressable.busy();
  await func();
  yield Progressable.success();
  // errors are processed by a stream
}

Progressable combine2P({required Progressable p1, required Progressable p2}) {
  return toProgressable(
    state: p1.state + p2.state,
    exception: p1.error ?? p2.error,
  );
}

Progressable combine3P({required Progressable p1, required Progressable p2, required Progressable p3}) {
  return toProgressable(
    state: p1.state + p2.state + p3.state,
    exception: p1.error ?? p2.error ?? p3.error,
  );
}

Progressable combine4P({required Progressable p1, required Progressable p2, required Progressable p3, required Progressable p4}) {
  return toProgressable(
    state: p1.state + p2.state + p3.state + p4.state,
    exception: p1.error ?? p2.error ?? p3.error ?? p4.error,
  );
}

Stream<Progressable> combine2PStreams({required Stream<Progressable> s1, required Stream<Progressable> s2}) {
  return CombineLatestStream.combine2<Progressable, Progressable, Progressable>(
    s1, s2, (p1, p2) {
      return combine2P(p1: p1, p2: p2);
    },
  );
}

Stream<Progressable> combine3PStreams({required Stream<Progressable> s1, required Stream<Progressable> s2, required Stream<Progressable> s3}) {
  return CombineLatestStream.combine3<Progressable, Progressable, Progressable, Progressable>(
    s1, s2, s3, (p1, p2, p3) {
      return combine3P(p1: p1, p2: p2, p3: p3);
    },
  );
}
