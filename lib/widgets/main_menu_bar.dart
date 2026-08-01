import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../state/app_state.dart';

class MainMenuBar extends StatelessWidget {
  const MainMenuBar({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();

    final menus = <String, Map<String, VoidCallback?>>{
      "File": {
        "New Project (Ctrl+N)": () => app.newProject(),
        "Open Project...": null,
        "Save (Ctrl+S)": null,
        "---1": null,
        "Import...": null,
        "Export...": null,
      },
      "Edit": {
        "Undo (Ctrl+Z)": app.canUndo ? app.undo : null,
        "Redo (Ctrl+Y)": app.canRedo ? app.redo : null,
        "---1": null,
        "Delete (Del)": () => app.deleteSelected(),
        "---2": null,
        "Deselect All": () => app.selectObject(null),
      },
      "Create": {
        "Cube": () => app.addObject(ObjectType.cube),
        "Sphere": () => app.addObject(ObjectType.sphere),
        "Cone": () => app.addObject(ObjectType.cone),
        "Null": () => app.addObject(ObjectType.nullObj),
        "---1": null,
        "Light": () => app.addObject(ObjectType.light),
        "Camera": () => app.addObject(ObjectType.camera),
      },
      "Modes": {"Model": null, "Building": null, "Texture": null, "Workplane": null},
      "Select": {"Select All": null, "Deselect All": () => app.selectObject(null)},
      "Tools": {
        "Move (E)": () => app.setTool(ToolMode.move),
        "Rotate (R)": () => app.setTool(ToolMode.rotate),
        "Scale (T)": () => app.setTool(ToolMode.scale),
      },
      "Window": {"Layout": null, "Asset Browser": null, "Console": null},
      "Help": {"Documentation...": null, "About Cinema 4D UI": null},
    };

    return Material(
      color: const Color(0xFF2A2A2A),
      child: SizedBox(
        height: 24,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: menus.entries.map((entry) => _buildMenuDropdown(context, entry.key, entry.value)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuDropdown(BuildContext context, String title, Map<String, VoidCallback?> items) {
    return Theme(
      data: Theme.of(context).copyWith(cardColor: const Color(0xFF222222)),
      child: PopupMenuButton<String>(
        offset: const Offset(0, 22),
        elevation: 6,
        padding: EdgeInsets.zero,
        tooltip: '',
        color: const Color(0xFF262626),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFF141414), width: 1),
          borderRadius: BorderRadius.circular(2),
        ),
        onSelected: (key) => items[key]?.call(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
          child: Text(title, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[300])),
        ),
        itemBuilder: (BuildContext context) {
          return items.entries.map<PopupMenuEntry<String>>((entry) {
            if (entry.key.startsWith("---")) {
              return const PopupMenuDivider(height: 4);
            }
            return PopupMenuItem<String>(
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              value: entry.key,
              enabled: entry.value != null,
              child: Text(
                entry.key,
                style: GoogleFonts.inter(fontSize: 11, color: entry.value == null ? Colors.grey[700] : Colors.grey[300]),
              ),
            );
          }).toList();
        },
      ),
    );
  }
}
