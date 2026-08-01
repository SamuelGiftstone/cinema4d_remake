import 'package:fluent_ui/fluent_ui.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTitleBar extends StatelessWidget {
  const CustomTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      color: Colors.white,
      child: WindowTitleBarBox(
        child: Row(
          children: [
            Expanded(
              child: MoveWindow(
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                     Image.network('https://e7.pngegg.com/pngimages/1017/118/png-clipart-cinema-4d-3d-computer-graphics-autodesk-maya-3d-modeling-motion-graphics-cinema-material-angle-3d-computer-graphics.png', height: 10,),
                    const SizedBox(width: 8),
                    Text(
                      "Cinema 4D Remake - [New_prject.c4d] * - Main",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF222222),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            MinimizeWindowButton(colors: lightWindowTitleButtonColors),
            MaximizeWindowButton(colors: lightWindowTitleButtonColors),
            CloseWindowButton(colors: lightCloseButtonColors),
          ],
        ),
      ),
    );
  }
}

final lightWindowTitleButtonColors = WindowButtonColors(
  iconNormal: const Color(0xFF333333),
  mouseOver: const Color(0xFFE5E5E5),
  mouseDown: const Color(0xFFCCCCCC),
  iconMouseOver: Colors.black,
  iconMouseDown: Colors.black,
);

final lightCloseButtonColors = WindowButtonColors(
  iconNormal: const Color(0xFF333333),
  mouseOver: const Color(0xFFE81123),
  mouseDown: const Color(0xFFF1707A),
  iconMouseOver: Colors.white,
  iconMouseDown: Colors.white,
);