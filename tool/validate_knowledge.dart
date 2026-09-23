// Lightweight validator for the able knowledge base (rules/ + knowledge/).
//
// Run from anywhere inside the repository:
//   dart run tool/validate_knowledge.dart
//
// Checks:
//  - knowledge/graph/graph.json is valid JSON with the expected shape
//  - every node id is unique
//  - every node's `path` points to a file that actually exists
//  - every edge's `from`/`to` references an existing node id
//  - every edge's `relation` is one of the eight allowed kinds
//  - every file in rules/ has a matching `rule` node (and vice versa)
//  - every file in knowledge/concepts/ has a matching `concept` node (and vice versa)
//  - every file in knowledge/decisions/ADR-*.md has a matching `decision` node (and vice versa)
//  - ADR filenames follow the ADR-NNN-slug.md pattern
//  - every app in example/ (a directory with a README.md) has a matching `example` node (and vice versa)
//
// Deliberately has zero dependencies beyond dart:core/io/convert so it runs with a bare Dart SDK,
// no `pub get` required, and never goes stale relative to a pubspec.

import 'dart:convert';
import 'dart:io';

const allowedRelations = {
  'uses',
  'extends',
  'implements',
  'depends_on',
  'used_by',
  'governed_by',
  'documented_by',
  'decided_by',
};

const allowedNodeTypes = {'concept', 'rule', 'decision', 'example'};

int errorCount = 0;

void fail(String message) {
  errorCount++;
  stderr.writeln('ERROR: $message');
}

void warn(String message) {
  stdout.writeln('WARNING: $message');
}

Directory findRepoRoot() {
  final scriptDir = File.fromUri(Platform.script).parent;
  return scriptDir.parent; // tool/ -> repo root
}

void main() {
  final root = findRepoRoot();
  final graphFile = File('${root.path}/knowledge/graph/graph.json');

  if (!graphFile.existsSync()) {
    fail('knowledge/graph/graph.json does not exist');
    report();
    return;
  }

  dynamic decoded;
  try {
    decoded = jsonDecode(graphFile.readAsStringSync());
  } catch (e) {
    fail('knowledge/graph/graph.json is not valid JSON: $e');
    report();
    return;
  }

  if (decoded is! Map || decoded['nodes'] is! List || decoded['edges'] is! List) {
    fail('knowledge/graph/graph.json must be an object with "nodes" and "edges" arrays');
    report();
    return;
  }

  final nodes = (decoded['nodes'] as List).cast<Map<String, dynamic>>();
  final edges = (decoded['edges'] as List).cast<Map<String, dynamic>>();

  final idsSeen = <String>{};
  final nodesById = <String, Map<String, dynamic>>{};

  for (final node in nodes) {
    final id = node['id'];
    final type = node['type'];
    final path = node['path'];

    if (id is! String || id.isEmpty) {
      fail('node missing a non-empty string "id": $node');
      continue;
    }
    if (!idsSeen.add(id)) {
      fail('duplicate node id "$id"');
    }
    nodesById[id] = node;

    if (type is! String || !allowedNodeTypes.contains(type)) {
      fail('node "$id" has invalid "type": $type (must be one of $allowedNodeTypes)');
    }

    if (path is! String || path.isEmpty) {
      fail('node "$id" missing a non-empty "path"');
    } else {
      final f = File('${root.path}/$path');
      if (!f.existsSync()) {
        fail('node "$id" points to a missing file: $path');
      }
    }
  }

  for (final edge in edges) {
    final from = edge['from'];
    final to = edge['to'];
    final relation = edge['relation'];

    if (from is! String || !nodesById.containsKey(from)) {
      fail('edge references unknown "from" node: $edge');
    }
    if (to is! String || !nodesById.containsKey(to)) {
      fail('edge references unknown "to" node: $edge');
    }
    if (relation is! String || !allowedRelations.contains(relation)) {
      fail('edge has invalid "relation" (must be one of $allowedRelations): $edge');
    }
  }

  checkDirectoryMatchesNodes(
    root: root,
    dirPath: 'rules',
    nodeType: 'rule',
    nodes: nodes,
  );
  checkDirectoryMatchesNodes(
    root: root,
    dirPath: 'knowledge/concepts',
    nodeType: 'concept',
    nodes: nodes,
  );
  checkDecisions(root: root, nodes: nodes);
  checkExamples(root: root, nodes: nodes);

  report();
}

void checkDirectoryMatchesNodes({
  required Directory root,
  required String dirPath,
  required String nodeType,
  required List<Map<String, dynamic>> nodes,
}) {
  final dir = Directory('${root.path}/$dirPath');
  if (!dir.existsSync()) {
    fail('expected directory does not exist: $dirPath');
    return;
  }

  final filesOnDisk = dir
      .listSync()
      .whereType<File>()
      .map((f) => f.uri.pathSegments.last)
      .where((name) => name.endsWith('.md'))
      .toSet();

  final pathsInGraph = nodes
      .where((n) => n['type'] == nodeType)
      .map((n) => (n['path'] as String).split('/').last)
      .toSet();

  for (final onDisk in filesOnDisk) {
    if (!pathsInGraph.contains(onDisk)) {
      warn('$dirPath/$onDisk has no matching "$nodeType" node in graph.json (orphan file)');
    }
  }
  for (final inGraph in pathsInGraph) {
    if (!filesOnDisk.contains(inGraph)) {
      fail('graph.json references a "$nodeType" node whose file is missing on disk: $dirPath/$inGraph');
    }
  }
}

void checkDecisions({required Directory root, required List<Map<String, dynamic>> nodes}) {
  final dir = Directory('${root.path}/knowledge/decisions');
  if (!dir.existsSync()) {
    fail('expected directory does not exist: knowledge/decisions');
    return;
  }

  final adrPattern = RegExp(r'^ADR-(\d{3})-[a-z0-9-]+\.md$');
  final adrFiles = dir
      .listSync()
      .whereType<File>()
      .map((f) => f.uri.pathSegments.last)
      .where((name) => name.startsWith('ADR-'))
      .toSet();

  for (final name in adrFiles) {
    if (!adrPattern.hasMatch(name)) {
      fail('knowledge/decisions/$name does not match the ADR-NNN-slug.md naming pattern');
    }
  }

  final pathsInGraph = nodes
      .where((n) => n['type'] == 'decision')
      .map((n) => (n['path'] as String).split('/').last)
      .toSet();

  for (final onDisk in adrFiles) {
    if (!pathsInGraph.contains(onDisk)) {
      warn('knowledge/decisions/$onDisk has no matching "decision" node in graph.json (orphan file)');
    }
  }
  for (final inGraph in pathsInGraph) {
    if (!adrFiles.contains(inGraph)) {
      fail('graph.json references a "decision" node whose file is missing on disk: knowledge/decisions/$inGraph');
    }
  }
}

void checkExamples({required Directory root, required List<Map<String, dynamic>> nodes}) {
  final dir = Directory('${root.path}/example');
  if (!dir.existsSync()) {
    return;
  }

  final appsOnDisk = dir
      .listSync()
      .whereType<Directory>()
      .where((d) => File('${d.path}/README.md').existsSync())
      .map((d) => 'example/${d.uri.pathSegments.where((s) => s.isNotEmpty).last}/README.md')
      .toSet();

  final pathsInGraph = nodes.where((n) => n['type'] == 'example').map((n) => n['path'] as String).toSet();

  for (final onDisk in appsOnDisk) {
    if (!pathsInGraph.contains(onDisk)) {
      warn('$onDisk has no matching "example" node in graph.json (orphan example)');
    }
  }
  for (final inGraph in pathsInGraph) {
    if (!appsOnDisk.contains(inGraph)) {
      fail('graph.json references an "example" node whose app is missing on disk: $inGraph');
    }
  }
}

void report() {
  if (errorCount == 0) {
    stdout.writeln('Knowledge base OK: no errors.');
    exit(0);
  } else {
    stderr.writeln('Knowledge base INVALID: $errorCount error(s) found.');
    exit(1);
  }
}
