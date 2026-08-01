/// The active interaction tool in the viewport / left tool bar.
enum ToolMode { select, move, rotate, scale }

/// The category of object that can be created from the middle creation bar.
enum ObjectType { cube, sphere, cone, light, camera, nullObj, spline }

extension ObjectTypeLabel on ObjectType {
  String get label {
    switch (this) {
      case ObjectType.cube:
        return 'Cube';
      case ObjectType.sphere:
        return 'Sphere';
      case ObjectType.cone:
        return 'Cone';
      case ObjectType.light:
        return 'Light';
      case ObjectType.camera:
        return 'Camera';
      case ObjectType.nullObj:
        return 'Null';
      case ObjectType.spline:
        return 'Spline';
    }
  }
}

/// Which attribute sub-tab is active (Mode | Basic | Object | Coord).
enum AttributeTab { mode, basic, object, coord }
