import 'package:able/src/fetchable/fetchable.dart';
import 'package:able/src/fetchable/fetchable_utils.dart';
import 'package:able/src/progressable/progressable.dart';
import 'package:rxdart/rxdart.dart';

extension FetchableStreamExtensions<T> on Stream<Fetchable<T>> {
  Stream<Fetchable<S>> flatMapOnSuccessF<S>(Stream<Fetchable<S>> Function(T value) mapper) {
    return flatMap((f) {
      if(f.success) {
        return mapper(f.data);
      } else {
        return Stream.value(f.cast<S>());
      }
    });
  }
  Stream<Progressable> flatMapOnSuccessFToProgressable<S>(Stream<Progressable> Function(T value) mapper) {
    return flatMap((f) {
      if(f.success) {
        return mapper(f.data);
      } else {
        return Stream.value(f.asProgressable());
      }
    });
  }
}