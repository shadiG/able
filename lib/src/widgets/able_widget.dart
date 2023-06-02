
import 'package:able/able.dart';
import 'package:able/src/widgets/activity_indicator.dart';
import 'package:flutter/material.dart';

Widget widgetForFetchable<D>({
  required BuildContext context,
  required Fetchable<D> fetchable,
  required Widget Function(BuildContext context, D data) buildSuccess,
  Widget Function(BuildContext context)? buildBusy,
  required Widget Function(BuildContext context, dynamic error) buildError,
  bool treatIdleAsBusy = true,
}) {
  if(fetchable.idle && !treatIdleAsBusy) {
    return Container();
  }
  if(fetchable.error != null) {
    return buildError(context, fetchable.error);
  }
  if(fetchable.busy || (fetchable.idle && treatIdleAsBusy)) {
    return buildBusy != null ? buildBusy(context) : const ActivityIndicator();
  }
  if(fetchable.success) {
    return buildSuccess(context, fetchable.data);
  }
  throw StateError('no case for $fetchable');
}