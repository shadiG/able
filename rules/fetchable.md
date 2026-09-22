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
`AbleState` is `f1.state + f2.state + ... ` (idle beats busy beats error beats success, see
[[state-management]]); the first non-null `.error` among the inputs is used.

> **Known bug to be aware of** (`fetchable_utils.dart`): `combine7F`, `combine8F`, and `combine9F`
> omit `f6.state` (and `combine8F`/`combine9F` also omit further terms) from the `state:`
> expression they pass to `toFetchable` — e.g. `combine7F`'s state sum is
> `f1.state + f2.state + f3.state + f4.state + f5.state + f7.state` (no `f6.state`). In practice
> this only matters when `f6` is the *sole* non-success input among 7–9 combined values (e.g. only
> `f6` is `busy` while the rest are `success`) — the combined result can read `success` one tick
> early. Prefer nesting `combine2F`/`combine3F` calls, or combine fewer than 7 at once, if this
> edge case matters for a given screen.

### Deriving a dependent fetch

`Stream<Fetchable<T>>.flatMapOnSuccessF<S>(Stream<Fetchable<S>> Function(T) mapper)` — only calls
`mapper` once the source reaches success, passing through idle/busy/error otherwise (cast via
`.cast<S>()`). `flatMapOnSuccessFToProgressable<S>` does the same but the dependent stream is a
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
placeholder dependency in tests.

### Combining several `Progressable`s

`combine2P`..`combine9P` and `*PStreams` mirror the `Fetchable` combinators, minus the payload
tuple — overall state via `AbleState.+`, first error wins. (These do not have the missing-term bug
described above; only the `Fetchable` combine7F/8F/9F functions are affected.)

### Extension helpers

- `T Function().asProgressable()` / `T Function().asFetchable()` — wrap a plain closure.
- `Future<T>.asProgressable()` / `Future<T>.asFetchable()` — wrap an existing `Future`.
- `Stream<Progressable>.flatMapOnSuccessP(AbleCubit cubit, Stream<Progressable> Function() mapper)`
  — chain a second action after the first succeeds, both as one combined `Progressable` stream.
- `List<Fetchable>`/`List<Progressable>` boolean aggregates — see [[state-management]].

Both types implement structural `==`/`hashCode`/`toString()` by hand, so
`Fetchable.success(x) == Fetchable.success(x)` holds when `x == x`, and printing a `Fetchable` in
logs (`'Fetchable(Success) : $data'`) is safe to leave in for debugging.

## Related knowledge

- Concepts: [[Fetchable]], [[Progressable]], [[AbleState]]
- Decisions: [[ADR-001-stream-based-async-state]], [[ADR-002-separate-fetchable-progressable-types]],
  [[ADR-003-dynamic-typed-errors]]
- Graph: `knowledge/graph/graph.json` (node `rule-fetchable`)