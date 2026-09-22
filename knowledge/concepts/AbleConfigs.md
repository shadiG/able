# AbleConfigs (`Able.initialize` / `Able.configs`)

## What it is
`AbleConfigs` (`lib/src/common/able_config.dart`) is a singleton holding the app-wide
`loadingWidget`/`errorWidget` defaults, set once via `Able.initialize(...)` and read via
`Able.configs`. `Able.initialize` also configures the [[ExceptionHandler]] singleton
(`handleException`/`onError`) as a side effect.

## Why it exists
So every [[FetchableWidget]]/[[FetchableListWidget]] doesn't need its own `buildBusy`/`buildError`
at every call site, and so the app's crash-reporting/toast wiring for unexpected errors lives in
one place (`main()`) instead of being repeated per cubit.

## Where it lives
`lib/src/common/able_config.dart`.

## What it depends on
- [[ExceptionHandler]] — `Able.initialize` constructs/feeds it.

## What depends on it
- [[FetchableWidget]], [[FetchableListWidget]] — fall back to `Able.configs.loadingWidget`/
  `.errorWidget` when a call site omits `buildBusy`/`buildError`.

## Which rules govern it
- `rules/architecture.md` — "Global configuration (`Able`)".
- `rules/patterns.md` item 1 (bootstrapping).
- `rules/anti-patterns.md` #6 (reading `Able.configs` before `initialize()`).

## Which decisions affect it
- [[ADR-004-centralized-exception-handling]]

## Examples of correct usage
```dart
void main() {
  Able.initialize(
    loadingWidget: const Center(child: CircularProgressIndicator.adaptive()),
    handleException: (e, s, type) => logger.error('Exception trapped by Able SDK ($type)', e, s),
    onError: (e, message) => logger.error('Logic error in Able SDK: $message', e),
  );
  runApp(const MyApp());
}
```

## Common mistakes
- Calling `Able.initialize()` more than once — the second call is a silent no-op with only a
  `debugPrint` warning (easy to miss in a release build).
- Reading `Able.configs` before `initialize()` runs — throws an assertion error.

## Known defect (verified against source)
The `onError` callback passed here is, in practice, never invoked by
[[ProgressablesResultPresenter]]. See [[ExceptionHandler]] for the verified root cause. This is a
package-source defect, not a usage mistake — do not "fix" it with application-code workarounds
without first deciding (with whoever owns the `able` package) whether to patch the package itself.
