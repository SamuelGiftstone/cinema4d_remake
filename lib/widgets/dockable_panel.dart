import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// A panel container with a title bar offering collapse and "undock to a
/// floating dialog" actions. Used to wrap Viewport/Timeline/Objects/
/// Attributes inside the resizable split layout.
class DockablePanel extends StatefulWidget {
  final String title;
  final Widget child;
  final bool showTitleBar;

  const DockablePanel({
    super.key,
    required this.title,
    required this.child,
    this.showTitleBar = true,
  });

  @override
  State<DockablePanel> createState() => _DockablePanelState();
}

class _DockablePanelState extends State<DockablePanel> {
  bool _isCollapsed = false;
  bool _isUndocked = false;

  void _undockPanel() {
    setState(() => _isUndocked = true);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return ContentDialog(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 550),
          content: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF242424),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF333333), width: 1),
            ),
            child: Column(
              children: [
                Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  color: const Color(0xFF1C1C1C),
                  child: Row(
                    children: [
                      Icon(PhosphorIconsBold.dotsSixVertical, size: 12, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        "${widget.title.toUpperCase()} (FLOATING DOCK)",
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 12),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(child: widget.child),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      if (mounted) setState(() => _isUndocked = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        border: Border.all(color: const Color(0xFF1B1B1B), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showTitleBar)
            Container(
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              color: const Color(0xFF1C1C1C),
              child: Row(
                children: [
                  Icon(PhosphorIconsBold.dotsSixVertical, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    widget.title.toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFFA0A0A0), letterSpacing: 0.5),
                  ),
                  const Spacer(),
                  _buildActionButton(icon: PhosphorIconsRegular.cornersOut, tooltip: "Undock Panel", onTap: _undockPanel),
                  _buildActionButton(
                    icon: _isCollapsed ? PhosphorIconsRegular.caretDown : PhosphorIconsRegular.caretUp,
                    tooltip: _isCollapsed ? "Expand" : "Collapse",
                    onTap: () => setState(() => _isCollapsed = !_isCollapsed),
                  ),
                ],
              ),
            ),
          if (!_isCollapsed)
            Expanded(
              child: _isUndocked
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(PhosphorIconsRegular.arrowSquareOut, size: 24, color: Colors.grey),
                          const SizedBox(height: 6),
                          Text("Panel Undocked", style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    )
                  : widget.child,
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String tooltip, required VoidCallback onTap}) {
    return Tooltip(
      message: tooltip,
      child: IconButton(icon: Icon(icon, size: 11, color: Colors.grey), onPressed: onTap),
    );
  }
}
