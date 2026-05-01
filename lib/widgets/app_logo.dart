import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// reusable logo widget — ginagamit sa lahat ng screens
// floating = yung bouncing animation (para sa welcome screen lang)
// small = compact version para sa home/gallery header
class AppLogo extends StatefulWidget {
  final bool floating; // mag-bounce ba?
  final bool small;    // smaller size para sa headers

  const AppLogo({super.key, this.floating = false, this.small = false});

  @override
  State<AppLogo> createState() => _AppLogoState();
}

class _AppLogoState extends State<AppLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _floatAnim = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    // mag-bounce lang kung floating mode
    if (widget.floating) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // size depende kung small or full
    final imgSize = widget.small ? 48.0 : 140.0;

    final logo = Image.asset(
      'assets/logo.png',
      width: imgSize,
      height: imgSize,
      fit: BoxFit.contain,
    );

    if (!widget.floating) return logo;

    // floating version — nag-bounce pataas pababa
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _floatAnim.value),
        child: logo,
      ),
    );
  }
}

// compact inline logo para sa app bars / headers
// shows the logo image + "TapArt" text side by side
class AppLogoInline extends StatelessWidget {
  final double fontSize;
  const AppLogoInline({super.key, this.fontSize = 28});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/logo.png',
            width: 44, height: 44,
            fit: BoxFit.contain),
        const SizedBox(width: 8),
        Text(
          'TapArt',
          style: GoogleFonts.pacifico(
            fontSize: fontSize,
            color: const Color(0xFFFF6B9D),
          ),
        ),
      ],
    );
  }
}
