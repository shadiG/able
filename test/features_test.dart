import 'dart:async';

import 'package:able/testing.dart';
import 'package:able/able.dart';
import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _State {
  const _State({required this.itemsF, required this.pagesF, required this.saveP});

  final Fetchable<BuiltList<int>> itemsF;
  final Fetchable<PagedList<int>> pagesF;
  final Progressable saveP;

  _State copyWith({Fetchable<BuiltList<int>>? itemsF, Fetchable<PagedList<int>>? pagesF, Progressable? saveP}) =>
      _State(itemsF: itemsF ?? this.itemsF, pagesF: pagesF ?? this.pagesF, saveP: saveP ?? this.saveP);
}

class _Cubit extends AbleCubit<_State> {
  _Cubit() : super(_State(itemsF: Fetchable.idle(), pagesF: Fetchable.idle(), saveP: Progressable.idle()));
}

class _RecordingObserver extends AbleObserver {
  final rebuilds = <Object?>[];
  final errors = <(Object?, bool)>[];

  @override
  void onRebuild(AbleCubit cubit, Object? previous, Object? next) => rebuilds.add(next);

  @override
  void onError(AbleCubit cubit, Object? error, StackTrace stackTrace, AbleType type, {required bool expected}) =>
      errors.add((error, expected));
}

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  setUp(() => Able.initialize());
  tearDown(Able.resetForTest);

  group('keeping data while reloading', () {
    final list = BuiltList<int>([1, 2]);

    test('toRefreshing keeps the data and reports refreshing', () {
      final refreshing = list.asFetchable().toRefreshing();
      expect(refreshing, isBusyF);
      expect(refreshing, isRefreshingF(list));
      expect(refreshing.latestData, list);
      expect(refreshing.latestDataOrNull, list);
    });

    test('keepingDataOf carries data through busy and error, not into idle', () {
      final previous = list.asFetchable();
      expect(Fetchable<BuiltList<int>>.busy().keepingDataOf(previous), isRefreshingF(list));
      final failed = Fetchable<BuiltList<int>>.error('x').keepingDataOf(previous);
      expect(failed, isErrorF('x'));
      expect(failed.latestData, list);
      expect(Fetchable<BuiltList<int>>.idle().keepingDataOf(previous).hasLatestData, isFalse);
    });

    test('kept data survives a chain of reloads', () {
      final twice = list.asFetchable().toRefreshing().toRefreshing();
      expect(twice.latestData, list);
    });

    test('a kept null is still data', () {
      final refreshing = Fetchable<int?>.success(null).toRefreshing();
      expect(refreshing.hasLatestData, isTrue);
      expect(refreshing.latestData, isNull);
    });

    test('plain busy has no latest data and is not refreshing', () {
      final busy = Fetchable<int>.busy();
      expect(busy.hasLatestData, isFalse);
      expect(busy.refreshing, isFalse);
      expect(() => busy.latestData, throwsStateError);
    });

    test('mapSuccess maps kept data too', () {
      expect(Fetchable.success(2).toRefreshing().mapSuccess((v) => v * 10).latestData, 20);
    });

    test('equality includes kept data', () {
      expect(Fetchable.success(1).toRefreshing(), Fetchable.success(1).toRefreshing());
      expect(Fetchable.success(1).toRefreshing(), isNot(Fetchable<int>.busy()));
      expect(Fetchable.success(1).toRefreshing(), isNot(Fetchable.success(2).toRefreshing()));
    });

    testWidgets('FetchableWidget shows kept data while busy, and the busy builder when asked', (tester) async {
      Widget build(bool showLatest) => _app(FetchableWidget<int>(
            fetchable: Fetchable.success(7).toRefreshing(),
            showLatestDataWhileBusy: showLatest,
            buildBusy: (_) => const Text('busy'),
            buildSuccess: (_, v) => Text('value $v'),
          ));

      await tester.pumpWidget(build(true));
      expect(find.text('value 7'), findsOneWidget);
      await tester.pumpWidget(build(false));
      expect(find.text('busy'), findsOneWidget);
    });
  });

  group('when / maybeWhen', () {
    String describeF(Fetchable<int> f) => f.when(
          idle: () => 'idle',
          busy: () => 'busy',
          success: (v) => 'success $v',
          error: (e) => 'error $e',
        );

    test('Fetchable.when calls the matching callback', () {
      expect(describeF(Fetchable.idle()), 'idle');
      expect(describeF(Fetchable.busy()), 'busy');
      expect(describeF(Fetchable.success(3)), 'success 3');
      expect(describeF(Fetchable.error('x')), 'error x');
    });

    test('Fetchable.maybeWhen falls back to orElse', () {
      expect(Fetchable<int>.busy().maybeWhen(success: (v) => '$v', orElse: () => 'other'), 'other');
      expect(Fetchable.success(4).maybeWhen(success: (v) => '$v', orElse: () => 'other'), '4');
    });

    test('Progressable.when passes progress to busy', () {
      final text = Progressable.busy(progress: 0.5).when(
        idle: () => 'idle',
        busy: (p) => 'busy $p',
        success: () => 'success',
        error: (e) => 'error',
      );
      expect(text, 'busy 0.5');
      expect(Progressable.success().maybeWhen(error: (_) => 'error', orElse: () => 'other'), 'other');
    });
  });

  group('execute* with a key', () {
    test('a second call with the same key cancels the first', () async {
      final cubit = _Cubit();
      final slow = Completer<BuiltList<int>>();
      final results = <Fetchable<BuiltList<int>>>[];

      cubit.executeF(() => slow.future, key: #load, then: results.add);
      cubit.executeF(() async => BuiltList<int>([2]), key: #load, then: results.add);
      await pumpEventQueue();
      slow.complete(BuiltList<int>([1]));
      await pumpEventQueue();

      expect(results.where((f) => f.success).map((f) => f.data), [BuiltList<int>([2])]);
      await cubit.close();
    });

    test('different keys run side by side', () async {
      final cubit = _Cubit();
      final results = <int>[];
      cubit.executeF(() async => 1, key: #a, then: (f) => f.success ? results.add(f.data) : null);
      cubit.executeF(() async => 2, key: #b, then: (f) => f.success ? results.add(f.data) : null);
      await pumpEventQueue();
      expect(results, unorderedEquals([1, 2]));
      await cubit.close();
    });

    test('cancelExecution stops a keyed call', () async {
      final cubit = _Cubit();
      final results = <Progressable>[];
      final release = Completer<void>();
      cubit.executeP(() => release.future, key: #save, then: results.add);
      await pumpEventQueue();
      cubit.cancelExecution(#save);
      release.complete();
      await pumpEventQueue();
      expect(results.where((p) => p.success), isEmpty);
      await cubit.close();
    });
  });

  group('progress', () {
    test('futureAsProgressableWithProgress reports clamped progress, then success', () async {
      final values = await futureAsProgressableWithProgress((report) async {
        report(0.25);
        report(1.5);
      }).toList();

      expect(values, [isBusyP(isNull), isBusyP(0.25), isBusyP(1.0), isSuccessP]);
    });

    test('an error is delivered as a stream error', () async {
      final cubit = _Cubit();
      final results = <Progressable>[];
      cubit.executeSP(futureAsProgressableWithProgress((_) async => throw StateError('x')),
          then: results.add, isExpectedError: (_) => true);
      await pumpEventQueue();
      expect(results.last, isErrorP(isA<StateError>()));
      await cubit.close();
    });

    testWidgets('ProgressableButton is disabled with a spinner while busy', (tester) async {
      var presses = 0;
      Widget build(Progressable p) =>
          _app(ProgressableButton(progressable: p, onPressed: () => presses++, child: const Text('Save')));

      await tester.pumpWidget(build(Progressable.busy(progress: 0.4)));
      expect(find.text('Save'), findsNothing);
      final spinner = tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator));
      expect(spinner.value, 0.4);
      await tester.tap(find.byType(FilledButton));
      expect(presses, 0);

      await tester.pumpWidget(build(Progressable.idle()));
      await tester.tap(find.text('Save'));
      expect(presses, 1);
    });

    testWidgets('ProgressableButton uses a custom builder', (tester) async {
      await tester.pumpWidget(_app(ProgressableButton(
        progressable: Progressable.idle(),
        onPressed: () {},
        builder: (context, onPressed, child) => OutlinedButton(onPressed: onPressed, child: child),
        child: const Text('Go'),
      )));
      expect(find.byType(OutlinedButton), findsOneWidget);
    });
  });

  group('withRetry', () {
    test('retries until it succeeds', () async {
      var attempts = 0;
      final result = await withRetry(() async {
        if (++attempts < 3) throw StateError('flaky');
        return 'ok';
      }, initialDelay: Duration.zero);
      expect(result, 'ok');
      expect(attempts, 3);
    });

    test('rethrows after maxAttempts', () async {
      var attempts = 0;
      await expectLater(
        withRetry(() async {
          attempts++;
          throw StateError('down');
        }, maxAttempts: 2, initialDelay: Duration.zero),
        throwsStateError,
      );
      expect(attempts, 2);
    });

    test('does not retry when retryIf says no', () async {
      var attempts = 0;
      await expectLater(
        withRetry(() async {
          attempts++;
          throw ArgumentError('bad input');
        }, retryIf: (e) => e is! ArgumentError, initialDelay: Duration.zero),
        throwsArgumentError,
      );
      expect(attempts, 1);
    });
  });

  group('combineAll', () {
    test('combineAllF succeeds with every value in order', () {
      final combined = combineAllF([Fetchable.success(1), Fetchable.success(2), Fetchable.success(3)]);
      expect(combined, isSuccessF(BuiltList<int>([1, 2, 3])));
    });

    test('combineAllF: error wins, then idle, then busy', () {
      expect(combineAllF([Fetchable.success(1), Fetchable<int>.busy(), Fetchable<int>.error('x')]), isErrorF('x'));
      expect(combineAllF([Fetchable<int>.busy(), Fetchable<int>.idle()]), isIdleF);
      expect(combineAllF([Fetchable.success(1), Fetchable<int>.busy()]), isBusyF);
    });

    test('combineAllF of nothing is an empty success', () {
      expect(combineAllF<int>([]), isSuccessF(isEmpty));
    });

    test('combineAllP combines progressables', () {
      expect(combineAllP([Progressable.success(), Progressable.success()]), isSuccessP);
      expect(combineAllP([Progressable.success(), Progressable.busy()]), isBusyP());
      expect(combineAllP([]), isSuccessP);
    });

    test('combineAllFStreams combines the latest of each stream', () async {
      final combined = await combineAllFStreams([
        Stream.value(Fetchable.success(1)),
        Stream.value(Fetchable.success(2)),
      ]).first;
      expect(combined, isSuccessF(BuiltList<int>([1, 2])));
    });
  });

  group('observer', () {
    test('sees rebuilds and errors, with whether they were expected', () async {
      final observer = _RecordingObserver();
      Able.observer = observer;
      final cubit = _Cubit();

      cubit.rebuild(cubit.state.copyWith(saveP: Progressable.busy()));
      cubit.executeP(() async => throw StateError('expected'), isExpectedError: (_) => true);
      cubit.executeP(() async => throw StateError('unexpected'));
      await pumpEventQueue();

      expect(observer.rebuilds, hasLength(1));
      expect(observer.errors.map((e) => e.$2), [true, false]);
      await cubit.close();
    });

    test('is not told about a rebuild to an equal state', () {
      final observer = _RecordingObserver();
      Able.observer = observer;
      final cubit = _Cubit();
      cubit.rebuild(cubit.state);
      expect(observer.rebuilds, isEmpty);
    });
  });

  group('Able.resetForTest and ExceptionHandler.unsubscribe', () {
    test('resetForTest lets initialize apply again', () {
      Able.initialize(loadingWidget: const Text('a'));
      Able.resetForTest();
      Able.initialize(loadingWidget: const Text('b'));
      expect((Able.configs.loadingWidget! as Text).data, 'b');
    });

    test('subscribe returns a function that unsubscribes', () async {
      final seen = <Object?>[];
      final unsubscribe = ExceptionHandler().subscribe((e, s, t) => seen.add(e));
      final cubit = _Cubit();

      cubit.executeP(() async => throw StateError('first'));
      await pumpEventQueue();
      unsubscribe();
      cubit.executeP(() async => throw StateError('second'));
      await pumpEventQueue();

      expect(seen, hasLength(1));
      await cubit.close();
    });
  });

  group('paging', () {
    Future<PageResult<int>> fetchPage(Object? key) async {
      final page = key! as int;
      return PageResult(
        items: List.generate(3, (i) => page * 3 + i),
        nextPageKey: page < 2 ? page + 1 : null,
      );
    }

    void loadMore(_Cubit cubit, {bool refresh = false, Future<PageResult<int>> Function(Object?)? fetch}) =>
        cubit.executeNextPage<int>(
          key: #pages,
          current: cubit.state.pagesF,
          refresh: refresh,
          firstPageKey: 0,
          fetch: fetch ?? fetchPage,
          then: (pagesF) => cubit.rebuild(cubit.state.copyWith(pagesF: pagesF)),
        );

    test('loads pages in order until the last one', () async {
      final cubit = _Cubit();
      for (var i = 0; i < 4; i++) {
        loadMore(cubit);
        await pumpEventQueue();
      }
      final pages = cubit.state.pagesF.data;
      expect(pages.items, List.generate(9, (i) => i));
      expect(pages.hasMore, isFalse);
      await cubit.close();
    });

    test('keeps loaded items while the next page loads', () async {
      final cubit = _Cubit();
      loadMore(cubit);
      await pumpEventQueue();

      final next = Completer<PageResult<int>>();
      loadMore(cubit, fetch: (_) => next.future);
      await pumpEventQueue();
      expect(cubit.state.pagesF, isRefreshingF(predicate<PagedList<int>>((p) => p.items.length == 3)));

      next.complete(const PageResult(items: [99], nextPageKey: null));
      await pumpEventQueue();
      expect(cubit.state.pagesF.data.items.last, 99);
      await cubit.close();
    });

    test('a failed page keeps the loaded items', () async {
      final cubit = _Cubit();
      loadMore(cubit);
      await pumpEventQueue();
      loadMore(cubit, fetch: (_) async => throw StateError('offline'));
      await pumpEventQueue();

      expect(cubit.state.pagesF, isErrorF(isA<StateError>()));
      expect(cubit.state.pagesF.latestData.items, hasLength(3));
      await cubit.close();
    });

    test('ignores load-more while a page is loading, but refresh starts over', () async {
      final cubit = _Cubit();
      loadMore(cubit);
      await pumpEventQueue();
      final pending = Completer<PageResult<int>>();
      loadMore(cubit, fetch: (_) => pending.future);
      await pumpEventQueue();

      expect(
          cubit.executeNextPage<int>(
            key: #pages,
            current: cubit.state.pagesF,
            fetch: fetchPage,
            then: (_) => fail('should not load'),
          ),
          isNull);

      loadMore(cubit, refresh: true);
      pending.complete(const PageResult(items: [42]));
      await pumpEventQueue();
      expect(cubit.state.pagesF.data.items, [0, 1, 2]);
      await cubit.close();
    });

    testWidgets('FetchablePagedListWidget asks for the next page near the end', (tester) async {
      var requests = 0;
      final pages = PagedList<int>.empty(firstPageKey: 0).append(const PageResult(items: [1, 2, 3, 4], nextPageKey: 1));

      await tester.pumpWidget(_app(CustomScrollView(slivers: [
        FetchablePagedListWidget<int>(
          fetchable: pages.asFetchable(),
          buildItem: (_, v) => SizedBox(height: 50, child: Text('item $v')),
          buildEmpty: (_) => const Text('empty'),
          onLoadMore: () => requests++,
        ),
      ])));
      await tester.pump();
      await tester.pump();

      expect(find.text('item 4'), findsOneWidget);
      expect(requests, 1);
    });

    testWidgets('FetchablePagedListWidget shows a loading footer and a retry footer', (tester) async {
      var retries = 0;
      final pages = PagedList<int>.empty().append(const PageResult(items: [1], nextPageKey: 1));
      Widget build(Fetchable<PagedList<int>> f) => _app(CustomScrollView(slivers: [
            FetchablePagedListWidget<int>(
              fetchable: f,
              buildItem: (_, v) => Text('item $v'),
              buildEmpty: (_) => const Text('empty'),
              onLoadMore: () => retries++,
            ),
          ]));

      await tester.pumpWidget(build(pages.asFetchable().toRefreshing()));
      expect(find.text('item 1'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpWidget(build(Fetchable<PagedList<int>>.error('offline').keepingDataOf(pages.asFetchable())));
      expect(find.text('offline'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retries, 1);
    });
  });

  group('list widgets', () {
    final items = BuiltList<int>([1, 2, 3]);

    testWidgets('FetchableListWidget renders separators', (tester) async {
      await tester.pumpWidget(_app(CustomScrollView(slivers: [
        FetchableListWidget<int>(
          fetchable: items.asFetchable(),
          buildItem: (_, v) => Text('item $v'),
          buildEmpty: (_) => const Text('empty'),
          buildError: null,
          separatorBuilder: (_, __) => const Divider(),
        ),
      ])));
      expect(find.byType(Divider), findsNWidgets(2));
    });

    testWidgets('FetchableSliverGrid renders items in a grid', (tester) async {
      await tester.pumpWidget(_app(CustomScrollView(slivers: [
        FetchableSliverGrid<int>(
          fetchable: items.asFetchable(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
          buildItem: (_, v) => Text('cell $v'),
          buildEmpty: (_) => const Text('empty'),
        ),
      ])));
      expect(find.text('cell 3'), findsOneWidget);
    });

    testWidgets('FetchableListView renders busy, empty and items', (tester) async {
      Widget build(Fetchable<BuiltList<int>> f) => _app(FetchableListView<int>(
            fetchable: f,
            buildItem: (_, v) => Text('row $v'),
            buildBusy: (_) => const Text('loading'),
            buildEmpty: (_) => const Text('empty'),
          ));

      await tester.pumpWidget(build(Fetchable.busy()));
      expect(find.text('loading'), findsOneWidget);
      await tester.pumpWidget(build(BuiltList<int>().asFetchable()));
      expect(find.text('empty'), findsOneWidget);
      await tester.pumpWidget(build(items.asFetchable().toRefreshing()));
      expect(find.text('row 2'), findsOneWidget);
    });
  });
}
