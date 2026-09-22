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
Documented usage mistakes are covered by `rules/anti-patterns.md` #6 and #8. The rest of this
document is a **verified package defect**, not a usage mistake — surfaced here because the
knowledge base's job is to report contradictions between documented behavior and actual code
rather than silently normalize them.

## Known defect 1 — `.onError` is effectively dead code

`ExceptionHandler`'s factory constructor is:

```dart
factory ExceptionHandler({OnError? onError}) {
  _handler.onError = onError;
  return _handler;
}
```

This unconditionally overwrites `_handler.onError`, including when called with no argument --
`ExceptionHandler()` (bare) always sets `.onError = null` as a side effect of merely obtaining the
singleton instance. Every call site other than `Able.initialize` calls `ExceptionHandler()` bare:
`AbleCubit.presentF`/`presentP`'s error branch (`ExceptionHandler().handleException(...)`) and
`ProgressablesResultPresenter._handleCubitStateChanges` (`ExceptionHandler().onError?.call(...)`)
both do this. Traced through the actual call order:

1. `Able.initialize(onError: myOnError)` sets `.onError = myOnError` correctly — the only call
   site that passes a non-null `onError`.
2. The first unexpected error anywhere in the app reaches `presentF`/`presentP`'s error branch,
   which calls `ExceptionHandler().handleException(...)` — the bare `ExceptionHandler()` call
   resets `.onError` to `null` before `handleException` even runs.
3. `ProgressablesResultPresenter` later reads `ExceptionHandler().onError?.call(...)` for the same
   error — but this read is itself a bare `ExceptionHandler()` call, so it resets `.onError` to
   `null` again immediately before reading the (already-null) field.

Net effect: the `onError` callback configured via `Able.initialize` is not reachable in practice.
`rules/patterns.md`'s claim that "`onError` is what `ProgressablesResultPresenter` calls for
errors not marked `shouldIgnoreMessage`" describes the intended design, not the actual runtime
behavior. `handleException`/`isExpectedError`/`shouldIgnoreMessage` are unaffected — they don't
depend on `.onError` — so this defect is narrow but real.

This is a genuine source contradiction, not a documentation error to quietly fix by rewording the
rule. The rule accurately describes the intended architecture; the code doesn't implement it.
Resolving it means either patching `ExceptionHandler`'s factory (e.g. only assign when
`onError != null`) or providing a separate setter — a decision for whoever owns the `able`
package, not something this knowledge base silently papers over.

## Known defect 2 — `presentP` mistags errors as `AbleType.fetchable`

In `lib/src/utils/able_cubit.dart`, `Stream<Progressable>.presentP`'s error branch calls:

```dart
ExceptionHandler().handleException(e, s, AbleType.fetchable);
```

This should be `AbleType.progressable` — `presentF`'s equivalent line correctly passes
`AbleType.fetchable`, but `presentP` copies the same literal instead of `AbleType.progressable`.
Consequence: any `handleException` subscriber that branches on `type` (e.g. to log
"Exception trapped by Able SDK ($type)", as telavi_app's `main.dart` does) always sees
`AbleType.fetchable`, even for errors that originated from a `Progressable` stream.
