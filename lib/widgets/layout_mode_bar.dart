import 'package:fluent_ui/fluent_ui.dart';
import 'package:google_fonts/google_fonts.dart';

class LayoutModeBar extends StatelessWidget {
  const LayoutModeBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      color: const Color(0xFF222222),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          _buildTab("01|EngineD...tres.c4d", false),
          _buildTab("02|MaxonOne.c4d", false),
          _buildTab("03|NewModelingTool.c4d", false),
          _buildTab("04|NewMode...emesher.c4d", false),
          _buildTab("2b_Modelin...mesher.c4d", true),
          const Spacer(),
          _buildLayoutButton("Standard", true),
          _buildLayoutButton("Model", false),
          _buildLayoutButton("Sculpt", false),
          _buildLayoutButton("UV Edit", false),
          _buildLayoutButton("Paint", false),
          _buildLayoutButton("Groom", false),
          _buildLayoutButton("Track", false),
          _buildLayoutButton("Script", false),
          const SizedBox(width: 8),
          const Icon(FluentIcons.view_all, size: 12, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            "New Layouts",
            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[100]),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool active) {
    return Container(
      margin: const EdgeInsets.only(right: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF333333) : const Color(0xFF1E1E1E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          color: active ? Colors.white : Colors.grey[80],
        ),
      ),
    );
  }

  Widget _buildLayoutButton(String label, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.0),
      child: Button(
        style: ButtonStyle(
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
          backgroundColor: WidgetStateProperty.all(
            active ? const Color(0xFF005A9E) : Colors.transparent,
          ),
        ),
        onPressed: () {},
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: active ? Colors.white : Colors.grey[100],
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}