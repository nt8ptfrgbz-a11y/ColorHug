import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SeedKind { mushroom, tree, flower }

enum Nutrient { moon, music, soda, rainbow }

enum LabPhase { planting, growing, grown }

const seedNames = ['团团种子', '星星种子', '花花种子'];
const nutrientNames = ['一勺月光', '一段音乐', '气泡汽水', '一滴彩虹'];
const nutrientShortNames = ['月光', '音乐', '汽水', '彩虹'];
const nutrientHints = ['会发光吗？', '会唱歌吗？', '会冒泡吗？', '会变色吗？'];
const _pairNames = [
  ['月亮', '晚安曲', '月光泡泡', '星河'],
  ['晚安曲', '叮咚', '咕噜交响', '彩虹音乐'],
  ['月光泡泡', '咕噜交响', '啵啵', '彩虹汽水'],
  ['星河', '彩虹音乐', '彩虹汽水', '七彩'],
];
const _shapeNames = ['蘑菇', '星星树', '花精灵'];

@immutable
class PlantDiscovery {
  const PlantDiscovery({
    required this.seed,
    required this.first,
    required this.second,
    this.parents = const [],
  });

  final SeedKind seed;
  final Nutrient first, second;
  final List<String> parents;

  String get recipeId {
    final pair = [first.index, second.index]..sort();
    return '${seed.index}-${pair[0]}-${pair[1]}';
  }

  String get id => parents.isEmpty
      ? recipeId
      : 'hybrid:${(parents.toList()..sort()).join("+")}';
  bool get hybrid => parents.isNotEmpty;
  String get name =>
      '${hybrid ? '双生·' : ''}'
      '${_pairNames[first.index][second.index]}${_shapeNames[seed.index]}';
  String get recipe =>
      '${nutrientShortNames[first.index]} + '
      '${nutrientShortNames[second.index]}';
  String get secret => hybrid
      ? '两位植物朋友的魔法，住进了同一颗种子里。'
      : switch (second) {
          Nutrient.moon => '把小小的月光，藏进每一个好梦。',
          Nutrient.music => '轻轻碰一碰，它就唱起叮叮咚咚的歌。',
          Nutrient.soda => '它打的每一个小嗝，都是圆滚滚的泡泡。',
          Nutrient.rainbow => '雨过天晴的颜色，全都藏在它的身体里。',
        };

  Map<String, Object> toJson() => {
    'seed': seed.index,
    'first': first.index,
    'second': second.index,
    'parents': parents,
  };

  static PlantDiscovery? fromJson(Object? value) {
    if (value is! Map) return null;
    final s = value['seed'], a = value['first'], b = value['second'];
    if (s is! int ||
        s < 0 ||
        s >= SeedKind.values.length ||
        a is! int ||
        a < 0 ||
        a >= Nutrient.values.length ||
        b is! int ||
        b < 0 ||
        b >= Nutrient.values.length) {
      return null;
    }
    final parents = value['parents'];
    final ids = parents is List
        ? parents.whereType<String>().toList()
        : <String>[];
    // Only base discoveries can be crossed; this keeps IDs finite and stable.
    if (ids.isNotEmpty &&
        (ids.length != 2 ||
            ids[0] == ids[1] ||
            ids.any((id) => !RegExp(r'^[0-2]-[0-3]-[0-3]$').hasMatch(id)))) {
      return null;
    }
    return PlantDiscovery(
      seed: SeedKind.values[s],
      first: Nutrient.values[a],
      second: Nutrient.values[b],
      parents: List.unmodifiable(ids),
    );
  }
}

/// Persist only stable states; a interrupted growth resumes ready to grow.
class SeedLabModel extends ChangeNotifier {
  SeedLabModel({this.save});
  final Future<void> Function(String)? save;
  Future<void> _writes = Future.value();
  static const storageKey = 'color_hug.seed_lab.v1';

  SeedKind _seed = SeedKind.mushroom;
  final List<Nutrient> _ingredients = [];
  final Map<String, PlantDiscovery> _discoveries = {};
  List<String> _parents = [];
  LabPhase _phase = LabPhase.planting;
  bool _reducedMotion = false;
  int _experiments = 0;

  SeedKind get seed => _seed;
  List<Nutrient> get ingredients => List.unmodifiable(_ingredients);
  List<PlantDiscovery> get discoveries =>
      List.unmodifiable(_discoveries.values);
  LabPhase get phase => _phase;
  bool get reducedMotion => _reducedMotion;
  int get experiments => _experiments;
  bool get ready => _ingredients.length == 2 && _phase == LabPhase.planting;
  bool get isHybrid => _parents.isNotEmpty;
  int get baseCount => _discoveries.values.where((p) => !p.hybrid).length;
  PlantDiscovery? get result {
    if (_ingredients.length != 2) return null;
    final pair = _ingredients.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    return PlantDiscovery(
      seed: _seed,
      first: pair[0],
      second: pair[1],
      parents: List.unmodifiable(_parents),
    );
  }

  static Future<SeedLabModel> load() async {
    final prefs = SharedPreferencesAsync();
    final model = SeedLabModel(
      save: (value) => prefs.setString(storageKey, value),
    );
    try {
      model.restore(await prefs.getString(storageKey));
    } catch (_) {
      /* Storage does not prevent offline play. */
    }
    return model;
  }

  void selectSeed(SeedKind value) {
    if (_phase != LabPhase.planting || isHybrid) return;
    _seed = value;
    _changed();
  }

  bool add(Nutrient value) {
    if (_phase != LabPhase.planting || _ingredients.length >= 2 || isHybrid) {
      return false;
    }
    _ingredients.add(value);
    _changed();
    return true;
  }

  void removeLast() {
    if (_phase != LabPhase.planting || _ingredients.isEmpty || isHybrid) return;
    _ingredients.removeLast();
    _changed();
  }

  bool startGrowing() {
    if (!ready) return false;
    _phase = LabPhase.growing;
    _changed();
    return true;
  }

  bool finishGrowing() {
    if (_phase != LabPhase.growing) return false;
    final plant = result!;
    final isNew = !_discoveries.containsKey(plant.id);
    _discoveries[plant.id] = plant;
    _phase = LabPhase.grown;
    _experiments++;
    _changed();
    return isNew;
  }

  void newPot() {
    if (_phase == LabPhase.growing) return;
    _phase = LabPhase.planting;
    _ingredients.clear();
    _parents = [];
    _changed();
  }

  bool cross(PlantDiscovery a, PlantDiscovery b) {
    if (_phase == LabPhase.growing ||
        a.id == b.id ||
        a.hybrid ||
        b.hybrid ||
        !_discoveries.containsKey(a.id) ||
        !_discoveries.containsKey(b.id)) {
      return false;
    }
    final parents = [a, b]..sort((x, y) => x.id.compareTo(y.id));
    _seed = parents.first.seed;
    _ingredients
      ..clear()
      ..addAll([parents.first.first, parents.last.second]);
    _parents = parents.map((p) => p.id).toList(growable: false);
    _phase = LabPhase.planting;
    _changed();
    return true;
  }

  void setReducedMotion(bool value) {
    _reducedMotion = value;
    _changed();
  }

  String encode() => jsonEncode({
    'version': 1,
    'seed': _seed.index,
    'ingredients': _ingredients.map((n) => n.index).toList(),
    'parents': _parents,
    'grown': _phase == LabPhase.grown,
    'discoveries': discoveries.map((p) => p.toJson()).toList(),
    'experiments': _experiments,
    'reducedMotion': _reducedMotion,
  });

  void restore(String? source) {
    if (source == null) return;
    try {
      final data = jsonDecode(source);
      if (data is! Map || data['version'] != 1) return;
      final s = data['seed'];
      if (s is int && s >= 0 && s < 3) _seed = SeedKind.values[s];
      _ingredients.clear();
      if (data['ingredients'] case final List list) {
        _ingredients.addAll(
          list
              .whereType<int>()
              .where((n) => n >= 0 && n < 4)
              .take(2)
              .map((n) => Nutrient.values[n]),
        );
      }
      _discoveries.clear();
      if (data['discoveries'] case final List list) {
        for (final value in list.take(465)) {
          final plant = PlantDiscovery.fromJson(value);
          if (plant != null) _discoveries[plant.id] = plant;
        }
      }
      _parents = [];
      if (data['parents'] case final List list) {
        final ids = list.whereType<String>().toList();
        if (ids.length == 2 &&
            ids[0] != ids[1] &&
            ids.every((id) => _discoveries[id]?.hybrid == false) &&
            _ingredients.length == 2) {
          _parents = ids;
        }
      }
      _experiments = data['experiments'] is int
          ? (data['experiments'] as int).clamp(0, 999999)
          : 0;
      _reducedMotion = data['reducedMotion'] == true;
      _phase =
          data['grown'] == true &&
              result != null &&
              _discoveries.containsKey(result!.id)
          ? LabPhase.grown
          : LabPhase.planting;
    } catch (_) {
      /* Ignore malformed saves; the lab remains usable. */
    }
  }

  void _changed() {
    final snapshot = encode();
    _writes = _writes.then((_) async {
      try {
        await save?.call(snapshot);
      } catch (_) {
        /* Best-effort persistence. */
      }
    });
    notifyListeners();
  }

  Future<void> flush() => _writes;
}
