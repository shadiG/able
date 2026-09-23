# AbleLints

## What it is
`able_lints/` — a separate Dart package in this repository (0.2.0): an analyzer plugin built on
`analysis_server_plugin` with three warning rules, `able_then_without_rebuild`,
`able_mirror_missing_take_once_false` and `able_mirror_missing_distinct`.

## Why it exists
These three mistakes are the ones reviews catch most often (the Shadig rulebook's STATE-3 and
STATE-8), and each fails silently at runtime: a dropped update, a mirror that stops updating, or
needless rebuilds. A lint catches them while typing instead of in review. See
[[ADR-008-lints-as-analyzer-plugin]] for why an analyzer plugin and not `custom_lint`.

## Where it lives
`able_lints/lib/main.dart` (plugin entry point), `able_lints/lib/src/*.dart` (one file per rule),
`able_lints/test/rules_test.dart`.

## What it depends on
Nothing in `able` at compile time: the rules match method names (`executeSF`, `mapFStream`,
`rebuild`...), not resolved types, so they are cheap and work on code that doesn't compile yet.

## What depends on it
Apps that enable it under `plugins:` in `analysis_options.yaml`; `example/country_listing` does.

## Which rules govern it
- `rules/patterns.md` item 27.
- The rules it enforces: `rules/anti-patterns.md` #1 and #4, `rules/cubits.md` (`.distinct()`).

## Which decisions affect it
- [[ADR-008-lints-as-analyzer-plugin]]

## Examples of correct usage
`rules/patterns.md` item 27; `example/country_listing/analysis_options.yaml`.

## Common mistakes
- Expecting `flutter analyze` to show its warnings: it doesn't run analyzer plugins. Use
  `dart analyze` or the IDE.
- Name-based matching has limits: a helper that wraps `rebuild` under another name makes
  `able_then_without_rebuild` report a false positive. Ignore it locally with
  `// ignore: able_then_without_rebuild`.
