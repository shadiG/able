# Knowledge graph

`graph.json` is a small, hand-maintained, Git-diffable index of `able`'s architecturally
significant entities and how they relate — not a database, not a duplicate of the source code,
and not exhaustive (no local variables, no every-method listing).

## Schema

```json
{
  "nodes": [ { "id": "...", "type": "concept|rule|decision", "name": "...", "path": "...", "summary": "..." } ],
  "edges": [ { "from": "...", "relation": "...", "to": "...", "note": "..." } ]
}
```

- `id` — kebab-case, unique, stable (referenced by other nodes' edges).
- `type` — `concept` (a `knowledge/concepts/*.md` file), `rule` (a `rules/*.md` file), or
  `decision` (a `knowledge/decisions/ADR-*.md` file).
- `path` — repo-relative path to the file this node represents.
- `relation` — one of exactly eight kinds: `uses`, `extends`, `implements`, `depends_on`,
  `used_by`, `governed_by`, `documented_by`, `decided_by`. No other relation string is valid — see
  `../../tool/validate_knowledge.dart`.

## Relation conventions used in this graph

- `depends_on` — a compile-time/type-level dependency (an import or generic bound needed to
  build).
- `uses` — a runtime/call-site relationship that isn't a type dependency (e.g. a widget reading
  `Able.configs` inside `build()`).
- `extends` — a literal Dart `extends` relationship.
- `used_by` — the inverse of adoption: a value type being used as the declared type of fields in
  a convention/role, without that role being a compile-time dependency of the package itself.
- `governed_by` — a rule file is normative for this concept (MUST/SHOULD/MUST NOT language
  applies).
- `documented_by` — a rule file explains this concept descriptively, without necessarily stating
  a strict rule (used for the [[BusinessCubit]]/[[ViewCubit]] conventions, which are observed
  patterns, not enforced rules).
- `decided_by` — an ADR explains why this concept is shaped the way it is.
- `implements` — reserved for a literal Dart `implements` relationship; unused in the current
  graph because none of the catalogued concepts implement an interface at the package level.

## How to query it without tooling

It's plain JSON — `grep`/`jq` it directly:

```bash
# What governs Fetchable?
jq '.edges[] | select(.from == "fetchable" and .relation == "governed_by")' knowledge/graph/graph.json

# What depends on AbleCubit?
jq '.edges[] | select(.to == "able-cubit" and .relation == "depends_on")' knowledge/graph/graph.json
```

## Keeping it honest

Every edge here must be traceable to something actually true of the current code or an existing
rule/ADR file — not an assumption about how the architecture "should" work. If you add an edge,
you should be able to point at the line of code, rule prose, or ADR that justifies it. Run
`dart run tool/validate_knowledge.dart` after editing this file or adding/removing a
concept/rule/ADR.
