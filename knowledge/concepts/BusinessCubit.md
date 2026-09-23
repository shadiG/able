# BusinessCubit (convention)

## What it is
Not a class the `able` package defines — a consuming-app convention, observed in practice
(telavi_app) and written up in `rules/architecture.md`/`rules/patterns.md` items 9-10: a
long-lived, app-scoped [[AbleCubit]] subclass (e.g. `ContactCubit`) holding canonical data for one
feature, provided once via dependency injection, with its methods split across `function/*.dart`
files as `extension on <Feature>Cubit` blocks rather than declared inline.

## Why it exists
Keeps a feature's core cubit file small (constructor, dependencies, `State`) while letting each
concern (data access, a specific integration, a specific sub-flow) grow its own extension file,
and gives the app one canonical, shared source of truth per feature that multiple [[ViewCubit]]s
can mirror from.

## Where it lives
Not in this repository — this concept documents an architectural role apps built on `able` are
expected to fill, conventionally at `domain/business/<feature>/<feature>_cubit.dart` plus
`domain/business/<feature>/function/*.dart`. Evidenced by telavi_app's `ContactCubit`, `AuthCubit`,
`AppCubit`, `MeasurementCubit`. In this repository: `CountryCubit` in
`example/country_listing/lib/domain/business/country/` (core file plus `function/extension.dart`,
`loading.dart`, `favorites.dart`).

## What it depends on
- [[AbleCubit]] — every business cubit extends it.
- Repositories/services (outside `able`'s scope).

## What depends on it
- [[ViewCubit]] — mirrors business-cubit fields via `mapFStream(...).distinct()` plus
  `executeSF(..., takeOnce: false)`.

## Which rules govern it
- `rules/architecture.md` — "Consuming-app conventions".
- `rules/patterns.md` items 9, 10, 16.

## Which decisions affect it
None recorded — this is an observed convention, not a package-level decision with commit
evidence. If it should be formalized (e.g. as a requirement rather than an observed pattern), that
would be a new ADR for whoever owns the convention across projects.

## Examples of correct usage
See `rules/patterns.md` items 9, 10, 16, and `example/country_listing/`.

## Common mistakes
Adding a method directly to `<feature>_cubit.dart` instead of the matching
`function/<concern>.dart` extension file when an existing concern file already fits — see
`rules/patterns.md` item 9.
