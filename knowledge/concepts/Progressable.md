# Progressable

## What it is
An immutable value type representing "an operation that runs asynchronously, may succeed or fail,
but produces no result payload." Same four-case shape as [[Fetchable]] (idle/busy/success/error),
minus the `data` field. Concrete subclasses: `IdleProgressable`, `BusyProgressable`,
`SuccessProgressable`, `ErrorProgressable`.

## Why it exists
Not every async operation returns a value worth modeling as a `Fetchable<D>` — save, delete,
sign-in, launch-an-external-app. `Progressable` gives those the same busy/error vocabulary,
combinators, and widget support as `Fetchable`, without forcing a `Fetchable<void>` with an
always-unused payload. See [[ADR-002-separate-fetchable-progressable-types]].

## Where it lives
`lib/src/progressable/progressable.dart` (type hierarchy, `toProgressable`) and
`lib/src/progressable/progressable_utils.dart` (extension getters, `futureAsProgressable`,
`combine2P`..`combine9P` and their `*Streams` counterparts; `emptyP` is re-exported via
`lib/src/common/able_utils.dart`).

## What it depends on
- [[AbleState]] — `.state` getter, used by combinators.

## What depends on it
- [[AbleCubit]] — `executeP`/`executeSP`/`mapPStream`, `doIf`, `.asFuture()`.
- [[ProgressablesResultPresenter]] — exists specifically to render one-shot success/error
  transitions of `Progressable` fields.
- Every business/view cubit field suffixed `P` by convention.
- [[Fetchable]] — via `.asProgressable()`/`.asFetchable(data)` conversions in both directions.
- [[BusinessCubit]], [[ViewCubit]] conventions.

## Which rules govern it
- `rules/fetchable.md` — covers `Progressable`'s full API alongside `Fetchable`'s.
- `rules/state-management.md` — the four-state model and `P`-suffix naming convention.
- `rules/patterns.md` items 7, 13, 14, 15.
- `rules/anti-patterns.md` #2, #5, #8.

## Which decisions affect it
- [[ADR-001-stream-based-async-state]]
- [[ADR-002-separate-fetchable-progressable-types]]
- [[ADR-003-dynamic-typed-errors]]

## Examples of correct usage
See `rules/patterns.md` items 2, 7, 13, 15.

## Common mistakes
See `rules/anti-patterns.md` #5 (`BlocListener` vs `ProgressablesResultPresenter`, and the
clarified exception) and #8 (treating every error as unexpected instead of using
`isExpectedError`).

Unlike `combine7F`/`combine8F`/`combine9F` (see [[Fetchable]]), `combine7P`/`combine8P`/
`combine9P` do **not** have the missing-state-term bug — verified directly against
`lib/src/progressable/progressable_utils.dart`, where every `combineNP` sums all `N` state terms
correctly.
