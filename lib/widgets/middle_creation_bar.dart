import 'package:fluent_ui/fluent_ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../state/app_state.dart';

class MiddleCreationBar extends StatelessWidget {
  const MiddleCreationBar({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();

    return Container(
      width: 32,
      color: const Color(0xFF222222),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 4),
        children: [
          _ToolIconButton(
            icon: PhosphorIconsFill.cube,
            tooltip: "Create Cube",
            color: Colors.teal,
            onTap: () => app.addObject(ObjectType.cube),
          ),
          _ToolIconButton(
            icon: PhosphorIconsFill.circle,
            tooltip: "Create Sphere",
            color: Colors.teal,
            onTap: () => app.addObject(ObjectType.sphere),
          ),
          _ToolIconButton(
            icon: PhosphorIconsFill.triangle,
            tooltip: "Create Cone",
            color: Colors.teal,
            onTap: () => app.addObject(ObjectType.cone),
          ),
          const Divider(
            style: DividerThemeData(
              thickness: 1,
              horizontalMargin: EdgeInsets.symmetric(vertical: 4),
            ),
          ),
          _ToolIconButton(
            icon: PhosphorIconsRegular.crosshair,
            tooltip: "Create Null Object",
            color: Colors.orange,
            onTap: () => app.addObject(ObjectType.nullObj),
          ),
          const Divider(
            style: DividerThemeData(
              thickness: 1,
              horizontalMargin: EdgeInsets.symmetric(vertical: 4),
            ),
          ),
          _ToolIconButton(
            icon: PhosphorIconsFill.lightbulb,
            tooltip: "Create Light",
            color: Colors.yellow,
            onTap: () => app.addObject(ObjectType.light),
          ),
          _ToolIconButton(
            icon: PhosphorIconsBold.camera,
            tooltip: "Create Camera",
            color: Colors.white,
            onTap: () => app.addObject(ObjectType.camera),
          ),
          const Divider(
            style: DividerThemeData(
              thickness: 1,
              horizontalMargin: EdgeInsets.symmetric(vertical: 4),
            ),
          ),
          _ToolIconButton(
            icon: PhosphorIconsFill.key,
            tooltip: "Set Keyframe on Selected (K)",
            color: Colors.red,
            onTap: () => app.recordKeyframeForSelected(),
          ),
        ],
      ),
    );
  }
}

class _ToolIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _ToolIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      useMousePosition: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 28,
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}