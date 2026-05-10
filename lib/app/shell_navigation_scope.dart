import 'package:flutter/widgets.dart';

/// Exposes page jumps for [BaigalaaShell]'s [PageView].
class ShellNavigationScope extends InheritedWidget {
  const ShellNavigationScope({
    super.key,
    required this.goToPage,
    required super.child,
  });

  final void Function(int index) goToPage;

  static ShellNavigationScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ShellNavigationScope>();
  }

  static ShellNavigationScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'ShellNavigationScope not found');
    return scope!;
  }

  @override
  bool updateShouldNotify(ShellNavigationScope oldWidget) =>
      goToPage != oldWidget.goToPage;
}
