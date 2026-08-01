import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

class TopActionBar extends StatelessWidget {
  const TopActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Container(
      height: 34,
      color: const Color(0xFF262626),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(icon: const Icon(FluentIcons.undo, size: 14), onPressed: app.canUndo ? app.undo : null),
          IconButton(icon: const Icon(FluentIcons.redo, size: 14), onPressed: app.canRedo ? app.redo : null),
          const Divider(direction: Axis.vertical),
          _buildAxisButton("X", Colors.red),
          _buildAxisButton("Y", Colors.green),
          _buildAxisButton("Z", Colors.blue),
          const Divider(direction: Axis.vertical),
          IconButton(icon: const Icon(FluentIcons.arrow_down_right8, size: 14), onPressed: () {}),
          IconButton(icon: const Icon(FluentIcons.move, size: 14), onPressed: () {}),
          IconButton(icon: const Icon(FluentIcons.size_legacy, size: 14), onPressed: () {}),
          IconButton(icon: const Icon(FluentIcons.sync_folder, size: 14), onPressed: () {}),
          const Divider(direction: Axis.vertical),
          IconButton(icon: const Icon(FluentIcons.snap_to_grid, size: 14), onPressed: () {}),
          IconButton(icon: const Icon(FluentIcons.globe, size: 14), onPressed: () {}),
          const Spacer(),
          IconButton(
            icon: Icon(FluentIcons.play, size: 14, color: Colors.orange),
            onPressed: () => app.togglePlay(),
          ),
          const SizedBox(width: 4),
          IconButton(icon: Icon(FluentIcons.camera, size: 14, color: Colors.orange), onPressed: () {}),
          const SizedBox(width: 4),
          IconButton(icon: const Icon(FluentIcons.settings, size: 14), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildAxisButton(String label, AccentColor color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.normal.withOpacity(0.2),
        border: Border.all(color: color.normal, width: 1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color.normal, fontWeight: FontWeight.bold)),
    );
  }
}
