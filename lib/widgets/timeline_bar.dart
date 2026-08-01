import 'package:fluent_ui/fluent_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';

class TimelineBar extends StatelessWidget {
  const TimelineBar({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Container(
      height: 72,
      color: const Color(0xFF222222),
      child: Column(
        children: [
          Container(
            height: 28,
            color: const Color(0xFF2A2A2A),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(2)),
                  child: Text(
                    "${app.currentFrame} F",
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(FluentIcons.previous, size: 12),
                      onPressed: () => app.setFrame(app.startFrame),
                    ),
                    IconButton(
                      icon: Icon(app.isPlaying ? FluentIcons.pause : FluentIcons.play, size: 12, color: Colors.orange),
                      onPressed: () => app.togglePlay(),
                    ),
                    IconButton(
                      icon: const Icon(FluentIcons.next, size: 12),
                      onPressed: () => app.setFrame(app.endFrame),
                    ),
                    const SizedBox(width: 12),
                    _buildKeyButton(
                      "Key",
                      Colors.red,
                      onTap: () => app.recordKeyframeForSelected(),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: Icon(FluentIcons.radio_btn_on, size: 12, color: app.isAutoKey ? Colors.red : Colors.grey[80]),
                      onPressed: () => app.toggleAutoKey(),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  "${app.startFrame} F < | > ${app.endFrame} F",
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[80]),
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                final int totalFrames = app.endFrame - app.startFrame;
                final double frameWidth = width / totalFrames;
                final double playheadX = (app.currentFrame - app.startFrame) * frameWidth;
                final selected = app.selectedObject;

                void handlePointer(Offset localPosition) {
                  final int newFrame = (localPosition.dx / frameWidth)
                      .clamp(app.startFrame.toDouble(), app.endFrame.toDouble())
                      .round();
                  app.setFrame(newFrame);
                }

                return GestureDetector(
                  onHorizontalDragUpdate: (details) => handlePointer(details.localPosition),
                  onTapDown: (details) => handlePointer(details.localPosition),
                  child: Container(
                    color: const Color(0xFF181818),
                    child: Stack(
                      children: [
                        Row(
                          children: List.generate(
                            (totalFrames / 4).ceil() + 1,
                            (index) {
                              final frameNum = index * 4;
                              return Expanded(
                                child: Container(
                                  alignment: Alignment.topLeft,
                                  decoration: BoxDecoration(
                                    border: Border(left: BorderSide(color: Colors.grey[160]!.withOpacity(0.3), width: 1)),
                                  ),
                                  padding: const EdgeInsets.only(left: 2, top: 2),
                                  child: Text(
                                    "$frameNum",
                                    style: GoogleFonts.inter(fontSize: 8, color: Colors.grey[100]),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (selected != null)
                          for (final key in selected.keyframes)
                            Positioned(
                              left: (key.frame - app.startFrame) * frameWidth - 4,
                              bottom: 3,
                              child: Transform.rotate(
                                angle: 0.785398, // 45deg, gives the classic keyframe diamond shape
                                child: Container(width: 6, height: 6, color: Colors.orange),
                              ),
                            ),
                        Positioned(
                          left: playheadX,
                          top: 0,
                          bottom: 0,
                          child: Container(width: 2, color: Colors.orange),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyButton(String label, Color color, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF333333),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: const Color(0xFF444444)),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }
}
