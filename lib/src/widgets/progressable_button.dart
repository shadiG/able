import 'package:able/src/progressable/export.dart';
import 'package:flutter/material.dart';

/// Builds the button itself from the effective [onPressed] (null while busy)
/// and [child] (the spinner while busy).
typedef ProgressableButtonBuilder = Widget Function(BuildContext context, VoidCallback? onPressed, Widget child);

/// A button for an action tracked by a [Progressable]: disabled, with a
/// spinner in place of its label, while the action is busy. A busy value with
/// a `progress` shows a determinate spinner.
///
/// Renders a `FilledButton` unless [builder] is given, so an app can use its
/// own button: `builder: (context, onPressed, child) => MyButton(onTap: onPressed, child: child)`.
class ProgressableButton extends StatelessWidget {
  const ProgressableButton({
    required this.progressable,
    required this.onPressed,
    required this.child,
    this.builder,
    this.busyChild,
    this.busySemanticsLabel,
    super.key,
  });

  final Progressable progressable;
  final VoidCallback? onPressed;
  final Widget child;
  final ProgressableButtonBuilder? builder;

  /// Shown instead of [child] while busy. Defaults to a small spinner.
  final Widget? busyChild;

  /// Read by screen readers while busy, e.g. "Saving".
  final String? busySemanticsLabel;

  @override
  Widget build(BuildContext context) {
    final busy = progressable.busy;
    final effectiveOnPressed = busy ? null : onPressed;
    final content = busy
        ? Semantics(
            label: busySemanticsLabel,
            liveRegion: true,
            child: busyChild ??
                SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, value: progressable.progress),
                ),
          )
        : child;
    return builder?.call(context, effectiveOnPressed, content) ??
        FilledButton(onPressed: effectiveOnPressed, child: content);
  }
}
