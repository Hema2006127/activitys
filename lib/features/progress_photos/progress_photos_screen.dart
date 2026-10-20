import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gymapp/core/theme/app_theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gymapp/core/database/hive_setup.dart';
import 'package:gymapp/core/widgets/empty_state_widget.dart';
import 'package:uuid/uuid.dart';

// ── Model ─────────────────────────────────────────────────────────────────────
class ProgressPhoto {
  final String id;
  final DateTime date;
  final String imagePath;
  final String? note;

  ProgressPhoto({
    required this.id,
    required this.date,
    required this.imagePath,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'imagePath': imagePath,
        'note': note,
      };

  factory ProgressPhoto.fromJson(Map<String, dynamic> j) => ProgressPhoto(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String),
        imagePath: j['imagePath'] as String,
        note: j['note'] as String?,
      );
}

// ── Screen ────────────────────────────────────────────────────────────────────
class ProgressPhotosScreen extends StatefulWidget {
  const ProgressPhotosScreen({super.key});

  @override
  State<ProgressPhotosScreen> createState() => _ProgressPhotosScreenState();
}

class _ProgressPhotosScreenState extends State<ProgressPhotosScreen> {
  List<ProgressPhoto> _photos = [];
  final Set<String> _selected = {};
  bool _selectionMode = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  void _loadPhotos() {
    final box = Hive.box<String>(HiveSetup.photosBox);
    final loaded = box.values
        .map((s) {
          try {
            return ProgressPhoto.fromJson(jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<ProgressPhoto>()
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    setState(() => _photos = loaded);
  }

  Future<void> _addPhoto(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;

    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${dir.path}/progress_photos');
    if (!photosDir.existsSync()) photosDir.createSync(recursive: true);

    final id = const Uuid().v4();
    final dest = '${photosDir.path}/$id.jpg';
    await File(picked.path).copy(dest);

    final photo = ProgressPhoto(id: id, date: DateTime.now(), imagePath: dest);
    final box = Hive.box<String>(HiveSetup.photosBox);
    await box.put(id, jsonEncode(photo.toJson()));
    _loadPhotos();
  }

  void _deleteSelected() {
    final box = Hive.box<String>(HiveSetup.photosBox);
    for (final id in _selected) {
      final photo = _photos.firstWhere((p) => p.id == id);
      final f = File(photo.imagePath);
      if (f.existsSync()) f.deleteSync();
      box.delete(id);
    }
    setState(() {
      _selected.clear();
      _selectionMode = false;
    });
    _loadPhotos();
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
        if (_selected.isEmpty) _selectionMode = false;
      } else {
        _selected.add(id);
      }
    });
  }

  void _openCompare() {
    if (_selected.length != 2) return;
    final ids = _selected.toList();
    final a = _photos.firstWhere((p) => p.id == ids[0]);
    final b = _photos.firstWhere((p) => p.id == ids[1]);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _CompareScreen(photoA: a, photoB: b)),
    );
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('إضافة صورة',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.secondaryColor),
              title: const Text('التقط صورة جديدة'),
              onTap: () {
                Navigator.pop(context);
                _addPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.accentColor),
              title: const Text('اختر من المعرض'),
              onTap: () {
                Navigator.pop(context);
                _addPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectionMode
            ? '${_selected.length} محددة'
            : 'صور التقدم'),
        actions: [
          if (_selectionMode && _selected.length == 2)
            IconButton(
              icon: const Icon(Icons.compare),
              tooltip: 'مقارنة',
              onPressed: _openCompare,
            ),
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'حذف',
              onPressed: _deleteSelected,
            ),
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _selected.clear();
                _selectionMode = false;
              }),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'photos_fab',
        onPressed: _showAddSheet,
        child: const Icon(Icons.add_a_photo),
      ),
      body: _photos.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.photo_camera_outlined,
              title: 'لسه ماضفتش صور',
              subtitle: 'التقط صورة كل أسبوع وشوف الفرق\nالتحول بيبان بالصور!',
              color: AppTheme.secondaryColor,
            )
          : Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.75,
                ),
                itemCount: _photos.length,
                itemBuilder: (context, i) => _PhotoCard(
                  photo: _photos[i],
                  isSelected: _selected.contains(_photos[i].id),
                  onTap: () {
                    if (_selectionMode) {
                      _toggleSelect(_photos[i].id);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _FullPhotoScreen(photo: _photos[i]),
                        ),
                      );
                    }
                  },
                  onLongPress: () {
                    setState(() => _selectionMode = true);
                    _toggleSelect(_photos[i].id);
                  },
                ),
              ),
            ),
    );
  }
}

// ── Photo card ────────────────────────────────────────────────────────────────
class _PhotoCard extends StatelessWidget {
  final ProgressPhoto photo;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _PhotoCard({
    required this.photo,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(photo.imagePath), fit: BoxFit.cover),
            // Gradient overlay at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Text(
                  DateFormat('d MMM yyyy', 'ar').format(photo.date),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
            // Selection indicator
            if (isSelected)
              Container(
                color: AppTheme.secondaryColor.withValues(alpha: 0.35),
                child: const Center(
                  child: Icon(Icons.check_circle, color: AppTheme.secondaryColor, size: 40),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Full photo screen ─────────────────────────────────────────────────────────
class _FullPhotoScreen extends StatelessWidget {
  final ProgressPhoto photo;
  const _FullPhotoScreen({required this.photo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(DateFormat('EEEE, d MMMM yyyy', 'ar').format(photo.date)),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(File(photo.imagePath)),
        ),
      ),
    );
  }
}

// ── Compare screen ────────────────────────────────────────────────────────────
class _CompareScreen extends StatelessWidget {
  final ProgressPhoto photoA;
  final ProgressPhoto photoB;
  const _CompareScreen({required this.photoA, required this.photoB});

  @override
  Widget build(BuildContext context) {
    final earlier = photoA.date.isBefore(photoB.date) ? photoA : photoB;
    final later   = photoA.date.isBefore(photoB.date) ? photoB : photoA;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('المقارنة'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _ComparePanel(photo: earlier, label: 'قبل')),
                const SizedBox(width: 2),
                Expanded(child: _ComparePanel(photo: later,   label: 'بعد')),
              ],
            ),
          ),
          // Days difference
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'الفارق: ${later.date.difference(earlier.date).inDays} يوم',
              style: const TextStyle(
                  color: AppTheme.secondaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparePanel extends StatelessWidget {
  final ProgressPhoto photo;
  final String label;
  const _ComparePanel({required this.photo, required this.label});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(File(photo.imagePath), fit: BoxFit.cover),
        Positioned(
          top: 10,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: AppTheme.secondaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  Text(
                    DateFormat('d MMM yyyy', 'ar').format(photo.date),
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
