# ViewCubit (convention)

## What it is
A consuming-app convention (not an `able` class): a per-screen [[AbleCubit]] subclass
(`presentation/view/**/cubit/*_view_cubit.dart`) that takes one or more [[BusinessCubit]]s as
constructor dependencies, mirrors whichever business fields the screen needs, and adds its own
screen-local `Fetchable`/`Progressable` fields for transient UI state (in-flight save, form
validity, search-bar focus).

## Why it exists
Keeps business logic and persistence in [[BusinessCubit]]s while each screen's transient state
stays local and is discarded when the screen is popped, rather than every screen reading business
cubits directly and re-deriving the same live subscriptions ad hoc.

## Where it lives
Observed in telavi_app (e.g. `ContactViewCubit`, `SendCodeViewCubit`). In this repository:
`CountryListViewCubit` and `CountryDetailViewCubit` under
`example/country_listing/lib/presentation/view/*/cubit/`.

## What it depends on
- [[AbleCubit]] — every view cubit extends it.
- [[BusinessCubit]] — constructor dependency, mirrored via `mapFStream`/`executeSF`.

## What depends on it
The screen's widgets ([[FetchableWidget]], [[ProgressablesResultPresenter]], etc.), via
`context.select`/`context.read`.

## Which rules govern it
- `rules/architecture.md` — "Consuming-app conventions".
- `rules/patterns.md` items 10, 11, 12, 13, 17, 18, 19.
- `rules/cubits.md` — the `.distinct()` note (load-bearing for exactly this mirroring pattern).

## Which decisions affect it
None recorded — observed convention, not a package-level decision.

## Examples of correct usage
See `rules/patterns.md` items 10, 11, 12, 13, 17, 18, 19, and `example/country_listing/`.

## Common mistakes
Forgetting `.distinct()` or `takeOnce: false` when mirroring a business-cubit field — see
`rules/anti-patterns.md` #4 and `rules/cubits.md`'s `.distinct()` note.
