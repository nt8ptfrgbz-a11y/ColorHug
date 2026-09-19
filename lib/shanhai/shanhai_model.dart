import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ShanPhase { sleeping, awakening, companion, flying, arrival }

enum ShanRealm { moon, stars, dawn }

const realmNames = ['月照青池', '星河天境', '金霞云海'];
const realmPoems = ['一池月色，候你唤醒。', '乘风入夜，万星相迎。', '追逐晨光，山海同游。'];

class ShanhaiModel extends ChangeNotifier {
  ShanhaiModel({this.save});
  final Future<void> Function(String)? save;
  static const storageKey = 'color_hug.shanhai.v1';
  Future<void> _writes = Future.value();
  ShanPhase phase = ShanPhase.sleeping;
  ShanRealm realm = ShanRealm.moon;
  bool reducedMotion = false;
  final Set<int> seals = {};
  final Set<ShanRealm> visited = {};
  final Set<int> collectedGates = {};
  int affection = 0, feeds = 0, flights = 0, totalStarlight = 0;
  double awaken = 0, flight = 0, steering = 0, orbit = 0, reaction = 0;
  double _petCooldown = 0, _feedCooldown = 0;
  bool awakened = false;
  int get flightStars => collectedGates.length;
  bool get canFeed => phase == ShanPhase.companion && _feedCooldown <= 0;
  bool get canPet => phase == ShanPhase.companion && _petCooldown <= 0;

  static Future<ShanhaiModel> load() async {
    final preferences = SharedPreferencesAsync();
    final model = ShanhaiModel(
      save: (s) => preferences.setString(storageKey, s),
    );
    try {
      model.restore(await preferences.getString(storageKey));
    } catch (_) {}
    return model;
  }

  bool traceSeal(int index) {
    if (phase != ShanPhase.sleeping ||
        index < 0 ||
        index > 2 ||
        !seals.add(index)) {
      return false;
    }
    if (seals.length == 3) {
      phase = ShanPhase.awakening;
      awaken = 0;
    }
    notifyListeners();
    return true;
  }

  bool pet() {
    if (!canPet) return false;
    affection = (affection + 1).clamp(0, 9999);
    _petCooldown = 1.3;
    reaction = .001;
    _changed();
    return true;
  }

  bool feed() {
    if (!canFeed) return false;
    feeds = (feeds + 1).clamp(0, 9999);
    affection = (affection + 3).clamp(0, 9999);
    _feedCooldown = 2.6;
    reaction = .001;
    _changed();
    return true;
  }

  void setRealm(ShanRealm value) {
    if (phase == ShanPhase.flying || phase == ShanPhase.awakening) return;
    realm = value;
    _changed();
  }

  void turn(double delta) {
    if (phase != ShanPhase.companion || !delta.isFinite) return;
    orbit = (orbit + delta).clamp(-.9, .9);
    notifyListeners();
  }

  void steer(double value) {
    if (phase != ShanPhase.flying || !value.isFinite) return;
    steering = value.clamp(-1.0, 1.0);
    notifyListeners();
  }

  bool startFlight() {
    if (phase != ShanPhase.companion) return false;
    phase = ShanPhase.flying;
    flight = 0;
    steering = 0;
    collectedGates.clear();
    _changed();
    return true;
  }

  /// Gate centers match the seven actual SceneKit portals. Crossing is judged
  /// when the dragon's head reaches each portal, not by tapping a UI counter.
  static double gateSteering(int i) => math.sin(i * 1.7);
  static double gateTime(int i) => (4.8 + i * 16) / 112;

  void advance(double seconds) {
    if (!seconds.isFinite || seconds <= 0) return;
    final dt = seconds.clamp(0.0, .1);
    _petCooldown = math.max(0, _petCooldown - dt);
    _feedCooldown = math.max(0, _feedCooldown - dt);
    if (reaction > 0) {
      reaction += dt / 1.3;
      if (reaction >= 1) reaction = 0;
    }
    if (phase == ShanPhase.awakening) {
      awaken = (awaken + dt / (reducedMotion ? 1.2 : 5.5)).clamp(0.0, 1.0);
      if (awaken >= 1) {
        phase = ShanPhase.companion;
        awakened = true;
        visited.add(realm);
        _persist();
      }
    } else if (phase == ShanPhase.flying) {
      final before = flight;
      flight = (flight + dt / 42).clamp(0.0, 1.0);
      for (var i = 0; i < 7; i++) {
        final gate = gateTime(i);
        if (before < gate &&
            flight >= gate &&
            (steering - gateSteering(i)).abs() < .52) {
          collectedGates.add(i);
        }
      }
      if (flight >= 1) {
        phase = ShanPhase.arrival;
        flights++;
        totalStarlight += flightStars;
        visited.add(realm);
        _persist();
      }
    }
    notifyListeners();
  }

  void returnToLake() {
    if (phase != ShanPhase.flying && phase != ShanPhase.arrival) return;
    phase = ShanPhase.companion;
    steering = 0;
    flight = 0;
    orbit = 0;
    _changed();
  }

  void replayAwakening() {
    if (phase != ShanPhase.companion) return;
    phase = ShanPhase.sleeping;
    seals.clear();
    awaken = 0;
    orbit = 0;
    notifyListeners();
  }

  void setReducedMotion(bool value) {
    reducedMotion = value;
    _changed();
  }

  Map<String, Object> get nativeValues => {
    'phase': phase.name,
    'realm': realm.name,
    'awaken': awaken,
    'flight': flight,
    'steering': steering,
    'orbit': orbit,
    'reaction': reaction,
    'reducedMotion': reducedMotion,
  };

  String encode() => jsonEncode({
    'version': 1,
    'awakened': awakened,
    'realm': realm.index,
    'visited': visited.map((e) => e.index).toList(),
    'affection': affection,
    'feeds': feeds,
    'flights': flights,
    'starlight': totalStarlight,
    'reducedMotion': reducedMotion,
  });

  void restore(String? raw) {
    if (raw == null) return;
    try {
      final data = jsonDecode(raw);
      if (data is! Map || data['version'] != 1) return;
      int integer(String key, int max) =>
          data[key] is int ? (data[key] as int).clamp(0, max) : 0;
      awakened = data['awakened'] == true;
      realm = ShanRealm.values[integer('realm', 2)];
      affection = integer('affection', 9999);
      feeds = integer('feeds', 9999);
      flights = integer('flights', 99999);
      totalStarlight = integer('starlight', 999999);
      reducedMotion = data['reducedMotion'] == true;
      visited.clear();
      if (data['visited'] case final List items) {
        visited.addAll(
          items
              .whereType<int>()
              .where((i) => i >= 0 && i < 3)
              .map((i) => ShanRealm.values[i]),
        );
      }
      phase = awakened ? ShanPhase.companion : ShanPhase.sleeping;
      awaken = awakened ? 1 : 0;
      flight = 0;
      reaction = 0;
      steering = 0;
      orbit = 0;
      seals.clear();
      collectedGates.clear();
    } catch (_) {
      /* A damaged save never prevents play. */
    }
  }

  void _changed() {
    _persist();
    notifyListeners();
  }

  void _persist() {
    final data = encode();
    _writes = _writes.then((_) async {
      try {
        await save?.call(data);
      } catch (_) {}
    });
  }

  Future<void> flush() => _writes;
}
