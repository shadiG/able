import 'package:able/src/common/able_config.dart';
import 'package:able/src/fetchable/export.dart';
import 'package:able/src/widgets/common.dart';
import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';

abstract class BaseFetchablesListWidget<D> extends StatelessWidget {
  final Fetchable<BuiltList<D>> fetchable;
  final BuildItem<D> buildItem;
  final BuildError? buildError;
  final BuildBusy? buildBusy;
  final BuildEmpty buildEmpty;
  final bool treatIdleAsBusy;

  const BaseFetchablesListWidget({
    required this.fetchable,
    required this.buildItem,
    required this.buildError,
    required this.buildEmpty,
    super.key,
    this.buildBusy,
    this.treatIdleAsBusy = true,
  });
}

class FetchableListWidget<D> extends BaseFetchablesListWidget<D> {
  final bool hasScrollBody;
  final bool fillRemaining;
  const FetchableListWidget({
    required super.fetchable,
    required super.buildItem,
    required super.buildEmpty,
    super.buildError,
    super.buildBusy,
    super.key,
    super.treatIdleAsBusy = true,
    this.hasScrollBody = true,
    this.fillRemaining = true,
  });

  @override
  Widget build(BuildContext context) {
    if (fetchable.idle && !treatIdleAsBusy) {
      if (fillRemaining) {
        return const SliverFillRemaining(
          child: SizedBox(),
        );
      } else {
        return const SliverToBoxAdapter(
          child: SizedBox(),
        );
      }
    }
    if (fetchable.error != null) {
      if (buildError != null) {
        if (fillRemaining) {
          return SliverFillRemaining(
            hasScrollBody: hasScrollBody,
            child: buildError!(context, fetchable.error),
          );
        } else {
          return SliverToBoxAdapter(
            child: buildError!(context, fetchable.error),
          );
        }
      } else {
        if (fillRemaining) {
          return SliverFillRemaining(
            hasScrollBody: hasScrollBody,
            child: AbleConfigs().errorWidget != null
                ? AbleConfigs().errorWidget!(context, fetchable.error)
                : const SizedBox(),
          );
        } else {
          return SliverToBoxAdapter(
            child: AbleConfigs().errorWidget != null
                ? AbleConfigs().errorWidget!(context, fetchable.error)
                : const SizedBox(),
          );
        }
      }
    }
    if (fetchable.busy || (fetchable.idle && treatIdleAsBusy)) {
      if (fillRemaining) {
        return SliverFillRemaining(
            hasScrollBody: hasScrollBody,
            child: buildBusy != null ? buildBusy!(context) : AbleConfigs().loadingWidget ?? const SizedBox());
      } else {
        return SliverToBoxAdapter(
            child: buildBusy != null ? buildBusy!(context) : AbleConfigs().loadingWidget ?? const SizedBox());
      }
    }
    if (fetchable.success) {
      final data = fetchable.data;
      if (data.isEmpty) {
        if (fillRemaining) {
          return SliverFillRemaining(hasScrollBody: hasScrollBody, child: buildEmpty(context));
        } else {
          return SliverToBoxAdapter(child: buildEmpty(context));
        }
      }
      return SliverList(
        key: key,
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final element = data.elementAt(i);
            return buildItem(context, element);
          },
          childCount: data.length,
        ),
      );
    }
    throw StateError('no case for $fetchable');
  }
}
