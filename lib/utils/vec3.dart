import 'dart:math' as math;

/// A minimal 3D vector type used for object transforms and camera math.
/// Kept dependency-free so the project doesn't need `vector_math`.
class Vec3 {
  final double x, y, z;
  const Vec3(this.x, this.y, this.z);

  static const zero = Vec3(0, 0, 0);
  static const one = Vec3(1, 1, 1);

  Vec3 operator +(Vec3 o) => Vec3(x + o.x, y + o.y, z + o.z);
  Vec3 operator -(Vec3 o) => Vec3(x - o.x, y - o.y, z - o.z);
  Vec3 operator *(double s) => Vec3(x * s, y * s, z * s);

  double dot(Vec3 o) => x * o.x + y * o.y + z * o.z;

  Vec3 cross(Vec3 o) => Vec3(
        y * o.z - z * o.y,
        z * o.x - x * o.z,
        x * o.y - y * o.x,
      );

  double get length => math.sqrt(x * x + y * y + z * z);

  Vec3 get normalized {
    final l = length;
    if (l < 1e-9) return Vec3.zero;
    return Vec3(x / l, y / l, z / l);
  }

  Vec3 lerp(Vec3 o, double t) => this + (o - this) * t;

  Vec3 copyWith({double? x, double? y, double? z}) =>
      Vec3(x ?? this.x, y ?? this.y, z ?? this.z);

  Map<String, double> toJson() => {'x': x, 'y': y, 'z': z};

  static Vec3 fromJson(Map<String, dynamic> j) =>
      Vec3((j['x'] as num).toDouble(), (j['y'] as num).toDouble(), (j['z'] as num).toDouble());

  @override
  String toString() => '(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)}, ${z.toStringAsFixed(1)})';
}
