import 'dart:async';

import 'package:able/able.dart';

extension AblePagingExtension<S> on AbleCubit<S> {
  /// Loads the page after [current] and reports the new list through [then].
  ///
  /// - While loading, [then] receives a busy value that keeps the items
  ///   already loaded (`refreshing`), so the list stays on screen with a
  ///   loading footer. A failed page keeps them too, as an error.
  /// - [refresh] starts again from [firstPageKey], keeping the old items on
  ///   screen until the first page arrives.
  /// - Returns null, doing nothing, when there is no next page, or when a
  ///   page is already loading and this is not a [refresh].
  ///
  /// [key] identifies this list, so a refresh cancels a page still loading
  /// for it (see `executeSF`'s `key`).
  ///
  /// ```dart
  /// void loadMore({bool refresh = false}) => executeNextPage<Country>(
  ///       key: #countries,
  ///       current: state.countriesF,
  ///       refresh: refresh,
  ///       firstPageKey: 0,
  ///       fetch: (page) => repository.fetchPage(page as int),
  ///       then: (countriesF) => rebuild(state.rebuild((b) => b..countriesF = countriesF)),
  ///     );
  /// ```
  StreamSubscription? executeNextPage<T>({
    required Object key,
    required Fetchable<PagedList<T>> current,
    required Future<PageResult<T>> Function(Object? pageKey) fetch,
    required void Function(Fetchable<PagedList<T>> pagesF) then,
    bool refresh = false,
    Object? firstPageKey,
    bool Function(dynamic e)? isExpectedError,
    void Function(dynamic e, StackTrace s)? onUnexpectedError,
  }) {
    if (!refresh && current.busy) return null;
    final base = refresh || !current.hasLatestData ? PagedList<T>.empty(firstPageKey: firstPageKey) : current.latestData;
    if (!base.hasMore) return null;

    return executeSF(
      futureAsFetchable(() async => base.append(await fetch(base.nextPageKey))),
      key: key,
      then: (pagesF) => then(pagesF.keepingDataOf(current)),
      isExpectedError: isExpectedError,
      onUnexpectedError: onUnexpectedError,
    );
  }
}
