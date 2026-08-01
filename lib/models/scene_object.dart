import 'dart:ui' show Color;

import 'enums.dart';
import 'keyframe.dart';
import '../utils/vec3.dart';

/// A single node in the scene hierarchy (the "Objects" tree).
///
/// This mirrors, at a simplified level, what Cinema 4D calls an "object":
/// it has a transform (position / rotation / scale), a type that decides
/// how it's drawn in the viewport, visibility/lock flags, an optional
/// parent (for grouping / nesting) and an animation track of [Keyframe]s.
class SceneObject {
  final String id;
  String name;
  ObjectType type;
  Vec3 position;
  Vec3 rotation; // degrees, euler H/P/B (yaw/pitch/bank)
  Vec3 scale;
  Color color;
  bool visibleInEditor;
  bool visibleInRenderer;
  bool locked;
  String? parentId;
  int depth; // nesting depth, purely for tree indentation
  final List<Keyframe> keyframes;

  SceneObject({
    required this.id,
    required this.name,
    required this.type,
    Vec3? position,
    Vec3? rotation,
    Vec3? scale,
    required this.color,
    this.visibleInEditor = true,
    this.visibleInRenderer = true,
    this.locked = false,
    this.parentId,
    this.depth = 0,
    List<Keyframe>? keyframes,
  })  : position = position ?? Vec3.zero,
        rotation = rotation ?? Vec3.zero,
        scale = scale ?? Vec3.one,
        keyframes = keyframes ?? [];

  bool get isAnimated => keyframes.isNotEmpty;

  SceneObject clone() => SceneObject(
        id: id,
        name: name,
        type: type,
        position: position,
        rotation: rotation,
        scale: scale,
        color: color,
        visibleInEditor: visibleInEditor,
        visibleInRenderer: visibleInRenderer,
        locked: locked,
        parentId: parentId,
        depth: depth,
        keyframes: List.of(keyframes),
      );

  /// Inserts or replaces the keyframe at [frame] with the object's current
  /// transform, keeping the track sorted by frame.
  void recordKeyframe(int frame) {
    keyframes.removeWhere((k) => k.frame == frame);
    keyframes.add(Keyframe(
      frame: frame,
      position: position,
      rotation: rotation,
      scale: scale,
    ));
    keyframes.sort((a, b) => a.frame.compareTo(b.frame));
  }

  void removeKeyframeAt(int frame) {
    keyframes.removeWhere((k) => k.frame == frame);
  }

  /// Evaluates (interpolates) the animation track at [frame] and writes the
  /// result into [position]/[rotation]/[scale]. No-op if there are no keys.
  void evaluateAt(int frame) {
    if (keyframes.isEmpty) return;
    if (keyframes.length == 1) {
      final k = keyframes.first;
      position = k.position;
      rotation = k.rotation;
      scale = k.scale;
      return;
    }

    if (frame <= keyframes.first.frame) {
      final k = keyframes.first;
      position = k.position;
      rotation = k.rotation;
      scale = k.scale;
      return;
    }
    if (frame >= keyframes.last.frame) {
      final k = keyframes.last;
      position = k.position;
      rotation = k.rotation;
      scale = k.scale;
      return;
    }

    Keyframe? prev;
    Keyframe? next;
    for (var i = 0; i < keyframes.length - 1; i++) {
      if (keyframes[i].frame <= frame && keyframes[i + 1].frame >= frame) {
        prev = keyframes[i];
        next = keyframes[i + 1];
        break;
      }
    }
    if (prev == null || next == null) return;
    final span = (next.frame - prev.frame).clamp(1, 1 << 30);
    final t = (frame - prev.frame) / span;
    position = prev.position.lerp(next.position, t);
    rotation = prev.rotation.lerp(next.rotation, t);
    scale = prev.scale.lerp(next.scale, t);
  }
}
