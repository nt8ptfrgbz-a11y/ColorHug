import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'town_catalog.dart';

class TownProgress extends ChangeNotifier {
  TownProgress({this.preferences}) {
    ready = _load();
  }
  factory TownProgress.persistent() =>
      TownProgress(preferences: SharedPreferencesAsync());
  static const storageKey = 'silly_town.progress.v1';
  final SharedPreferencesAsync? preferences;
  late final Future<void> ready;
  final Set<int> _completed = {};
  final Set<String> _words = {};
  bool music = true;
  bool _closed = false;
  Future<void> _writes = Future.value();
  Set<int> get completed => Set.unmodifiable(_completed);
  Set<String> get words => Set.unmodifiable(_words);
  int get nextLevel {
    for (var i = 0; i < townLevels.length; i++) {
      if (!_completed.contains(i)) return i;
    }
    return 0;
  }

  int countIn(int district) =>
      _completed.where((i) => i ~/ 5 == district).length;
  Future<void> _load() async {
    try {
      final raw = await preferences?.getString(storageKey);
      if (raw != null) {
        final data = jsonDecode(raw);
        if (data is Map) {
          final completed = data['completed'];
          if (completed is List) {
            _completed.addAll(
              completed.whereType<int>().where(
                (i) => i >= 0 && i < townLevels.length,
              ),
            );
          }
          final words = data['words'];
          if (words is List) {
            _words.addAll(
              words.whereType<String>().where(
                (w) =>
                    townLevels.any((l) => l.words.contains(w) || l.phrase == w),
              ),
            );
          }
          if (data['music'] is bool) music = data['music'];
        }
      }
    } catch (_) {
      /* A damaged save should never prevent a child from playing. */
    }
    if (!_closed) notifyListeners();
  }

  void finish(int id) {
    if (id < 0 || id >= townLevels.length || !_completed.add(id)) return;
    _save();
  }

  void encounter(String word) {
    if (_words.add(word)) _save();
  }

  void toggleMusic() {
    music = !music;
    _save();
  }

  void _save() {
    if (_closed) return;
    notifyListeners();
    // Serialize snapshots so a slower old write cannot overwrite newer progress.
    final raw = jsonEncode({
      'completed': _completed.toList()..sort(),
      'words': _words.toList()..sort(),
      'music': music,
    });
    _writes = _writes.then((_) async {
      try {
        await preferences?.setString(storageKey, raw);
      } catch (_) {
        /* Keep the in-memory save. */
      }
    });
  }

  Future<void> flush() => _writes;
  @override
  void dispose() {
    _closed = true;
    super.dispose();
  }
}
