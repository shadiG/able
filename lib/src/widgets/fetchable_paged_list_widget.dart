import 'package:able/src/common/able_config.dart';
import 'package:able/src/fetchable/export.dart';
import 'package:able/src/paging/paged_list.dart';
import 'package:able/src/widgets/common.dart';
import 'package:flutter/material.dart';

/// Builds the footer shown when loading the next page failed. Call [retry]
/// to try that page again.
typedef BuildLoadMoreError = Widget Function(BuildContext context, dynamic error, VoidCallback retry);

/// A sliver list for a `Fetchable<PagedList<T>>` that asks for the next page
/// as the user nears the end.
///
/// - Before the first page: busy, error and empty states like
///   `FetchableListWidget`.
/// - After it: the items, plus a footer while the next page loads
///   ([buildLoadingMore]) or after it failed ([buildLoadMoreError]).
/// - [onLoadMore] is called once per loaded list when an item within
///   [loadMoreThreshold] of the end is built. Pair it with
///   `executeNextPage`, which ignores calls while a page is loading.
class FetchablePagedListWidget<T> extends StatefulWidget {
  const FetchablePagedListWidget({
    required this.fetchable,
    required this.buildItem,
    required this.onLoadMore,
    required this.buildEmpty,
    this.buildError,
    this.buildBusy,
    this.buildLoadingMore,
    this.buildLoadMoreError,
    this.separatorBuilder,
    this.loadMoreThreshold = 3,
    this.hasScrollBody = false,
    this.fillRemaining = true,
    super.key,
  });

  final Fetchable<PagedList<T>> fetchable;
  final BuildItem<T> buildItem;
  final VoidCallback onLoadMore;
  final BuildEmpty buildEmpty;

  /// First-page error. Falls back to `Able.configs.errorWidget`.
  final BuildError? buildError;

  /// First-page loading. Falls back to `Able.configs.loadingWidget`.
  final BuildBusy? buildBusy;

  /// Footer while the next page loads. Defaults to a small spinner.
  final BuildBusy? buildLoadingMore;

  /// Footer after the next page failed. Defaults to the error and a Retry
  /// button.
  final BuildLoadMoreError? buildLoadMoreError;

  final IndexedWidgetBuilder? separatorBuilder;

  /// How many items before the end the next page is requested.
  final int loadMoreThreshold;
  final bool hasScrollBody;
  final bool fillRemaining;

  @override
  State<FetchablePagedListWidget<T>> createState() => _FetchablePagedListWidgetState<T>();
}

class _FetchablePagedListWidgetState<T> extends State<FetchablePagedListWidget<T>> {
  /// The list a next page was last requested for, so one list asks once.
  PagedList<T>? _requestedFor;

  void _requestMore(PagedList<T> pages) {
    if (identical(_requestedFor, pages)) return;
    _requestedFor = pages;
    // Not during build: onLoadMore rebuilds the cubit that feeds this widget.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onLoadMore();
    });
  }

  Widget _stateSliver(Widget child) => widget.fillRemaining
      ? SliverFillRemaining(hasScrollBody: widget.hasScrollBody, child: child)
      : SliverToBoxAdapter(child: child);

  @override
  Widget build(BuildContext context) {
    final fetchable = widget.fetchable;

    if (!fetchable.hasLatestData) {
      if (fetchable.hasError) {
        return _stateSliver(widget.buildError?.call(context, fetchable.error) ??
            Able.configs.errorWidget?.call(context, fetchable.error) ??
            const SizedBox());
      }
      return _stateSliver(widget.buildBusy?.call(context) ?? Able.configs.loadingWidget ?? const SizedBox());
    }

    final pages = fetchable.latestData;
    final items = pages.items;
    final canLoadMore = fetchable.success && pages.hasMore;

    if (items.isEmpty) {
      if (canLoadMore) _requestMore(pages);
      if (fetchable.success && !pages.hasMore) return _stateSliver(widget.buildEmpty(context));
    }

    final Widget? footer = fetchable.busy
        ? (widget.buildLoadingMore?.call(context) ?? const _LoadingMoreFooter())
        : fetchable.hasError
            ? (widget.buildLoadMoreError?.call(context, fetchable.error, widget.onLoadMore) ??
                _LoadMoreErrorFooter(error: fetchable.error, retry: widget.onLoadMore))
            : null;

    final itemCount = items.length + (footer == null ? 0 : 1);
    Widget buildAt(BuildContext context, int i) {
      if (i >= items.length) return footer!;
      if (canLoadMore && i >= items.length - widget.loadMoreThreshold) _requestMore(pages);
      return widget.buildItem(context, items[i]);
    }

    if (widget.separatorBuilder != null) {
      return SliverList.separated(
        itemCount: itemCount,
        itemBuilder: buildAt,
        separatorBuilder: widget.separatorBuilder!,
      );
    }
    return SliverList(delegate: SliverChildBuilderDelegate(buildAt, childCount: itemCount));
  }
}

class _LoadingMoreFooter extends StatelessWidget {
  const _LoadingMoreFooter();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2))),
      );
}

class _LoadMoreErrorFooter extends StatelessWidget {
  const _LoadMoreErrorFooter({required this.error, required this.retry});

  final dynamic error;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$error', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextButton(onPressed: retry, child: const Text('Retry')),
          ],
        ),
      );
}
