# ADR-001: Represent async state as immutable value types carried over `Stream`s

## Status
Accepted

## Context
The package's very first commit (`7ae2739`, "a flutter package to manage states using stream")
states the founding intent directly in its message. `README.md` explains the specific rationale
for `Stream` over `Future`: "Error handling is performed at the end of the data flow, where
results are subscribed to. This approach allows for taking advantage of `Stream` error handling
operators." `futureAsFetchable`/`futureAsProgressable` (`lib/src/fetchable/fetchable_utils.dart`,
`lib/src/progressable/progressable_utils.dart`) both carry the comment `// errors are processed by
a stream` at the point where they deliberately do not catch exceptions thrown by the wrapped
`Future`.

## Decision
Every piece of async state is represented as an immutable value ([[Fetchable]]/[[Progressable]]),
produced as `Stream<Fetchable<D>>`/`Stream<Progressable>` by `futureAsFetchable`/
`futureAsProgressable`/`streamAsFetchable`, and consumed by [[AbleCubit]]'s `executeF`/`executeSF`/
`executeP`/`executeSP`, which catch stream errors at that single boundary and convert them to
`Fetchable.error`/`Progressable.error`.

## Consequences
- A uniform vocabulary (idle/busy/success/error) applies to every async operation in an app built
  on `able` — see `rules/state-management.md`.
- Error handling is centralized at the `presentF`/`presentP` boundary rather than scattered across
  `try`/`catch` blocks at each call site.
- Requires the whole codebase to adopt `able`'s vocabulary rather than mixing it with raw
  `Future`/`try`-`catch` patterns — deviating from it is the subject of `rules/anti-patterns.md`
  #2.
- Depends on `rxdart` for stream combinators (`CombineLatestStream`, `takeWhileInclusive`) used
  throughout `fetchable_utils.dart`/`progressable_utils.dart`/`able_cubit.dart`.

## Alternatives
Not documented in the repository. No commit or comment records what was considered and rejected
(e.g. a `Future`-only API, or bare `try`/`catch` per cubit method) before this design.

## Related Rules
- rules/state-management.md
- rules/fetchable.md
- rules/cubits.md

## Related Concepts
- [[Fetchable]]
- [[Progressable]]
- [[AbleCubit]]
