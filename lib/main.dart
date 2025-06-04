import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

void main() => runApp(WotMapEditor());

class WotMapEditor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WoT Map Editor',
      home: MapEditorPage(),
    );
  }
}

enum ToolType { point, zone, brush }
enum TankType { none, lt, mt, ht, td, spg, route }

class MapEditorPage extends StatefulWidget {
  @override
  _MapEditorPageState createState() => _MapEditorPageState();
}

class _MapEditorPageState extends State<MapEditorPage> {
  List<Map<String, dynamic>> positions = [];
  List<Map<String, dynamic>> zones = [];
  List<Map<String, dynamic>> brushes = [];
  List<Offset> currentBrush = [];
  File? imageFile;
  String imageName = "";
  final GlobalKey _key = GlobalKey();

  ToolType selectedTool = ToolType.point;
  TankType selectedTank = TankType.none;

  Offset? zoneStart;
  Offset? zoneEnd;

  void _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        imageFile = File(result.files.single.path!);
        imageName = result.files.single.name;
        positions.clear();
        zones.clear();
        brushes.clear();
      });
    }
  }

  void _handleTap(TapUpDetails details) async {
    if (selectedTool != ToolType.point) return;
    RenderBox box = _key.currentContext?.findRenderObject() as RenderBox;
    Offset local = box.globalToLocal(details.globalPosition);
    Size size = box.size;
    double x = local.dx / size.width;
    double y = local.dy / size.height;

    var data = await _showPointDialog(x, y);
    if (data != null) {
      setState(() {
        positions.add(data);
      });
    }
  }

  Future<Map<String, dynamic>?> _showPointDialog(double x, double y) async {
    String id = "";
    String type = selectedTank.toString().split('.').last;
    String description = "";
    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add Position"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(decoration: InputDecoration(labelText: 'ID'), onChanged: (v) => id = v),
              TextField(decoration: InputDecoration(labelText: 'Description'), onChanged: (v) => description = v),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, null), child: Text("Cancel")),
            TextButton(
              onPressed: () => Navigator.pop(context, {
                'id': id,
                'x': x,
                'y': y,
                'type': type,
                'description': description,
              }),
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _exportToJson() async {
    Map<String, dynamic> output = {
      'image': imageName,
      'positions': positions,
      'zones': zones,
      'brushes': brushes,
    };
    String jsonStr = jsonEncode(output);
    String? path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      File file = File("$path/${imageName.split('.').first}_data.json");
      await file.writeAsString(jsonStr);
    }
  }

  void _showJsonDialog() {
    Map<String, dynamic> output = {
      'image': imageName,
      'positions': positions,
      'zones': zones,
      'brushes': brushes,
    };
    String jsonStr = const JsonEncoder.withIndent('  ').convert(output);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("JSON Output"),
        content: SingleChildScrollView(child: SelectableText(jsonStr)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Close"))],
      ),
    );
  }

  void _undo() {
    setState(() {
      if (positions.isNotEmpty) {
        positions.removeLast();
      } else if (zones.isNotEmpty) {
        zones.removeLast();
      } else if (brushes.isNotEmpty) {
        brushes.removeLast();
      }
    });
  }

  void _clearAll() {
    setState(() {
      positions.clear();
      zones.clear();
      brushes.clear();
    });
  }

  Widget _buildToolButtons() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: ToolType.values.map((tool) {
      return Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: tool == selectedTool ? Colors.orange : null,
          ),
          onPressed: () => setState(() => selectedTool = tool),
          child: Text(tool.toString().split('.').last),
        ),
      );
    }).toList(),
  );

  Widget _buildTankButtons() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: TankType.values.map((type) {
      return Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: type == selectedTank ? Colors.green : null,
          ),
          onPressed: () => setState(() => selectedTank = type),
          child: Text(
            type == TankType.lt ? 'LT' :
            type == TankType.mt ? 'MT' :
            type == TankType.ht ? 'HT' :
            type == TankType.td ? 'TD' :
            type == TankType.spg ? 'SPG' :
            type == TankType.route ? 'RT' :
            '',
          ),
        ),
      );
    }).toList(),
  );

  Widget _buildUtilityRow() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      IconButton(icon: Icon(Icons.undo), onPressed: _undo),
      IconButton(icon: Icon(Icons.delete), onPressed: _clearAll),
      IconButton(icon: Icon(Icons.save), onPressed: _exportToJson),
      IconButton(icon: Icon(Icons.code), onPressed: _showJsonDialog),
      IconButton(icon: Icon(Icons.image), onPressed: _pickImage),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('WoT Map Editor')),
      body: Column(
        children: [
          _buildTankButtons(),
          _buildToolButtons(),
          _buildUtilityRow(),
          Expanded(
            child: imageFile == null
                ? Center(child: Text('Select an image to start'))
                : GestureDetector(
              onTapUp: _handleTap,
              onPanStart: (details) {
                if (selectedTool == ToolType.brush) {
                  setState(() => currentBrush = [details.localPosition]);
                } else if (selectedTool == ToolType.zone) {
                  zoneStart = details.localPosition;
                }
              },
              onPanUpdate: (details) {
                if (selectedTool == ToolType.brush) {
                  setState(() => currentBrush.add(details.localPosition));
                } else if (selectedTool == ToolType.zone) {
                  zoneEnd = details.localPosition;
                }
              },
              onPanEnd: (_) async {
                RenderBox box = _key.currentContext?.findRenderObject() as RenderBox;
                Size size = box.size;
                if (selectedTool == ToolType.brush && currentBrush.length > 2) {
                  String id = '', label = '', color = '#00FF00';
                  await showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text("Add Brush Area"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(decoration: InputDecoration(labelText: 'ID'), onChanged: (v) => id = v),
                          TextField(decoration: InputDecoration(labelText: 'Label'), onChanged: (v) => label = v),
                        ],
                      ),
                      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))],
                    ),
                  );
                  List<Map<String, double>> normalizedPath = currentBrush.map((offset) {
                    return {
                      'x': offset.dx / size.width,
                      'y': offset.dy / size.height,
                    };
                  }).toList();
                  setState(() {
                    brushes.add({'id': id, 'label': label, 'color': color, 'path': normalizedPath});
                    currentBrush = [];
                  });
                } else if (selectedTool == ToolType.zone && zoneStart != null && zoneEnd != null) {
                  double x = zoneStart!.dx / size.width;
                  double y = zoneStart!.dy / size.height;
                  double width = (zoneEnd!.dx - zoneStart!.dx).abs() / size.width;
                  double height = (zoneEnd!.dy - zoneStart!.dy).abs() / size.height;
                  zoneStart = null;
                  zoneEnd = null;

                  String id = '', label = '', color = '#FF0000';
                  await showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text("Add Zone"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(decoration: InputDecoration(labelText: 'ID'), onChanged: (v) => id = v),
                          TextField(decoration: InputDecoration(labelText: 'Label'), onChanged: (v) => label = v),
                        ],
                      ),
                      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))],
                    ),
                  );
                  setState(() {
                    zones.add({'id': id, 'x': x, 'y': y, 'width': width, 'height': height, 'color': color, 'label': label});
                  });
                }
              },
              child: Stack(
                children: [
                  Container(
                    key: _key,
                    decoration: BoxDecoration(
                      image: DecorationImage(image: FileImage(imageFile!), fit: BoxFit.contain),
                    ),
                  ),
                  CustomPaint(
                    painter: OverlayPainter(zones, brushes, positions, currentBrush, zoneStart, zoneEnd),
                    size: Size.infinite,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OverlayPainter extends CustomPainter {
  final List<Map<String, dynamic>> zones;
  final List<Map<String, dynamic>> brushes;
  final List<Map<String, dynamic>> positions;
  final List<Offset> currentBrush;
  final Offset? zoneStart;
  final Offset? zoneEnd;

  OverlayPainter(this.zones, this.brushes, this.positions, this.currentBrush, this.zoneStart, this.zoneEnd);

  @override
  void paint(Canvas canvas, Size size) {
    final brushPaint = Paint()
      ..strokeWidth = 2
      ..color = Colors.green.withOpacity(0.5)
      ..style = PaintingStyle.stroke;

    final zonePaint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final pointPaint = Paint()
      ..style = PaintingStyle.fill;

    // Assign color by tank type if available
    Map<String, Color> tankColors = {
      'lt': Colors.yellow,
      'mt': Colors.green,
      'ht': Colors.red,
      'td': Colors.purple,
      'spg': Colors.cyan,
      'route': Colors.orange,
      'none': Colors.blue,
    };

    for (var zone in zones) {
      double x = zone['x'] * size.width;
      double y = zone['y'] * size.height;
      double w = zone['width'] * size.width;
      double h = zone['height'] * size.height;
      canvas.drawRect(Rect.fromLTWH(x, y, w, h), zonePaint);
    }

    for (var brush in brushes) {
      var path = Path();
      var points = (brush['path'] as List).cast<Map<String, dynamic>>().map((p) => Offset(p['x'] * size.width, p['y'] * size.height)).toList();
      if (points.isNotEmpty) {
        path.moveTo(points.first.dx, points.first.dy);
        for (var point in points.skip(1)) {
          path.lineTo(point.dx, point.dy);
        }
        canvas.drawPath(path, brushPaint);
      }
    }

    for (var pos in positions) {
      double px = pos['x'] * size.width;
      double py = pos['y'] * size.height;
      final type = (pos['type'] ?? 'none').toString();
      final color = tankColors[type] ?? Colors.grey;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), 6, paint);
    }

    if (currentBrush.isNotEmpty) {
      var path = Path();
      path.moveTo(currentBrush.first.dx, currentBrush.first.dy);
      for (var point in currentBrush.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, brushPaint);
    }

    if (zoneStart != null && zoneEnd != null) {
      final previewPaint = Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      Rect rect = Rect.fromPoints(zoneStart!, zoneEnd!);
      canvas.drawRect(rect, previewPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
