# Fetchable<D>

## What it is
An immutable value type representing "a value that must be fetched/computed asynchronously and may
be idle, busy, successful (carrying data of type `D`), or failed (carrying a `dynamic` exception)."
Concrete subclasses: `IdleFetchable<D>`, `BusyFetchable<D>`, `SuccessFetchable<D>`,
`ErrorFetchable<D>`.

## Why it exists
To eliminate hand-rolled `isLoading`/`error`/`data` field triples on cubit state (see
`rules/anti-patterns.md` #2) by giving every "has a result" piece of async state one field of one
type, with structural equality, combinators, and dedicated widgets.

## Where it lives
`lib/src/fetchable/fetchable.dart` (the type hierarchy) and
`lib/src/fetchable/fetchable_utils.dart` (extension getters, `futureAsFetchable`/
`streamAsFetchable`, `combine2F`..`combine9F` and their `*Streams` counterparts).

## What it depends on
- [[AbleState]] — `.state` getter, used by combinators.

## What depends on it
- [[AbleCubit]] — `executeF`/`executeSF`/`mapFStream`, and the `.asFuture()` extension.
- [[FetchableWidget]], [[FetchableListWidget]] — render a `Fetchable`/`Fetchable<BuiltList<D>>`.
- [[ProgressablesResultPresenter]] — indirectly, via `.asProgressable()` conversions consuming
  apps use to feed a `Fetchable`-derived value into a `Progressable` field.
- Every business/view cubit field suffixed `F` by convention (see `rules/state-management.md`
  "Naming convention for state fields").
- [[BusinessCubit]], [[ViewCubit]] conventions.

## Which rules govern it
- `rules/fetchable.md` — full API reference, including the documented `combine7F`/`combine8F`/
  `combine9F` state-summation bug.
- `rules/state-management.md` — the four-state model and field-naming convention.
- `rules/patterns.md` items 11, 12, 14 — deriving fields, widget-level combining,
  `value.asFetchable()` as the everyday setter.
- `rules/anti-patterns.md` #2, #3, #9.

## Which decisions affect it
- [[ADR-001-stream-based-async-state]] — why async state is a value type carried over a `Stream`.
- [[ADR-002-separate-fetchable-progressable-types]] — why `Fetchable` and `Progressable` are two
  types rather than one.
- [[ADR-003-dynamic-typed-errors]] — why `.error`/`exception` is `dynamic`.

## Examples of correct usage
See `rules/patterns.md` items 2, 5, 11, 12, 14.

## Common mistakes
See `rules/anti-patterns.md` #2 (hand-rolled loading/error/data fields), #3 (branching on the
concrete subclass), #7 (trusting `combine7F`/`combine8F`/`combine9F`'s combined state exactly —
verified against `lib/src/fetchable/fetchable_utils.dart`: `combine7F`'s `state:` expression sums
`f1..f5` and `f7` but omits `f6.state`; `combine8F`/`combine9F` have the same omission).
