# Patterns

Concrete recipes for writing cubits and widgets against `able`. See [[architecture]] for the
package layout these fit into, [[state-management]] for the underlying model, [[cubits]] for the
`AbleCubit` API, and [[fetchable]] for `Fetchable`/`Progressable` themselves.

## 1. Bootstrapping

```dart
void main() {
  Able.initialize(
    loadingWidget: const CircularProgressIndicator(),
    errorWidget: (context, error) => Text('$error'),
    handleException: (e, s, type) => logger.e('Unhandled ($type)', e, s),
    onError: (e, message) => showErrorToast(message ?? e.toString()),
  );
  runApp(const MyApp());
}
```

Call this once, before `runApp`. `loadingWidget`/`errorWidget` become the fallback used by
`FetchableWidget`/`FetchableListWidget` when a call site doesn't pass its own `buildBusy`/
`buildError`. `handleException` is where *unexpected* errors from `executeF`/`executeP` land;
`onError` is what `ProgressablesResultPresenter` calls for errors not marked
`shouldIgnoreMessage`.

## 2. Writing a cubit

```dart
class ContactCubit extends AbleCubit<ContactState> {
  ContactCubit({required this.repository}) : super(ContactState.initial) {
    _initContacts();
  }

  final ContactRepository repository;

  void _initContacts() => executeF(
        () => repository.fetchAll(),
        then: (contactsF) => rebuild(state.rebuild((b) => b..contactsF = contactsF)),
      );

  Stream<Progressable> saveContact(Contact contact) =>
      futureAsProgressable(() => repository.save(contact));
}

abstract class ContactState implements Built<ContactState, ContactStateBuilder> {
  Fetchable<BuiltList<Contact>> get contactsF;

  ContactState._();
  factory ContactState([void Function(ContactStateBuilder) updates]) = _$ContactState;

  static ContactState get initial =>
      ContactState((b) => b..contactsF = Fetchable.idle());
}
```

- One `F`-suffixed field per fetched value, one `P`-suffixed field per action, both initialized to
  `Fetchable.idle()`/`Progressable.idle()` in a `static Xstate get initial`.
- Every business method that mutates external state returns a **stream** (`Stream<Progressable>`
  via `futureAsProgressable`, `Stream<Fetchable<T>>` via `futureAsFetchable`) — the *caller*
  decides how to consume it (`executeSP`/`executeSF` to reflect it into state, or `.asFuture(this)`
  to await it inline).
- State mutation is always `rebuild(state.rebuild((b) => ...))` — never a bare `emit` and never a
  mutated builder without a `rebuild` call (see [[anti-patterns]]).

## 3. Subscribing one cubit to another

```dart
class ContactViewCubit extends AbleCubit<ContactViewState> {
  ContactViewCubit({required this.contactCubit}) : super(ContactViewState.initial) {
    executeSF(
      contactCubit.mapFStream((s) => s.contactsF),
      then: (contactsF) => rebuild(state.rebuild((b) => b..contactsF = contactsF)),
      takeOnce: false, // keep listening for the cubit's whole lifetime
    );
  }

  final ContactCubit contactCubit;
}
```

`takeOnce: false` is required whenever the subscription should outlive the first success —
without it, `executeSF`/`executeSP` stop listening after the first success (the default, correct
for one-shot fetches, wrong for mirroring a live upstream field).

## 4. One-shot reads inside a method

```dart
Future<void> saveWithCurrentUser() async {
  final user = await mapFStream((s) => s.userF).asFuture(this);
  await repository.save(user);
}
```

`.asFuture(this)` resolves on first success and throws on first error — use it to read a field
synchronously inside an `async` method body, instead of subscribing.

## 5. Rendering a `Fetchable`

```dart
FetchableWidget<Contact>(
  fetchable: context.select((ContactCubit c) => c.state.contactF),
  buildSuccess: (context, contact) => ContactCard(contact: contact),
  buildError: (context, error) => ErrorBanner(error: error),
)
```

- Prefer `context.select` (one field) over `context.watch` (whole state) so the widget only
  rebuilds when that field changes.
- Omit `buildBusy`/`buildError` to fall back to `Able.configs.loadingWidget`/`.errorWidget`.
- `treatIdleAsBusy: true` (default) renders the busy UI for `idle` too — set it `false` when idle
  should render nothing (`SizedBox`) until the fetch is explicitly triggered.

In practice, `buildBusy: (_) => const SizedBox.shrink()` is the single most common override —
reach for it for small/inline `FetchableWidget`s (a text field's prefix, a validation hint, one
piece of a larger screen) where the global `Able.configs.loadingWidget` (typically a centered
`CircularProgressIndicator`) would be visually wrong for that spot, even briefly. Leave `buildBusy`
unset for a `FetchableWidget` that owns the main content of a screen, where the global default is
correct. `buildError` is rarely given a bespoke widget at all — most call sites either omit it
(falling back to `Able.configs.errorWidget`) or, for a field whose error is already surfaced
elsewhere (a derived UI-only field, or one paired with a `ProgressablesResultPresenter` that
already toasts the same error), explicitly suppress it with `buildError: (_, __) =>
const SizedBox.shrink()` rather than writing a second, redundant inline error UI.

`FetchableWidget`s nest for conditional visibility — an outer `FetchableWidget` (often wrapping a
`combine2F`/`combine3F` of several fields) decides *whether* to show anything at all in
`buildSuccess`, returning `SizedBox.shrink()` for the "don't show" branches and a second, inner
`FetchableWidget` (over the field that actually needs busy/error/success handling) for the branch
that should render:

```dart
FetchableWidget(
  fetchable: combine2F(f1: otpViewTypeF, f2: hasPassedF),
  buildBusy: (context) => const SizedBox.shrink(),
  buildSuccess: (context, data) {
    final (otpViewType, hasPassed) = data;
    if (otpViewType != OtpViewType.verifyCode || hasPassed == true) {
      return const SizedBox.shrink();
    }
    return FetchableWidget(
      fetchable: verifyCodeF,
      buildBusy: (context) => const SizedBox.shrink(),
      buildError: (context, error) => WrongCodeText(error: error),
    );
  },
)
```

## 6. Rendering a `Fetchable<BuiltList<D>>`

```dart
CustomScrollView(
  slivers: [
    FetchableListWidget<Contact>(
      fetchable: context.select((ContactCubit c) => c.state.contactsF),
      buildItem: (context, contact) => ContactTile(contact: contact),
      buildEmpty: (context) => const EmptyContactsPlaceholder(),
      buildError: (context, error) => ErrorBanner(error: error),
    ),
  ],
)
```

`FetchableListWidget` returns a sliver — it must be a direct child of a `CustomScrollView`'s
`slivers:`, not used standalone. `fillRemaining`/`hasScrollBody` control whether busy/error/empty
states fill the viewport (`SliverFillRemaining`) or size to content (`SliverToBoxAdapter`).

In practice `FetchableListWidget` is reached for far less often than plain `FetchableWidget` —
most list-shaped screens instead unwrap `.data` once inside a single `FetchableWidget`'s
`buildSuccess` and hand the `BuiltList` to a purpose-built scrolling widget (a custom
sliver/section view, grouped by a header, etc.) that the app already has for that screen's
specific layout:

```dart
FetchableWidget(
  fetchable: contactsF,
  buildSuccess: (context, contacts) => _ContactList(contacts: contacts), // its own CustomScrollView
)
```

Reach for `FetchableListWidget` itself when a screen's list truly has no per-item layout needs
beyond "one row per element, with busy/error/empty slivers" — otherwise the buildSuccess-then-
custom-widget style above gives more control over headers, grouping, and item keys than
`buildItem` alone does. When it is used, `buildError`/`buildEmpty` are commonly suppressed to
`(_, __) => const SliverToBoxAdapter(child: SizedBox.shrink())` for a list embedded inside a
larger scrollable screen, where an inline sliver-sized error/empty state would look out of place
next to the rest of the page — same reasoning as the `buildError`/`buildBusy` suppression pattern
under [[patterns]] item 5.

## 7. Side effects on action completion

```dart
ProgressablesResultPresenter<ContactViewCubit, ContactViewState>(
  presenters: [
    ProgressableResultPresenter(
      progressable: (s) => s.saveContactP,
      onSuccess: () => Navigator.of(context).pop(),
      onError: (e) => showErrorToast('$e'),
      shouldIgnoreMessage: (e) => e is ValidationException,
    ),
  ],
  child: const ContactFormView(),
)
```

Fires `onSuccess`/`onError` **once per transition** (idle→success, idle→error), diffed against the
previous emission — this is the tool for "navigate away on save" / "toast on failure", not
`BlocListener`, because it already handles the transition-detection and the ignore-list plumbing.
`shouldIgnoreMessage` suppresses the generic `ExceptionHandler().onError` call (e.g. a toast) while
still invoking the presenter's own `onError` — use it for errors the screen already shows inline
(a form validation message next to the field).

`ProgressablesResultPresenter` takes a `presenters:` *list* precisely so one wrapper can cover
several independent `Progressable` fields on the same screen at once — each with its own
`onSuccess` (typically a success toast, or a navigation/follow-up call) and its own `onError`:

```dart
ProgressablesResultPresenter<ListMeasurementViewCubit, ListMeasurementViewCubitState>(
  presenters: [
    ProgressableResultPresenter(
      progressable: (state) => state.setCurrentP,
      onSuccess: () => showSuccessToast(context: context, title: l10n.set_current_success),
    ),
    ProgressableResultPresenter(
      progressable: (state) => state.deleteP,
      onSuccess: () => showSuccessToast(context: context, title: l10n.deleted_success),
    ),
    ProgressableResultPresenter(
      progressable: (state) => state.copyToOtherContactP,
      onSuccess: () => showSuccessToast(context: context, title: l10n.copy_success),
    ),
  ],
  child: /* the rest of the screen */,
)
```

`errorToMessage` sees essentially no real use — screens instead either let an unhandled error fall
through to the global `Able.configs`'s `onError` (wired once in `main()`, see item 1 above) or
write their own `onError:` callback per presenter for anything screen-specific (a dialog, a
field-level message), rather than customizing the generic toast's text via `errorToMessage`.

## 8. Marking expected errors

```dart
executeP(
  () => repository.deleteContact(id),
  then: (p) => rebuild(state.rebuild((b) => b..deleteContactP = p)),
  isExpectedError: (e) => e is PermissionDeniedException,
);
```

Anything matched by `isExpectedError` still becomes `Progressable.error`/`Fetchable.error` in
local state (so the UI can render it), but is *not* forwarded to `Able.configs`'s global exception
handler — reserve that for genuinely unexpected failures (network blips, bugs), not
"user denied permission" or "validation failed."

## 9. Splitting a business cubit's methods across `function/*.dart` extension files

A business cubit (`domain/business/<feature>/<feature>_cubit.dart`) usually only declares its
constructor, injected dependencies, and `State`. Its methods are added via `extension on
<Feature>Cubit` blocks in sibling files under `function/`, one file per concern:

```
domain/business/contact/
  contact_cubit.dart          # class ContactCubit extends AbleCubit<ContactState>, ContactState
  function/
    extension.dart             # ContactCubitExtension — data access (contacts getter, updateContact)
    launcher.dart               # LauncherExtension — launchDialer/launchSms/launchUrl/launchWhatsApp
    phone_book.dart             # PhoneBookExtension — device phone-book import + permission flow
    profile.dart                 # ProfileExtension — updateGender etc.
```

Each extension file imports the cubit class and adds methods as `extension <Name>Extension on
<Feature>Cubit`. This keeps a business cubit's core file small (constructor, dependencies, state)
while letting each feature area grow its own file instead of one cubit class accumulating dozens
of unrelated methods. Callers (view cubits, other extensions) just import whichever extension file
they need — the methods appear on the cubit instance either way, since Dart extension methods are
resolved by import, not by declaration site.

When adding a new capability to an existing business cubit, prefer adding a new method to the
existing extension file for that concern (or a new `function/<concern>.dart` file with a new
extension) over adding it directly to the `<feature>_cubit.dart` file.

## 10. Two-tier cubits: a business cubit feeding one or more view cubits

`able` apps consistently split cubits into two tiers:

- **Business cubits** (`domain/business/**`) hold canonical, app-wide data — one instance per
  feature, provided high in the widget tree via DI, long-lived for the app session. Their state
  fields are the source of truth (e.g. `ContactCubit.state.contactsF`).
- **View cubits** (`presentation/view/**/cubit/*_view_cubit.dart`) are created per screen (or per
  widget), take one or more business cubits as constructor dependencies, and mirror the business
  fields they need with `executeSF`/`executeSP` + `takeOnce: false`:

```dart
class ContactViewCubit extends AbleCubit<ContactViewState> {
  ContactViewCubit({required this.contactCubit, required this.navigationCubit})
      : super(ContactViewState.initial) {
    initContacts();
  }

  final ContactCubit contactCubit;
  final NavigationCubit navigationCubit;

  void initContacts() => executeSF(
        contactCubit.mapFStream((state) => state.contactsF).distinct(),
        then: (contactsF) => rebuild(state.rebuild((b) => b..contactsF = contactsF)),
        takeOnce: false,
      );
}
```

A view cubit then adds its *own* fields (`Progressable`s for screen-local actions like "save",
`Fetchable`s for screen-local derived values) alongside the mirrored business field, and calls
into the business cubit (or its extension methods) for anything that mutates shared data. This
keeps business logic and persistence in one place while each screen's transient UI state
(search-bar focus, form validity, in-flight save) stays local to its view cubit and gets discarded
when the screen is popped.

## 11. Deriving a field from several upstream fields, live, inside a cubit constructor

The single most common `able` idiom in view-cubit constructors: subscribe to a `combineNFStreams`
of two or more `mapFStream(...).distinct()` sources, `.flatMapOnSuccessF(...)` into a computed
value via a nested `futureAsFetchable`, and drive it with `executeSF(..., takeOnce: false)`:

```dart
void _initPhoneNumberMask() => executeSF(
      combine2FStreams(
        s1: mapFStream((s) => s.selectedCountryF).distinct(),
        s2: mapFStream((s) => s.phoneNumberF).distinct(),
      ).distinct().flatMapOnSuccessF((data) {
        final country = data.$1;
        final phoneNumber = data.$2;
        return futureAsFetchable(() async {
          if (country == null) return null;
          return MaskTextInputFormatter(mask: country.mask, /* ... */);
        });
      }),
      then: (maskF) => rebuild(state.rebuild((b) => b.phoneNumberMaskF = maskF)),
      takeOnce: false,
    );
```

- `.distinct()` on every `mapFStream`/combined stream in this chain is load-bearing, not
  decoration — see [[cubits]] for why.
- `combineNFStreams` (not the value-level `combineNF`) belongs in a constructor/`_init*` method,
  where the goal is a live subscription that keeps recomputing as any input changes.
- One cubit field can depend on another field *of the same cubit* this way, not just on another
  cubit's fields — e.g. a `_initValidation` method deriving from `phoneNumberF`/
  `phoneNumberMaskF`/`selectedCountryF`, all on that same cubit's own `State`.

## 12. Combining fields at the widget layer for one render, without a cubit field

When two or more `Fetchable`s only need to be combined for a single widget's rendering — not as a
persistent derived cubit field — combine the already-`context.select`ed *values* directly in
`build()` with the value-level `combineNF` (not `combineNFStreams`):

```dart
final state = context.select((SendCodeViewCubit cubit) => cubit.state);

return FetchableWidget(
  fetchable: combine3F(
    f1: state.selectedCountryF,
    f2: state.phoneNumberF,
    f3: state.phoneNumberMaskF,
  ),
  buildSuccess: (context, data) {
    final (country, phoneNumber, mask) = data;
    // ...
  },
);
```

Reach for `combineNFStreams` in a cubit only when the combined value needs to be its own
persistent state field (other widgets read it, or a business method awaits it via `.asFuture`);
reach for the plain `combineNF` at the call site when it's purely a rendering concern for one
widget.

## 13. A shared busy overlay across several `Progressable`s, instead of per-field busy builders

For screens where several independent actions (e.g. "save" and "load from phone book") should all
block the screen behind one spinner rather than each rendering its own inline busy state, combine
their busy-ness with the `anyBusy` list extension (see [[state-management]]) and drive a
full-screen cover widget, leaving `FetchableWidget`'s own `buildBusy` unset for the main content:

```dart
CoverStack(
  coverBuilder: (context) => const ActivityCover(),
  showCover: [saveContactsP, loadContactsP].anyBusy,
  child: FetchableWidget(
    fetchable: contactsF,
    buildSuccess: (context, contacts) => _ContactList(contacts: contacts),
  ),
)
```

Reserve per-call-site `buildBusy` (e.g. `buildBusy: (context) => const SizedBox.shrink()`) for
small, inline pieces of a screen (a text field, a stack overlay) where a full-screen loading
indicator would be wrong even briefly — the global `Able.configs.loadingWidget` default is tuned
for a normal fetch-and-render case, not every `FetchableWidget` on a page.

## 14. `value.asFetchable()` / `value.asProgressable()` are the everyday way to set a field, not an edge case

[[state-management]]'s "Converting between the two" section documents `value.asFetchable()` (an
extension on `T` that wraps a plain, already-known value as `Fetchable.success(value)`) — in
practice this, not `futureAsFetchable`, is how most `Fetchable` fields actually get set inside a
`then:`/business-method body, because most business methods already have the value in hand after
an `await` and are just re-wrapping it before a `rebuild`:

```dart
rebuild(
  state.rebuild(
    (b) => b.contactsF = contacts.sortedByDisplayName().toBuiltList().asFetchable(),
  ),
);
```

`futureAsFetchable`/`futureAsProgressable` are for the *outer* boundary — turning the overall
async operation into a `busy`-then-`success`/`error` stream that `executeF`/`executeSF` consumes —
`value.asFetchable()`/`.asProgressable()` are for setting individual fields to an already-known
value inside that operation, and for one-off "this is synchronously available" fields
(`false.asFetchable()`, `null.asFetchable()`).

## 15. Conditional flows: a hand-written `if`/`else` inside `futureAsProgressable`, not `AbleCubit.doIf`

`AbleCubit.doIf` exists in the package (see [[cubits]]) but is rarely reached for in practice.
Most "do A, or do B if some condition doesn't hold" flows are written directly as an `if`/`else`
inside a `futureAsProgressable`/`futureAsFetchable` body, reading whatever `Fetchable<bool>` or
condition is needed via `.asFuture(this)`:

```dart
void loadContactsFromPhoneBook() => executeSP(
      futureAsProgressable(() async {
        final isPermissionDenied =
            await contactCubit.isContactPermissionDenied().asFuture(this);

        if (isPermissionDenied) {
          await openAppSettings();
          return;
        }

        // ... proceed
      }),
      then: (p) => rebuild(state.rebuild((b) => b..loadContactsP = p)),
      isExpectedError: (error) => error is PermissionDeniedException,
    );
```

This reads more like ordinary imperative code and keeps the branching visible at the call site,
which is likely why `doIf` sees little real use — prefer this style unless `doIf`'s specific
shape (an entirely separate `ifP`/`elseP` stream pair keyed off a `Fetchable<bool>`) genuinely
fits better."

## Related knowledge

- Concepts: all package-internal concepts, plus [[BusinessCubit]] and [[ViewCubit]] (items 9-15
  are entirely about those two conventions).
- Decisions: [[ADR-004-centralized-exception-handling]] (item 1, item 7).
- Graph: `knowledge/graph/graph.json` (node `rule-patterns`)