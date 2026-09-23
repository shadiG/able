# ADR-008: Lints ship as an `analysis_server_plugin` package

## Status
Accepted (0.2.0).

## Context
Three recurring mistakes (a `then:` that never calls `rebuild`, a live mirror without
`takeOnce: false`, a mirror without `.distinct()`) fail silently at runtime, so they were caught
only in review. The two ways to add custom lints are `custom_lint` (a community package) and the
official analyzer plugin API, `analysis_server_plugin`, available from Dart 3.10. When this was
built (Dart 3.13, analyzer 14), `custom_lint_builder` could not be resolved together with
`analysis_server_plugin`: they need incompatible `analyzer_plugin` versions.

## Decision
The lints live in `able_lints/`, a separate package built on `analysis_server_plugin`, registered as
warning rules (on by default once the plugin is enabled). The rules match on method names rather
than resolved types. They are tested with `analyzer_testing`.

## Consequences
- Warnings appear in the IDE and in `dart analyze`. `flutter analyze` does not run analyzer
  plugins, so CI runs `dart analyze` for apps that use it.
- Name-based matching is fast and works on incomplete code, but can misfire on unrelated methods
  with the same names; each rule can be silenced per line or turned off in
  `analysis_options.yaml`.
- Requires Dart 3.10+ in apps that enable it; `able` itself keeps its lower constraint.

## Alternatives
- `custom_lint`: rejected, because of the dependency conflict above and because it runs in its own
  isolate outside the analysis server.
- No lints, rules only: rejected; these mistakes already had rules and still reached review.

## Related Rules
- rules/patterns.md (item 27)
- rules/anti-patterns.md (#1, #4)
- rules/cubits.md

## Related Concepts
- [[AbleLints]]
