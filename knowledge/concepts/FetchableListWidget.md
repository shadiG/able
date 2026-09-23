# FetchableListWidget

## What it is
`FetchableListWidget<D>` (`lib/src/widgets/fetchable_list_widget.dart`) — the sliver counterpart
of [[FetchableWidget]] for a `Fetchable<BuiltList<D>>`: busy/error/empty states render as
`SliverFillRemaining`/`SliverToBoxAdapter`, success renders a `SliverList`.

Siblings in the same file (0.2.0) share its busy/error/empty handling: `FetchableSliverGrid`
(a sliver grid) and `FetchableListView` (a box `ListView`). `FetchableListWidget` also takes a
`separatorBuilder`. All render kept data while busy (`showLatestDataWhileBusy`). For paged lists
see [[Paging]].

## Why it exists
To cover the common "fetch a list, render one row per item" case with the same busy/error handling
as [[FetchableWidget]], without hand-writing a `SliverList` plus manual state branching.

## Where it lives
`lib/src/widgets/fetchable_list_widget.dart`.

## What it depends on
- [[Fetchable]] (specialized to `Fetchable<BuiltList<D>>`) — requires `built_collection`.
- [[AbleConfigs]] — busy/error fallback widgets.

## What depends on it
Must be a direct child of a `CustomScrollView`'s `slivers:` — it returns a sliver, not a regular
widget.

## Which rules govern it
- `rules/patterns.md` items 6 and 21.

## Which decisions affect it
- [[ADR-007-kept-data-on-busy-and-error]] — rendering kept data while busy.

## Examples of correct usage
See `rules/patterns.md` item 6.

## Common mistakes
Reached for by default when [[FetchableWidget]] plus a custom scrolling widget would give more
control — see `rules/patterns.md` item 6's real-usage note (used once vs. `FetchableWidget`'s 24
uses in the surveyed codebase). Not wrong to use it, but confirm the screen's list truly has no
per-item layout needs beyond "one row per element" first.
