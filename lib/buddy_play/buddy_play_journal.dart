import 'dart:convert';
import 'buddy_play_catalog.dart';

bool _number(Object? v, double low, double high) =>
    v is num && v.isFinite && v >= low && v <= high;
bool _integer(Object? v, int low, int high) =>
    v is int && v >= low && v <= high;
bool _list(Object? v, int min, int max, bool Function(Object?) check) =>
    v is List && v.length >= min && v.length <= max && v.every(check);
bool _point(Object? v, double minX, double maxX, double minY, double maxY) =>
    v is List &&
    v.length == 2 &&
    _number(v[0], minX, maxX) &&
    _number(v[1], minY, maxY);

bool validPlayData(BuddyPlay game, Object? value) {
  if (value is! Map || value['v'] != 1) return false;
  final d = value;
  return switch (game) {
    BuddyPlay.rolling =>
      _list(d['parts'], 3, 3, (v) => _integer(v, 0, 4)) &&
          _integer(d['scene'], 0, 2) &&
          _integer(d['ball'], 0, 2) &&
          d['right'] is bool,
    BuddyPlay.salon =>
      _integer(d['guest'], 0, 2) &&
          _list(
            d['looks'],
            3,
            3,
            (v) =>
                v is Map &&
                _list(v['lengths'], 11, 11, (n) => _number(n, .06, .35)) &&
                _list(v['leans'], 11, 11, (n) => _number(n, -.2, .2)) &&
                _integer(v['color'], 0, 3) &&
                _integer(v['decor'], 0, 3),
          ),
    BuddyPlay.water =>
      _integer(d['scene'], 0, 2) &&
          _list(d['pipes'], 3, 3, (v) => _integer(v, 0, 3)) &&
          d['gate'] is bool &&
          d['plug'] is bool,
    BuddyPlay.delivery =>
      _integer(d['guest'], 0, 2) &&
          _list(d['gifts'], 3, 3, (v) => v is bool) &&
          _integer(d['paint'], 0, 3),
    BuddyPlay.squishy =>
      _integer(d['color'], 0, 3) &&
          _integer(d['mood'], 0, 2) &&
          _list(
            d['face'],
            3,
            3,
            (v) => _list(v, 2, 2, (n) => _number(n, .32, .68)),
          ),
    BuddyPlay.soundTrain =>
      _list(d['cars'], 2, 6, (v) => _integer(v, 0, 3)) &&
          _integer(d['speed'], 0, 2) &&
          _integer(d['scene'], 0, 2),
    BuddyPlay.shadows =>
      _integer(d['scene'], 0, 2) &&
          _point(d['light'], .12, .88, .82, .99) &&
          _list(
            d['toys'],
            1,
            4,
            (v) =>
                v is Map &&
                _integer(v['kind'], 0, 3) &&
                _point(v['at'], .18, .82, .53, .77) &&
                _integer(v['hat'], 0, 2),
          ),
    BuddyPlay.tinyWorld =>
      _integer(d['scene'], 0, 2) &&
          d['rain'] is bool &&
          _list(d['ground'], 80, 80, (v) => _integer(v, 0, 2)) &&
          _list(
            d['objects'],
            0,
            12,
            (v) =>
                v is Map &&
                _integer(v['kind'], 0, 5) &&
                _integer(v['cell'], 0, 79),
          ) &&
          (d['objects'] as List).map((v) => v['cell']).toSet().length ==
              (d['objects'] as List).length &&
          (d['objects'] as List).every(
            (o) => o['kind'] == 1 || (d['ground'] as List)[o['cell']] != 2,
          ),
  };
}

Map<String, dynamic> normalisePlayData(BuddyPlay game, Map data) {
  final fields = switch (game) {
    BuddyPlay.rolling => ['parts', 'scene', 'ball', 'right'],
    BuddyPlay.salon => ['guest', 'looks'],
    BuddyPlay.water => ['scene', 'pipes', 'gate', 'plug'],
    BuddyPlay.delivery => ['guest', 'gifts', 'paint'],
    BuddyPlay.squishy => ['color', 'mood', 'face'],
    BuddyPlay.soundTrain => ['cars', 'speed', 'scene'],
    BuddyPlay.shadows => ['scene', 'light', 'toys'],
    BuddyPlay.tinyWorld => ['scene', 'rain', 'ground', 'objects'],
  };
  final clean = <String, dynamic>{
    'v': 1,
    for (final key in fields) key: data[key],
  };
  for (final entry in {
    'looks': ['lengths', 'leans', 'color', 'decor'],
    'toys': ['kind', 'at', 'hat'],
    'objects': ['kind', 'cell'],
  }.entries) {
    if (clean[entry.key] is List) {
      clean[entry.key] = [
        for (final item in clean[entry.key])
          {for (final key in entry.value) key: item[key]},
      ];
    }
  }
  return copyPlayData(clean);
}

Map<String, dynamic> copyPlayData(Map data) =>
    Map<String, dynamic>.from(jsonDecode(jsonEncode(data)) as Map);

class BuddyPlayJournal {
  final Map<BuddyPlay, Map<String, dynamic>> _drafts = {};
  final Map<BuddyPlay, List<Map<String, dynamic>>> _albums = {};
  final Set<BuddyPlay> _edited = {};

  Map<String, dynamic>? draft(BuddyPlay game) =>
      _drafts[game] == null ? null : copyPlayData(_drafts[game]!);
  List<Map<String, dynamic>> album(BuddyPlay game) =>
      (_albums[game] ?? []).map(copyPlayData).toList();

  bool save(BuddyPlay game, Map<String, dynamic> data, {bool collect = false}) {
    if (!validPlayData(game, data)) return false;
    _edited.add(game);
    final clean = normalisePlayData(game, data);
    _drafts[game] = clean;
    if (collect) {
      final items = _albums.putIfAbsent(game, () => []);
      final encoded = jsonEncode(clean);
      items.removeWhere((v) => jsonEncode(v) == encoded);
      items.insert(0, copyPlayData(clean));
      if (items.length > 6) items.removeLast();
    }
    return true;
  }

  void merge(Object? raw) {
    if (raw is! Map || raw['v'] != 1) return;
    for (final game in BuddyPlay.values) {
      final record = raw[game.name];
      if (record is! Map) continue;
      if (!_edited.contains(game) && validPlayData(game, record['draft'])) {
        _drafts[game] = normalisePlayData(game, record['draft'] as Map);
      }
      final album = record['album'];
      if (album is List) {
        final combined = [
          ...?_albums[game],
          ...album
              .where((v) => validPlayData(game, v))
              .map((v) => normalisePlayData(game, v as Map)),
        ];
        final seen = <String>{};
        _albums[game] = combined
            .where((v) => seen.add(jsonEncode(v)))
            .take(6)
            .toList();
      }
    }
  }

  Map<String, dynamic> toJson() => {
    'v': 1,
    for (final g in BuddyPlay.values)
      g.name: {'draft': draft(g), 'album': album(g)},
  };
}
