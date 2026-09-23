# ADR-005: `rebuild()` as the sanctioned alias for `Cubit.emit()`

## Status
Accepted

## Context
Commit `16bce15` ("Adding rebuild method", 2025-08-31) added `void rebuild(State state) =>
emit(state);` to [[AbleCubit]] alongside `mapFStream`/`mapPStream`. Source inspection of every
`AbleCubit` subclass in the surveyed telavi_app codebase (22/22 cubits) shows `rebuild(...)`
called exclusively — `emit` is never called directly in any of them.

## Decision
State transitions in an `able`-based cubit go through `AbleCubit.rebuild(State)` — a one-line
`emit` alias — rather than calling `Cubit.emit` directly.

## Consequences
- Mainly a naming/readability convention: `rebuild(state.rebuild((b) => ...))` reads consistently,
  pairing `AbleCubit.rebuild` (sets cubit state) with the `Built` value's own `.rebuild(...)`
  (produces the next immutable state) at the same call site.
- Until 0.1.0 there was no behavioral difference from calling `emit`. Since 0.1.0 `rebuild`
  does nothing once the cubit is closed, while `emit` throws, so async work that finishes after
  its screen is gone is safe only through `rebuild`. A cubit that calls `emit` directly also
  breaks the vocabulary `rules/anti-patterns.md` #1 is written against, and makes the codebase's
  cubits look inconsistent.

## Alternatives
Not documented in the repository.

## Related Rules
- rules/cubits.md
- rules/patterns.md
- rules/anti-patterns.md (#1)

## Related Concepts
- [[AbleCubit]]
