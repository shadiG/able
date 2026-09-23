import 'package:able_lints/src/ast.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Flags a `then:` callback that builds a new state with `state.rebuild(...)`
/// but never passes it to the cubit's own `rebuild(...)`, so the update is
/// silently dropped (Able anti-pattern #1, Shadig STATE-3).
class ThenWithoutRebuild extends AnalysisRule {
  static const LintCode code = LintCode(
    'able_then_without_rebuild',
    "This 'then:' builds a new state but never calls the cubit's 'rebuild', so the update is dropped.",
    correctionMessage: "Wrap it: 'rebuild(state.rebuild((b) => ...))'.",
    severity: DiagnosticSeverity.WARNING,
  );

  ThenWithoutRebuild()
      : super(
          name: 'able_then_without_rebuild',
          description: "A 'then:' callback that builds a state without emitting it.",
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
    if (!executeMethods.contains(node.methodName.name)) return;
    final then = namedArgument(node, 'then');
    if (then is! FunctionExpression) return;

    final rebuilds = invocationsIn(then.body).where((i) => i.methodName.name == 'rebuild');
    final buildsState = rebuilds.any((i) => !isOwnCall(i));
    final emits = rebuilds.any(isOwnCall);
    if (buildsState && !emits) {
      rule.reportAtNode(then);
    }
  }
}
