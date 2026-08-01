import 'package:fluent_ui/fluent_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final selected = app.selectedObject;

    return Container(
      height: 20,
      color: const Color(0xFF141414),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Text(
            selected == null
                ? "No object selected"
                : "${selected.name}: pos ${selected.position}  rot ${selected.rotation}  scale ${selected.scale}",
            style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[80]),
          ),
          const Spacer(),
          Text(
            "Tool: ${app.tool.name}   Frame: ${app.currentFrame}/${app.endFrame}",
            style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[100]),
          ),
        ],
      ),
    );
  }
}
