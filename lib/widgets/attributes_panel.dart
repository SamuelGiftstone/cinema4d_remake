import 'package:fluent_ui/fluent_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/scene_object.dart';
import '../state/app_state.dart';
import '../utils/vec3.dart';

class AttributesPanel extends StatelessWidget {
  const AttributesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final obj = app.selectedObject;

    return Container(
      color: const Color(0xFF242424),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 26,
            color: const Color(0xFF1E1E1E),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Text(
                  "Attributes",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                if (obj != null)
                  Text(
                    obj.name,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.orange,
                    ),
                  ),
              ],
            ),
          ),
          if (obj == null)
            Expanded(
              child: Center(
                child: Text(
                  "Nothing selected",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[100],
                  ),
                ),
              ),
            )
          else ...[
            Container(
              height: 22,
              color: const Color(0xFF1E1E1E),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  _tab(app, "Mode", AttributeTab.mode),
                  _tab(app, "Basic", AttributeTab.basic),
                  _tab(app, "Object", AttributeTab.object),
                  _tab(app, "Coord.", AttributeTab.coord),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildBody(app, obj),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tab(AppState app, String label, AttributeTab tab) {
    final active = app.attributeTab == tab;
    return GestureDetector(
      onTap: () => app.setAttributeTab(tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF282828) : Colors.transparent,
          border: active
              ?  Border(bottom: BorderSide(color: Colors.orange, width: 2))
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            color: active ? Colors.white : Colors.grey[100],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppState app, SceneObject obj) {
    switch (app.attributeTab) {
      case AttributeTab.mode:
        return ListView(
          children: [
            _CheckboxRow(
              label: "Visible in Editor",
              value: obj.visibleInEditor,
              onChanged: (v) {
                obj.visibleInEditor = v;
                app.selectObject(obj.id);
              },
            ),
            _CheckboxRow(
              label: "Visible in Renderer",
              value: obj.visibleInRenderer,
              onChanged: (v) {
                obj.visibleInRenderer = v;
                app.selectObject(obj.id);
              },
            ),
          ],
        );
      case AttributeTab.basic:
        return ListView(
          children: [
            _NameField(app: app, obj: obj),
            const SizedBox(height: 8),
            _staticRow("Type", obj.type.label),
            _staticRow(
              "Animated",
              obj.isAnimated ? "Yes (${obj.keyframes.length} keys)" : "No",
            ),
          ],
        );
      case AttributeTab.object:
        return ListView(
          children: [
            Row(
              children: [
                Text(
                  "Color",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.grey[100],
                  ),
                ),
                const Spacer(),
                Container(width: 16, height: 16, color: obj.color),
              ],
            ),
            const SizedBox(height: 6),
            _staticRow("Locked", obj.locked ? "Yes" : "No"),
          ],
        );
      case AttributeTab.coord:
        return ListView(
          children: [
            Text(
              "Position",
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.grey[100],
                fontWeight: FontWeight.bold,
              ),
            ),
            _Vec3Editor(
              vec: obj.position,
              onChanged: (v) => app.setPosition(obj.id, v),
              onGestureStart: () => app.beginTransformGesture(obj.id),
              onGestureEnd: () => app.endTransformGesture(),
            ),
            const SizedBox(height: 10),
            Text(
              "Rotation (H/P/B)",
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.grey[100],
                fontWeight: FontWeight.bold,
              ),
            ),
            _Vec3Editor(
              vec: obj.rotation,
              onChanged: (v) => app.setRotation(obj.id, v),
              onGestureStart: () => app.beginTransformGesture(obj.id),
              onGestureEnd: () => app.endTransformGesture(),
            ),
            const SizedBox(height: 10),
            Text(
              "Scale",
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.grey[100],
                fontWeight: FontWeight.bold,
              ),
            ),
            _Vec3Editor(
              vec: obj.scale,
              onChanged: (v) => app.setScale(obj.id, v),
              onGestureStart: () => app.beginTransformGesture(obj.id),
              onGestureEnd: () => app.endTransformGesture(),
            ),
          ],
        );
    }
  }

  Widget _staticRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[100]),
          ),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 10, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _NameField extends StatefulWidget {
  final AppState app;
  final SceneObject obj;
  const _NameField({required this.app, required this.obj});

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.obj.name);
  }

  @override
  void didUpdateWidget(covariant _NameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obj.id != widget.obj.id || oldWidget.obj.name != widget.obj.name) {
      _controller.text = widget.obj.name;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          "Name",
          style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[100]),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 24,
            child: TextBox(
              controller: _controller,
              style: GoogleFonts.inter(fontSize: 10, color: Colors.white),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              onSubmitted: (v) => widget.app.renameObject(widget.obj.id, v),
              onEditingComplete: () =>
                  widget.app.renameObject(widget.obj.id, _controller.text),
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckboxRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _CheckboxRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Checkbox(
            checked: value,
            onChanged: (v) => onChanged(v ?? false),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[40]),
          ),
        ],
      ),
    );
  }
}

class _Vec3Editor extends StatelessWidget {
  final Vec3 vec;
  final ValueChanged<Vec3> onChanged;
  final VoidCallback onGestureStart;
  final VoidCallback onGestureEnd;

  const _Vec3Editor({
    required this.vec,
    required this.onChanged,
    required this.onGestureStart,
    required this.onGestureEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _axisField(
            'X',
            vec.x,
            (v) => onChanged(vec.copyWith(x: v)),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _axisField(
            'Y',
            vec.y,
            (v) => onChanged(vec.copyWith(y: v)),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: _axisField(
            'Z',
            vec.z,
            (v) => onChanged(vec.copyWith(z: v)),
          ),
        ),
      ],
    );
  }

  Widget _axisField(String label, double value, ValueChanged<double> onValue) {
    return _AxisNumberField(
      label: label,
      value: value,
      onValue: onValue,
      onGestureStart: onGestureStart,
      onGestureEnd: onGestureEnd,
    );
  }
}

class _AxisNumberField extends StatefulWidget {
  final String label;
  final double value;
  final ValueChanged<double> onValue;
  final VoidCallback onGestureStart;
  final VoidCallback onGestureEnd;

  const _AxisNumberField({
    required this.label,
    required this.value,
    required this.onValue,
    required this.onGestureStart,
    required this.onGestureEnd,
  });

  @override
  State<_AxisNumberField> createState() => _AxisNumberFieldState();
}

class _AxisNumberFieldState extends State<_AxisNumberField> {
  late TextEditingController _controller;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toStringAsFixed(1));
  }

  @override
  void didUpdateWidget(covariant _AxisNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.value != widget.value) {
      _controller.text = widget.value.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commit() {
    final parsed = double.tryParse(_controller.text);
    if (parsed != null) {
      widget.onGestureStart();
      widget.onValue(parsed);
      widget.onGestureEnd();
    } else {
      _controller.text = widget.value.toStringAsFixed(1);
    }
    _editing = false;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: TextBox(
        controller: _controller,
        style: GoogleFonts.inter(fontSize: 10, color: Colors.white),
        prefix: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            widget.label,
            style: GoogleFonts.inter(fontSize: 9, color: Colors.grey[100]),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        onChanged: (_) => _editing = true,
        onSubmitted: (_) => _commit(),
        onEditingComplete: _commit,
      ),
    );
  }
}