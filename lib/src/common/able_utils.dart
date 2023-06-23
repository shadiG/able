import 'package:able/able.dart';
import 'package:rxdart/rxdart.dart';

extension ProgressableStreamExtensions on Stream<Progressable> {
  Stream<Progressable> flatMapOnSuccessP(AbleCubit cubit, Stream<Progressable> Function() mapper) {
    return flatMap((p) {
      if (p.success) {
        return mapper().asBroadcastStream();
      } else {
        return Stream.value(p);
      }
    });
  }
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
