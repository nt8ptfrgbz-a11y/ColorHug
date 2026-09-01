import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class ColorDiscovery {
  const ColorDiscovery({
    required this.name,
    required this.color,
    required this.emoji,
    required this.fact,
  });

  final String name;
  final Color color;
  final String emoji;
  final String fact;
}

const colorDiscoveryCatalog = <ColorDiscovery>[
  ColorDiscovery(
    name: '红色',
    color: Color(0xFFFF4F64),
    emoji: '🍓',
    fact: '像草莓和勇敢的小火车',
  ),
  ColorDiscovery(
    name: '珊瑚色',
    color: Color(0xFFFF766C),
    emoji: '🩸',
    fact: '像海底珊瑚一样温暖又活泼',
  ),
  ColorDiscovery(
    name: '橙色',
    color: Color(0xFFFF922E),
    emoji: '🍊',
    fact: '红色和黄色颜料能调出橙色',
  ),
  ColorDiscovery(
    name: '琥珀色',
    color: Color(0xFFFFB52E),
    emoji: '🍯',
    fact: '像蜜糖和夕阳里闪亮的光',
  ),
  ColorDiscovery(
    name: '黄色',
    color: Color(0xFFFFD84A),
    emoji: '☀️',
    fact: '像太阳一样明亮又温暖',
  ),
  ColorDiscovery(
    name: '黄绿色',
    color: Color(0xFF9BC94A),
    emoji: '🍐',
    fact: '像刚长出来的嫩叶',
  ),
  ColorDiscovery(
    name: '绿色',
    color: Color(0xFF45CE75),
    emoji: '🌱',
    fact: '森林和小芽最喜欢的颜色',
  ),
  ColorDiscovery(
    name: '薄荷色',
    color: Color(0xFF72DEB1),
    emoji: '🍃',
    fact: '像薄荷叶和清凉的微风',
  ),
  ColorDiscovery(
    name: '青色',
    color: Color(0xFF42D7D0),
    emoji: '🐳',
    fact: '像清亮的海水和天空',
  ),
  ColorDiscovery(
    name: '湖蓝色',
    color: Color(0xFF31B9D8),
    emoji: '🌊',
    fact: '像阳光下清澈闪亮的湖水',
  ),
  ColorDiscovery(
    name: '蓝绿色',
    color: Color(0xFF357EC2),
    emoji: '🐬',
    fact: '蓝色和青色颜料的海洋颜色',
  ),
  ColorDiscovery(
    name: '蓝色',
    color: Color(0xFF4687FF),
    emoji: '💧',
    fact: '像雨滴，也像安静的夜晚',
  ),
  ColorDiscovery(
    name: '深蓝色',
    color: Color(0xFF3158A6),
    emoji: '🌌',
    fact: '像星星刚刚亮起来的夜空',
  ),
  ColorDiscovery(
    name: '靛蓝色',
    color: Color(0xFF5C58C9),
    emoji: '🔮',
    fact: '在蓝色和紫色之间藏着的神秘颜色',
  ),
  ColorDiscovery(
    name: '紫色',
    color: Color(0xFF9B67E8),
    emoji: '🍇',
    fact: '红色和蓝色相遇后的魔法',
  ),
  ColorDiscovery(
    name: '薰衣草色',
    color: Color(0xFFB99AEF),
    emoji: '🪣',
    fact: '像薰衣草花田一样柔和',
  ),
  ColorDiscovery(
    name: '品红色',
    color: Color(0xFFE45AB7),
    emoji: '🎆',
    fact: '光的三个基础伙伴之一，鲜艳又有活力',
  ),
  ColorDiscovery(
    name: '红紫色',
    color: Color(0xFFC25388),
    emoji: '🌺',
    fact: '像一朵神秘的大花',
  ),
  ColorDiscovery(
    name: '粉色',
    color: Color(0xFFFF9DB1),
    emoji: '🌸',
    fact: '红色遇到白色后变得轻轻的',
  ),
  ColorDiscovery(
    name: '玫红色',
    color: Color(0xFFE84F84),
    emoji: '🌹',
    fact: '像盛开的玫瑰，热情又自信',
  ),
  ColorDiscovery(
    name: '桃色',
    color: Color(0xFFFFB38D),
    emoji: '🍑',
    fact: '像成熟桃子一样甜甜暖暖',
  ),
  ColorDiscovery(
    name: '棕色',
    color: Color(0xFF8A654A),
    emoji: '🐻',
    fact: '像泥土、树干和小熊',
  ),
  ColorDiscovery(
    name: '米色',
    color: Color(0xFFE6D2A8),
    emoji: '🌾',
    fact: '像麦穗和沙滩一样自然温和',
  ),
  ColorDiscovery(
    name: '白色',
    color: Color(0xFFF8F5EB),
    emoji: '☁️',
    fact: '所有彩色的光抱在一起会变白',
  ),
  ColorDiscovery(
    name: '灰色',
    color: Color(0xFF8C8F99),
    emoji: '🐘',
    fact: '像雨云和大象的颜色',
  ),
  ColorDiscovery(
    name: '黑色',
    color: Color(0xFF30333D),
    emoji: '🌙',
    fact: '像没有开灯的夜空',
  ),
];

class IslandProgress extends ChangeNotifier {
  IslandProgress() : this._(null);

  IslandProgress._(this._preferences)
    : _discoveredColors = {'红色', '黄色', '蓝色', '绿色'} {
    if (_preferences != null) {
      _writeQueue = _load();
      unawaited(_writeQueue);
    }
  }

  factory IslandProgress.persistent() {
    return IslandProgress._(SharedPreferencesAsync());
  }

  static const _starsKey = 'color_hug.stars';
  static const _repairedPartsKey = 'color_hug.repaired_parts';
  static const _detectiveWinsKey = 'color_hug.detective_wins';
  static const _artworksKey = 'color_hug.artworks';
  static const _guardianWinsKey = 'color_hug.guardian_wins';
  static const _discoveriesKey = 'color_hug.discoveries';
  static const _rewardTokensKey = 'color_hug.reward_tokens';

  final SharedPreferencesAsync? _preferences;
  final Set<String> _discoveredColors;
  final Set<String> _rewardTokens = {};
  int _stars = 0;
  int _repairedParts = 0;
  int _detectiveWins = 0;
  int _artworks = 0;
  int _guardianWins = 0;
  bool _disposed = false;
  Future<void> _writeQueue = Future<void>.value();

  int get stars => _stars;
  int get repairedParts => _repairedParts;
  int get detectiveWins => _detectiveWins;
  int get artworks => _artworks;
  int get guardianWins => _guardianWins;
  int get monsterRadarWins => _rewardCount('ultra-radar-');
  int get beamTrainingWins => _rewardCount('ultra-beam-');
  int get spaceRescueWins => _rewardCount('ultra-rescue-');
  int get fruitSliceWins => _rewardCount('ultra-fruit-');
  int get monsterPlanetWins => _rewardCount('monster-planet-');
  int get completedColorChallenges => _rewardTokens
      .where((token) => token.startsWith('color-challenge-'))
      .length;
  int get discoveredCount => colorDiscoveryCatalog
      .where((item) => _discoveredColors.contains(item.name))
      .length;
  int get discoveryTotal => colorDiscoveryCatalog.length;

  bool hasDiscovered(String name) => _discoveredColors.contains(name);

  bool hasMonsterPlanetWin(String fighterId) =>
      _rewardTokens.contains('monster-planet-$fighterId');

  bool discover(String name) {
    var changed = _discoveredColors.add(name);
    if (name.startsWith('浅') || name.startsWith('深')) {
      changed = _discoveredColors.add(name.substring(1)) || changed;
    }
    if (name == '灰棕色') {
      changed = _discoveredColors.add('棕色') || changed;
      changed = _discoveredColors.add('灰色') || changed;
    }
    if (changed) {
      notifyListeners();
      _persist();
    }
    return changed;
  }

  bool awardStar({String? token}) {
    if (token != null && !_rewardTokens.add(token)) return false;
    _stars++;
    notifyListeners();
    _persist();
    return true;
  }

  void recordDetectiveWin(int roundIndex, String colorName) {
    discover(colorName);
    if (awardStar(token: 'detective-$roundIndex')) {
      _detectiveWins++;
      notifyListeners();
      _persist();
    }
  }

  void repairPart(int completedParts, String colorName) {
    discover(colorName);
    if (completedParts <= _repairedParts) return;
    _repairedParts = completedParts;
    awardStar(token: 'repair-$completedParts');
    notifyListeners();
    _persist();
  }

  void recordArtwork(Set<String> colors) {
    for (final color in colors) {
      discover(color);
    }
    _artworks++;
    awardStar(token: 'first-artwork');
    notifyListeners();
    _persist();
  }

  bool recordColorChallenge(int challengeNumber, String colorName) {
    discover(colorName);
    return awardStar(token: 'color-challenge-$challengeNumber');
  }

  bool recordGuardianWin(int missionIndex, String colorName) {
    discover(colorName);
    final earned = awardStar(token: 'guardian-$missionIndex');
    if (earned) {
      _guardianWins++;
      notifyListeners();
      _persist();
    }
    return earned;
  }

  bool recordUltraTrainingWin(String game, int roundIndex) {
    return awardStar(token: 'ultra-$game-$roundIndex');
  }

  bool recordMonsterPlanetWin(String fighterId) {
    return awardStar(token: 'monster-planet-$fighterId');
  }

  int _rewardCount(String prefix) =>
      _rewardTokens.where((token) => token.startsWith(prefix)).length;

  Future<void> _load() async {
    final preferences = _preferences;
    if (preferences == null) return;
    try {
      final storedStars = await preferences.getInt(_starsKey) ?? 0;
      final storedParts = await preferences.getInt(_repairedPartsKey) ?? 0;
      final storedWins = await preferences.getInt(_detectiveWinsKey) ?? 0;
      final storedArtworks = await preferences.getInt(_artworksKey) ?? 0;
      final storedGuardianWins =
          await preferences.getInt(_guardianWinsKey) ?? 0;
      final storedDiscoveries =
          await preferences.getStringList(_discoveriesKey) ?? const [];
      final storedTokens =
          await preferences.getStringList(_rewardTokensKey) ?? const [];
      if (_disposed) return;
      if (storedStars > _stars) _stars = storedStars;
      if (storedParts > _repairedParts) _repairedParts = storedParts;
      if (storedWins > _detectiveWins) _detectiveWins = storedWins;
      if (storedArtworks > _artworks) _artworks = storedArtworks;
      if (storedGuardianWins > _guardianWins) {
        _guardianWins = storedGuardianWins;
      }
      _discoveredColors.addAll(storedDiscoveries);
      _rewardTokens.addAll(storedTokens);
      notifyListeners();
    } catch (_) {
      // Widget tests and unsupported embedders may not provide the plugin.
      // The game remains fully playable with an in-memory progress model.
    }
  }

  void _persist() {
    if (_preferences == null) return;
    _writeQueue = _writeQueue.then((_) => _writeProgress());
    unawaited(_writeQueue);
  }

  Future<void> _writeProgress() async {
    final preferences = _preferences;
    if (preferences == null) return;
    try {
      await Future.wait([
        preferences.setInt(_starsKey, _stars),
        preferences.setInt(_repairedPartsKey, _repairedParts),
        preferences.setInt(_detectiveWinsKey, _detectiveWins),
        preferences.setInt(_artworksKey, _artworks),
        preferences.setInt(_guardianWinsKey, _guardianWins),
        preferences.setStringList(
          _discoveriesKey,
          _discoveredColors.toList(growable: false),
        ),
        preferences.setStringList(
          _rewardTokensKey,
          _rewardTokens.toList(growable: false),
        ),
      ]);
    } catch (_) {
      // Progress persistence is best-effort and must never stop play.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
