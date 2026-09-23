import 'package:able_lints/src/ast.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Flags a `mapFStream`/`mapPStream` feeding a live (`takeOnce: false`)
/// `executeSF`/`executeSP` without a `.distinct()` after it. Without it,
/// every upstream emission rebuilds this cubit, even when the field did not
/// change (Able cubits.md, Shadig STATE-8).
class MirrorMissingDistinct extends AnalysisRule {
  static const LintCode code = LintCode(
    'able_mirror_missing_distinct',
    "This field stream feeds a live subscription without '.distinct()', so every upstream change rebuilds.",
    correctionMessage: "Add '.distinct()' after it (after any '.map(...)').",
    severity: DiagnosticSeverity.WARNING,
  );

  MirrorMissingDistinct()
      : super(
          name: 'able_mirror_missing_distinct',
          description: "A 'mapFStream'/'mapPStream' in a live subscription without '.distinct()'.",
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
    if (!passesTakeOnceFalse(node)) return;
    final source = firstPositionalArgument(node);
    if (source == null) return;

    for (final mapStream in invocationsIn(source).where((i) => mapStreamMethods.contains(i.methodName.name))) {
      if (!_isFollowedByDistinct(mapStream, source)) {
        rule.reportAtNode(mapStream.methodName);
      }
    }
  }

  /// Whether a `.distinct()` is called on [node]'s result, possibly after
  /// other chained calls such as `.map(...)`, before reaching [root].
  bool _isFollowedByDistinct(MethodInvocation node, Expression root) {
    AstNode child = node;
    var parent = node.parent;
    while (parent != null && !identical(child, root)) {
      if (parent is MethodInvocation && identical(parent.target, child)) {
        if (parent.methodName.name == 'distinct') return true;
      } else {
        // Left the call chain (for example into another call's argument list).
        return false;
      }
      child = parent;
      parent = parent.parent;
    }
    return false;
  }
}
