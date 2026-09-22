# ADR-002: `Fetchable<D>` and `Progressable` as two separate types

## Status
Accepted

## Context
`README.md`: "The `Progressable` class is similar to `Fetchable` but is used to represent
operations that do not have any resulting data... Unlike `Fetchable`, the success state of
`Progressable` does not contain any data." Both types have been maintained as parallel hierarchies
since early in the package's history (separate `combine2F..9F` / `combine2P..9P` families,
separate widgets for `Fetchable` but not `Progressable` — see Related Concepts).

## Decision
Model "a value that must be fetched" (`Fetchable<D>`) and "an action with no result" (`Progressable`)
as two distinct type hierarchies sharing [[AbleState]], rather than a single generic type (e.g. a
`Fetchable<void>` for actions), with explicit conversions (`Fetchable.asProgressable()`,
`Progressable.asFetchable<D>(data)`) at the boundary between them.

## Consequences
- No nullable-payload ambiguity: a `Progressable` success case can never be confused with a
  `Fetchable<D?>` success case holding a `null` payload.
- Two parallel combinator families (`combine2F`..`combine9F`, `combine2P`..`combine9P`) and two
  parallel sets of list-aggregate extensions (`allSuccess`/`anyBusy`/etc.) must be maintained --
  this is also where the [[Fetchable]]-only `combine7F`/`combine8F`/`combine9F` state-summation
  bug lives; the `Progressable` equivalents do not have it (verified against
  `progressable_utils.dart`).
- Only `Fetchable`/`Fetchable<BuiltList<D>>` have dedicated rendering widgets
  ([[FetchableWidget]]/[[FetchableListWidget]]); `Progressable` is rendered only via
  [[ProgressablesResultPresenter]]'s side-effect model, never inline — an app that needs to show a
  `Progressable`'s busy state inline typically reads `.busy` directly (see `rules/patterns.md`
  item 13's `anyBusy` pattern).

## Alternatives
Not documented in the repository. A single `Fetchable<void>` used for actions is the natural
alternative but no commit or comment explains why it was rejected in favor of a second hierarchy.

## Related Rules
- rules/fetchable.md
- rules/state-management.md

## Related Concepts
- [[Fetchable]]
- [[Progressable]]
