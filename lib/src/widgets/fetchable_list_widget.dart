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
  const BaseFetchableListWidget({
    required this.fetchable,
    required this.buildItem,
    required this.buildError,
    required this.buildEmpty,
    super.key,
    this.buildBusy,
    this.treatIdleAsBusy = true,
  });
}

class FetchableListWidget<D> extends BaseFetchableListWidget<D> {
  final bool hasScrollBody;
  final bool fillRemaining;
  const FetchableListWidget({
    required super.fetchable,
    required super.buildItem,
    required super.buildError,
    required super.buildEmpty,
    super.buildBusy,
    super.key,
    super.treatIdleAsBusy = true,
    this.hasScrollBody = true,
    this.fillRemaining = true,
  });

  @override
  Widget build(BuildContext context) {
    if (fetchable.idle && !treatIdleAsBusy) {
      return fillRemaining
          ? const SliverFillRemaining(child: SizedBox())
          : const SliverToBoxAdapter(child: SizedBox());
    }
    if (fetchable.error != null) {
      final errorContent = (buildError != null
          ? buildError!(context, fetchable.error)
          : (Able.configs.errorWidget != null
              ? Able.configs.errorWidget!(context, fetchable.error)
              : const SizedBox()));

      return fillRemaining
          ? SliverFillRemaining(
              hasScrollBody: hasScrollBody,
              child: errorContent,
            )
          : SliverToBoxAdapter(
              child: errorContent,
            );
    }
    if (fetchable.busy || (fetchable.idle && treatIdleAsBusy)) {
      final busyContent = (buildBusy != null
          ? buildBusy!(context)
          : Able.configs.loadingWidget ?? const SizedBox());

      return fillRemaining
          ? SliverFillRemaining(
              hasScrollBody: hasScrollBody,
              child: busyContent,
            )
          : SliverToBoxAdapter(
              child: busyContent,
            );
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
