import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class _Swatch {
  final Color color;
  final String name;
  const _Swatch(this.color, this.name);
}

const List<_Swatch> _kSwatches = [
  _Swatch(Color(0xFFE85D5D), 'Strawberry Red'),
  _Swatch(Color(0xFFE8845D), 'Sunset Orange'),
  _Swatch(Color(0xFFF4A460), 'Sandy Orange'),
  _Swatch(Color(0xFFF5C842), 'Sunny Yellow'),
  _Swatch(Color(0xFFD4E84A), 'Lime Green'),
  _Swatch(Color(0xFF7DC95E), 'Grass Green'),
  _Swatch(Color(0xFF4CAF7D), 'Mint Green'),
  _Swatch(Color(0xFF4DB6AC), 'Ocean Teal'),
  _Swatch(Color(0xFF5BA8D4), 'Sky Blue'),
  _Swatch(Color(0xFF5B7FD4), 'Blueberry'),
  _Swatch(Color(0xFF7B68D4), 'Lavender'),
  _Swatch(Color(0xFFAA68D4), 'Grape Purple'),
  _Swatch(Color(0xFFD468C8), 'Bubblegum'),
  _Swatch(Color(0xFFE87AAA), 'Flamingo Pink'),
  _Swatch(Color(0xFFE8A0B4), 'Cotton Candy'),
  _Swatch(Color(0xFF9E7B5A), 'Chocolate'),
  _Swatch(Color(0xFFB0A090), 'Warm Grey'),
  _Swatch(Color(0xFFFFFFFF), 'White'),
  _Swatch(Color(0xFF333333), 'Black'),
];

class ColorPalette extends StatefulWidget {
  const ColorPalette({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  @override
  State<ColorPalette> createState() => _ColorPaletteState();
}

class _ColorPaletteState extends State<ColorPalette> {
  static const double _swatchSize = 48.0;
  String? _hoveredName;

  bool _isSame(Color a, Color b) =>
      a.red == b.red && a.green == b.green && a.blue == b.blue;

  Widget _buildSwatch(_Swatch swatch) {
    final isSelected = _isSame(swatch.color, widget.selectedColor);
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredName = swatch.name),
      onExit: (_) => setState(() => _hoveredName = null),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onColorSelected(swatch.color),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: isSelected ? _swatchSize + 8 : _swatchSize,
          height: isSelected ? _swatchSize + 8 : _swatchSize,
          margin: EdgeInsets.symmetric(
            horizontal: 4,
            vertical: isSelected ? 0 : 4,
          ),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: swatch.color,
            border: isSelected
                ? Border.all(color: Colors.white, width: 3)
                : Border.all(color: Colors.black12, width: 1.5),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: swatch.color.withOpacity(0.6),
                        blurRadius: 12,
                        spreadRadius: 2),
                    const BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2)),
                  ]
                : [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 4,
                        offset: const Offset(0, 2)),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomSwatch() {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredName = 'Custom Color ✨'),
      onExit: (_) => setState(() => _hoveredName = null),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _openPicker,
        child: Container(
          width: _swatchSize,
          height: _swatchSize,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const SweepGradient(colors: [
              Color(0xFFFF0000),
              Color(0xFFFFFF00),
              Color(0xFF00FF00),
              Color(0xFF00FFFF),
              Color(0xFF0000FF),
              Color(0xFFFF00FF),
              Color(0xFFFF0000),
            ]),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: const Icon(Icons.colorize, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Future<void> _openPicker() async {
    final picked = await showDialog<Color>(
      context: context,
      builder: (_) => _ColorPickerDialog(initialColor: widget.selectedColor),
    );
    if (picked != null) widget.onColorSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hover color name label
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: _hoveredName != null
              ? Container(
                  key: ValueKey(_hoveredName),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B68EE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _hoveredName!,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                )
              : const SizedBox(key: ValueKey('empty'), height: 28),
        ),
        // Swatches row
        Container(
          height: _swatchSize + 20,
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                ..._kSwatches.map(_buildSwatch),
                _buildCustomSwatch(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.initialColor});
  final Color initialColor;
  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initialColor);
  }

  @override
  Widget build(BuildContext context) {
    final current = _hsv.toColor();
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text('Pick a Color 🎨',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
      content: SizedBox(
        width: 300,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _GradientSlider(
            label: 'Hue 🌈',
            value: _hsv.hue / 360,
            gradient: LinearGradient(
                colors: List.generate(
                    7, (i) => HSVColor.fromAHSV(1, i * 60.0, 1, 1).toColor())),
            onChanged: (v) => setState(() => _hsv = _hsv.withHue(v * 360)),
          ),
          const SizedBox(height: 10),
          _GradientSlider(
            label: 'Saturation 💧',
            value: _hsv.saturation,
            gradient: LinearGradient(colors: [
              HSVColor.fromAHSV(1, _hsv.hue, 0, _hsv.value).toColor(),
              HSVColor.fromAHSV(1, _hsv.hue, 1, _hsv.value).toColor(),
            ]),
            onChanged: (v) => setState(() => _hsv = _hsv.withSaturation(v)),
          ),
          const SizedBox(height: 10),
          _GradientSlider(
            label: 'Brightness ☀️',
            value: _hsv.value,
            gradient: LinearGradient(colors: [
              Colors.black,
              HSVColor.fromAHSV(1, _hsv.hue, _hsv.saturation, 1).toColor(),
            ]),
            onChanged: (v) => setState(() => _hsv = _hsv.withValue(v)),
          ),
          const SizedBox(height: 16),
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: current,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
        ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B9D),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () => Navigator.of(context).pop(current),
          child: Text('Use this color!',
              style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800, color: Colors.white)),
        ),
      ],
    );
  }
}

class _GradientSlider extends StatelessWidget {
  const _GradientSlider({
    required this.label,
    required this.value,
    required this.gradient,
    required this.onChanged,
  });
  final String label;
  final double value;
  final LinearGradient gradient;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600)),
      const SizedBox(height: 4),
      Stack(alignment: Alignment.center, children: [
        Container(
          height: 14,
          decoration: BoxDecoration(
              gradient: gradient, borderRadius: BorderRadius.circular(7)),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 14,
            activeTrackColor: Colors.transparent,
            inactiveTrackColor: Colors.transparent,
            thumbColor: Colors.white,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
            overlayColor: Colors.white24,
          ),
          child: Slider(value: value.clamp(0.0, 1.0), onChanged: onChanged),
        ),
      ]),
    ]);
  }
}
