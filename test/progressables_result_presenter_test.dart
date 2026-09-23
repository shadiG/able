import 'package:able/able.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _State {
  const _State(this.saveP);

  final Progressable saveP;
}

class _Cubit extends AbleCubit<_State> {
  _Cubit() : super(_State(Progressable.idle()));
}

void main() {
  testWidgets('accepts presenters typed with the cubit state', (tester) async {
    final cubit = _Cubit();
    var successes = 0;

    await tester.pumpWidget(
      BlocProvider<_Cubit>.value(
        value: cubit,
        child: ProgressablesResultPresenter<_Cubit, _State>(
          presenters: [
            ProgressableResultPresenter<_State>(progressable: (s) => s.saveP, onSuccess: () => successes++),
          ],
          child: const SizedBox(),
        ),
      ),
    );
    expect(tester.takeException(), isNull);

    cubit.rebuild(_State(Progressable.success()));
    await tester.pump();
    await tester.pump();
    expect(successes, 1);

    await cubit.close();
  });
}
