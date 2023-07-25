import 'package:flutter/material.dart';

typedef BuildItem<D> = Widget Function(BuildContext context, D element);
typedef BuildEmpty<D> = Widget Function(BuildContext context);
typedef BuildSuccess<D> = Widget Function(BuildContext context, D data);
typedef BuildError = Widget Function(BuildContext context, dynamic error);
typedef BuildBusy = Widget Function(BuildContext context);
