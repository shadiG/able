import 'package:able/src/common/able_config.dart';
import 'package:able/src/fetchable/export.dart';
import 'package:able/src/widgets/common.dart';
import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';

abstract class BaseFetchableListWidget<D> extends StatelessWidget {
  final Fetchable<BuiltList<D>> fetchable;
  final BuildItem<D> buildItem;
  final BuildError? buildError;
  final BuildBusy? buildBusy;
  final BuildEmpty buildEmpty;
  final bool treatIdleAsBusy;

  /// When the fetchable is busy but kept earlier items, keep rendering them
  /// instead of the busy builder. Default true.
  final bool showLatestDataWhileBusy;

  const BaseFetchableListWidget({
    required this.fetchable,
    required this.buildItem,
    required this.buildError,
    required this.buildEmpty,
    super.key,
    this.buildBusy,
    this.treatIdleAsBusy = true,
    this.showLatestDataWhileBusy = true,
  });

  /// The box widget to show instead of the items (busy, error, empty), or
  /// null when the items should be rendered.
  @protected
  Widget? buildStateContent(BuildContext context) {
    if (fetchable.idle && !treatIdleAsBusy) return const SizedBox();
    if (fetchable.hasError) {
      return buildError?.call(context, fetchable.error) ??
          Able.configs.errorWidget?.call(context, fetchable.error) ??
          const SizedBox();
    }
    final showItems = fetchable.success || (fetchable.refreshing && showLatestDataWhileBusy);
    if (!showItems) {
      return buildBusy?.call(context) ?? Able.configs.loadingWidget ?? const SizedBox();
    }
    if (fetchable.latestData.isEmpty) return buildEmpty(context);
    return null;
  }
}

/// Base for the sliver variants: wraps the busy/error/empty content in a
/// sliver sized by [fillRemaining] and [hasScrollBody].
abstract class _BaseFetchableSliver<D> extends BaseFetchableListWidget<D> {
  final bool hasScrollBody;
  final bool fillRemaining;

  const _BaseFetchableSliver({
    required super.fetchable,
    required super.buildItem,
    required super.buildError,
    required super.buildEmpty,
    super.buildBusy,
    super.key,
    super.treatIdleAsBusy,
    super.showLatestDataWhileBusy,
    this.hasScrollBody = true,
    this.fillRemaining = true,
  });

  Widget buildItemsSliver(BuildContext context, BuiltList<D> items);

  @override
  Widget build(BuildContext context) {
    final stateContent = buildStateContent(context);
    if (stateContent == null) return buildItemsSliver(context, fetchable.latestData);
    return fillRemaining
        ? SliverFillRemaining(hasScrollBody: hasScrollBody, child: stateContent)
        : SliverToBoxAdapter(child: stateContent);
  }
}

/// A sliver list for a `Fetchable<BuiltList<D>>`, with busy, error and empty
/// states. Must be a direct child of a `CustomScrollView`'s `slivers`.
class FetchableListWidget<D> extends _BaseFetchableSliver<D> {
  /// Builds a separator between two items, like `ListView.separated`.
  final IndexedWidgetBuilder? separatorBuilder;

  const FetchableListWidget({
    required super.fetchable,
    required super.buildItem,
    required super.buildError,
    required super.buildEmpty,
    super.buildBusy,
    super.key,
    super.treatIdleAsBusy = true,
    super.showLatestDataWhileBusy = true,
    super.hasScrollBody = true,
    super.fillRemaining = true,
    this.separatorBuilder,
  });

  @override
  Widget buildItemsSliver(BuildContext context, BuiltList<D> items) {
    if (separatorBuilder != null) {
      return SliverList.separated(
        itemCount: items.length,
        itemBuilder: (context, i) => buildItem(context, items[i]),
        separatorBuilder: separatorBuilder!,
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) => buildItem(context, items[i]),
        childCount: items.length,
      ),
    );
  }
}

/// A sliver grid for a `Fetchable<BuiltList<D>>`, with busy, error and empty
/// states. Must be a direct child of a `CustomScrollView`'s `slivers`.
class FetchableSliverGrid<D> extends _BaseFetchableSliver<D> {
  final SliverGridDelegate gridDelegate;

  const FetchableSliverGrid({
    required super.fetchable,
    required super.buildItem,
    required super.buildEmpty,
    required this.gridDelegate,
    super.buildError,
    super.buildBusy,
    super.key,
    super.treatIdleAsBusy = true,
    super.showLatestDataWhileBusy = true,
    super.hasScrollBody = true,
    super.fillRemaining = true,
  });

  @override
  Widget buildItemsSliver(BuildContext context, BuiltList<D> items) => SliverGrid(
        gridDelegate: gridDelegate,
        delegate: SliverChildBuilderDelegate(
          (context, i) => buildItem(context, items[i]),
          childCount: items.length,
        ),
      );
}

/// A plain (box) list for a `Fetchable<BuiltList<D>>`, for places where a
/// sliver doesn't fit: the whole body of a screen, a sheet, a tab.
class FetchableListView<D> extends BaseFetchableListWidget<D> {
  final IndexedWidgetBuilder? separatorBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const FetchableListView({
    required super.fetchable,
    required super.buildItem,
    required super.buildEmpty,
    super.buildError,
    super.buildBusy,
    super.key,
    super.treatIdleAsBusy = true,
    super.showLatestDataWhileBusy = true,
    this.separatorBuilder,
    this.padding,
    this.controller,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final stateContent = buildStateContent(context);
    if (stateContent != null) return stateContent;
    final items = fetchable.latestData;
    if (separatorBuilder != null) {
      return ListView.separated(
        padding: padding,
        controller: controller,
        physics: physics,
        shrinkWrap: shrinkWrap,
        itemCount: items.length,
        itemBuilder: (context, i) => buildItem(context, items[i]),
        separatorBuilder: separatorBuilder!,
      );
    }
    return ListView.builder(
      padding: padding,
      controller: controller,
      physics: physics,
      shrinkWrap: shrinkWrap,
      itemCount: items.length,
      itemBuilder: (context, i) => buildItem(context, items[i]),
    );
  }
}
