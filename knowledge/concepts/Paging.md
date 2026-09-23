# Paging

## What it is
Able's support for lists loaded page by page (0.2.0): the value type `PagedList<T>` (items loaded
so far, the next page key, whether there is more), `PageResult<T>` (one page from the source),
the cubit helper `executeNextPage` (extension `AblePagingExtension` on [[AbleCubit]]), and the
sliver `FetchablePagedListWidget<T>`, which asks for the next page as the user nears the end.

## Why it exists
Paged lists were hand-rolled per screen: a list, a page counter, a "loading more" flag and an
error flag next to each other — the loading/error/data trio `able` exists to replace. Held as one
`Fetchable<PagedList<T>>`, a paged list uses the same four states as everything else, and the kept
data from [[ADR-007-kept-data-on-busy-and-error]] keeps loaded items visible while the next page
loads or after it fails.

## Where it lives
`lib/src/paging/paged_list.dart`, `lib/src/paging/paging_cubit.dart`,
`lib/src/widgets/fetchable_paged_list_widget.dart`.

## What it depends on
- [[Fetchable]] — the field type, and its kept data.
- [[AbleCubit]] — `executeNextPage` runs through `executeSF` with a `key`.
- [[AbleConfigs]] — first-page busy/error fallback widgets.

## What depends on it
Nothing inside the package. Apps hold a `Fetchable<PagedList<T>>` per paged list.

## Which rules govern it
- `rules/patterns.md` item 22.

## Which decisions affect it
- [[ADR-007-kept-data-on-busy-and-error]]

## Examples of correct usage
`rules/patterns.md` item 22; `test/features_test.dart`, group `paging`.

## Common mistakes
- Forgetting `key:` semantics: two paged lists in one cubit need different keys, or a refresh of
  one cancels the other's page.
- Calling `executeNextPage` with a stale `current` (captured before a `rebuild`): pass
  `state.xF` at the call, as the recipe does.
