# FetchableWidget

## What it is
`FetchableWidget<D>` (`lib/src/widgets/fetchable_widget.dart`) — a `StatelessWidget` that pattern-
matches a `Fetchable<D>` and calls `buildBusy`/`buildError`/`buildSuccess` accordingly, falling
back to [[AbleConfigs]]'s `loadingWidget`/`errorWidget` when `buildBusy`/`buildError` are omitted.

## Why it exists
So a widget never branches on `fetchable.busy`/`.hasError`/`.success` by hand — the busy/error/
success/idle cases and the global-default fallback are handled once, centrally.

## Where it lives
`lib/src/widgets/fetchable_widget.dart` (and its shared base, `BaseFetchableWidget`, also used by
[[FetchableListWidget]]); typedefs in `lib/src/widgets/common.dart`.

## What it depends on
- [[Fetchable]] — the value it renders.
- [[AbleConfigs]] — the busy/error fallback widgets.

## What depends on it
Nothing inside the package; it's a leaf, consumer-facing widget. In the surveyed telavi_app
codebase it's the single most-used `able` widget (24 files).

## Which rules govern it
- `rules/patterns.md` item 5 (rendering recipe, `buildBusy`/`buildError` conventions, nested
  `FetchableWidget`s for conditional visibility).

## Which decisions affect it
None specific — inherits [[Fetchable]]'s decisions.

## Examples of correct usage
See `rules/patterns.md` item 5.

## Common mistakes
`buildBusy: (_) => const SizedBox.shrink()` is the correct override for small/inline fields, not a
workaround to avoid — see `rules/patterns.md` item 5 for when to use it vs. leaving it unset.
