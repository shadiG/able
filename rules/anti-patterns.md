# Anti-patterns

Concrete mistakes seen (or easy to make) with `able`, and why they matter. See [[patterns]] for
the corresponding correct recipe and [[cubits]]/[[fetchable]] for the APIs referenced.

## 1. `then:` that builds state but never calls `rebuild`

```dart
// WRONG — silently drops the update
executeF(
  () => repository.fetchAll(),
  then: (contactsF) => state.rebuild((b) => b..contactsF = contactsF),
);
```

`state.rebuild(...)` returns a **new** `State` object — it does not mutate anything and does not
emit. If the `then:` callback doesn't pass that value into `this.rebuild(...)` (the `AbleCubit`
method, i.e. `emit`), the new state is computed and discarded. The symptom is a screen stuck on
`busy` or on stale data with no error and no crash — easy to miss in review. Always:

```dart
then: (contactsF) => rebuild(state.rebuild((b) => b..contactsF = contactsF)),
```

## 2. Hand-rolled loading/error/data fields instead of `Fetchable`/`Progressable`

```dart
// WRONG
class ContactState {
  final bool isLoading;
  final String? error;
  final List<Contact>? contacts;
}
```

This reintroduces the exact bug class `able` exists to prevent — invalid combinations
(`isLoading: true` with a non-null `error`), no shared vocabulary with `combineNF`/`anyBusy`/
`FetchableWidget`, and every screen reinventing its own state machine. Use `Fetchable<T>`/
`Progressable` fields even for a "simple" screen — the four-state model costs nothing extra to
declare and buys the combinators, the widgets, and consistency with every other screen.

## 3. Branching on the concrete subclass instead of the extension getters

```dart
// WRONG
if (fetchable is SuccessFetchable<Contact>) { ... }
```

`IdleFetchable`/`BusyFetchable`/`SuccessFetchable`/`ErrorFetchable` are implementation details of
`Fetchable`'s factory constructors, not a public API to pattern-match on. Use `.success`,
`.hasError`, `.idle`, `.busy`, `.data`/`.dataOrNull` instead — they're what the rest of the
package (widgets, combinators) actually reads, and they stay stable even if the internal class
hierarchy changes.

## 4. Forgetting `takeOnce: false` on a live subscription

```dart
// WRONG — stops updating after the contacts list first loads once
executeSF(
  contactCubit.mapFStream((s) => s.contactsF),
  then: (f) => rebuild(state.rebuild((b) => b..contactsF = f)),
);
```

The default `takeOnce: true` calls `takeWhileInclusive` under the hood and unsubscribes after the
first `success`. A screen that's supposed to mirror `contactCubit`'s list for its whole lifetime
(new contacts added later, edits, etc.) will silently freeze after the first successful load.
Pass `takeOnce: false` whenever the upstream stream is expected to keep emitting.

## 5. Using `BlocListener` for a one-shot success/error side effect that `ProgressablesResultPresenter` already handles

```dart
// Works, but duplicates logic able already provides
BlocListener<ContactViewCubit, ContactViewState>(
  listenWhen: (prev, curr) => prev.saveContactP != curr.saveContactP,
  listener: (context, state) {
    if (state.saveContactP.success) Navigator.of(context).pop();
    if (state.saveContactP.hasError) showErrorToast('${state.saveContactP.error}');
  },
  child: ...,
)
```

`ProgressablesResultPresenter`/`ProgressableResultPresenter` already do the previous-vs-current
diffing, batch multiple `Progressable` fields into one widget, and route unhandled errors through
the same `ExceptionHandler`/`Able.configs` pipeline used everywhere else. Reimplementing it with
`BlocListener` means two different error-handling paths in the same app — one that respects
`isExpectedError`/`shouldIgnoreMessage` and one that doesn't.

### This is not a blanket ban on `BlocListener`

`BlocListener` is the right tool — used routinely in production code — for a different job:
pushing a `Fetchable`'s *success payload* into imperative, non-widget state that `able` has no
widget for, most commonly a `TextEditingController` or `FocusNode`:

```dart
// Fine — syncing a Fetchable's data into an imperative TextEditingController.
// ProgressablesResultPresenter can't do this job: it only exists for Progressable, and only
// fires on idle->success/idle->error transitions, not "every time this Fetchable's success
// payload changes."
BlocListener<SendCodeViewCubit, SendCodeViewCubitState>(
  listenWhen: (previous, current) =>
      previous.phoneNumberF != current.phoneNumberF,
  listener: (context, state) => state.phoneNumberF.mapSuccess(_updateController),
  child: _PhoneNumberTextFieldLoader(...),
)
```

The distinction: `ProgressablesResultPresenter` is for one-shot reactions to a `Progressable`
finishing (navigate away, show a toast) — never reach for `BlocListener` there, for the reasons
above. `BlocListener` is for continuously mirroring a `Fetchable`'s value into something outside
the widget tree that `FetchableWidget` can't reach (a controller, a focus node, an animation) —
`able` has no widget for that job, so `listenWhen` + `.mapSuccess(...)` (called here purely for
its side effect, with the mapped result discarded) is the established way to do it.

## 6. Reading `Able.configs` before `Able.initialize()`

```dart
// WRONG — throws an assertion error
runApp(MyApp()); // MyApp's build() reads Able.configs.loadingWidget
// Able.initialize(...) called later, e.g. after Firebase setup
```

`Able.configs` asserts `_configs != null`. `Able.initialize(...)` must run before the first widget
that depends on the default `loadingWidget`/`errorWidget` builds — in practice, before `runApp()`.
Calling `initialize()` a second time is *not* an error, but it's also not applied: the original
configuration is kept and a `debugPrint` warning is emitted, which is easy to miss in a release
build's silenced debug output.

## 7. (Fixed in 0.1.0) Combining 7–9 `Fetchable`s and trusting the overall state

`combine7F`, `combine8F` and `combine9F` used to leave `f6.state` out of the combined state. They
sum every input since 0.1.0, so this is no longer a pitfall. Kept here so the numbering of the
other items stays stable.

## 8. Treating every error as unexpected

```dart
// WRONG — a "no gender selected" validation error triggers a crash-reporting toast
executeP(() => repository.updateGender(gender));
```

Without `isExpectedError`, *every* error thrown inside the wrapped `Future` is forwarded to
`ExceptionHandler().handleException(...)` — i.e. `Able.configs`'s global `handleException`/
`onError`, typically logging + a generic toast. Expected, user-facing failure modes (validation,
permission denial, "already exists") should be dedicated exception types matched by
`isExpectedError:`, so they only ever render through the screen's own `buildError`/
`ProgressableResultPresenter.onError`, not the app-wide handler.

## 9. Mutating a `Fetchable`/`Progressable` in place

Both types are immutable value classes with no setters — there is no way to "mutate" one directly,
but the anti-pattern shows up as caching a reference to `state.contactsF` and expecting it to
reflect later `rebuild` calls. It won't: every `rebuild` replaces the whole `State` object, so a
previously-read `Fetchable` reference is a frozen snapshot. Always re-read the field from
`state`/`context.select` rather than holding onto an old `Fetchable`/`Progressable` value.

## 10. (Fixed in 0.1.0) Awaiting `.asFuture` on a field that can fail and later recover

Before 0.1.0, `asFuture` kept listening after completing with an error, so a later success on the
same field threw `Bad state: Future already completed`. It now stops at the first success or
error, so awaiting a field that errors and then recovers (a Retry) is safe. Kept here so the
numbering of the other items stays stable.

## 11. Resetting a loaded field to plain `busy` on reload

```dart
// WRONG (since 0.2.0) — the list disappears behind a spinner on every refresh
rebuild(state.rebuild((b) => b..contactsF = Fetchable.busy()));
```

Use `state.contactsF.toRefreshing()` (or `keepingDataOf` in a `then:`), so the screen keeps what it
was showing while the new data loads — see [[patterns]] item 21. Plain `busy` is right only for a
first load, or when the old data must not be shown any more (a different user, a changed filter
whose old results would mislead).

## 12. Hand-written `onPressed: xP.busy ? null : ...` buttons

Every such button re-implements the disable-while-busy rule and usually forgets the spinner and the
screen-reader label. Use `ProgressableButton` ([[patterns]] item 24).

## Related knowledge

- Concepts: [[AbleCubit]] (#1, #3, #4, #7, #10), [[Fetchable]] (#11), [[Fetchable]]/[[Progressable]] (#2, #8, #9),
  [[ProgressablesResultPresenter]] (#5), [[AbleConfigs]] (#6).
- Decisions: [[ADR-005-rebuild-alias-for-emit]] (#1), [[ADR-004-centralized-exception-handling]]
  (#6, #8).
- Graph: `knowledge/graph/graph.json` (node `rule-anti-patterns`)