import 'package:able/able.dart';
import 'package:built_value/built_value.dart';
import 'package:rxdart/rxdart.dart';

part 'counter_cubit.g.dart';

class CounterCubit extends AbleCubit<CounterModel> {
  CounterCubit({int counter = 0})
      : super(CounterModel(
          (b) => b..counterF = Fetchable.idle(),
        )) {
    _initCount(counter);
  }

  void _initCount(int counter) {
    emit(state.rebuild((b) => b..counterF = Fetchable.success(counter)));
  }

  void increment() {
    stream
        .startWith(state)
        .map((m) => m.counterF)
        .distinct()
        .flatMapOnSuccessF((counter) => futureAsFetchable(() async {
              return counter + 1;
            }))
        .takeWhileInclusive((m) => !m.success)
        .presentF(this, (counterF) {
      emit(state.rebuild((b) => b..counterF = counterF));
    });
  }

  void decrement() {
    stream
        .startWith(state)
        .map((m) => m.counterF)
        .distinct()
        .flatMapOnSuccessF((counter) => futureAsFetchable(() async {
              return counter - 1 <= 0 ? 0 : counter - 1;
            }))
        .takeWhileInclusive((m) => !m.success)
        .presentF(this, (counterF) {
      emit(state.rebuild((b) => b..counterF = counterF));
    });
  }
}

abstract class CounterModel implements Built<CounterModel, CounterModelBuilder> {
  Fetchable<int> get counterF;

  CounterModel._();

  factory CounterModel([void Function(CounterModelBuilder b) updates]) = _$CounterModel;
}
