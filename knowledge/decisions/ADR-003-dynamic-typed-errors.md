# ADR-003: Error payloads are typed `dynamic`, not `Exception`/`Object`

## Status
Accepted

## Context
Commit `fa4b01d` ("replacing Exception with dynamic type", 2023-06-04) changed
`Fetchable.error(Exception exception)` / `ErrorFetchable.exception: Exception` (and the
`Progressable` equivalents, and `toFetchable`'s `exception` parameter) to `dynamic`, across
`fetchable.dart`, `fetchable_utils.dart`, `progressable.dart`, `progressable_utils.dart`, and
`able_state.dart`. This was a deliberate, project-wide change away from an earlier, more strictly
typed design — the diff shows `Exception exception` parameters and fields becoming `dynamic
exception` in one commit.

## Decision
`Fetchable.error(dynamic exception)`, `Progressable.error(dynamic exception)`, and the `.error`
getters carry `dynamic`, not `Exception` or `Object`.

## Consequences
- Any thrown value — including a plain `String`, an `Error` (not `Exception`), or a custom object
  that doesn't extend `Exception` — can be carried as an error without a wrapping step, matching
  Dart's own `throw` statement, which accepts any object.
- Loses static type-checking on what `.error` contains. Call sites that need to discriminate error
  types do so at runtime via `is SomeException` checks inside `isExpectedError`/
  `shouldIgnoreMessage` callbacks (see `rules/patterns.md` item 8, `rules/anti-patterns.md` #8) --
  there is no compile-time guarantee those checks are exhaustive or even reachable.

## Alternatives
The prior design (typed `Exception`) is directly visible in the pre-`fa4b01d` diff and was
explicitly moved away from. No further alternative (e.g. a typed `Object`, or a sealed error type)
is documented as having been considered.

## Related Rules
- rules/fetchable.md
- rules/anti-patterns.md (#8)
- rules/patterns.md (item 8)

## Related Concepts
- [[Fetchable]]
- [[Progressable]]
