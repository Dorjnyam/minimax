import 'package:flutter/material.dart';

class FixedTextScale extends StatelessWidget {
  const FixedTextScale({super.key, required this.child});

  final Widget child;

  static Widget builder(BuildContext context, Widget? child) {
    return FixedTextScale(child: child ?? const SizedBox.shrink());
  }

  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.maybeOf(context);
    if (data == null) {
      return child;
    }
    return MediaQuery(
      data: data.copyWith(textScaler: TextScaler.noScaling),
      child: child,
    );
  }
}
