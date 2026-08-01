import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../state/app_state.dart';
import '../widgets/attributes_panel.dart';
import '../widgets/custom_title_bar.dart';
import '../widgets/dockable_panel.dart';
import '../widgets/layout_mode_bar.dart';
import '../widgets/left_tool_bar.dart';
import '../widgets/main_menu_bar.dart';
import '../widgets/middle_creation_bar.dart';
import '../widgets/objects_panel.dart';
import '../widgets/status_bar.dart';
import '../widgets/timeline_bar.dart';
import '../widgets/top_action_bar.dart';
import '../widgets/viewport_area.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late MultiSplitViewController _mainHorizontalController;
  late MultiSplitViewController _centerVerticalController;
  late MultiSplitViewController _rightVerticalController;
  final FocusNode _shortcutFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    _centerVerticalController = MultiSplitViewController(
      areas: [
        Area(flex: 4, min: 180, builder: (context, area) => const DockablePanel(title: "Viewport", child: ViewportArea())),
        Area(
          flex: 1,
          min: 80,
          max: 350,
          builder: (context, area) => const DockablePanel(title: "Timeline / Dope Sheet", child: TimelineBar()),
        ),
      ],
    );

    _rightVerticalController = MultiSplitViewController(
      areas: [
        Area(flex: 1, min: 120, builder: (context, area) => const DockablePanel(title: "Objects", child: ObjectsPanel())),
        Area(flex: 1, min: 120, builder: (context, area) => const DockablePanel(title: "Attributes", child: AttributesPanel())),
      ],
    );

    _mainHorizontalController = MultiSplitViewController(
      areas: [
        Area(
          flex: 7,
          min: 400,
          builder: (context, area) => MultiSplitView(axis: Axis.vertical, controller: _centerVerticalController),
        ),
        Area(
          flex: 3,
          min: 220,
          max: 550,
          builder: (context, area) => MultiSplitView(axis: Axis.vertical, controller: _rightVerticalController),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _shortcutFocus.dispose();
    super.dispose();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final app = context.read<AppState>();
    final isCtrl = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;

    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyZ) {
      app.undo();
      return KeyEventResult.handled;
    }
    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyY) {
      app.redo();
      return KeyEventResult.handled;
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.keyQ:
        app.setTool(ToolMode.select);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyE:
        app.setTool(ToolMode.move);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyR:
        app.setTool(ToolMode.rotate);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyT:
        app.setTool(ToolMode.scale);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyK:
        app.recordKeyframeForSelected();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.delete:
      case LogicalKeyboardKey.backspace:
        app.deleteSelected();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.space:
        app.togglePlay();
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    final MultiSplitViewThemeData splitTheme = MultiSplitViewThemeData(
      dividerThickness: 4,
      dividerPainter: DividerPainters.grooved1(color: const Color(0xFF141414), highlightedColor: Colors.orange),
    );

    return Focus(
      focusNode: _shortcutFocus,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: ScaffoldPage(
        padding: EdgeInsets.zero,
        content: Column(
          children: [
            const CustomTitleBar(),
            const LayoutModeBar(),
            const MainMenuBar(),
            const TopActionBar(),
            Expanded(
              child: Row(
                children: [
                  const SizedBox(width: 44, child: LeftToolBar()),
                  Expanded(
                    child: MultiSplitViewTheme(
                      data: splitTheme,
                      child: MultiSplitView(axis: Axis.horizontal, controller: _mainHorizontalController),
                    ),
                  ),
                  const SizedBox(width: 38, child: MiddleCreationBar()),
                ],
              ),
            ),
            const StatusBar(),
          ],
        ),
      ),
    );
  }
}
