import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';

class CommunityImageEditor extends StatefulWidget {
  const CommunityImageEditor({super.key, required this.file});
  final File file;
  @override
  State<CommunityImageEditor> createState() => _CommunityImageEditorState();
}

class _CommunityImageEditorState extends State<CommunityImageEditor> {
  final GlobalKey _canvasKey = GlobalKey();
  final List<_OverlayItem> _items = [];
  Uint8List? _bytes;
  double _maxWidth = 1600;
  bool _busy = false;

  @override
  void initState() { super.initState(); _bytes = widget.file.readAsBytesSync(); }

  Future<void> _crop() async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: widget.file.path,
      uiSettings: [AndroidUiSettings(
        toolbarTitle: 'برش تصویر', toolbarColor: const Color(0xFF171B2B),
        toolbarWidgetColor: Colors.white, activeControlsWidgetColor: const Color(0xFF8B5CF6),
        lockAspectRatio: false, hideBottomControls: false,
      )],
    );
    if (cropped != null) setState(() => _bytes = File(cropped.path).readAsBytesSync());
  }

  Future<void> _addText() async {
    final controller = TextEditingController();
    final text = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: const Text('افزودن نوشته روی عکس'),
      content: TextField(controller: controller, autofocus: true, maxLength: 100,
        decoration: const InputDecoration(hintText: 'متن دلخواه…')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
        FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('افزودن')),
      ],
    ));
    if (text != null && text.isNotEmpty) setState(() => _items.add(_OverlayItem(text, false)));
    controller.dispose();
  }

  void _addSticker(String value) => setState(() => _items.add(_OverlayItem(value, true)));

  Future<Uint8List?> _export() async {
    setState(() => _busy = true);
    try {
      final boundary = _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ratio = (_maxWidth / boundary.size.width).clamp(0.5, 3.0);
      final image = await boundary.toImage(pixelRatio: ratio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) return null;
      final decoded = img.decodeImage(data.buffer.asUint8List());
      if (decoded == null) return data.buffer.asUint8List();
      return Uint8List.fromList(img.encodeJpg(img.copyResize(decoded, width: _maxWidth.toInt()), quality: 88));
    } catch (_) { return null; }
    finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: const Color(0xFF0A0D18),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0D18), foregroundColor: Colors.white,
        title: const Text('ویرایش تصویر', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        actions: [TextButton.icon(
          onPressed: _busy ? null : () async {
            final result = await _export();
            if (mounted && result != null) Navigator.pop(context, result);
          },
          icon: _busy ? const SizedBox(width: 16,height: 16,child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_circle_rounded),
          label: const Text('تأیید و ادامه'),
        )],
      ),
      body: SafeArea(child: Column(children: [
        Expanded(child: Center(child: Padding(
          padding: const EdgeInsets.all(12),
          child: RepaintBoundary(
            key: _canvasKey,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.passthrough,
                alignment: Alignment.center,
                children: [
                  Image.memory(_bytes!, fit: BoxFit.contain),
                  ..._items.asMap().entries.map((entry) => Positioned(
                    left: 16 + (entry.key % 3) * 38.0, top: 24 + (entry.key % 4) * 42.0,
                    child: GestureDetector(
                      onPanUpdate: (d) => setState(() { entry.value.dx += d.delta.dx; entry.value.dy += d.delta.dy; }),
                      onLongPress: () => setState(() => _items.remove(entry.value)),
                      child: Transform.translate(
                        offset: Offset(entry.value.dx, entry.value.dy),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: entry.value.sticker ? null : BoxDecoration(
                            color: Colors.black.withValues(alpha: .42), borderRadius: BorderRadius.circular(8)),
                          child: Text(entry.value.text, style: TextStyle(
                            color: Colors.white, fontSize: entry.value.sticker ? 38 : 24, fontWeight: FontWeight.w900,
                            shadows: const [Shadow(color: Colors.black87, blurRadius: 5)],
                          )),
                        ),
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),
        ))),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          decoration: const BoxDecoration(color: Color(0xFF141A2A), borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
          child: Column(children: [
            Row(children: [
              _tool(Icons.crop_rounded, 'برش', _crop),
              _tool(Icons.title_rounded, 'متن', _addText),
              _tool(Icons.emoji_emotions_outlined, 'استیکر', () => showModalBottomSheet(
                context: context, backgroundColor: const Color(0xFF1C2335),
                builder: (_) => SafeArea(child: Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 12,
                  children: ['❤️','🔥','✨','😂','😍','👏','💯','🎉','🌟','😎','💜','🚀']
                    .map((e) => IconButton(onPressed: () { Navigator.pop(context); _addSticker(e); },
                      icon: Text(e, style: const TextStyle(fontSize: 30)))).toList(),
                )),
              )),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.photo_size_select_large_rounded, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              const Text('اندازه خروجی', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Expanded(child: Slider(value: _maxWidth, min: 640, max: 2560, divisions: 12,
                onChanged: (v) => setState(() => _maxWidth = v))),
              Text('${_maxWidth.toInt()}px', style: const TextStyle(color: Colors.white, fontSize: 11)),
            ]),
            const Text('برای جابه‌جایی نوشته یا استیکر، آن را بکش؛ برای حذف، چند لحظه نگه دار.',
              style: TextStyle(color: Colors.white54, fontSize: 10)),
          ]),
        ),
      ])),
    ),
  );

  Widget _tool(IconData icon, String label, VoidCallback onTap) => Expanded(
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(13),
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(children: [
          Icon(icon, color: const Color(0xFFB9A5FF), size: 23),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ]),
      ),
    ),
  );
}

class _OverlayItem {
  _OverlayItem(this.text, this.sticker);
  final String text;
  final bool sticker;
  double dx = 0;
  double dy = 0;
}
