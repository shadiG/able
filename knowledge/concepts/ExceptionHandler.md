# ExceptionHandler

## What it is
`ExceptionHandler` (`lib/src/utils/exception_handler.dart`) is a singleton that (a) holds a list of
`HandleException` subscribers (`void Function(dynamic exception, StackTrace stackTrace, AbleType
type)`), invoked by `handleException(...)`, and (b) holds a single `OnError` callback (`void
Function(dynamic e, String? message)`) read as `.onError`.

## Why it exists
So [[AbleCubit]]'s `presentF`/`presentP` and [[ProgressablesResultPresenter]] have one shared place
to report *unexpected* errors (crash reporting, logging, generic toasts) without each cubit/widget
wiring its own callback. Configured once via `Able.initialize` -> [[AbleConfigs]].

## Where it lives
`lib/src/utils/exception_handler.dart`. Tagged by `AbleType` (`lib/src/common/able_type.dart`,
`enum AbleType { fetchable, progressable }`) so a `handleException` subscriber can tell which kind
of stream the error came from.

## What it depends on
Nothing (leaf utility).

## What depends on it
- [[AbleConfigs]] — `Able.initialize` constructs it and subscribes `handleException`.
- [[AbleCubit]] — `presentF`/`presentP` call `ExceptionHandler().handleException(...)` for every
  unexpected error.
- [[ProgressablesResultPresenter]] — reads `ExceptionHandler().onError` to fire a generic error
  callback for transitions not suppressed by `shouldIgnoreMessage`.

## Which rules govern it
- `rules/architecture.md` — "Global configuration (`Able`)".
- `rules/patterns.md` item 1, item 7 (batching presenters).

## Which decisions affect it
- [[ADR-004-centralized-exception-handling]]

## Examples of correct usage
Application code never constructs `ExceptionHandler` directly — it is configured exclusively
through `Able.initialize(handleException:, onError:)`.

## Common mistakes
Documented usage mistakes are covered by `rules/anti-patterns.md` #6 and #8.

## Fixed defects (history)

Both defects below were verified against source, documented here, and fixed in 0.1.0 with
regression tests in `test/regression_test.dart`. They are kept as history, per `SKILL.md`'s rule
of recording contradictions rather than quietly normalizing them.

### Defect 1 (fixed) — `.onError` was never called

The factory constructor used to be:

```dart
factory ExceptionHandler({OnError? onError}) {
  _handler.onError = onError;
  return _handler;
}
```

It overwrote `.onError` even when called with no argument, and every call site other than
`Able.initialize` calls `ExceptionHandler()` bare (`presentF`/`presentP`'s error branch and
`ProgressablesResultPresenter`). So the first unexpected error cleared the callback before it was
ever read, and the `onError` passed to `Able.initialize` was never invoked.

**Fix:** the factory now only assigns `onError` when one is passed.

### Defect 2 (fixed) — `presentP` tagged errors `AbleType.fetchable`

`Stream<Progressable>.presentP` copied `presentF`'s `AbleType.fetchable` literal, so any
`handleException` subscriber branching on `type` saw the wrong tag for `Progressable` errors.

**Fix:** `presentP` passes `AbleType.progressable`. `AbleType` is now exported from
`package:able/able.dart`; before, a `handleException` callback could receive it but could not
name the type.
