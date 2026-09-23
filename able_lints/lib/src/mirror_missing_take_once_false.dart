import 'package:able_lints/src/ast.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Flags an `executeSF`/`executeSP` that mirrors another cubit's field into
/// this cubit's state without `takeOnce: false`. With the default
/// `takeOnce: true` the mirror stops after the first success (Able
/// anti-pattern #4, Shadig STATE-8).
class MirrorMissingTakeOnceFalse extends AnalysisRule {
  static const LintCode code = LintCode(
    'able_mirror_missing_take_once_false',
    "This mirrors another cubit's field but stops after the first success.",
    correctionMessage: "Pass 'takeOnce: false' so it follows every change, or ignore this if one value is intended.",
    severity: DiagnosticSeverity.WARNING,
  );

  MirrorMissingTakeOnceFalse()
      : super(
          name: 'able_mirror_missing_take_once_false',
          description: "A live mirror of another cubit's field without 'takeOnce: false'.",
        );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addMethodInvocation(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AnalysisRule rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!streamExecuteMethods.contains(node.methodName.name)) return;
    if (passesTakeOnceFalse(node)) return;
    final source = firstPositionalArgument(node);
    final then = namedArgument(node, 'then');
    if (source == null || then == null) return;

    final readsOtherCubit = invocationsIn(source)
        .any((i) => mapStreamMethods.contains(i.methodName.name) && !isOwnCall(i));
    final writesOwnState = invocationsIn(then).any((i) => i.methodName.name == 'rebuild' && isOwnCall(i));
    if (readsOtherCubit && writesOwnState) {
      rule.reportAtNode(node.methodName);
    }
  }
}
