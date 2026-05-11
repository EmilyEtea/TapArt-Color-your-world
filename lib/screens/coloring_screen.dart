import 'dart:async';
import 'dart:collection';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../widgets/color_palette.dart';

// tolerance value for color matching — how similar colors need to be to fill
const int _kFillTolerance = 30;

// checks if a pixel is a dark outline — we don't fill these
bool _isOutline(int argb) {
  final r = (argb >> 16) & 0xFF;
  final g = (argb >> 8) & 0xFF;
  final b = argb & 0xFF;
  return (r + g + b) ~/ 3 < 80;
}

// checks if two colors are close enough to be considered the same
bool _matches(int a, int b) {
  final dr = ((a >> 16) & 0xFF) - ((b >> 16) & 0xFF);
  final dg = ((a >> 8) & 0xFF) - ((b >> 8) & 0xFF);
  final db = (a & 0xFF) - (b & 0xFF);
  return dr.abs() <= _kFillTolerance && dg.abs() <= _kFillTolerance && db.abs() <= _kFillTolerance;
}

// BFS flood fill — fills a region with the selected color
// same idea as the paint bucket tool in MS Paint
Uint32List floodFill(Uint32List pixels, int w, int h, int x, int y, Color c) {
  final fill = (c.alpha << 24) | (c.red << 16) | (c.green << 8) | c.blue;
  final target = pixels[y * w + x];

  // don't fill outlines or same-colored areas
  if (_isOutline(target)) return Uint32List.fromList(pixels);
  if (_matches(target, fill)) return Uint32List.fromList(pixels);

  final result = Uint32List.fromList(pixels);
  final visited = List<bool>.filled(w * h, false);
  final queue = Queue<int>();

  queue.add(y * w + x);
  visited[y * w + x] = true;

  while (queue.isNotEmpty) {
    final idx = queue.removeFirst();
    result[idx] = fill;
    final cx = idx % w;
    final cy = idx ~/ w;

    // check all 4 neighbors
    for (final (nx, ny) in [(cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)]) {
      if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
      final ni = ny * w + nx;
      if (visited[ni] || _isOutline(result[ni])) continue;
      if (_matches(result[ni], target)) {
        visited[ni] = true;
        queue.add(ni);
      }
    }
  }
  return result;
}

// converts ARGB pixel buffer to RGBA bytes (needed for PNG encoding)
Uint8List _argbToRgba(Uint32List pixels) {
  final rgba = Uint8List(pixels.length * 4);
  for (int i = 0; i < pixels.length; i++) {
    final argb = pixels[i];
    rgba[i * 4]     = (argb >> 16) & 0xFF; // R
    rgba[i * 4 + 1] = (argb >> 8)  & 0xFF; // G
    rgba[i * 4 + 2] =  argb        & 0xFF; // B
    rgba[i * 4 + 3] = (argb >> 24) & 0xFF; // A
  }
  return rgba;
}

// generates the download filename
String _fileName(String userName, String template, DateTime date) {
  final clean = userName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
  return '${clean}_${template}_${DateFormat('yyyyMMdd').format(date)}.png';
}

// triggers a PNG download in the browser
Future<String> saveArtworkWeb({
  required Uint32List pixels,
  required int width,
  required int height,
  required String userName,
  required String templateName,
}) async {
  final rgba = _argbToRgba(pixels);

  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(rgba, width, height, ui.PixelFormat.rgba8888, completer.complete);
  final image = await completer.future;
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final pngBytes = byteData!.buffer.asUint8List();

  final fileName = _fileName(userName, templateName, DateTime.now());
  final blob = html.Blob([pngBytes], 'image/png');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);

  return fileName;
}

// draws the pixel image onto the canvas widget
class _CanvasPainter extends CustomPainter {
  final ui.Image image;
  _CanvasPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint(),
    );
  }

  @override
  bool shouldRepaint(_CanvasPainter old) => old.image != image;
}

// main coloring screen
class ColoringScreen extends StatefulWidget {
  const ColoringScreen({
    super.key,
    required this.userName,
    required this.assetPath,
    required this.templateName,
    this.templateEmoji = '🎨',
    this.templateDisplayName = '',
  });

  final String userName;
  final String assetPath;
  final String templateName;
  final String templateEmoji;
  final String templateDisplayName;

  @override
  State<ColoringScreen> createState() => _ColoringScreenState();
}

class _ColoringScreenState extends State<ColoringScreen> {
  Uint32List? _pixels;
  Uint32List? _originalPixels; // saved for reset
  ui.Image? _canvasImage;
  int _canvasW = 0, _canvasH = 0;
  Color _selectedColor = const Color(0xFFE85D5D);
  final List<Uint32List> _undoStack = [];
  bool _isLoading = true;
  bool _isSaving = false;
  double _zoom = 0.85;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSvg());
  }

  Future<void> _loadSvg() async {
    final size = MediaQuery.of(context).size;
    final targetW = (size.width * 0.9).round().clamp(300, 1200);
    final targetH = (size.height * 0.7).round().clamp(300, 900);

    try {
      final svgBytes = await rootBundle.load(widget.assetPath);
      final svgString = utf8.decode(svgBytes.buffer.asUint8List());
      final info = await vg.loadPicture(SvgStringLoader(svgString), null);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // scale SVG to fit canvas without distorting
      final scale = min(targetW / info.size.width, targetH / info.size.height);

      // center the SVG inside the canvas
      final offsetX = (targetW - info.size.width * scale) / 2;
      final offsetY = (targetH - info.size.height * scale) / 2;
      canvas.translate(offsetX, offsetY);
      canvas.scale(scale, scale);
      canvas.drawPicture(info.picture);

      final image = await recorder.endRecording().toImage(targetW, targetH);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final rgba = byteData!.buffer.asUint8List();

      // convert RGBA to ARGB for our pixel buffer
      final pixels = Uint32List(targetW * targetH);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = (rgba[i * 4 + 3] << 24) | (rgba[i * 4] << 16) | (rgba[i * 4 + 1] << 8) | rgba[i * 4 + 2];
      }

      setState(() {
        _pixels = pixels;
        _originalPixels = Uint32List.fromList(pixels);
        _canvasW = targetW;
        _canvasH = targetH;
        _isLoading = false;
      });
      _refreshImage(pixels, targetW, targetH);
    } catch (e) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Oops! 😅', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
          content: Text("Couldn't load template. Please try again.", style: GoogleFonts.nunito(fontSize: 16)),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B9D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () { Navigator.of(context).pop(); Navigator.of(context).pop(); },
              child: Text('OK', style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  // converts pixel buffer back to a displayable image
  void _refreshImage(Uint32List pixels, int w, int h) {
    final rgba = _argbToRgba(pixels);
    ui.decodeImageFromPixels(rgba, w, h, ui.PixelFormat.rgba8888, (img) {
      if (mounted) setState(() => _canvasImage = img);
    });
  }

  // called when user taps the canvas
  void _onTap(TapDownDetails details, BoxConstraints constraints) {
    final buf = _pixels;
    if (buf == null) return;

    // convert tap position to pixel coordinates
    final px = (details.localPosition.dx * _canvasW / constraints.maxWidth).round().clamp(0, _canvasW - 1);
    final py = (details.localPosition.dy * _canvasH / constraints.maxHeight).round().clamp(0, _canvasH - 1);

    // save current state for undo
    _undoStack.add(Uint32List.fromList(buf));
    if (_undoStack.length > 20) _undoStack.removeAt(0);

    final newBuf = floodFill(buf, _canvasW, _canvasH, px, py, _selectedColor);
    setState(() => _pixels = newBuf);
    _refreshImage(newBuf, _canvasW, _canvasH);
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    final restored = _undoStack.removeLast();
    setState(() => _pixels = restored);
    _refreshImage(restored, _canvasW, _canvasH);
  }

  void _reset() {
    if (_originalPixels == null) return;
    _undoStack.clear();
    final fresh = Uint32List.fromList(_originalPixels!);
    setState(() => _pixels = fresh);
    _refreshImage(fresh, _canvasW, _canvasH);
  }

  Future<void> _save() async {
    final buf = _pixels;
    if (buf == null || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      final fileName = await saveArtworkWeb(
        pixels: buf,
        width: _canvasW,
        height: _canvasH,
        userName: widget.userName,
        templateName: widget.templateName,
      );

      if (!mounted) return;
      _showSnack('🎉  Saved & downloading $fileName', const Color(0xFF4CAF7D));
    } catch (e) {
      if (!mounted) return;
      _showSnack("😢  Couldn't save. Please try again.", const Color(0xFFFF6B6B));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      content: Text(msg, style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: Colors.white)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.templateName[0].toUpperCase() + widget.templateName.substring(1);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B68EE),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('$title 🖌️', style: GoogleFonts.pacifico(fontSize: 22, color: Colors.white)),
        actions: [
          _ToolBtn(icon: Icons.undo_rounded, label: 'Undo', color: const Color(0xFFFFD700),
              enabled: _undoStack.isNotEmpty, onTap: _undoStack.isEmpty ? null : _undo),
          _ToolBtn(icon: Icons.refresh_rounded, label: 'Reset', color: const Color(0xFFFF8E53),
              enabled: _pixels != null, onTap: _pixels == null ? null : _reset),
          _ToolBtn(
              icon: _isSaving ? Icons.hourglass_top_rounded : Icons.download_rounded,
              label: 'Save', color: const Color(0xFF4CAF7D),
              enabled: _pixels != null && !_isSaving,
              onTap: (_pixels == null || _isSaving) ? null : _save),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          // zoom slider bar
          Container(
            color: const Color(0xFF7B68EE).withOpacity(0.08),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                const Text('🔍', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text('Zoom', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF7B68EE))),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF7B68EE),
                      inactiveTrackColor: const Color(0xFF7B68EE).withOpacity(0.2),
                      thumbColor: const Color(0xFFFF6B9D),
                      overlayColor: const Color(0xFFFF6B9D).withOpacity(0.2),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                    ),
                    child: Slider(value: _zoom, min: 0.4, max: 1.5, divisions: 22,
                        onChanged: (v) => setState(() => _zoom = v)),
                  ),
                ),
                Text('${(_zoom * 100).round()}%',
                    style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF7B68EE))),
                const SizedBox(width: 8),
              ],
            ),
          ),

          // canvas
          Expanded(
            child: _isLoading || _canvasImage == null
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const CircularProgressIndicator(color: Color(0xFFFF6B9D)),
                      const SizedBox(height: 16),
                      Text('Loading your canvas... 🎨',
                          style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF7B68EE))),
                    ]),
                  )
                : Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: Center(
                          child: Container(
                            width: _canvasW * _zoom,
                            height: _canvasH * _zoom,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFF7B68EE).withOpacity(0.18), blurRadius: 24, offset: const Offset(0, 6)),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: LayoutBuilder(
                              builder: (ctx, constraints) => GestureDetector(
                                onTapDown: (d) => _onTap(d, constraints),
                                child: SizedBox.expand(
                                  child: CustomPaint(painter: _CanvasPainter(_canvasImage!)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),

          // color palette at the bottom
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
            ),
            child: ColorPalette(
              selectedColor: _selectedColor,
              onColorSelected: (c) => setState(() => _selectedColor = c),
            ),
          ),
        ],
      ),
    );
  }
}

// toolbar button with hover and press effects
class _ToolBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final Color color;
  final VoidCallback? onTap;

  const _ToolBtn({required this.icon, required this.label, required this.enabled, required this.color, this.onTap});

  @override
  State<_ToolBtn> createState() => _ToolBtnState();
}

class _ToolBtnState extends State<_ToolBtn> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) { if (widget.enabled) setState(() => _hovered = true); },
      onExit: (_) { if (mounted) setState(() { _hovered = false; _pressed = false; }); },
      child: GestureDetector(
        onTapDown: (_) { if (widget.enabled) setState(() => _pressed = true); },
        onTapUp: (_) { setState(() => _pressed = false); widget.onTap?.call(); },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.93 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.enabled ? widget.color : Colors.white24,
              borderRadius: BorderRadius.circular(16),
              boxShadow: widget.enabled && _hovered
                  ? [BoxShadow(color: widget.color.withOpacity(0.45), blurRadius: 10, offset: const Offset(0, 3))]
                  : [],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(widget.icon, color: Colors.white, size: 18),
              const SizedBox(width: 5),
              Text(widget.label, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
            ]),
          ),
        ),
      ),
    );
  }
}
