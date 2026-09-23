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
`(_, __) => const SizedBox.shrink()` (with `fillRemaining: false`) for a list embedded inside a
larger scrollable screen, where an inline error/empty state would look out of place next to the
rest of the page — same reasoning as the `buildError`/`buildBusy` suppression pattern under
[[patterns]] item 5. Return a **box** widget there, not a sliver: the widget wraps it in a
`SliverFillRemaining`/`SliverToBoxAdapter` itself. (Before 0.2.0 this item wrongly suggested
returning a `SliverToBoxAdapter`, which would nest a sliver inside a sliver.)

Variants (0.2.0), all sharing the same busy/error/empty handling:
- `FetchableListWidget(separatorBuilder: ...)` — separators, like `ListView.separated`.
- `FetchableSliverGrid(gridDelegate: ...)` — a sliver grid.
- `FetchableListView` — a plain box `ListView`, for a whole screen body, a sheet or a tab where no
  `CustomScrollView` is needed.
- `FetchablePagedListWidget` — see item 22.

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
- When the inputs can change faster than the computation finishes (a search query), use
  `switchMapOnSuccessF` instead, so a stale result can't overwrite a fresh one. The example app's
  `CountryListViewCubit._initVisibleCountries` does this. Only safe because the computed field is
  not one of the inputs.
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

## 16. A business load method that writes its own field and still returns a `Progressable`

When a business cubit's canonical field must be reloadable on demand (a Retry button, a refresh
action), put the load in one method that mirrors every step into the field **and** returns a
`Stream<Progressable>` for the caller:

```dart
extension CountryLoadingExtension on CountryCubit {
  Stream<Progressable> loadCountries() => futureAsProgressable(() async {
        rebuild(state.rebuild((b) => b..countriesF = Fetchable.busy()));
        try {
          final countries = await countryRepository.fetchCountries();
          rebuild(state.rebuild((b) => b..countriesF = countries.asFetchable()));
        } catch (e) {
          rebuild(state.rebuild((b) => b..countriesF = Fetchable.error(e)));
          rethrow;
        }
      });
}
```

- The business cubit's constructor starts it with `executeSP(loadCountries())`.
- A view cubit reloads with `executeSP(countryCubit.loadCountries(), then: (p) =>
  rebuild(state.rebuild((b) => b..reloadP = p)))` and reacts to `reloadP` through a
  `ProgressablesResultPresenter`.
- The `rethrow` matters: without it the field shows the error but the caller's `Progressable`
  reports success.

Reference: `example/country_listing/lib/domain/business/country/function/loading.dart`.

## 17. A live, derived per-screen value from another cubit's field: `.map(mapSuccess)`

When a screen needs a small value computed from a business field (is *this* item a favorite?),
map the mirrored stream instead of mirroring the whole field and computing in the widget:

```dart
void _observeIsFavorite() => executeSF(
      countryCubit
          .mapFStream((s) => s.favoriteCodesF)
          .map((favoriteCodesF) => favoriteCodesF.mapSuccess((codes) => codes.contains(countryCode)))
          .distinct(),
      then: (isFavoriteF) => rebuild(state.rebuild((b) => b..isFavoriteF = isFavoriteF)),
      takeOnce: false,
    );
```

`mapSuccess` passes idle/busy/error through unchanged, and `.distinct()` after the `map` means the
screen only rebuilds when the derived `bool` actually flips, not whenever the set changes.

## 18. A dependent load chained on another: `flatMapOnSuccessF` in a view cubit

```dart
void _initNeighbours() => executeSF(
      countryCubit.countryByCode(countryCode).flatMapOnSuccessF(countryCubit.neighboursOf),
      then: (neighboursF) => rebuild(state.rebuild((b) => b..neighboursF = neighboursF)),
    );
```

Idle/busy/error of the first stream flow straight into `neighboursF`, so one `FetchableWidget`
covers both steps. Use this rather than `await`ing the first result inside a
`futureAsFetchable` when the second query is already a business method returning a stream.

## 19. List rows that carry per-row flags: a record type in the view state

When each row needs data from two business fields (the country and whether it is a favorite),
derive the rows in the view cubit (item 11) as a `BuiltList` of records, so the widget renders
exactly one field and never looks anything up:

```dart
typedef CountryListItem = ({Country country, bool isFavorite});

/// The rows to render, after filtering and sorting by name.
Fetchable<BuiltList<CountryListItem>> get visibleCountriesF;
```

Records have structural `==`, so `.distinct()` and `BuiltList` equality still work. The derived
field is what `FetchableListWidget<CountryListItem>` renders.

## 20. Testing cubits

- Call `Able.initialize` once per test file (`setUpAll(Able.initialize)`); a second call is a
  harmless no-op.
- Build the business cubit over a fake repository with `latency: Duration.zero`, then await its
  first load with the same accessor production code uses (`await cubit.countries`).
- Assert on state with the matchers in `package:able/testing.dart` (0.2.0): `isIdleF`, `isBusyF`,
  `isRefreshingF([data])`, `isSuccessF([data])`, `isErrorF([error])`, and `isIdleP`,
  `isBusyP([progress])`, `isSuccessP`, `isErrorP([error])`. Each optional argument is a value or
  a matcher: `expect(cubit.state.countriesF, isErrorF(isA<CountryLoadException>()))`.
- When tests need different `Able.initialize` configurations, call `Able.resetForTest()` in
  `tearDown`; otherwise the second `initialize` is ignored.
- Drive actions with `.asFuture(cubit)`: `await cubit.toggleFavorite('TG').asFuture(cubit)`; an
  expected error surfaces as `throwsA(isA<FavoriteLimitReachedException>())`.
- For derived view-cubit fields, call the input method and let the event loop settle
  (`await Future<void>.delayed(const Duration(milliseconds: 10))`) before reading
  `state.xF.data`. Reading `.data` in a test is fine; in production code it is not (item 4).
- To assert a field *failed*, `expectLater(cubit.countries, throwsA(isA<CountryLoadException>()))`
  works: `.asFuture` completes with the error and stops listening.
- Close every cubit you create at the end of the test.

Reference: `example/country_listing/test/`.

## 21. Reloading without a spinner flash: keep the data while busy

A reload that sets the field to plain `Fetchable.busy()` hides everything the screen was showing
until the new data arrives. Since 0.2.0 a busy (or error) `Fetchable` can keep the data it had:

```dart
// In the business method that reloads:
rebuild(state.rebuild((b) => b..countriesF = state.countriesF.toRefreshing()));

// In a view cubit's then:, for a field derived from it:
then: (visibleF) => rebuild(state.rebuild((b) => b..visibleF = visibleF.keepingDataOf(state.visibleF))),
```

- `toRefreshing()` = busy, keeping this value's data. `keepingDataOf(previous)` = this busy/error
  value, keeping `previous`'s data. Success and idle are left as they are.
- Read kept data with `latestData` / `latestDataOrNull` / `hasLatestData`; `refreshing` is true
  for busy-with-data. `.data` still only works on success.
- `FetchableWidget`, `FetchableListWidget`, `FetchableSliverGrid` and `FetchableListView` render
  kept data with the success builder while busy (`showLatestDataWhileBusy`, default true), so a
  reload keeps the screen and a separate indicator (a `LinearProgressIndicator` bound to the
  reload's `Progressable`) shows progress. An error still renders the error builder.
- Combining (`combine2F`...) does not carry kept data: keep it on the derived field instead, as in
  the view-cubit line above.

Reference: `example/country_listing` (`loading.dart`, `CountryListViewCubit._initVisibleCountries`).

## 22. Pagination: `PagedList`, `executeNextPage`, `FetchablePagedListWidget`

```dart
// State: one field.
Fetchable<PagedList<Contact>> get contactsF;          // initial: Fetchable.idle()

// Cubit: one method, used both for the first page and for "load more".
void loadContacts({bool refresh = false}) => executeNextPage<Contact>(
      key: #contacts,
      current: state.contactsF,
      refresh: refresh,
      firstPageKey: 0,
      fetch: (page) => contactRepository.fetchPage(page as int),   // returns PageResult<Contact>
      then: (contactsF) => rebuild(state.rebuild((b) => b..contactsF = contactsF)),
    );

// View, inside a CustomScrollView:
FetchablePagedListWidget<Contact>(
  fetchable: contactsF,
  onLoadMore: cubit.loadContacts,
  buildItem: (context, contact) => ContactTile(contact: contact),
  buildEmpty: (context) => const NoContacts(),
)
```

- The page key is whatever the source uses (page number, cursor, offset); a `PageResult` with a
  null `nextPageKey` is the last page.
- While a page loads, the field is busy keeping the loaded items (item 21); a failed page is an
  error keeping them. The widget shows a loading footer or an error footer with Retry.
- `executeNextPage` does nothing while a page is loading or after the last page, so calling it
  from `onLoadMore` repeatedly is safe. `refresh: true` starts over, cancelling a page in flight
  (the `key`), and keeps the old items on screen until the first page arrives.

## 23. Actions a user can re-trigger: `key:` on `execute*`

```dart
void search(String query) => executeF(
      () => placeRepository.search(query),
      key: #search,
      then: (resultsF) => rebuild(state.rebuild((b) => b..resultsF = resultsF)),
    );
```

Starting an `execute*` call with a `key` first cancels the running call with the same key, so only
the latest one reaches `then:`, and a slow response to an old query can't overwrite a newer one.
`cancelExecution(key)` cancels without starting another. Different keys run side by side. For a
*derived* value computed from state instead of a method call, use `switchMapOnSuccessF` (item 11).
To wait for typing to pause, debounce the source with rxdart's `debounceTime` before
`switchMapOnSuccessF`.

Cancelling stops the result from reaching state; it does not stop the `Future` itself. Don't use it
to "cancel" a write the user expects to happen.

## 24. Buttons bound to an action: `ProgressableButton`

```dart
ProgressableButton(
  progressable: saveP,
  onPressed: cubit.save,
  busySemanticsLabel: l10n.saving,
  child: Text(l10n.save),
)
```

Disabled with a spinner while `saveP` is busy (a determinate one when the busy value has a
`progress`). Renders a `FilledButton`; pass `builder: (context, onPressed, child) => AppButton(...)`
to use the app's own button. Use it instead of hand-writing `onPressed: saveP.busy ? null : ...`.

## 25. Reporting progress, retrying, combining many values

- `futureAsProgressableWithProgress((report) async { ...; report(sent / total); })` emits
  `Progressable.busy(progress: ...)` values; read them with `progressable.progress` or render them
  with `ProgressableButton`.
- `withRetry(() => repository.fetchAll(), maxAttempts: 3, retryIf: (e) => e is NetworkException)`
  retries with exponential backoff; compose it inside `futureAsFetchable`. Only retry errors that
  can succeed on a second try.
- `combineAllF(listOfFetchables)` / `combineAllP(...)` (and `*Streams`) combine any number of
  same-typed values into `Fetchable<BuiltList<T>>` / `Progressable`, instead of nesting
  `combine9F` calls.

## 26. Observing every cubit: `AbleObserver`

```dart
class CrashlyticsObserver extends AbleObserver {
  @override
  void onError(AbleCubit cubit, Object? error, StackTrace stackTrace, AbleType type, {required bool expected}) {
    if (!expected) crashReporter.record(error, stackTrace, reason: '${cubit.runtimeType}');
  }
}

Able.initialize(observer: CrashlyticsObserver(), ...);   // or Able.observer = ...
```

`onRebuild(cubit, previous, next)` sees every state change made through `rebuild`; `onError` sees
every `execute*` failure, with `expected` telling whether `isExpectedError` matched. Use it for
app-wide logging and analytics rather than adding logging to each cubit.

## 27. Linting the common mistakes: `able_lints`

`able_lints/` is an analyzer plugin with three warnings: `able_then_without_rebuild`
([[anti-patterns]] #1), `able_mirror_missing_take_once_false` (#4) and
`able_mirror_missing_distinct` ([[cubits]], `.distinct()`). Enable it in the app's
`analysis_options.yaml`:

```yaml
plugins:
  able_lints:
    path: ../able/able_lints   # or a git/hosted source
```

The warnings show in the IDE and in `dart analyze`. `flutter analyze` does not run analyzer
plugins, so CI should run `dart analyze` (as `.github/workflows/ci.yml` does for the examples).

## Related knowledge

- Concepts: all package-internal concepts, plus [[BusinessCubit]] and [[ViewCubit]] (items 9-19
  are entirely about those two conventions).
- Reference implementation: `example/country_listing/` uses items 1-12, 16-21, 24 and 27; its
  README maps each Able feature to the file that shows it. Items 22, 23, 25 and 26 are covered by
  `test/features_test.dart`.
- Concepts for items 21-27: [[Fetchable]] (kept data), [[Paging]], [[AbleObserver]],
  [[AbleLints]].
- Decisions: [[ADR-007-kept-data-on-busy-and-error]], [[ADR-008-lints-as-analyzer-plugin]].
- Decisions: [[ADR-004-centralized-exception-handling]] (item 1, item 7).
- Graph: `knowledge/graph/graph.json` (node `rule-patterns`)