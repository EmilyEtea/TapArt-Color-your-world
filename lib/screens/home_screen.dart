import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import 'coloring_screen.dart';
import 'gallery_screen.dart';

// simple model para sa bawat template
class _Template {
  final String name;
  final String assetPath;
  final String displayName;
  final String emoji;
  const _Template({
    required this.name,
    required this.assetPath,
    required this.displayName,
    required this.emoji,
  });
}

const _kTemplates = [
  _Template(
    name: 'butterfly',
    assetPath: 'assets/svg/butterfly.svg',
    displayName: 'Butterfly',
    emoji: '🦋',
  ),
  _Template(
    name: 'house',
    assetPath: 'assets/svg/house.svg',
    displayName: 'House',
    emoji: '🏠',
  ),
];

const _kCardGradients = [
  [Color(0xFFFFD6E7), Color(0xFFFFB3C6)],
  [Color(0xFFD6EEFF), Color(0xFFB3D9FF)],
];
const _kCardBorders = [Color(0xFFFF6B9D), Color(0xFF5BA8D4)];

class HomeScreen extends StatelessWidget {
  final String userName;
  const HomeScreen({super.key, required this.userName});

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Sign Out? 👋',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Text('Are you sure you want to sign out?',
            style: GoogleFonts.nunito(fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Stay 🎨',
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF7B68EE))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B9D),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Sign Out',
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService().signOut();
      // AuthWrapper sa main.dart na bahala mag-redirect
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: SafeArea(
          child: Column(
            children: [
              // top bar — gallery, logo, sign out
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    _NavBtn(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      color: const Color(0xFF7B68EE),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GalleryScreen(userName: userName),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // logo image
                    Image.asset(
                      'assets/logo.png',
                      height: 64,
                      fit: BoxFit.contain,
                    ),
                    const Spacer(),
                    _NavBtn(
                      icon: Icons.logout_rounded,
                      label: 'Sign Out',
                      color: const Color(0xFFFF8E53),
                      onTap: () => _confirmSignOut(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // greeting banner
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B68EE),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7B68EE).withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('👋', style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Hi, $userName! Pick a picture to color!',
                        style: GoogleFonts.nunito(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              Text(
                'Tap a card to start! 👇',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF8E53),
                ),
              ),
              const SizedBox(height: 14),

              // template cards
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: _kTemplates
                        .asMap()
                        .entries
                        .map((e) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: _TemplateCard(
                                  template: e.value,
                                  index: e.key,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ColoringScreen(
                                        userName: userName,
                                        assetPath: e.value.assetPath,
                                        templateName: e.value.name,
                                        templateEmoji: e.value.emoji,
                                        templateDisplayName: e.value.displayName,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// nav button with hover + press effect
class _NavBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _NavBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_NavBtn> createState() => _NavBtnState();
}

class _NavBtnState extends State<_NavBtn> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) {
        if (mounted) setState(() { _hovered = false; _pressed = false; });
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _hovered
                  ? widget.color.withOpacity(0.22)
                  : widget.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.color.withOpacity(0.3)),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: widget.color.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(widget.icon, color: widget.color, size: 18),
              const SizedBox(width: 5),
              Text(widget.label,
                  style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: widget.color)),
            ]),
          ),
        ),
      ),
    );
  }
}

// template card with hover + press effect
class _TemplateCard extends StatefulWidget {
  final _Template template;
  final int index;
  final VoidCallback onTap;
  const _TemplateCard({
    required this.template,
    required this.index,
    required this.onTap,
  });

  @override
  State<_TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends State<_TemplateCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final gradColors = _kCardGradients[widget.index % _kCardGradients.length];
    final borderColor = _kCardBorders[widget.index % _kCardBorders.length];

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) {
        if (mounted) setState(() { _hovered = false; _pressed = false; });
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : (_hovered ? 1.03 : 1.0),
          duration: const Duration(milliseconds: 130),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradColors,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: borderColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: borderColor.withOpacity(_hovered ? 0.5 : 0.3),
                  blurRadius: _hovered ? 22 : 14,
                  offset: _pressed
                      ? const Offset(0, 2)
                      : const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.template.emoji,
                    style: const TextStyle(fontSize: 52)),
                const SizedBox(height: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      color: Colors.white.withOpacity(0.7),
                      padding: const EdgeInsets.all(8),
                      child: SvgPicture.asset(widget.template.assetPath,
                          fit: BoxFit.contain),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    widget.template.displayName,
                    style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
