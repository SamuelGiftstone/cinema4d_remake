import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

import '../models/enums.dart';
import '../models/scene_object.dart';
import '../utils/vec3.dart';
import 'commands.dart';

/// Simple orbit camera used by the viewport's manual 3D projection.
class OrbitCamera {
  double yaw; // radians, rotation around Y
  double pitch; // radians, clamped to avoid gimbal flip
  double distance;
  Vec3 target;

  OrbitCamera({
    this.yaw = -0.6,
    this.pitch = 0.45,
    this.distance = 900,
    Vec3? target,
  }) : target = target ?? Vec3.zero;

  Vec3 get direction => Vec3(
        math.cos(pitch) * math.sin(yaw),
        math.sin(pitch),
        math.cos(pitch) * math.cos(yaw),
      );

  Vec3 get position => target + direction * distance;

  void orbit(double dYaw, double dPitch) {
    yaw += dYaw;
    pitch = (pitch + dPitch).clamp(-1.5, 1.5);
  }

  void dolly(double delta) {
    distance = (distance * (1 + delta)).clamp(80.0, 6000.0);
  }
}

/// The single source of truth for the whole editor: scene graph, selection,
/// active tool, camera, timeline/playback and the undo/redo stacks. Exposed
/// to the widget tree via `ChangeNotifierProvider` in main.dart.
class AppState extends ChangeNotifier {
  final List<SceneObject> objects = [];
  String? selectedId;
  ToolMode tool = ToolMode.select;
  AttributeTab attributeTab = AttributeTab.object;

  final OrbitCamera camera = OrbitCamera();

  // --- Timeline / playback ---
  int currentFrame = 0;
  int startFrame = 0;
  int endFrame = 90;
  bool isPlaying = false;
  bool isAutoKey = false;
  Timer? _playbackTimer;

  // --- Undo / redo ---
  final List<Command> _undoStack = [];
  final List<Command> _redoStack = [];
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  int _idCounter = 0;
  String _nextId(String prefix) => '${prefix}_${_idCounter++}';

  AppState() {
    _seedDefaultScene();
  }

  void _seedDefaultScene() {
    addObject(ObjectType.light, name: 'RS Dome Light', silent: true);
    addObject(ObjectType.sphere, name: 'Sphere', silent: true);
    objects.last.position = const Vec3(-120, 0, 0);
    addObject(ObjectType.cube, name: 'Cube', silent: true);
    objects.last.position = const Vec3(120, 0, 0);
    selectedId = objects.isNotEmpty ? objects.first.id : null;
  }

  SceneObject? get selectedObject {
    if (selectedId == null) return null;
    for (final o in objects) {
      if (o.id == selectedId) return o;
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // Selection & tool
  // ---------------------------------------------------------------------

  void selectObject(String? id) {
    if (selectedId == id) return;
    selectedId = id;
    notifyListeners();
  }

  void setTool(ToolMode mode) {
    if (tool == mode) return;
    tool = mode;
    notifyListeners();
  }

  void setAttributeTab(AttributeTab tab) {
    attributeTab = tab;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Object creation / deletion
  // ---------------------------------------------------------------------

  Color _colorFor(ObjectType type) {
    switch (type) {
      case ObjectType.cube:
        return const Color(0xFF4FC3F7);
      case ObjectType.sphere:
        return const Color(0xFF81C784);
      case ObjectType.cone:
        return const Color(0xFFBA68C8);
      case ObjectType.light:
        return const Color(0xFFFFEB3B);
      case ObjectType.camera:
        return const Color(0xFFEEEEEE);
      case ObjectType.nullObj:
        return const Color(0xFFFF9800);
      case ObjectType.spline:
        return const Color(0xFF4DD0E1);
    }
  }

  SceneObject addObject(ObjectType type, {String? name, bool silent = false}) {
    final obj = SceneObject(
      id: _nextId('obj'),
      name: name ?? _defaultNameFor(type),
      type: type,
      color: _colorFor(type),
    );
    objects.add(obj);
    selectedId = obj.id;

    if (!silent) {
      _pushCommand(ClosureCommand(
        undo: () {
          objects.removeWhere((o) => o.id == obj.id);
          if (selectedId == obj.id) selectedId = null;
          notifyListeners();
        },
        redo: () {
          objects.add(obj);
          selectedId = obj.id;
          notifyListeners();
        },
      ));
      notifyListeners();
    }
    return obj;
  }

  String _defaultNameFor(ObjectType type) {
    final count = objects.where((o) => o.type == type).length + 1;
    return count == 1 ? type.label : '${type.label}.$count';
  }

  void deleteSelected() {
    final obj = selectedObject;
    if (obj == null) return;
    final index = objects.indexOf(obj);
    objects.removeAt(index);
    selectedId = null;

    _pushCommand(ClosureCommand(
      undo: () {
        objects.insert(index.clamp(0, objects.length), obj);
        selectedId = obj.id;
        notifyListeners();
      },
      redo: () {
        objects.removeWhere((o) => o.id == obj.id);
        if (selectedId == obj.id) selectedId = null;
        notifyListeners();
      },
    ));
    notifyListeners();
  }

  void renameObject(String id, String newName) {
    final obj = objects.where((o) => o.id == id).firstOrNull;
    if (obj == null) return;
    obj.name = newName;
    notifyListeners();
  }

  void toggleVisibility(String id) {
    final obj = objects.where((o) => o.id == id).firstOrNull;
    if (obj == null) return;
    obj.visibleInEditor = !obj.visibleInEditor;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Transform editing (used by both the gizmo and the Attributes panel)
  // ---------------------------------------------------------------------

  void setPosition(String id, Vec3 value, {bool commit = true}) =>
      _setTransform(id, position: value, commit: commit);

  void setRotation(String id, Vec3 value, {bool commit = true}) =>
      _setTransform(id, rotation: value, commit: commit);

  void setScale(String id, Vec3 value, {bool commit = true}) =>
      _setTransform(id, scale: value, commit: commit);

  Vec3? _dragStartPosition;
  Vec3? _dragStartRotation;
  Vec3? _dragStartScale;
  String? _dragObjectId;

  /// Call once when a gizmo drag / numeric-field edit begins, so the whole
  /// gesture becomes a single undo step instead of one step per frame.
  void beginTransformGesture(String id) {
    final obj = objects.where((o) => o.id == id).firstOrNull;
    if (obj == null) return;
    _dragObjectId = id;
    _dragStartPosition = obj.position;
    _dragStartRotation = obj.rotation;
    _dragStartScale = obj.scale;
  }

  void endTransformGesture() {
    final id = _dragObjectId;
    if (id == null) return;
    final obj = objects.where((o) => o.id == id).firstOrNull;
    if (obj == null) {
      _dragObjectId = null;
      return;
    }
    final startPos = _dragStartPosition!;
    final startRot = _dragStartRotation!;
    final startScale = _dragStartScale!;
    final endPos = obj.position;
    final endRot = obj.rotation;
    final endScale = obj.scale;

    if (startPos != endPos || startRot != endRot || startScale != endScale) {
      _pushCommand(ClosureCommand(
        undo: () {
          final o = objects.where((o) => o.id == id).firstOrNull;
          if (o == null) return;
          o.position = startPos;
          o.rotation = startRot;
          o.scale = startScale;
          notifyListeners();
        },
        redo: () {
          final o = objects.where((o) => o.id == id).firstOrNull;
          if (o == null) return;
          o.position = endPos;
          o.rotation = endRot;
          o.scale = endScale;
          notifyListeners();
        },
      ));
    }

    if (isAutoKey) {
      obj.recordKeyframe(currentFrame);
    }

    _dragObjectId = null;
    _dragStartPosition = null;
    _dragStartRotation = null;
    _dragStartScale = null;
  }

  void _setTransform(String id, {Vec3? position, Vec3? rotation, Vec3? scale, bool commit = true}) {
    final obj = objects.where((o) => o.id == id).firstOrNull;
    if (obj == null) return;
    if (position != null) obj.position = position;
    if (rotation != null) obj.rotation = rotation;
    if (scale != null) obj.scale = scale;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Keyframes / timeline
  // ---------------------------------------------------------------------

  void setFrame(int frame) {
    currentFrame = frame.clamp(startFrame, endFrame);
    _evaluateFrame();
    notifyListeners();
  }

  void _evaluateFrame() {
    for (final obj in objects) {
      obj.evaluateAt(currentFrame);
    }
  }

  void recordKeyframeForSelected() {
    final obj = selectedObject;
    if (obj == null) return;
    obj.recordKeyframe(currentFrame);
    notifyListeners();
  }

  void togglePlay() {
    isPlaying = !isPlaying;
    if (isPlaying) {
      _playbackTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
        int next = currentFrame + 1;
        if (next > endFrame) next = startFrame;
        setFrame(next);
      });
    } else {
      _playbackTimer?.cancel();
    }
    notifyListeners();
  }

  void stop() {
    _playbackTimer?.cancel();
    isPlaying = false;
    setFrame(startFrame);
  }

  void toggleAutoKey() {
    isAutoKey = !isAutoKey;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Undo / redo
  // ---------------------------------------------------------------------

  void _pushCommand(Command c) {
    _undoStack.add(c);
    _redoStack.clear();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    final c = _undoStack.removeLast();
    c.undo();
    _redoStack.add(c);
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final c = _redoStack.removeLast();
    c.redo();
    _undoStack.add(c);
  }

  // ---------------------------------------------------------------------
  // Project
  // ---------------------------------------------------------------------

  void newProject() {
    objects.clear();
    selectedId = null;
    _undoStack.clear();
    _redoStack.clear();
    currentFrame = startFrame;
    _seedDefaultScene();
    notifyListeners();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
