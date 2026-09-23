# State management

`able`'s state-management model has one rule: **a cubit's state never holds a raw
loading/error/data trio — every piece of async state is a `Fetchable<D>` (has a result) or a
`Progressable` (fire-and-forget action), and state is only ever replaced wholesale, never
mutated.**

## The four-state model

Both `Fetchable<D>` and `Progressable` are built on the same `AbleState` enum:

```dart
enum AbleState { idle, busy, success, error }
```

- **idle** — nothing has been requested yet (the initial value of every field).
- **busy** — a `Future`/`Stream` is in flight.
- **success** — completed; `Fetchable` carries `data`, `Progressable` carries nothing.
- **error** — completed with an exception; both carry `.error` (`dynamic`).

`AbleState` has a `+` operator (`able_state.dart`) used to combine multiple states when several
`Fetchable`/`Progressable`s are merged (see the `combineNF`/`combineNP` family): error beats
everything, then idle, then busy, then success. So an error in any input shows at once, even while
another input is still loading, and a field that is still `idle` yields an overall `idle` result,
not a partial `success`. (Before 0.1.0, idle and busy beat error, which hid a failure until every
other input finished — see [[ADR-006-errors-win-when-combining]].)

`Fetchable.error(null)` and `Progressable.error(null)` are valid error states: widgets and
combinators check `.hasError`, never `.error != null`.

## Immutability

`Fetchable`/`Progressable` instances are immutable value classes (`IdleFetchable`,
`BusyFetchable`, `SuccessFetchable`, `ErrorFetchable`, and the `Progressable` equivalents), with
structural `==`/`hashCode`/`toString()` implemented by hand (state + payload). A cubit's `State`
class should itself be an immutable `Built` value (see [[cubits]]) so that every state transition
produces a brand-new object rather than patching fields in place.

## Reading state

Never branch on `is IdleFetchable` etc. from outside the package — use the extension getters:

```dart
fetchable.idle       // AbleState.idle
fetchable.busy
fetchable.success
fetchable.hasError
fetchable.idleOrBusy
fetchable.data        // throws StateError unless success
fetchable.dataOrNull  // null unless success
fetchable.error       // null unless error
```

`Progressable` has the same getters plus `successOrIdle`.

## Deriving one state from many

- `combine2F`…`combine9F` and their `*FStreams` counterparts merge `Fetchable<T1>..Fetchable<Tn>`
  into `Fetchable<(T1, ..., Tn)>` (a Dart record) — success only when every input is success,
  state combined via `AbleState.+`, first non-null error wins.
- `combine2P`…`combine9P` (+ `*PStreams`) do the same for `Progressable`, with no payload.
- List helpers on `List<Fetchable>`/`List<Progressable>` (`able_utils.dart`): `allSuccess`,
  `anySuccess`, `allFailure`, `anyFailure`, `allIdle`, `anyIdle`, `allIdleOrBusy`,
  `anyIdleOrBusy`, plus `allBusy`/`anyBusy` for `Progressable` — use these instead of manually
  `.every`/`.any`-ing over `.success`/`.busy` at call sites (e.g. `[a, b].anyBusy` to block a
  screen behind a `CoverStack` while either of two actions runs).

## Converting between the two

- `fetchable.asProgressable()` drops the payload, keeping idle/busy/error, mapping success to
  `SuccessProgressable`.
- `progressable.asFetchable<D>(data)` does the reverse — you must supply the payload to attach
  on success.
- `value.asFetchable()` (extension on `T`) wraps a plain value as `Fetchable.success(value)` —
  used for state fields that are "loaded" synchronously (e.g. `null.asFetchable()` for a nullable
  field that starts populated).

In practice, `value.asFetchable()`/`value.asProgressable()` are the most common way a `Fetchable`/
`Progressable` field actually gets set — most business-method bodies already have a value in hand
after an `await` (a freshly sorted list, a computed bool, a value read from another field) and
just re-wrap it before `rebuild`, rather than routing every field update through
`futureAsFetchable`/`futureAsProgressable`. See [[patterns]] for concrete examples.

## Naming convention for state fields

By convention (not enforced by the package, but required by every consumer — see
[[patterns]]): a `Fetchable<T>` field is suffixed `F` (`contactsF`, `userStateF`), a
`Progressable` field is suffixed `P` (`saveContactsP`, `signInP`). This lets `mapFStream`/
`mapPStream`/`executeSF`/`executeSP` call sites read as "the F field" / "the P field" without
extra type annotations, and keeps `state.rebuild((b) => b..xF = ...)` unambiguous at a glance.

See [[fetchable]] for the full `Fetchable`/`Progressable` API and [[cubits]] for how state
transitions are driven through `AbleCubit`.

## Related knowledge

- Concepts: [[AbleState]], [[Fetchable]], [[Progressable]]
- Decisions: [[ADR-001-stream-based-async-state]], [[ADR-002-separate-fetchable-progressable-types]],
  [[ADR-006-errors-win-when-combining]]
- Graph: `knowledge/graph/graph.json` (node `rule-state-management`)