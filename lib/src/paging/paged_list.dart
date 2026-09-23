import 'package:built_collection/built_collection.dart';

/// One page returned by a paged source: its items, and the key of the next
/// page (`null` when this is the last page).
class PageResult<T> {
  const PageResult({required this.items, this.nextPageKey});

  final Iterable<T> items;

  /// Passed back to the fetch function to load the following page. Anything
  /// the source understands: a page number, a cursor, an offset.
  final Object? nextPageKey;
}

/// Every item loaded so far from a paged source, plus where to continue.
///
/// Held as `Fetchable<PagedList<T>>`; load pages with
/// `AblePagingExtension.executeNextPage` and render with
/// `FetchablePagedListWidget`.
class PagedList<T> {
  const PagedList._({required this.items, required this.nextPageKey, required this.hasMore});

  /// Nothing loaded yet; the first fetch uses [firstPageKey].
  PagedList.empty({Object? firstPageKey})
      : items = BuiltList<T>(),
        nextPageKey = firstPageKey,
        hasMore = true;

  final BuiltList<T> items;

  /// The key for the next fetch. Meaningless when [hasMore] is false.
  final Object? nextPageKey;

  /// Whether another page can be loaded.
  final bool hasMore;

  /// A new list with [page]'s items added at the end.
  PagedList<T> append(PageResult<T> page) => PagedList._(
        items: items.rebuild((b) => b.addAll(page.items)),
        nextPageKey: page.nextPageKey,
        hasMore: page.nextPageKey != null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PagedList && other.items == items && other.nextPageKey == nextPageKey && other.hasMore == hasMore;

  @override
  int get hashCode => Object.hash(items, nextPageKey, hasMore);

  @override
  String toString() => 'PagedList(${items.length} items, ${hasMore ? 'next: $nextPageKey' : 'complete'})';
}
