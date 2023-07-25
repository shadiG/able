import 'package:able/src/common/able_state.dart';
import 'package:able/src/progressable/progressable.dart';
import 'package:rxdart/rxdart.dart';

//progressable extension
extension ProgressableExtension on Progressable {
  bool get success => state == AbleState.success;

  bool get hasError => state == AbleState.error;

  bool get idle => state == AbleState.idle;

  bool get busy => state == AbleState.busy;

  bool get idleOrBusy => idle || busy;

  dynamic get error => () {
        if (state != AbleState.error) {
          return null;
        }
        return (this as ErrorProgressable).exception;
      }();
}

/// represents Future as Stream<Progressable>
Stream<Progressable> futureAsProgressable(Future Function() func) async* {
  yield Progressable.busy();
  await func();
  yield Progressable.success();
  // errors are processed by a stream
}

Progressable combine2P({
  required Progressable p1,
  required Progressable p2,
}) {
  return toProgressable(
    state: p1.state + p2.state,
    exception: p1.error ?? p2.error,
  );
}

Progressable combine3P({
  required Progressable p1,
  required Progressable p2,
  required Progressable p3,
}) {
  return toProgressable(
    state: p1.state + p2.state + p3.state,
    exception: p1.error ?? p2.error ?? p3.error,
  );
}

Progressable combine4P({
  required Progressable p1,
  required Progressable p2,
  required Progressable p3,
  required Progressable p4,
}) {
  return toProgressable(
    state: p1.state + p2.state + p3.state + p4.state,
    exception: p1.error ?? p2.error ?? p3.error ?? p4.error,
  );
}

Progressable combine5P({
  required Progressable p1,
  required Progressable p2,
  required Progressable p3,
  required Progressable p4,
  required Progressable p5,
}) {
  return toProgressable(
    state: p1.state + p2.state + p3.state + p4.state + p5.state,
    exception: p1.error ?? p2.error ?? p3.error ?? p4.error ?? p5.error,
  );
}

Progressable combine6P({
  required Progressable p1,
  required Progressable p2,
  required Progressable p3,
  required Progressable p4,
  required Progressable p5,
  required Progressable p6,
}) {
  return toProgressable(
    state: p1.state + p2.state + p3.state + p4.state + p5.state + p6.state,
    exception: p1.error ?? p2.error ?? p3.error ?? p4.error ?? p5.error ?? p6.error,
  );
}

Progressable combine7P({
  required Progressable p1,
  required Progressable p2,
  required Progressable p3,
  required Progressable p4,
  required Progressable p5,
  required Progressable p6,
  required Progressable p7,
}) {
  return toProgressable(
    state: p1.state + p2.state + p3.state + p4.state + p5.state + p6.state + p7.state,
    exception: p1.error ?? p2.error ?? p3.error ?? p4.error ?? p5.error ?? p6.error ?? p7.error,
  );
}

Progressable combine8P({
  required Progressable p1,
  required Progressable p2,
  required Progressable p3,
  required Progressable p4,
  required Progressable p5,
  required Progressable p6,
  required Progressable p7,
  required Progressable p8,
}) {
  return toProgressable(
    state: p1.state + p2.state + p3.state + p4.state + p5.state + p6.state + p7.state + p8.state,
    exception: p1.error ?? p2.error ?? p3.error ?? p4.error ?? p5.error ?? p6.error ?? p7.error ?? p8.error,
  );
}

Progressable combine9P({
  required Progressable p1,
  required Progressable p2,
  required Progressable p3,
  required Progressable p4,
  required Progressable p5,
  required Progressable p6,
  required Progressable p7,
  required Progressable p8,
  required Progressable p9,
}) {
  return toProgressable(
    state: p1.state + p2.state + p3.state + p4.state + p5.state + p6.state + p7.state + p8.state + p9.state,
    exception: p1.error ?? p2.error ?? p3.error ?? p4.error ?? p5.error ?? p6.error ?? p7.error ?? p8.error ?? p9.error,
  );
}

Stream<Progressable> combine2PStreams({
  required Stream<Progressable> s1,
  required Stream<Progressable> s2,
}) {
  return CombineLatestStream.combine2<Progressable, Progressable, Progressable>(
    s1,
    s2,
    (p1, p2) {
      return combine2P(p1: p1, p2: p2);
    },
  );
}

Stream<Progressable> combine3PStreams({
  required Stream<Progressable> s1,
  required Stream<Progressable> s2,
  required Stream<Progressable> s3,
}) {
  return CombineLatestStream.combine3<Progressable, Progressable, Progressable, Progressable>(
    s1,
    s2,
    s3,
    (p1, p2, p3) {
      return combine3P(p1: p1, p2: p2, p3: p3);
    },
  );
}

Stream<Progressable> combine4PStreams({
  required Stream<Progressable> s1,
  required Stream<Progressable> s2,
  required Stream<Progressable> s3,
  required Stream<Progressable> s4,
}) {
  return CombineLatestStream.combine4<Progressable, Progressable, Progressable, Progressable, Progressable>(
    s1,
    s2,
    s3,
    s4,
    (p1, p2, p3, p4) {
      return combine4P(p1: p1, p2: p2, p3: p3, p4: p4);
    },
  );
}

Stream<Progressable> combine5PStreams({
  required Stream<Progressable> s1,
  required Stream<Progressable> s2,
  required Stream<Progressable> s3,
  required Stream<Progressable> s4,
  required Stream<Progressable> s5,
}) {
  return CombineLatestStream.combine5<Progressable, Progressable, Progressable, Progressable, Progressable,
      Progressable>(
    s1,
    s2,
    s3,
    s4,
    s5,
    (p1, p2, p3, p4, p5) {
      return combine5P(p1: p1, p2: p2, p3: p3, p4: p4, p5: p5);
    },
  );
}

Stream<Progressable> combine6PStreams({
  required Stream<Progressable> s1,
  required Stream<Progressable> s2,
  required Stream<Progressable> s3,
  required Stream<Progressable> s4,
  required Stream<Progressable> s5,
  required Stream<Progressable> s6,
}) {
  return CombineLatestStream.combine6<Progressable, Progressable, Progressable, Progressable, Progressable,
      Progressable, Progressable>(
    s1,
    s2,
    s3,
    s4,
    s5,
    s6,
    (p1, p2, p3, p4, p5, p6) {
      return combine6P(p1: p1, p2: p2, p3: p3, p4: p4, p5: p5, p6: p6);
    },
  );
}

Stream<Progressable> combine7PStreams({
  required Stream<Progressable> s1,
  required Stream<Progressable> s2,
  required Stream<Progressable> s3,
  required Stream<Progressable> s4,
  required Stream<Progressable> s5,
  required Stream<Progressable> s6,
  required Stream<Progressable> s7,
}) {
  return CombineLatestStream.combine7<Progressable, Progressable, Progressable, Progressable, Progressable,
      Progressable, Progressable, Progressable>(
    s1,
    s2,
    s3,
    s4,
    s5,
    s6,
    s7,
    (p1, p2, p3, p4, p5, p6, p7) {
      return combine7P(p1: p1, p2: p2, p3: p3, p4: p4, p5: p5, p6: p6, p7: p7);
    },
  );
}

Stream<Progressable> combine8PStreams({
  required Stream<Progressable> s1,
  required Stream<Progressable> s2,
  required Stream<Progressable> s3,
  required Stream<Progressable> s4,
  required Stream<Progressable> s5,
  required Stream<Progressable> s6,
  required Stream<Progressable> s7,
  required Stream<Progressable> s8,
}) {
  return CombineLatestStream.combine8<Progressable, Progressable, Progressable, Progressable, Progressable,
      Progressable, Progressable, Progressable, Progressable>(
    s1,
    s2,
    s3,
    s4,
    s5,
    s6,
    s7,
    s8,
    (p1, p2, p3, p4, p5, p6, p7, p8) {
      return combine8P(p1: p1, p2: p2, p3: p3, p4: p4, p5: p5, p6: p6, p7: p7, p8: p8);
    },
  );
}

Stream<Progressable> combine9PStreams({
  required Stream<Progressable> s1,
  required Stream<Progressable> s2,
  required Stream<Progressable> s3,
  required Stream<Progressable> s4,
  required Stream<Progressable> s5,
  required Stream<Progressable> s6,
  required Stream<Progressable> s7,
  required Stream<Progressable> s8,
  required Stream<Progressable> s9,
}) {
  return CombineLatestStream.combine9<Progressable, Progressable, Progressable, Progressable, Progressable,
      Progressable, Progressable, Progressable, Progressable, Progressable>(
    s1,
    s2,
    s3,
    s4,
    s5,
    s6,
    s7,
    s8,
    s9,
    (p1, p2, p3, p4, p5, p6, p7, p8, p9) {
      return combine9P(p1: p1, p2: p2, p3: p3, p4: p4, p5: p5, p6: p6, p7: p7, p8: p8, p9: p9);
    },
  );
}
