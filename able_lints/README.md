# able_lints

An analyzer plugin that flags the three Able mistakes reviews catch most often. All three are
warnings, on by default once the plugin is enabled.

| Rule | Flags |
|---|---|
| `able_then_without_rebuild` | A `then:` that builds a state with `state.rebuild(...)` but never passes it to the cubit's `rebuild(...)`, so the update is dropped. |
| `able_mirror_missing_take_once_false` | An `executeSF`/`executeSP` that mirrors another cubit's `mapFStream`/`mapPStream` into this cubit's state without `takeOnce: false`, so it stops after the first success. |
| `able_mirror_missing_distinct` | A `mapFStream`/`mapPStream` feeding a `takeOnce: false` subscription without `.distinct()`, so every upstream change rebuilds. |

## Use it

Requires Dart 3.10 or later. In the app's `analysis_options.yaml`:

```yaml
plugins:
  able_lints:
    path: ../able/able_lints   # adjust the path, or use a git source
```

Warnings show in the IDE and in `dart analyze`. `flutter analyze` does not run analyzer plugins, so
use `dart analyze` in CI.

To turn a rule off for one line: `// ignore: able_then_without_rebuild`. To turn it off everywhere:

```yaml
plugins:
  able_lints:
    path: ../able/able_lints
    diagnostics:
      able_mirror_missing_take_once_false: false
```

## Develop

```sh
dart pub get
dart analyze
dart test
```

The rules match method names, not resolved types (see `knowledge/decisions/ADR-008-lints-as-analyzer-plugin.md`).
