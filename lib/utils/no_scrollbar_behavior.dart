// lib/utils/no_scrollbar_behavior.dart
import 'package:flutter/material.dart';

class NoScrollbarBehavior extends ScrollBehavior {
  const NoScrollbarBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Return child directly without wrapping in a Scrollbar widget
    return child;
  }
}