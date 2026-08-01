import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../state/app_state.dart';

class LeftToolBar extends StatelessWidget {
  const LeftToolBar({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Container(
      width: 32,
      color: const Color(0xFF222222),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 4),
        children: [
          _ToolIconButton(
            icon: PhosphorIconsFill.cursor,
            tooltip: "Live Selection (Q)",
            isActive: app.tool == ToolMode.select,
            onTap: () => app.setTool(ToolMode.select),
          ),
          const Divider(height: 8, color: Colors.black),
          _ToolIconButton(
            icon: PhosphorIconsFill.arrowsOutCardinal,
            tooltip: "Move Tool (E)",
            isActive: app.tool == ToolMode.move,
            onTap: () => app.setTool(ToolMode.move),
          ),
          _ToolIconButton(
            icon: PhosphorIconsFill.arrowsClockwise,
            tooltip: "Rotate Tool (R)",
            isActive: app.tool == ToolMode.rotate,
            onTap: () => app.setTool(ToolMode.rotate),
          ),
          _ToolIconButton(
            icon: PhosphorIconsFill.arrowsLeftRight,
            tooltip: "Scale Tool (T)",
            isActive: app.tool == ToolMode.scale,
            onTap: () => app.setTool(ToolMode.scale),
          ),
          const Divider(height: 8, color: Colors.black),
          _ToolIconButton(
            icon: PhosphorIconsFill.trash,
            tooltip: "Delete Selected (Backspace)",
            onTap: () => app.deleteSelected(),
          ),
          _ToolIconButton(
            icon: PhosphorIconsFill.arrowUUpLeft,
            tooltip: "Undo (Ctrl+Z)",
            onTap: app.canUndo ? app.undo : null,
          ),
          _ToolIconButton(
            icon: PhosphorIconsFill.arrowUUpRight,
            tooltip: "Redo (Ctrl+Y)",
            onTap: app.canRedo ? app.redo : null,
          ),
        ],
      ),
    );
  }
}

class _ToolIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final VoidCallback? onTap;

  const _ToolIconButton({
    required this.icon,
    required this.tooltip,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent, // Prevents background color conflicts
      child: Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 500),
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 28,
            margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF383838) : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
              border: isActive
                  ? Border.all(color: Colors.orangeAccent, width: 1)
                  : null,
            ),
            child: Icon(
              icon,
              size: 16,
              color: onTap == null
                  ? Colors.grey[700]
                  : (isActive ? Colors.orangeAccent : Colors.grey[400]),
            ),
          ),
        ),
      ),
    );
  }
}