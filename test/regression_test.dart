import 'dart:async';

import 'package:able/able.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _State {
  const _State({required this.valueF, required this.saveP});

  final Fetchable<int> valueF;
  final Progressable saveP;

  _State copyWith({Fetchable<int>? valueF, Progressable? saveP}) =>
      _State(valueF: valueF ?? this.valueF, saveP: saveP ?? this.saveP);
}

class _Cubit extends AbleCubit<_State> {
  _Cubit() : super(_State(valueF: Fetchable.idle(), saveP: Progressable.idle()));
}

/// Collects uncaught async errors raised while [body] runs.
Future<List<Object>> _uncaughtErrors(Future<void> Function() body) async {
  final errors = <Object>[];
  await runZonedGuarded(body, (e, _) => errors.add(e));
  return errors;
}

void main() {
  final handled = <(dynamic, AbleType)>[];
  final onErrorCalls = <dynamic>[];

  setUpAll(() {
    Able.initialize(
      handleException: (e, s, type) => handled.add((e, type)),
      onError: (e, message) => onErrorCalls.add(e),
    );
  });

  setUp(() {
    handled.clear();
    onErrorCalls.clear();
  });

  group('asFuture', () {
    test('Fetchable: stops listening after an error, so a later success does not throw', () async {
      final cubit = _Cubit();
      final errors = await _uncaughtErrors(() async {
        final future = cubit.mapFStream((s) => s.valueF).asFuture(cubit);
        cubit.rebuild(cubit.state.copyWith(valueF: Fetchable.error('boom')));
        await expectLater(future, throwsA('boom'));
        cubit.rebuild(cubit.state.copyWith(valueF: Fetchable.success(1)));
        await pumpEventQueue();
      });
      expect(errors, isEmpty);
      await cubit.close();
    });

    test('Progressable: stops listening after an error, so a later success does not throw', () async {
      final cubit = _Cubit();
      final errors = await _uncaughtErrors(() async {
        final future = cubit.mapPStream((s) => s.saveP).asFuture(cubit);
        cubit.rebuild(cubit.state.copyWith(saveP: Progressable.error('boom')));
        await expectLater(future, throwsA('boom'));
        cubit.rebuild(cubit.state.copyWith(saveP: Progressable.success()));
        await pumpEventQueue();
      });
      expect(errors, isEmpty);
      await cubit.close();
    });
  });

  test('executeSP(onSuccessP:) starts the second action only after the first succeeds', () async {
    final cubit = _Cubit();
    final firstDone = Completer<void>();
    final events = <String>[];

    cubit.executeSP(
      futureAsProgressable(() async {
        await firstDone.future;
        events.add('first');
      }),
      onSuccessP: () => futureAsProgressable(() async => events.add('second')),
    );
    await pumpEventQueue();
    expect(events, isEmpty);

    firstDone.complete();
    await pumpEventQueue();
    expect(events, ['first', 'second']);
    await cubit.close();
  });

  test('Function().asProgressable() calls the function', () async {
    final cubit = _Cubit();
    var calls = 0;
    void increment() => calls++;

    await increment.asProgressable().asFuture(cubit);
    expect(calls, 1);
    await cubit.close();
  });

  test('emptyP can be listened to more than once', () async {
    final cubit = _Cubit();
    await emptyP.asFuture(cubit);
    await emptyP.asFuture(cubit);
    await cubit.close();
  });

  testWidgets('Able.initialize onError is still called after ExceptionHandler() is obtained elsewhere',
      (tester) async {
    final cubit = _Cubit();
    await tester.pumpWidget(
      BlocProvider<_Cubit>.value(
        value: cubit,
        child: ProgressablesResultPresenter<_Cubit, _State>(
          presenters: [ProgressableResultPresenter<_State>(progressable: (s) => s.saveP)],
          child: const SizedBox(),
        ),
      ),
    );

    // presentP obtains the handler with a bare ExceptionHandler() call.
    cubit.executeP(() async => throw StateError('save failed'),
        then: (p) => cubit.rebuild(cubit.state.copyWith(saveP: p)));
    await tester.pump();
    await tester.pump();

    expect(onErrorCalls, [isA<StateError>()]);
    await cubit.close();
  });

  test('presentP reports errors as AbleType.progressable', () async {
    final cubit = _Cubit();
    cubit.executeP(() async => throw StateError('x'));
    await pumpEventQueue();

    expect(handled.single.$2, AbleType.progressable);
    await cubit.close();
  });

  group('combine7F / combine8F / combine9F include f6', () {
    final s = Fetchable.success(1);
    final busy = Fetchable<int>.busy();

    test('combine7F', () {
      expect(combine7F(f1: s, f2: s, f3: s, f4: s, f5: s, f6: busy, f7: s).busy, isTrue);
    });
    test('combine8F', () {
      expect(combine8F(f1: s, f2: s, f3: s, f4: s, f5: s, f6: busy, f7: s, f8: s).busy, isTrue);
    });
    test('combine9F', () {
      expect(combine9F(f1: s, f2: s, f3: s, f4: s, f5: s, f6: busy, f7: s, f8: s, f9: s).busy, isTrue);
    });
  });

  test('rebuild after close is ignored instead of throwing', () async {
    final cubit = _Cubit();
    final release = Completer<void>();
    cubit.executeSP(futureAsProgressable(() async {
      await release.future;
      cubit.rebuild(cubit.state.copyWith(valueF: Fetchable.success(1)));
    }));
    await pumpEventQueue();
    await cubit.close();

    final errors = await _uncaughtErrors(() async {
      release.complete();
      await pumpEventQueue();
    });
    expect(errors, isEmpty);
  });

  test('switchMapOnSuccessF drops results for superseded inputs', () async {
    final source = StreamController<Fetchable<int>>();
    final slow = Completer<String>();
    final results = <Fetchable<String>>[];

    final sub = source.stream
        .switchMapOnSuccessF((v) => futureAsFetchable(() => v == 1 ? slow.future : Future.value('fast $v')))
        .listen(results.add);

    source.add(Fetchable.success(1));
    await pumpEventQueue();
    source.add(Fetchable.success(2));
    await pumpEventQueue();
    slow.complete('slow 1');
    await pumpEventQueue();

    expect(results.where((f) => f.success).map((f) => f.data), ['fast 2']);
    await sub.cancel();
    await source.close();
  });

  testWidgets('ProgressablesResultPresenter sees a change made before the first frame ends', (tester) async {
    final cubit = _Cubit();
    var successes = 0;

    await tester.pumpWidget(
      BlocProvider<_Cubit>.value(
        value: cubit,
        child: ProgressablesResultPresenter<_Cubit, _State>(
          presenters: [
            ProgressableResultPresenter<_State>(progressable: (s) => s.saveP, onSuccess: () => successes++),
          ],
          // Emits from its initState, before any post-frame callback has run.
          child: _OnInit(() => cubit.rebuild(cubit.state.copyWith(saveP: Progressable.success()))),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(successes, 1);
    await cubit.close();
  });

  group('Fetchable.error(null)', () {
    testWidgets('FetchableWidget renders buildError', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FetchableWidget<int>(
            fetchable: Fetchable.error(null),
            buildSuccess: (_, __) => const Text('success'),
            buildError: (_, __) => const Text('error'),
          ),
        ),
      );
      expect(find.text('error'), findsOneWidget);
    });

    test('combine2F keeps the error state', () {
      expect(combine2F(f1: Fetchable<int>.error(null), f2: Fetchable.success(1)).hasError, isTrue);
    });
  });

  group('AbleState +', () {
    test('an error wins over idle and busy', () {
      expect(AbleState.error + AbleState.idle, AbleState.error);
      expect(AbleState.busy + AbleState.error, AbleState.error);
    });

    test('combine2F surfaces an error while another input is still loading', () {
      final combined = combine2F(f1: Fetchable<int>.error('boom'), f2: Fetchable<int>.busy());
      expect(combined.hasError, isTrue);
      expect(combined.error, 'boom');
    });
  });

  test('Fetchable equality ignores the static type argument', () {
    final Fetchable<int?> a = Fetchable<int?>.success(null);
    final Fetchable<int?> b = Fetchable<Null>.success(null);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect({a, b}, hasLength(1));
  });
}

class _OnInit extends StatefulWidget {
  const _OnInit(this.onInit);

  final VoidCallback onInit;

  @override
  State<_OnInit> createState() => _OnInitState();
}

class _OnInitState extends State<_OnInit> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
