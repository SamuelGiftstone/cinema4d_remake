import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Size;
import 'package:provider/provider.dart';

import 'state/app_state.dart';
import 'views/home_page.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const C4DApp(),
    ),
  );

  doWhenWindowReady(() {
    const initialSize = Size(1200, 600);
    appWindow.minSize = const Size(1200, 600);
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.title = "Cinema 4D R26/S26";
    appWindow.show();
  });
}

/// Custom ScrollBehavior that completely removes visible scrollbars
/// while retaining mouse wheel and touch scrolling capabilities.
class NoScrollbarBehavior extends FluentScrollBehavior {
  const NoScrollbarBehavior();

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class C4DApp extends StatelessWidget {
  const C4DApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      debugShowCheckedModeBanner: false,
      title: 'Cinema 4D UI',
      themeMode: ThemeMode.dark,
      scrollBehavior: const NoScrollbarBehavior(),
      darkTheme: FluentThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1B1B1B),
        cardColor: const Color(0xFF262626),
        dividerTheme: const DividerThemeData(
          thickness: 1,
          horizontalMargin: EdgeInsets.zero,
          verticalMargin: EdgeInsets.zero,
        ),
        accentColor: Colors.teal,
      ),
      home: const HomePage(),
    );
  }
}
