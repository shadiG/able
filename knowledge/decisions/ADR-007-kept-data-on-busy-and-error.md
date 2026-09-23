# ADR-007: Busy and error `Fetchable`s can keep earlier data

## Status
Accepted (0.2.0).

## Context
A reload set a loaded field to `Fetchable.busy()`, which dropped the data, so every refresh
blanked the screen behind a spinner. Apps worked around it by keeping a second field with the last
good value, or by not showing the reload at all. Pagination had the same need in a stronger form:
while page 3 loads, pages 1 and 2 must stay on screen. Both were raised as improvements in the
0.1.0 review of this package.

## Decision
`BusyFetchable` and `ErrorFetchable` carry an optional copy of the last success data (a private
`_Latest<D>` wrapper, so a kept `null` differs from nothing kept). It is set with `toRefreshing()`
and `keepingDataOf(previous)` and read with `latestData`/`latestDataOrNull`/`hasLatestData`;
`refreshing` means busy with kept data. The four states and `.data` are unchanged: `.data` still
only works on success.

## Consequences
- No new state: code that switches on `idle`/`busy`/`success`/`error` keeps working, and
  `AbleState +` is unchanged.
- The Able widgets render kept data while busy by default (`showLatestDataWhileBusy`), which
  changes nothing for apps that never keep data.
- Kept data is part of `==`, so `.distinct()` sees a refresh that keeps different data as a change.
- Combinators do not carry kept data: a derived field keeps its own with `keepingDataOf` in its
  `then:` (rules/patterns.md item 21).

## Alternatives
- A fifth `refreshing` state: rejected, because it would break every exhaustive branch on the
  four states, `AbleState +`, and the `combine*` functions.
- A separate "previous value" field next to each `Fetchable`: rejected; it is the hand-rolled
  pairing `able` exists to remove.

## Related Rules
- rules/fetchable.md
- rules/patterns.md (items 21, 22)
- rules/anti-patterns.md (#11)

## Related Concepts
- [[Fetchable]]
- [[Paging]]
- [[FetchableWidget]]
- [[FetchableListWidget]]
