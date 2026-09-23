# AbleState

## What it is
`enum AbleState { idle, busy, success, error }` plus an `AbleState operator +` combinator
(`lib/src/common/able_state.dart`). It is the four-case lifecycle shared by both async-state types
in the package.

## Why it exists
`Fetchable<D>` and `Progressable` both need the same "has this operation started / is it running /
did it finish / did it fail" vocabulary. Centralizing it in one enum — rather than each type
declaring its own — is what lets `combineNF`/`combineNP` merge states with the same `+` rule, and
what lets `.idle`/`.busy`/`.success`/`.hasError`/`.idleOrBusy` extension getters exist once and
apply to both types.

## Where it lives
`lib/src/common/able_state.dart` — the enum and its `+` operator extension. No Flutter import;
pure Dart.

## What it depends on
Nothing — this is the package's most primitive type.

## What depends on it
- [[Fetchable]] — `Fetchable.state` returns an `AbleState`.
- [[Progressable]] — same.
- `combine2F..combine9F`/`combine2P..combine9P` — combine several states via `AbleState.+`.

## Which rules govern it
- `rules/state-management.md` ("The four-state model" section) — the authoritative description of
  what each case means and how `+` orders them (error beats idle beats busy beats success, since 0.1.0 — see
  [[ADR-006-errors-win-when-combining]]).

## Which decisions affect it
- [[ADR-006-errors-win-when-combining]] — why an error takes precedence in `+`.
- See [[Fetchable]] and [[Progressable]] for the decisions built on top of it.

## Examples of correct usage
```dart
if (fetchable.hasError) { ... }        // prefer this
final combined = f1.state + f2.state;  // error beats idle beats busy beats success
```

## Common mistakes
Branching on `AbleState` values by hand instead of the `.idle`/`.busy`/`.success`/`.hasError`
extension getters — the same reasoning as `rules/anti-patterns.md` #3 (which targets branching on
the concrete `Fetchable` subclass instead of its getters).
