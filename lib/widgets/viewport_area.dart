import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/scene_object.dart';
import '../state/app_state.dart';
import '../utils/vec3.dart';

/// Projects world-space points into screen space for a given camera + size.
/// This is a hand-rolled perspective projection (no external 3D engine),
/// good enough for a wireframe / gizmo style viewport.
class Projector {
  final OrbitCamera camera;
  final Size size;
  late final Vec3 camPos;
  late final Vec3 forward;
  late final Vec3 right;
  late final Vec3 up;
  final double focal;

  Projector(this.camera, this.size) : focal = size.shortestSide * 0.9 {
    camPos = camera.position;
    forward = (camera.target - camPos).normalized;
    var r = forward.cross(const Vec3(0, 1, 0));
    if (r.length < 1e-6) r = const Vec3(1, 0, 0);
    right = r.normalized;
    up = right.cross(forward).normalized;
  }

  /// Returns null if the point is behind the camera (can't be projected).
  Offset? project(Vec3 p) {
    final rel = p - camPos;
    final vz = rel.dot(forward);
    if (vz < 8) return null;
    final vx = rel.dot(right);
    final vy = rel.dot(up);
    return Offset(
      size.width / 2 + vx / vz * focal,
      size.height / 2 - vy / vz * focal,
    );
  }

  double depthOf(Vec3 p) => (p - camPos).dot(forward);
}

const _gizmoAxes = [Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 1)];
const _gizmoColors = [Color(0xFFE53935), Color(0xFF66BB6A), Color(0xFF42A5F5)];

class ViewportArea extends StatefulWidget {
  const ViewportArea({super.key});

  static const Map<String, List<String>> viewportMenus = {
    "View": ["Default Camera", "Redraw (F5)", "---", "Frame Selected (S)", "Frame All (H)"],
    "Cameras": ["Perspective", "Top (F2)", "Right (F3)", "Front (F4)"],
    "Display": ["Gouraud Shading", "Wireframe", "Isoparms"],
    "Options": ["Level of Detail", "SSAO", "Shadows"],
    "Filter": ["All", "None"],
    "Panel": ["Single View (F1)", "4 Views (F5)"],
  };

  @override
  State<ViewportArea> createState() => _ViewportAreaState();
}

enum _DragMode { none, orbit, axis }

class _ViewportAreaState extends State<ViewportArea> {
  _DragMode _dragMode = _DragMode.none;
  Vec3? _dragAxis;
  Offset? _dragAxisScreenDir;

  void _handleTapUp(TapUpDetails details, AppState app, Size size) {
    final projector = Projector(app.camera, size);
    String? hitId;
    double bestDepth = double.infinity;
    for (final obj in app.objects) {
      if (!obj.visibleInEditor) continue;
      final screen = projector.project(obj.position);
      if (screen == null) continue;
      final depth = projector.depthOf(obj.position);
      final dist = (screen - details.localPosition).distance;
      final hitRadius = (900 / depth).clamp(6.0, 18.0);
      if (dist <= hitRadius && depth < bestDepth) {
        bestDepth = depth;
        hitId = obj.id;
      }
    }
    app.selectObject(hitId);
  }

  void _handlePanStart(DragStartDetails details, AppState app, Size size) {
    final selected = app.selectedObject;
    if (selected != null) {
      final projector = Projector(app.camera, size);
      final origin = projector.project(selected.position);
      if (origin != null) {
        final gizmoWorldLen = (selected.type == ObjectType.light || selected.type == ObjectType.camera)
            ? 60.0
            : 70.0;
        double bestDist = 16; // px hit threshold
        Vec3? bestAxis;
        Offset? bestDir;
        for (var i = 0; i < _gizmoAxes.length; i++) {
          final tip = projector.project(selected.position + _gizmoAxes[i] * gizmoWorldLen);
          if (tip == null) continue;
          final dist = _distanceToSegment(details.localPosition, origin, tip);
          if (dist < bestDist) {
            bestDist = dist;
            bestAxis = _gizmoAxes[i];
            final dir = tip - origin;
            bestDir = dir.distance > 0 ? dir / dir.distance : const Offset(1, 0);
          }
        }
        if (bestAxis != null) {
          _dragMode = _DragMode.axis;
          _dragAxis = bestAxis;
          _dragAxisScreenDir = bestDir;
          app.beginTransformGesture(selected.id);
          return;
        }
      }
    }
    _dragMode = _DragMode.orbit;
  }

  void _handlePanUpdate(DragUpdateDetails details, AppState app) {
    if (_dragMode == _DragMode.axis && _dragAxis != null && _dragAxisScreenDir != null) {
      final selected = app.selectedObject;
      if (selected == null) return;
      final screenDelta = details.delta.dx * _dragAxisScreenDir!.dx + details.delta.dy * _dragAxisScreenDir!.dy;
      final worldPerPixel = app.camera.distance / 700;
      switch (app.tool) {
        case ToolMode.move:
        case ToolMode.select:
          final amount = screenDelta * worldPerPixel;
          app.setPosition(selected.id, selected.position + _dragAxis! * amount, commit: false);
          break;
        case ToolMode.rotate:
          final degrees = screenDelta * 0.6;
          app.setRotation(selected.id, selected.rotation + _dragAxis! * degrees, commit: false);
          break;
        case ToolMode.scale:
          final factor = 1 + screenDelta * 0.01;
          final s = selected.scale;
          final newScale = Vec3(
            _dragAxis!.x != 0 ? (s.x * factor).clamp(0.05, 50.0) : s.x,
            _dragAxis!.y != 0 ? (s.y * factor).clamp(0.05, 50.0) : s.y,
            _dragAxis!.z != 0 ? (s.z * factor).clamp(0.05, 50.0) : s.z,
          );
          app.setScale(selected.id, newScale, commit: false);
          break;
      }
    } else if (_dragMode == _DragMode.orbit) {
      app.camera.orbit(details.delta.dx * 0.008, -details.delta.dy * 0.008);
      setState(() {});
    }
  }

  void _handlePanEnd(DragEndDetails details, AppState app) {
    if (_dragMode == _DragMode.axis) {
      app.endTransformGesture();
    }
    _dragMode = _DragMode.none;
    _dragAxis = null;
    _dragAxisScreenDir = null;
  }

  double _distanceToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final lenSq = ab.dx * ab.dx + ab.dy * ab.dy;
    if (lenSq < 1e-6) return (p - a).distance;
    final t = (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / lenSq).clamp(0.0, 1.0);
    final proj = a + ab * t;
    return (p - proj).distance;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Expanded(
      child: Material(
        color: const Color(0xFF181818),
        child: Column(
          children: [
            Container(
              height: 22,
              color: const Color(0xFF222222),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  ...ViewportArea.viewportMenus.entries.map((entry) => _buildViewportMenu(context, entry.key, entry.value)),
                  const Spacer(),
                  if (app.selectedObject != null)
                    Text(
                      '${app.selectedObject!.name}  •  ${app.tool.name}',
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.orangeAccent),
                    ),
                  const SizedBox(width: 8),
                  Text('Perspective', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500])),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  return Listener(
                    onPointerSignal: (event) {
                      if (event is PointerScrollEvent) {
                        app.camera.dolly(event.scrollDelta.dy * 0.0012);
                        setState(() {});
                      }
                    },
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (d) => _handleTapUp(d, app, size),
                      onPanStart: (d) => _handlePanStart(d, app, size),
                      onPanUpdate: (d) => _handlePanUpdate(d, app),
                      onPanEnd: (d) => _handlePanEnd(d, app),
                      child: CustomPaint(
                        size: size,
                        painter: _ViewportPainter(app),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewportMenu(BuildContext context, String title, List<String> items) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 20),
      elevation: 4,
      color: const Color(0xFF262626),
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0),
        child: Text(title, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[300])),
      ),
      itemBuilder: (context) => items
          .map<PopupMenuEntry<String>>((item) => item == "---"
              ? const PopupMenuDivider(height: 4)
              : PopupMenuItem<String>(
                  height: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  value: item,
                  child: Text(item, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[300])),
                ))
          .toList(),
    );
  }
}

class _ViewportPainter extends CustomPainter {
  final AppState app;
  _ViewportPainter(this.app) : super(repaint: null);

  @override
  void paint(Canvas canvas, Size size) {
    final projector = Projector(app.camera, size);
    _drawGrid(canvas, projector);
    _drawWorldAxisGizmo(canvas, size);

    final sorted = [...app.objects.where((o) => o.visibleInEditor)];
    sorted.sort((a, b) => projector.depthOf(b.position).compareTo(projector.depthOf(a.position)));

    for (final obj in sorted) {
      _drawObject(canvas, projector, obj, obj.id == app.selectedId);
    }

    final selected = app.selectedObject;
    if (selected != null) {
      _drawGizmo(canvas, projector, selected, app.tool);
    }
  }

  void _drawGrid(Canvas canvas, Projector p) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;
    const extent = 500.0;
    const step = 50.0;
    for (double i = -extent; i <= extent; i += step) {
      final a = p.project(Vec3(i, 0, -extent));
      final b = p.project(Vec3(i, 0, extent));
      if (a != null && b != null) canvas.drawLine(a, b, paint);
      final c = p.project(Vec3(-extent, 0, i));
      final d = p.project(Vec3(extent, 0, i));
      if (c != null && d != null) canvas.drawLine(c, d, paint);
    }
  }

  void _drawWorldAxisGizmo(Canvas canvas, Size size) {
    final labels = [
      ('X', const Color(0xFFEF5350)),
      ('Y', const Color(0xFF66BB6A)),
      ('Z', const Color(0xFF42A5F5)),
    ];
    double dy = size.height - 54;
    for (final (label, color) in labels) {
      final tp = TextPainter(
        text: TextSpan(text: '$label-Axis', style: GoogleFonts.firaCode(fontSize: 9, color: color)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(12, dy));
      dy += 13;
    }
  }

  void _drawObject(Canvas canvas, Projector p, SceneObject obj, bool selected) {
    final center = p.project(obj.position);
    if (center == null) return;
    final depth = p.depthOf(obj.position);
    final dotColor = selected ? Colors.orangeAccent : obj.color;

    switch (obj.type) {
      case ObjectType.cube:
        _drawCube(canvas, p, obj, dotColor);
        break;
      case ObjectType.sphere:
        _drawSphere(canvas, p, obj, dotColor);
        break;
      case ObjectType.cone:
        _drawCone(canvas, p, obj, dotColor);
        break;
      case ObjectType.light:
        _drawLightIcon(canvas, center, depth, dotColor);
        break;
      case ObjectType.camera:
        _drawCameraIcon(canvas, p, obj, dotColor);
        break;
      case ObjectType.nullObj:
      case ObjectType.spline:
        _drawCross(canvas, center, depth, dotColor);
        break;
    }

    final labelPaint = TextPainter(
      text: TextSpan(
        text: obj.name,
        style: GoogleFonts.inter(fontSize: 9, color: selected ? Colors.orangeAccent : Colors.grey[400]),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelPaint.paint(canvas, center + const Offset(8, -6));
  }

  void _drawCube(Canvas canvas, Projector p, SceneObject obj, Color color) {
    final s = obj.scale;
    final hx = 45.0 * s.x, hy = 45.0 * s.y, hz = 45.0 * s.z;
    final corners = <Vec3>[
      for (final sx in [-1, 1])
        for (final sy in [-1, 1])
          for (final sz in [-1, 1]) obj.position + Vec3(sx * hx, sy * hy, sz * hz),
    ];
    final pts = corners.map((c) => p.project(c)).toList();
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    const edges = [
      [0, 1], [0, 2], [0, 4], [1, 3], [1, 5], [2, 3],
      [2, 6], [3, 7], [4, 5], [4, 6], [5, 7], [6, 7],
    ];
    for (final e in edges) {
      final a = pts[e[0]];
      final b = pts[e[1]];
      if (a != null && b != null) canvas.drawLine(a, b, paint);
    }
  }

  void _drawSphere(Canvas canvas, Projector p, SceneObject obj, Color color) {
    final r = 45.0 * obj.scale.x;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    const segments = 24;
    for (final plane in ['xy', 'xz', 'yz']) {
      Offset? prev;
      for (var i = 0; i <= segments; i++) {
        final t = (i / segments) * 2 * math.pi;
        Vec3 pt;
        switch (plane) {
          case 'xy':
            pt = obj.position + Vec3(math.cos(t) * r, math.sin(t) * r, 0);
            break;
          case 'xz':
            pt = obj.position + Vec3(math.cos(t) * r, 0, math.sin(t) * r);
            break;
          default:
            pt = obj.position + Vec3(0, math.cos(t) * r, math.sin(t) * r);
        }
        final s = p.project(pt);
        if (prev != null && s != null) canvas.drawLine(prev, s, paint);
        prev = s;
      }
    }
  }

  void _drawCone(Canvas canvas, Projector p, SceneObject obj, Color color) {
    final r = 40.0 * obj.scale.x;
    final h = 80.0 * obj.scale.y;
    final base = obj.position + Vec3(0, -h / 2, 0);
    final apex = obj.position + Vec3(0, h / 2, 0);
    final apexS = p.project(apex);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    const segments = 16;
    Offset? prev;
    Offset? first;
    for (var i = 0; i <= segments; i++) {
      final t = (i / segments) * 2 * math.pi;
      final pt = base + Vec3(math.cos(t) * r, 0, math.sin(t) * r);
      final s = p.project(pt);
      if (s != null) {
        if (prev != null) canvas.drawLine(prev, s, paint);
        if (apexS != null && i % 4 == 0) canvas.drawLine(s, apexS, paint);
        prev = s;
        first ??= s;
      }
    }
  }

  void _drawLightIcon(Canvas canvas, Offset center, double depth, Color color) {
    final r = (500 / depth).clamp(4.0, 12.0);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, r, paint);
    for (var i = 0; i < 8; i++) {
      final a = (i / 8) * 2 * math.pi;
      final inner = center + Offset(math.cos(a), math.sin(a)) * (r + 2);
      final outer = center + Offset(math.cos(a), math.sin(a)) * (r + 6);
      canvas.drawLine(inner, outer, paint);
    }
  }

  void _drawCameraIcon(Canvas canvas, Projector p, SceneObject obj, Color color) {
    final center = p.project(obj.position);
    final forward = p.project(obj.position + const Vec3(0, 0, -60));
    if (center == null) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromCenter(center: center, width: 16, height: 12), paint);
    if (forward != null) canvas.drawLine(center, forward, paint);
  }

  void _drawCross(Canvas canvas, Offset center, double depth, Color color) {
    final r = (500 / depth).clamp(5.0, 14.0);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4;
    canvas.drawLine(center - Offset(r, 0), center + Offset(r, 0), paint);
    canvas.drawLine(center - Offset(0, r), center + Offset(0, r), paint);
  }

  void _drawGizmo(Canvas canvas, Projector p, SceneObject obj, ToolMode tool) {
    final origin = p.project(obj.position);
    if (origin == null) return;
    const gizmoWorldLen = 70.0;

    for (var i = 0; i < _gizmoAxes.length; i++) {
      final tip = p.project(obj.position + _gizmoAxes[i] * gizmoWorldLen);
      if (tip == null) continue;
      final paint = Paint()
        ..color = _gizmoColors[i]
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(origin, tip, paint);

      switch (tool) {
        case ToolMode.move:
        case ToolMode.select:
          _drawArrowHead(canvas, origin, tip, _gizmoColors[i]);
          break;
        case ToolMode.rotate:
          canvas.drawCircle(tip, 5, Paint()..color = _gizmoColors[i]..style = PaintingStyle.stroke..strokeWidth = 2);
          break;
        case ToolMode.scale:
          canvas.drawRect(Rect.fromCenter(center: tip, width: 8, height: 8), Paint()..color = _gizmoColors[i]);
          break;
      }
    }
    canvas.drawCircle(origin, 4, Paint()..color = Colors.white);
  }

  void _drawArrowHead(Canvas canvas, Offset origin, Offset tip, Color color) {
    final dir = (tip - origin);
    final len = dir.distance;
    if (len < 1e-3) return;
    final unit = dir / len;
    final normal = Offset(-unit.dy, unit.dx);
    final back = tip - unit * 10;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo((back + normal * 4).dx, (back + normal * 4).dy)
      ..lineTo((back - normal * 4).dx, (back - normal * 4).dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ViewportPainter oldDelegate) => true;
}
