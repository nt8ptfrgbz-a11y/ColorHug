import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dress_catalog.dart';

typedef DressSave = Future<void> Function(String value);

@immutable
class DressLook {
  const DressLook({
    this.character = 0,
    this.outfit = 'petal',
    this.top = 'blouse',
    this.bottom = 'pleats',
    this.shoes = 'maryjane',
    this.hair = 'pigtails',
    this.accessory = 'bow',
    this.tint = -1,
  });
  final int character, tint;
  final String outfit, top, bottom, shoes, hair, accessory;
  String itemFor(DressCategory category) => switch (category) {
    DressCategory.outfit => outfit,
    DressCategory.top => outfit.isEmpty ? top : '',
    DressCategory.bottom => outfit.isEmpty ? bottom : '',
    DressCategory.shoes => shoes,
    DressCategory.hair => hair,
    DressCategory.accessory => accessory,
  };
  Map<String, Object> toJson() => {
    'character': character,
    'outfit': outfit,
    'top': top,
    'bottom': bottom,
    'shoes': shoes,
    'hair': hair,
    'accessory': accessory,
    'tint': tint,
  };
  static DressLook fromJson(Object? raw) {
    final v = raw is Map ? raw : const {};
    String valid(
      String key,
      String fallback,
      DressCategory category, {
      bool empty = false,
    }) {
      final id = v[key];
      if (empty && id == '') return '';
      return id is String && dressItemsById[id]?.category == category
          ? id
          : fallback;
    }

    return DressLook(
      character: v['character'] == 1 ? 1 : 0,
      outfit: valid('outfit', 'petal', DressCategory.outfit, empty: true),
      top: valid('top', 'blouse', DressCategory.top),
      bottom: valid('bottom', 'pleats', DressCategory.bottom),
      shoes: valid('shoes', 'maryjane', DressCategory.shoes),
      hair: valid('hair', 'pigtails', DressCategory.hair),
      accessory: valid(
        'accessory',
        'bow',
        DressCategory.accessory,
        empty: true,
      ),
      tint: v['tint'] is int && v['tint'] >= -1 && v['tint'] < 6
          ? v['tint'] as int
          : -1,
    );
  }

  DressLook change(Map<String, Object> values) =>
      fromJson({...toJson(), ...values});
}

@immutable
class DressMemory {
  const DressMemory({
    required this.id,
    required this.look,
    required this.place,
    required this.photo,
    this.sticker = 0,
  });
  final String id, photo;
  final DressLook look;
  final DressPlace place;
  final int sticker;
  Map<String, Object> toJson() => {
    'id': id,
    'look': look.toJson(),
    'place': place.name,
    'photo': photo,
    'sticker': sticker,
  };
  static DressMemory? fromJson(Object? raw) {
    if (raw is! Map || raw['id'] is! String || raw['photo'] is! String) {
      return null;
    }
    final id = raw['id'] as String, photo = raw['photo'] as String;
    if (!RegExp(r'^\d{10,20}$').hasMatch(id) ||
        !RegExp(r'^look_\d{10,20}\.png$').hasMatch(photo)) {
      return null;
    }
    return DressMemory(
      id: id,
      look: DressLook.fromJson(raw['look']),
      place: DressPlace.values.firstWhere(
        (v) => v.name == raw['place'],
        orElse: () => DressPlace.studio,
      ),
      photo: photo,
      sticker: raw['sticker'] is int ? (raw['sticker'] as int).clamp(0, 3) : 0,
    );
  }
}

class DressModel extends ChangeNotifier {
  DressModel({DressSave? save})
    : _save = save; // ignore: prefer_initializing_formals
  final DressSave? _save;
  static const storageKey = 'color_hug.dress_studio.v1';
  static const albumLimit = 24;
  static const defaults = DressLook();
  DressLook look = defaults;
  DressPlace place = DressPlace.studio;
  bool sound = true, reducedMotion = false, saveFailed = false;
  final List<DressLook> _undo = [];
  final List<DressMemory> _memories = [];
  final Set<DressPlace> discoveries = {};
  List<DressMemory> get memories => List.unmodifiable(_memories);
  bool get canUndo => _undo.isNotEmpty;
  Future<void> _writes = Future.value();
  Future<void> get saved => _writes;
  bool _disposed = false;

  static Future<DressModel> load() async {
    final preferences = SharedPreferencesAsync();
    final model = DressModel(save: (v) => preferences.setString(storageKey, v));
    try {
      model.restore(await preferences.getString(storageKey));
    } catch (_) {
      model.saveFailed = true;
    }
    return model;
  }

  void restore(String? raw) {
    if (raw == null) return;
    try {
      final v = jsonDecode(raw);
      if (v is! Map || v['version'] != 1) return;
      look = DressLook.fromJson(v['look']);
      place = DressPlace.values.firstWhere(
        (p) => p.name == v['place'],
        orElse: () => DressPlace.studio,
      );
      sound = v['sound'] != false;
      reducedMotion = v['reducedMotion'] == true;
      _memories.clear();
      if (v['memories'] is List) {
        for (final raw in (v['memories'] as List).take(albumLimit)) {
          final memory = DressMemory.fromJson(raw);
          if (memory != null && !_memories.any((m) => m.id == memory.id)) {
            _memories.add(memory);
          }
        }
      }
      discoveries.clear();
      if (v['discoveries'] is List) {
        discoveries.addAll(
          DressPlace.values.where(
            (p) => (v['discoveries'] as List).contains(p.name),
          ),
        );
      }
    } on FormatException {
      /* A damaged record starts a clean, usable wardrobe. */
    }
  }

  String encode() => jsonEncode({
    'version': 1,
    'look': look.toJson(),
    'place': place.name,
    'sound': sound,
    'reducedMotion': reducedMotion,
    'memories': _memories.map((m) => m.toJson()).toList(),
    'discoveries': discoveries.map((p) => p.name).toList(),
  });
  void _changed() {
    notifyListeners();
    final encoded = encode();
    _writes = _writes.then((_) async {
      try {
        await _save?.call(encoded);
        if (saveFailed && !_disposed) {
          saveFailed = false;
          notifyListeners();
        }
      } catch (_) {
        if (!_disposed) {
          saveFailed = true;
          notifyListeners();
        }
      }
    });
  }

  void _setLook(DressLook value) {
    if (mapEquals(value.toJson(), look.toJson())) return;
    _undo.add(look);
    if (_undo.length > 30) _undo.removeAt(0);
    look = value;
    _changed();
  }

  void wear(DressItem item) {
    if (dressItemsById[item.id] != item) return;
    final changes = <String, Object>{item.category.name: item.id};
    if (item.category == DressCategory.top ||
        item.category == DressCategory.bottom) {
      changes['outfit'] = '';
    }
    if ([DressCategory.outfit, DressCategory.top].contains(item.category)) {
      changes['tint'] = -1;
    }
    _setLook(look.change(changes));
  }

  void chooseCharacter(int value) {
    if (value == 0 || value == 1) _setLook(look.change({'character': value}));
  }

  void tint(int value) {
    if (value >= -1 && value < 6) _setLook(look.change({'tint': value}));
  }

  void removeAccessory() => _setLook(look.change({'accessory': ''}));
  void undo() {
    if (_undo.isNotEmpty) {
      look = _undo.removeLast();
      _changed();
    }
  }

  void visit(DressPlace value) {
    place = value;
    _changed();
  }

  void discover() {
    if (place != DressPlace.studio && discoveries.add(place)) _changed();
  }

  void setSound(bool value) {
    sound = value;
    _changed();
  }

  void setReducedMotion(bool value) {
    reducedMotion = value;
    _changed();
  }

  List<String> addMemory(DressMemory memory) {
    _memories.insert(0, memory);
    final expired = _memories.skip(albumLimit).map((m) => m.photo).toList();
    if (_memories.length > albumLimit) {
      _memories.removeRange(albumLimit, _memories.length);
    }
    _changed();
    return expired;
  }

  void restoreMemory(DressMemory memory) {
    _setLook(memory.look);
    place = memory.place;
    _changed();
  }

  void setSticker(String id, int sticker) {
    if (sticker < 0 || sticker > 3) return;
    final index = _memories.indexWhere((m) => m.id == id);
    if (index < 0 || _memories[index].sticker == sticker) return;
    final memory = _memories[index];
    _memories[index] = DressMemory(
      id: memory.id,
      look: memory.look,
      place: memory.place,
      photo: memory.photo,
      sticker: sticker,
    );
    _changed();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
