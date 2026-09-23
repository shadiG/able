# `Fetchable<D>` and `Progressable`

These are the two value types every piece of async state in an `able`-based app is expressed as.
Both live under `lib/src/fetchable/` and `lib/src/progressable/` and share the same four-case
shape described in [[state-management]].

## `Fetchable<D>` — a value with a result

```dart
abstract class Fetchable<D> {
  factory Fetchable.idle();
  factory Fetchable.success(D data);
  factory Fetchable.busy();
  factory Fetchable.error(dynamic exception);
}
```

Concrete subclasses: `IdleFetchable<D>`, `BusyFetchable<D>`, `SuccessFetchable<D>` (holds `data`),
`ErrorFetchable<D>` (holds `exception`). Use `Fetchable<T>` for anything that produces a result:
a list of contacts, a user profile, a computed value.

### Instance API

- `.state` → `AbleState`.
- `.toBusy()` → new `BusyFetchable<D>` (used when re-triggering a fetch while keeping the type).
- `.asProgressable()` → drops the payload, same state (error case carries the same exception).
- `.mapSuccess<ND>(ND Function(D) mapper)` → maps only the success payload; other states pass
  through unchanged. Use this instead of unwrapping `.data` and rewrapping by hand.
- `.cast<ND>()` → unsafe payload cast (`as ND`), for when you know the runtime type matches.
- Extension getters (`fetchable_utils.dart`): `.success`, `.hasError`, `.idle`, `.busy`,
  `.idleOrBusy`, `.data` (throws `StateError` off-success), `.dataOrNull`, `.error`.

### Building one from a `Future`/`Stream`

```dart
Stream<Fetchable<D>> futureAsFetchable<D>(Future<D> Function() func); // yields busy, then success
Stream<Fetchable<D>> streamAsFetchable<D>(Stream<D> Function() func); // yields busy, then success per event
```

Both yield `Fetchable.busy()` immediately, then map the underlying result(s) to
`Fetchable.success(...)`. Neither catches errors — an exception thrown inside `func` propagates
as a **stream error**, which is exactly what `presentF`/`executeF` (see [[cubits]]) expect: they
catch it there and convert it to `Fetchable.error(e)` at the boundary.

### Combining several `Fetchable`s

`combine2F`..`combine9F` (values) and `combine2FStreams`..`combine9FStreams` (streams, via
`rxdart`'s `CombineLatestStream`) merge `Fetchable<T1>..Fetchable<Tn>` into
`Fetchable<(T1, ..., Tn)>` — a Dart record. Success only when **every** input is success; overall
`AbleState` is `f1.state + f2.state + ... ` (error beats idle beats busy beats success, see
[[state-management]]); the first non-null `.error` among the inputs is used.

> **Fixed in 0.1.0:** `combine7F`, `combine8F` and `combine9F` used to leave `f6.state` out of
> the combined state, so the result could read `success` while the 6th input was still busy. They
> now sum every input (regression test: `test/regression_test.dart`).

### Deriving a dependent fetch

`Stream<Fetchable<T>>.flatMapOnSuccessF<S>(Stream<Fetchable<S>> Function(T) mapper)` — only calls
`mapper` once the source reaches success, passing through idle/busy/error otherwise (cast via
`.cast<S>()`). Every inner stream runs to completion, even after a newer upstream value.

`switchMapOnSuccessF<S>` (0.1.0) is the same, except a new upstream value cancels the previous
inner stream, so a slow result for an old input can't overwrite a newer one. Use it for derived
values such as search results. Don't use it when the result is written back into the source
stream (a cubit reading its own field and rebuilding it): the write-back cancels the inner stream
before it finishes. `flatMapOnSuccessFToProgressable<S>` does the same but the dependent stream is a
`Progressable`.

## `Progressable` — an action with no result

```dart
abstract class Progressable {
  factory Progressable.idle();
  factory Progressable.success();
  factory Progressable.busy();
  factory Progressable.error(dynamic exception);
}
```

Same four states, same `.state`/`.success`/`.hasError`/`.idle`/`.busy`/`.idleOrBusy`/`.error`
getters, plus `.successOrIdle`. Use `Progressable` for save/delete/sign-in/launch actions — cases
where a screen needs to know "busy vs. done vs. failed" but there's no payload to render.

- `.toBusy()` → new `BusyProgressable`.
- `.asFetchable<D>(data)` → promotes to `Fetchable<D>`, attaching `data` only on the success case.

### Building one from a `Future`

```dart
Stream<Progressable> futureAsProgressable(Future Function() func); // yields busy, then success
```

Same error-propagates-as-stream-error contract as `futureAsFetchable`. `able_utils.dart` also
exposes `emptyP` — a ready-made `Stream<Progressable>` that resolves immediately
(`futureAsProgressable(() async => null)`) — handy as a stub `elseP` in `AbleCubit.doIf`, or a
placeholder dependency in tests. It is a getter that returns a new stream on every read (before
0.1.0 it was one shared stream and threw on its second listen).

### Combining several `Progressable`s

`combine2P`..`combine9P` and `*PStreams` mirror the `Fetchable` combinators, minus the payload
tuple — overall state via `AbleState.+`, first error wins.

### Extension helpers

- `T Function().asProgressable()` / `T Function().asFetchable()` — wrap a plain closure and call
  it when the stream is listened to. (Before 0.1.0, `asProgressable` never called the closure.)
- `Future<T>.asProgressable()` / `Future<T>.asFetchable()` — wrap an existing `Future`.
- `Stream<Progressable>.flatMapOnSuccessP(AbleCubit cubit, Stream<Progressable> Function() mapper)`
  — chain a second action after the first succeeds, both as one combined `Progressable` stream.
- `List<Fetchable>`/`List<Progressable>` boolean aggregates — see [[state-management]].

Both types implement structural `==`/`hashCode`/`toString()` by hand, so
`Fetchable.success(x) == Fetchable.success(x)` holds when `x == x` — regardless of the type
argument since 0.1.0, so `Fetchable<int?>.success(null) == Fetchable<Null>.success(null)`, and printing a `Fetchable` in
logs (`'Fetchable(Success) : $data'`) is safe to leave in for debugging.

## Related knowledge

- Concepts: [[Fetchable]], [[Progressable]], [[AbleState]]
- Decisions: [[ADR-001-stream-based-async-state]], [[ADR-002-separate-fetchable-progressable-types]],
  [[ADR-003-dynamic-typed-errors]]
- Graph: `knowledge/graph/graph.json` (node `rule-fetchable`)