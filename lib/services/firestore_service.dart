import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

// originally Firestore ito pero nag-require ng billing kaya SharedPreferences na lang
// same behavior — per user UID, sorted by date, pwedeng mag-delete
// stored locally sa browser — okay na for school project naman hehe
class ArtworkEntry {
  final String id;
  final String templateName;
  final String displayName;
  final String emoji;
  final DateTime savedAt;
  final String uid;

  const ArtworkEntry({
    required this.id,
    required this.templateName,
    required this.displayName,
    required this.emoji,
    required this.savedAt,
    required this.uid,
  });

  factory ArtworkEntry.fromMap(Map<String, dynamic> map) {
    return ArtworkEntry(
      id: map['id'] as String,
      templateName: map['templateName'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      emoji: map['emoji'] as String? ?? '🎨',
      savedAt: DateTime.tryParse(map['savedAt'] as String? ?? '') ?? DateTime.now(),
      uid: map['uid'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'templateName': templateName,
        'displayName': displayName,
        'emoji': emoji,
        'savedAt': savedAt.toIso8601String(),
        'uid': uid,
      };
}

/// Stores artwork metadata locally using SharedPreferences.
/// Replaces Firestore to avoid billing requirements.
class FirestoreService {
  static String _key(String uid) => 'artworks_$uid';

  Future<List<ArtworkEntry>> _load(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key(uid)) ?? [];
    return raw
        .map((s) {
          try {
            return ArtworkEntry.fromMap(
                jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<ArtworkEntry>()
        .toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  Future<void> _save(String uid, List<ArtworkEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key(uid),
      entries.map((e) => jsonEncode(e.toMap())).toList(),
    );
  }

  /// Save a new artwork entry for the given user.
  Future<void> saveArtwork({
    required String uid,
    required String templateName,
    required String displayName,
    required String emoji,
  }) async {
    final entries = await _load(uid);
    entries.add(ArtworkEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      templateName: templateName,
      displayName: displayName,
      emoji: emoji,
      savedAt: DateTime.now(),
      uid: uid,
    ));
    await _save(uid, entries);
  }

  /// Stream of artworks — emits once immediately from local storage.
  Stream<List<ArtworkEntry>> artworksStream(String uid) async* {
    yield await _load(uid);
  }

  /// Delete an artwork entry.
  Future<void> deleteArtwork(String uid, String artworkId) async {
    final entries = await _load(uid);
    entries.removeWhere((e) => e.id == artworkId);
    await _save(uid, entries);
  }
}
