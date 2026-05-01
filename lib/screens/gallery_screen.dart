import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';

// gallery ng lahat ng na-save na artworks — stored locally per user UID
class GalleryScreen extends StatefulWidget {
  final String userName;
  const GalleryScreen({super.key, required this.userName});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final _service = FirestoreService();
  late final String _uid;
  List<ArtworkEntry> _artworks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _uid = AuthService().currentUser?.uid ?? '';
    _loadArtworks();
  }

  Future<void> _loadArtworks() async {
    setState(() => _loading = true);
    final list = await _service.artworksStream(_uid).first;
    if (mounted) {
      setState(() {
        _artworks = list;
        _loading = false;
      });
    }
  }

  Future<void> _confirmDelete(ArtworkEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Delete Artwork? 🗑️',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Text(
          'Remove "${entry.displayName}" from your gallery?',
          style: GoogleFonts.nunito(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Keep it 🎨',
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF7B68EE))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete',
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.deleteArtwork(_uid, entry.id);
      await _loadArtworks(); // i-refresh pagkatapos mag-delete
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
              // header row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    // back button with hover
                    _IconBtn(
                      icon: Icons.arrow_back_ios_new_rounded,
                      color: const Color(0xFF7B68EE),
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    // logo + subtitle
                    Column(
                      children: [
                        Image.asset(
                          'assets/logo.png',
                          height: 56,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.userName}\'s artworks',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFF6B9D),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // refresh button with hover
                    _IconBtn(
                      icon: Icons.refresh_rounded,
                      color: const Color(0xFFFF6B9D),
                      onTap: _loadArtworks,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // content
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFFFF6B9D)))
                    : _artworks.isEmpty
                        ? _emptyState()
                        : _ArtworkGrid(
                            artworks: _artworks,
                            onDelete: _confirmDelete,
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎨', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 16),
          Text(
            'No artworks yet!\nGo color something! 🖌️',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF7B68EE),
            ),
          ),
        ],
      ),
    );
  }
}

// reusable icon button with hover + press effect
class _IconBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.onTap});

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
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
          scale: _pressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _hovered
                  ? widget.color.withOpacity(0.2)
                  : widget.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: widget.color.withOpacity(0.3)),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: widget.color.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : [],
            ),
            child: Icon(widget.icon, color: widget.color, size: 18),
          ),
        ),
      ),
    );
  }
}

// artwork grid
class _ArtworkGrid extends StatelessWidget {
  final List<ArtworkEntry> artworks;
  final Future<void> Function(ArtworkEntry) onDelete;

  const _ArtworkGrid({required this.artworks, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.82,
        ),
        itemCount: artworks.length,
        itemBuilder: (context, i) => _ArtworkCard(
          entry: artworks[i],
          onDelete: () => onDelete(artworks[i]),
        ),
      ),
    );
  }
}

// single artwork card with hover + press
class _ArtworkCard extends StatefulWidget {
  final ArtworkEntry entry;
  final VoidCallback onDelete;
  const _ArtworkCard({required this.entry, required this.onDelete});

  @override
  State<_ArtworkCard> createState() => _ArtworkCardState();
}

class _ArtworkCardState extends State<_ArtworkCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d, yyyy').format(widget.entry.savedAt);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) {
        if (mounted) setState(() { _hovered = false; _pressed = false; });
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : (_hovered ? 1.03 : 1.0),
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B68EE)
                      .withOpacity(_hovered ? 0.22 : 0.12),
                  blurRadius: _hovered ? 20 : 14,
                  offset: _pressed
                      ? const Offset(0, 2)
                      : const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // emoji preview area
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F5),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24)),
                    ),
                    child: Center(
                      child: Text(
                        widget.entry.emoji,
                        style: const TextStyle(fontSize: 56),
                      ),
                    ),
                  ),
                ),

                // name + date + delete
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.entry.displayName,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF5C4033),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              dateStr,
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                          // delete button — also has hover
                          _DeleteBtn(onTap: widget.onDelete),
                        ],
                      ),
                    ],
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

// small delete button with its own hover
class _DeleteBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _DeleteBtn({required this.onTap});

  @override
  State<_DeleteBtn> createState() => _DeleteBtnState();
}

class _DeleteBtnState extends State<_DeleteBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) {
        if (mounted) setState(() => _hovered = false);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: _hovered
                ? const Color(0xFFFF6B6B).withOpacity(0.18)
                : const Color(0xFFFFEEEE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.delete_outline_rounded,
            color: _hovered ? const Color(0xFFFF3333) : const Color(0xFFFF6B6B),
            size: 16,
          ),
        ),
      ),
    );
  }
}
