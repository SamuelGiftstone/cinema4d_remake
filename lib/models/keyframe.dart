import '../utils/vec3.dart';

/// A single recorded transform state at a given frame number.
class Keyframe {
  final int frame;
  final Vec3 position;
  final Vec3 rotation;
  final Vec3 scale;

  const Keyframe({
    required this.frame,
    required this.position,
    required this.rotation,
    required this.scale,
  });

  Keyframe copyWith({int? frame, Vec3? position, Vec3? rotation, Vec3? scale}) {
    return Keyframe(
      frame: frame ?? this.frame,
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
    );
  }
}
