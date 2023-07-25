import 'dart:async';

import 'package:able/able.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
          ExceptionHandler().onError?.call(progressable.error, message);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
