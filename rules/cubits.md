# Cubits (`AbleCubit`)

`AbleCubit<State>` (`lib/src/utils/able_cubit.dart`) is a thin `Cubit<State>` subclass. Every
cubit in a consuming app extends it — never raw `Cubit` — because the execution helpers
(`executeF`/`executeP`/`executeSF`/`executeSP`) and the auto-disposing subscription list only
exist on `AbleCubit`.

## What `AbleCubit` adds over `Cubit`

```dart
class AbleCubit<State> extends Cubit<State> {
  AbleCubit(super.initialState);

  StreamSubscription closeWithCubit(StreamSubscription subscription);
  Future<void> close();                                   // disposes tracked subscriptions first

  Stream<Fetchable<T>>  mapFStream<T>(Fetchable<T> Function(State) s);
  Stream<Progressable>  mapPStream<T>(Progressable Function(State) s);

  void rebuild(State state) => emit(state);                // the only way state is set

  Stream<Progressable> doIf({
    required Stream<Progressable> ifP,
    required Stream<Fetchable<bool>> condition,
    Stream<Progressable>? elseP,
  });
}
```

- **`rebuild`** is just `emit` under a different name — call it, not `emit`, so state transitions
  read consistently across a codebase built on `able`.
- **`mapFStream`/`mapPStream`** project one field of *this* cubit's `State` into a stream other
  cubits (or widgets) can subscribe to: `stream.startWith(state).map(selector)` — note the
  `startWith(state)`, which is why a subscriber always receives the current value immediately,
  not just future emissions.
- **`closeWithCubit`** registers a `StreamSubscription` with an internal `CompositeSubscription`
  so it's cancelled automatically when the cubit is closed; `presentF`/`presentP` (below) already
  route through it, so you rarely call it directly.
- **`doIf`** runs `ifP` only when a `Fetchable<bool>` condition resolves `true`, otherwise runs
  `elseP` (or completes with no-op); it's a `Progressable`-returning helper for "do this action,
  but only if a guard condition holds."

## Turning a `Future`/`Stream` into cubit state

Two families of extension methods do the actual work, both defined in `able_cubit.dart`:

### `presentF` / `presentP` — the low-level plumbing

`Stream<Fetchable<T>>.presentF(cubit, onData, {onUnexpectedError, isExpectedError, doIf})` and the
`Progressable` equivalent `presentP` `listen()` to the stream, forward every value to `onData`,
and on a stream **error** wrap it as `Fetchable.error(e)`/`Progressable.error(e)` before calling
`onData`. If the error is not marked `isExpectedError`, it's also forwarded to
`ExceptionHandler().handleException(...)` (app-level logging/crash reporting). You will rarely
call `presentF`/`presentP` directly — reach for `executeF`/`executeP`/`executeSF`/`executeSP`.

### `executeF` / `executeSF` / `executeP` / `executeSP` — what you actually call

These are extension methods **on `AbleCubit<T>` itself** (`AbleCubitExt`), so inside a cubit
method you call them unqualified:

| Method | Input | Emits | Use for |
|---|---|---|---|
| `executeF` | `Future<SP> Function()` | `Stream<Fetchable<SP>>` | one-shot fetch |
| `executeSF` | `Stream<Fetchable<SP>>` | same | subscribing to another cubit's `Fetchable` stream, or a stream-based fetch |
| `executeP` | `Future Function()` | `Stream<Progressable>` | one-shot action (save, delete, sign-in) |
| `executeSP` | `Stream<Progressable>` | same | subscribing to/chaining a business-method's `Progressable` stream |

All four take:
- `then:` — usually `(f) => rebuild(state.rebuild((b) => b..xF = f))`. **This is the only place
  the new value actually reaches `emit`** — see [[anti-patterns]] for what happens when a `then:`
  callback builds a new state but forgets to pass it to `rebuild`.
- `onUnexpectedError:` / `isExpectedError:` — mark exceptions that shouldn't hit the app-wide
  handler (permission denied, validation failure, "not found") so they only surface as
  `Fetchable.error`/`Progressable.error` in local state, never as a toast/crash report.
- `takeOnce: true` (default) — stops listening after the first success (`takeWhileInclusive`
  under the hood); pass `takeOnce: false` for a subscription meant to live for the cubit's whole
  lifetime (e.g. mirroring another cubit's ongoing `Fetchable` stream).

`executeSP` additionally accepts `onSuccessP:` — a second `Progressable` stream to run *after*
the first succeeds, combined via `combine2PStreams` so the overall progress reflects both steps.

### `.distinct()` is load-bearing on `mapFStream`/`mapPStream` and combined streams

`mapFStream`/`mapPStream` re-map the *entire* upstream `State` on every `emit` from that cubit —
including emits that don't touch the field being selected. In practice every `mapFStream`/
`mapPStream` call that feeds a live (`takeOnce: false`) subscription or a `combineNFStreams`/
`combineNPStreams` call is followed by `.distinct()`:

```dart
executeSF(
  contactCubit.mapFStream((s) => s.contactsF).distinct(),
  then: (contactsF) => rebuild(state.rebuild((b) => b..contactsF = contactsF)),
  takeOnce: false,
);
```

Because `Fetchable`/`Progressable` implement structural `==` (see [[fetchable]]), `.distinct()`
only lets a value through when the field actually changed — otherwise this cubit would rebuild
(and any widget subscribed via `context.select` would re-render) every time the *upstream* cubit
emitted for any reason. Omitting `.distinct()` here doesn't produce as obvious a bug as missing
`takeOnce: false` does (see [[anti-patterns]]), so it's easy to skip by accident; treat it as
required whenever `mapFStream`/`mapPStream` output feeds a long-lived subscription rather than a
single `.asFuture()` read.

`doIf`/`emptyP` exist on `AbleCubit`/in `able_utils.dart` but see little real use in practice —
see [[patterns]] for the hand-written `if`/`else`-inside-`futureAsProgressable` style most
conditional flows use instead.

## One-shot reads: `.asFuture(cubit)`

`Stream<Fetchable<T>>.asFuture(cubit)` and `Stream<Progressable>.asFuture(cubit)` convert a stream
into a single `Future` that resolves on the first `success` and rejects on the first `error` —
this is how a business method awaits another cubit's field synchronously
(`await contactCubit.mapFStream((s) => s.contactsF).asFuture(this)`) or awaits its own dependent
action mid-flow (`await mapper().asFuture(cubit)` inside `flatMapOnSuccessP`).

> **Known defect** (`able_cubit.dart`, `AbleCubitFStreamExtensions.asFuture`): the subscription
> is only closed after a *success* (`takeOnceSuccess()`), so after completing the `Future` with an
> error it keeps listening. If the same field later reaches `success`, `completer.complete` runs a
> second time and throws `Bad state: Future already completed` as an uncaught error. Found while
> testing `example/country_listing` (a load that fails once, then succeeds on Retry). The fix
> belongs in `able` — stop on error as well as success, or guard with `completer.isCompleted` —
> with a regression test. See [[anti-patterns]] #10 for how to avoid it until then.

## Streams as sources, not just async values

Because `mapFStream`/`executeSF`/`asFuture` all operate on `Stream<Fetchable<T>>` rather than
`Future<Fetchable<T>>`, one cubit's derived state is naturally expressed as a live subscription to
another cubit's field — `executeSF(otherCubit.mapFStream((s) => s.xF), then: rebuild, takeOnce:
false)` keeps this cubit's state in sync with `otherCubit` for as long as both are alive, with no
manual `BlocListener`/polling required.

See [[patterns]] for the full cubit-writing recipe and [[fetchable]] for the value types these
methods produce.

## Related knowledge

- Concepts: [[AbleCubit]], [[Fetchable]], [[Progressable]], [[ExceptionHandler]]
- Decisions: [[ADR-001-stream-based-async-state]], [[ADR-004-centralized-exception-handling]],
  [[ADR-005-rebuild-alias-for-emit]]
- Graph: `knowledge/graph/graph.json` (node `rule-cubits`)