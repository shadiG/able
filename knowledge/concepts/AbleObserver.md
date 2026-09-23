# AbleObserver

## What it is
`AbleObserver` (`lib/src/common/able_observer.dart`, 0.2.0) — an app-wide hook with two callbacks:
`onRebuild(cubit, previous, next)`, called by [[AbleCubit]]'s `rebuild` when the state changes,
and `onError(cubit, error, stackTrace, type, expected:)`, called by `presentF`/`presentP` for every
`execute*` failure. Set with `Able.initialize(observer:)` or `Able.observer = ...`.

## Why it exists
Logging, analytics and crash reporting used to need either a line in every cubit or bloc's generic
`BlocObserver`, which knows nothing about Able's errors or whether they were expected. Unlike
[[ExceptionHandler]]'s `handleException`, `onError` also sees expected errors (flagged
`expected: true`) and knows which cubit failed.

## Where it lives
`lib/src/common/able_observer.dart`; the static `Able.observer` in `able_config.dart`.

## What it depends on
- [[AbleCubit]] — the cubit passed to each callback.

## What depends on it
- [[AbleCubit]] — `rebuild` and `presentF`/`presentP` call it.
- [[AbleConfigs]] — `Able.initialize(observer:)` sets it; `Able.resetForTest` clears it.

## Which rules govern it
- `rules/patterns.md` item 26.
- `rules/cubits.md` (what `rebuild` reports).

## Which decisions affect it
- [[ADR-004-centralized-exception-handling]] — the observer complements, not replaces, the
  centralized `handleException`.

## Examples of correct usage
`rules/patterns.md` item 26; `test/features_test.dart`, group `observer`.

## Common mistakes
- Doing slow work in `onRebuild`: it runs synchronously on every state change of every cubit.
- Reporting `expected: true` errors as crashes.
