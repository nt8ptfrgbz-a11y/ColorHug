import 'package:flutter/widgets.dart';

/// Describes the page underneath a game opened directly from the catalog.
/// Routes opened within the game keep their existing navigation labels.
class GameEntryNavigation extends InheritedWidget {
  const GameEntryNavigation({
    super.key,
    required this.backLabel,
    required super.child,
  });

  final String backLabel;

  static String label(BuildContext context, String fallback) =>
      context
          .dependOnInheritedWidgetOfExactType<GameEntryNavigation>()
          ?.backLabel ??
      fallback;

  @override
  bool updateShouldNotify(GameEntryNavigation oldWidget) =>
      backLabel != oldWidget.backLabel;
}
