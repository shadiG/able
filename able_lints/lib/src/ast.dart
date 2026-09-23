import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// The `execute*` methods that turn a stream into cubit state.
const executeMethods = {'executeF', 'executeSF', 'executeP', 'executeSP'};

/// The `execute*` methods that take a stream as their first argument.
const streamExecuteMethods = {'executeSF', 'executeSP'};

/// The `AbleCubit` methods that project one state field as a stream.
const mapStreamMethods = {'mapFStream', 'mapPStream'};

/// The named argument [name] of [node], or null.
Expression? namedArgument(MethodInvocation node, String name) {
  for (final argument in node.argumentList.arguments) {
    if (argument is NamedArgument && argument.name.lexeme == name) {
      return argument.argumentExpression;
    }
  }
  return null;
}

/// The first positional argument of [node], or null.
Expression? firstPositionalArgument(MethodInvocation node) {
  for (final argument in node.argumentList.arguments) {
    if (argument is! NamedArgument) return argument.argumentExpression;
  }
  return null;
}

/// Whether [node] passes `takeOnce: false`.
bool passesTakeOnceFalse(MethodInvocation node) {
  final takeOnce = namedArgument(node, 'takeOnce');
  return takeOnce is BooleanLiteral && !takeOnce.value;
}

/// Whether [invocation] is a call on the cubit itself: `rebuild(...)` or
/// `this.rebuild(...)`, as opposed to `state.rebuild(...)` on a built value.
bool isOwnCall(MethodInvocation invocation) {
  final target = invocation.target;
  return target == null || target is ThisExpression;
}

/// Every method invocation inside [root], [root] included.
List<MethodInvocation> invocationsIn(AstNode root) {
  final collector = _InvocationCollector();
  root.accept(collector);
  return collector.found;
}

class _InvocationCollector extends RecursiveAstVisitor<void> {
  final found = <MethodInvocation>[];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    found.add(node);
    super.visitMethodInvocation(node);
  }
}
