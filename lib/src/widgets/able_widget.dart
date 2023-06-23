import 'dart:async';

import 'package:able/able.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef BuildSuccess<D> = Widget Function(BuildContext context, D data);
typedef BuildError = Widget Function(BuildContext context, dynamic error);
typedef BuildBusy = Widget Function(BuildContext context);

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
        return AbleConfigs().errorWidget != null
            ? AbleConfigs().errorWidget!(context, fetchable.error)
            : const SizedBox();
      }
    }
    if (fetchable.busy || (fetchable.idle && treatIdleAsBusy)) {
      return buildBusy != null ? buildBusy!(context) : AbleConfigs().loadingWidget ?? const SizedBox();
    }
    if (fetchable.success) {
      return buildSuccess(context, fetchable.data);
    }
    throw StateError('no case for $fetchable');
  }
}

class ProgressableResultPresenter<S> {
  final Progressable Function(S state) progressable;
  final String? Function(dynamic e)? errorToMessage;
  final bool Function(dynamic e)? shouldIgnoreMessage;
  final VoidCallback? onSuccess;
  final void Function(dynamic e)? onError;

  ProgressableResultPresenter({
    required this.progressable,
    this.errorToMessage,
    this.onSuccess,
    this.onError,
    this.shouldIgnoreMessage,
  });
}

class ProgressablesResultPresenter<C extends AbleCubit<S>, S> extends StatefulWidget {
  final Widget child;
  final List<ProgressableResultPresenter> presenters;

  const ProgressablesResultPresenter({
    required this.presenters,
    required this.child,
    super.key,
  });

  @override
  State<ProgressablesResultPresenter<C, S>> createState() => _ProgressablesResultPresenterState<C, S>();
}

class _ProgressablesResultPresenterState<C extends AbleCubit<S>, S> extends State<ProgressablesResultPresenter<C, S>> {
  late List<Progressable> lastProgressables;

  StreamSubscription<S>? cubitSubscription;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<C>();
    lastProgressables = cubitStateToProgressables(cubit.state);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      cubitSubscription = context.read<C>().stream.listen((state) {
        _handleCubitStateChanges(state);
        lastProgressables = cubitStateToProgressables(state);
      });
    });
  }

  @override
  void dispose() {
    cubitSubscription?.cancel();
    super.dispose();
  }

  List<Progressable> cubitStateToProgressables(S state) {
    return widget.presenters.map((p) => p.progressable(state)).toList();
  }

  void _handleCubitStateChanges(S s) {
    for (int i = 0; i < widget.presenters.length; i++) {
      final presenter = widget.presenters[i];
      final progressable = presenter.progressable(s);
      final lastProgressable = lastProgressables[i];

      if (progressable.success != lastProgressable.success && progressable.success) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          presenter.onSuccess?.call();
        });
      }

      if (progressable.error != lastProgressable.error && progressable.error != null) {
        final shouldIgnore = presenter.shouldIgnoreMessage?.call(progressable.error) ?? false;
        presenter.onError?.call(progressable.error);

        if (!shouldIgnore) {
          final message = presenter.errorToMessage?.call(progressable.error);
          ExceptionHandler().showError?.call(progressable.error, message);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
