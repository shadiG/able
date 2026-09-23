# AbleConfigs (`Able.initialize` / `Able.configs`)

## What it is
`AbleConfigs` (`lib/src/common/able_config.dart`) is a singleton holding the app-wide
`loadingWidget`/`errorWidget` defaults, set once via `Able.initialize(...)` and read via
`Able.configs`. `Able.initialize` also configures the [[ExceptionHandler]] singleton
(`handleException`/`onError`) as a side effect.

Since 0.2.0 `Able.initialize` also takes an `observer:` (the static `Able.observer`, see
[[AbleObserver]]), and `Able.resetForTest()` forgets the configuration, the observer and every
exception handler, so a test can initialize again.

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

## Fixed defect (0.1.0)
Before 0.1.0 the `onError` callback passed here was never invoked, because every bare
`ExceptionHandler()` call cleared it. Fixed; see [[ExceptionHandler]] for the history.
