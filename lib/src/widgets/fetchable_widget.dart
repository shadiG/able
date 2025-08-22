import 'package:able/src/common/able_config.dart';
import 'package:able/src/fetchable/export.dart';
import 'package:able/src/widgets/common.dart';
import 'package:flutter/material.dart';

abstract class BaseFetchableWidget<D> extends StatelessWidget {
  final Fetchable<D> fetchable;
  final BuildSuccess<D> buildSuccess;
  final BuildError? buildError;
  final BuildBusy? buildBusy;
  final bool treatIdleAsBusy;

  const BaseFetchableWidget({
    required this.fetchable,
    required this.buildSuccess,
    required this.buildError,
    super.key,
    this.buildBusy,
    this.treatIdleAsBusy = true,
  });
}

class FetchableWidget<D> extends BaseFetchableWidget<D> {
  const FetchableWidget({
    required super.fetchable,
    required super.buildSuccess,
    super.buildError,
    super.buildBusy,
    super.key,
    super.treatIdleAsBusy = true,
  });

  @override
  Widget build(BuildContext context) {
    if (fetchable.idle && !treatIdleAsBusy) {
      return const SizedBox();
    }
    if (fetchable.error != null) {
      if (buildError != null) {
        return buildError!(context, fetchable.error);
      } else {
        return Able.configs.errorWidget != null
            ? Able.configs.errorWidget!(context, fetchable.error)
            : const SizedBox();
      }
    }
    if (fetchable.busy || (fetchable.idle && treatIdleAsBusy)) {
      return buildBusy != null
          ? buildBusy!(context)
          : Able.configs.loadingWidget ?? const SizedBox();
    }
    if (fetchable.success) {
      return buildSuccess(context, fetchable.data);
    }
    throw StateError('no case for $fetchable');
  }
}
