// test_reflective_loader finds tests by their 'test_' prefix.
// ignore_for_file: non_constant_identifier_names

import 'package:able_lints/src/mirror_missing_distinct.dart';
import 'package:able_lints/src/mirror_missing_take_once_false.dart';
import 'package:able_lints/src/then_without_rebuild.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ThenWithoutRebuildTest);
    defineReflectiveTests(MirrorMissingTakeOnceFalseTest);
    defineReflectiveTests(MirrorMissingDistinctTest);
  });
}

/// Minimal stand-ins for Able's API. The rules match on names, so these only
/// need to type-check.
const _stubs = r'''
extension StreamStubs<T> on Stream<T> {
  Stream<T> distinct() => this;
  Stream<R> map<R>(R Function(T) convert) => throw 0;
}
class Fetchable<T> {}
class State {
  Fetchable<int> get countF => Fetchable();
  State rebuild(void Function(dynamic) updates) => this;
}
class Cubit {
  State state = State();
  void rebuild(State next) {}
  Stream<Fetchable<int>> mapFStream(Fetchable<int> Function(State) select) => throw 0;
  void executeF(Future<int> Function() f, {void Function(Fetchable<int>)? then, bool takeOnce = true}) {}
  void executeSF(Stream<Fetchable<int>> s, {void Function(Fetchable<int>)? then, bool takeOnce = true}) {}
}
''';

mixin _Helpers on PubPackageResolutionTest {
  /// The code under test, wrapped in a cubit method.
  String inCubit(String body) => '$_stubs\nclass MyCubit extends Cubit {\n  final Cubit other = Cubit();\n  void run() {\n$body\n  }\n}\n';
}

extension on AnalysisRuleTest {
  /// A lint on the last occurrence of [snippet]: the code under test comes
  /// after the stubs, which may use the same names.
  ExpectedDiagnostic lintAt(String code, String snippet) {
    final offset = code.lastIndexOf(snippet);
    assert(offset >= 0, 'snippet not found: $snippet');
    return lint(offset, snippet.length);
  }
}

@reflectiveTest
class ThenWithoutRebuildTest extends AnalysisRuleTest with _Helpers {
  @override
  void setUp() {
    rule = ThenWithoutRebuild();
    super.setUp();
  }

  Future<void> test_buildsStateWithoutEmitting() async {
    final code = inCubit(r'''
    executeF(() async => 1, then: (countF) => state.rebuild((b) => b..countF = countF));''');
    await assertDiagnostics(code, [lintAt(code, '(countF) => state.rebuild((b) => b..countF = countF)')]);
  }

  Future<void> test_emits() async {
    await assertNoDiagnostics(inCubit(r'''
    executeF(() async => 1, then: (countF) => rebuild(state.rebuild((b) => b..countF = countF)));'''));
  }

  Future<void> test_emitsThroughThis() async {
    await assertNoDiagnostics(inCubit(r'''
    executeF(() async => 1, then: (countF) { this.rebuild(state.rebuild((b) => b..countF = countF)); });'''));
  }

  Future<void> test_thenWithoutAnyState() async {
    await assertNoDiagnostics(inCubit(r'''
    final seen = [];
    executeF(() async => 1, then: seen.add);
    executeF(() async => 1, then: (countF) => seen.add(countF));'''));
  }
}

@reflectiveTest
class MirrorMissingTakeOnceFalseTest extends AnalysisRuleTest with _Helpers {
  @override
  void setUp() {
    rule = MirrorMissingTakeOnceFalse();
    super.setUp();
  }

  Future<void> test_mirrorWithoutTakeOnceFalse() async {
    final code = inCubit(r'''
    executeSF(other.mapFStream((s) => s.countF).distinct(),
        then: (countF) => rebuild(state.rebuild((b) => b..countF = countF)));''');
    await assertDiagnostics(code, [lintAt(code, 'executeSF')]);
  }

  Future<void> test_mirrorWithTakeOnceFalse() async {
    await assertNoDiagnostics(inCubit(r'''
    executeSF(other.mapFStream((s) => s.countF).distinct(),
        then: (countF) => rebuild(state.rebuild((b) => b..countF = countF)), takeOnce: false);'''));
  }

  Future<void> test_ownFieldIsNotAMirror() async {
    await assertNoDiagnostics(inCubit(r'''
    executeSF(mapFStream((s) => s.countF), then: (countF) => rebuild(state.rebuild((b) => b..countF = countF)));'''));
  }

  Future<void> test_oneShotReadWithoutWritingState() async {
    await assertNoDiagnostics(inCubit(r'''
    final seen = [];
    executeSF(other.mapFStream((s) => s.countF), then: seen.add);'''));
  }
}

@reflectiveTest
class MirrorMissingDistinctTest extends AnalysisRuleTest with _Helpers {
  @override
  void setUp() {
    rule = MirrorMissingDistinct();
    super.setUp();
  }

  Future<void> test_liveWithoutDistinct() async {
    final code = inCubit(r'''
    executeSF(other.mapFStream((s) => s.countF),
        then: (countF) => rebuild(state.rebuild((b) => b..countF = countF)), takeOnce: false);''');
    await assertDiagnostics(code, [lintAt(code, 'mapFStream')]);
  }

  Future<void> test_liveWithDistinct() async {
    await assertNoDiagnostics(inCubit(r'''
    executeSF(other.mapFStream((s) => s.countF).distinct(),
        then: (countF) => rebuild(state.rebuild((b) => b..countF = countF)), takeOnce: false);'''));
  }

  Future<void> test_distinctAfterMap() async {
    await assertNoDiagnostics(inCubit(r'''
    executeSF(other.mapFStream((s) => s.countF).map((f) => f).distinct(),
        then: (countF) => rebuild(state.rebuild((b) => b..countF = countF)), takeOnce: false);'''));
  }

  Future<void> test_oneShotNeedsNoDistinct() async {
    await assertNoDiagnostics(inCubit(r'''
    executeSF(other.mapFStream((s) => s.countF), then: (countF) => rebuild(state.rebuild((b) => b..countF = countF)));'''));
  }
}
