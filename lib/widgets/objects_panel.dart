import 'package:fluent_ui/fluent_ui.dart' hide Divider;
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/scene_object.dart';
import '../state/app_state.dart';

class ObjectsPanel extends StatefulWidget {
  const ObjectsPanel({super.key});

  @override
  State<ObjectsPanel> createState() => _ObjectsPanelState();
}

class _ObjectsPanelState extends State<ObjectsPanel> {
  int _selectedUpperTab = 0; // 0 = Objects, 1 = Takes, 2 = Layers

  final FlyoutController _objectsMenuController = FlyoutController();
  final FlyoutController _editMenuController = FlyoutController();

  @override
  void dispose() {
    _objectsMenuController.dispose();
    _editMenuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Container(
      color: const Color(0xFF242424),
      child: Column(
        children: [
          Container(
            height: 24,
            color: const Color(0xFF1E1E1E),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                _buildUpperTabButton("Objects", 0),
                _buildUpperTabButton("Takes", 1),
                _buildUpperTabButton("Layers", 2),
              ],
            ),
          ),
          Container(
            height: 20,
            color: const Color(0xFF2A2A2A),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                _buildPanelMenu(
                  controller: _objectsMenuController,
                  label: "Objects",
                  items: {
                    "Cube": () => app.addObject(ObjectType.cube),
                    "Sphere": () => app.addObject(ObjectType.sphere),
                    "Light": () => app.addObject(ObjectType.light),
                    "Camera": () => app.addObject(ObjectType.camera),
                    "Null": () => app.addObject(ObjectType.nullObj),
                  },
                ),
                _buildPanelMenu(
                  controller: _editMenuController,
                  label: "Edit",
                  items: {
                    "Delete (Backspace)": () => app.deleteSelected(),
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedUpperTab,
              children: [
                _buildObjectsTreeView(app),
                _buildTakesView(),
                _buildLayersView(app),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpperTabButton(String label, int index) {
    final bool isActive = _selectedUpperTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedUpperTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF242424) : Colors.transparent,
          border: isActive
              ? Border(
                  top: BorderSide(color: Colors.orange, width: 2))
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.white : Colors.grey[100],
          ),
        ),
      ),
    );
  }

  Widget _buildPanelMenu({
    required FlyoutController controller,
    required String label,
    required Map<String, VoidCallback> items,
  }) {
    return FlyoutTarget(
      controller: controller,
      child: GestureDetector(
        onTap: () {
          controller.showFlyout(
            builder: (context) {
              return MenuFlyout(
                items: items.entries.map((entry) {
                  return MenuFlyoutItem(
                    text: Text(
                      entry.key,
                      style: GoogleFonts.inter(
                          fontSize: 10, color: Colors.grey[30]),
                    ),
                    onPressed: () {
                      entry.value();
                      Navigator.of(context).pop();
                    },
                  );
                }).toList(),
              );
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[120]),
          ),
        ),
      ),
    );
  }

  Widget _buildObjectsTreeView(AppState app) {
    if (app.objects.isEmpty) {
      return Center(
        child: Text(
          "No objects — use the creation bar to add one",
          style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[100]),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(4),
      itemCount: app.objects.length,
      itemBuilder: (context, index) {
        final obj = app.objects[index];
        return _TreeRow(
          obj: obj,
          selected: obj.id == app.selectedId,
          onTap: () => app.selectObject(obj.id),
          onToggleVisibility: () => app.toggleVisibility(obj.id),
        );
      },
    );
  }

  Widget _buildTakesView() {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        Row(
          children: [
             Icon(PhosphorIconsFill.stack,
                size: 14, color: Colors.orange),
            const SizedBox(width: 6),
            Text("Main Take (Active)",
                style: GoogleFonts.inter(fontSize: 11, color: Colors.white)),
          ],
        ),
        Container(
            height: 1,
            color: Colors.white.withOpacity(0.1),
            margin: const EdgeInsets.symmetric(vertical: 8)),
      ],
    );
  }

  Widget _buildLayersView(AppState app) {
    final types = app.objects.map((o) => o.type).toSet();
    return ListView(
      padding: const EdgeInsets.all(8),
      children: types
          .map((t) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(t.label,
                        style: GoogleFonts.inter(
                            fontSize: 11, color: Colors.grey[40])),
                    const Spacer(),
                    Text(
                      '${app.objects.where((o) => o.type == t).length}',
                      style: GoogleFonts.inter(
                          fontSize: 10, color: Colors.grey[100]),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _TreeRow extends StatelessWidget {
  final SceneObject obj;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onToggleVisibility;

  const _TreeRow({
    required this.obj,
    required this.selected,
    required this.onTap,
    required this.onToggleVisibility,
  });

  IconData get _icon {
    switch (obj.type) {
      case ObjectType.cube:
        return PhosphorIconsFill.cube;
      case ObjectType.sphere:
        return PhosphorIconsFill.circle;
      case ObjectType.cone:
        return PhosphorIconsFill.triangle;
      case ObjectType.light:
        return PhosphorIconsFill.lightbulb;
      case ObjectType.camera:
        return PhosphorIconsFill.videoCamera;
      case ObjectType.nullObj:
        return PhosphorIconsRegular.crosshair;
      case ObjectType.spline:
        return PhosphorIconsRegular.path;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: selected ? const Color(0xFF3A3A3A) : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 4),
        child: Row(
          children: [
            Icon(_icon, size: 14, color: obj.color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                obj.name,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: selected ? Colors.white : Colors.grey[40],
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (obj.isAnimated)
              Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(PhosphorIconsFill.clock,
                    size: 11, color: Colors.orange),
              ),
            GestureDetector(
              onTap: onToggleVisibility,
              child: Icon(
                obj.visibleInEditor
                    ? PhosphorIconsFill.eye
                    : PhosphorIconsRegular.eyeClosed,
                size: 12,
                color:
                    obj.visibleInEditor ? Colors.grey[40] : Colors.grey[120],
              ),
            ),
          ],
        ),
      ),
    );
  }
}