import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

const valleyEnd = 2250.0,
    campX = 260.0,
    riverLeft = 1260.0,
    riverRight = 1450.0;
const bridgeCenter = (riverLeft + riverRight) / 2, bridgeLength = 245.0;
const riverStop = 1130.0;
const expeditionInk = Color(0xFF335B51);

double roadHeight(double x) {
  if (x > riverLeft - 50 && x < riverRight + 60) return 0;
  return math.sin(x / 180) * 7 - 23 * math.exp(-math.pow((x - 710) / 105, 2));
}

Offset onRoad(double x) => Offset(x, roadHeight(x));

enum LogPlace { bank, hook, bridge }

enum DinoAction {
  waiting,
  curious,
  crossing,
  following,
  boarding,
  riding,
  alighting,
  home,
}

enum ExpeditionInput { none, road, hook, fruit }

@immutable
class ExpeditionEvent {
  const ExpeditionEvent(
    this.id,
    this.english,
    this.chinese, {
    this.sound,
    this.important = false,
  });
  final String id, english, chinese;
  final String? sound;
  final bool important;
}

class ValleyParticle {
  ValleyParticle(
    this.position,
    this.velocity,
    this.color,
    this.radius,
    this.life,
  );
  Offset position, velocity;
  final Color color;
  final double radius;
  double life;
}

@immutable
class ValleyCheckpoint {
  const ValleyCheckpoint({
    this.carX = campX,
    this.logX = 1205,
    this.bridge = false,
    this.joined = false,
    this.home = false,
    this.mud = 0,
    this.fruitX = 760,
    this.fruitCarried = false,
    this.fed = false,
    this.riding = false,
    this.secrets = const {},
  });
  final double carX, logX, mud, fruitX;
  final bool bridge, joined, home, fruitCarried, fed, riding;
  final Set<String> secrets;
  Map<String, dynamic> toJson() => {
    'v': 1,
    'car': carX,
    'log': logX,
    'bridge': bridge,
    'joined': joined,
    'home': home,
    'mud': mud,
    'fruit': fruitX,
    'carried': fruitCarried,
    'fed': fed,
    'riding': riding,
    'secrets': secrets.toList()..sort(),
  };
  static ValleyCheckpoint? fromJson(Object? raw) {
    if (raw is! Map || raw['v'] != 1) return null;
    bool number(String key, double lo, double hi) =>
        raw[key] is num &&
        (raw[key] as num).isFinite &&
        (raw[key] as num) >= lo &&
        (raw[key] as num) <= hi;
    if (!number('car', 120, valleyEnd) ||
        !number('log', 940, 1630) ||
        !number('mud', 0, 1) ||
        !number('fruit', 120, valleyEnd)) {
      return null;
    }
    for (final key in ['bridge', 'joined', 'home', 'carried', 'fed']) {
      if (raw[key] is! bool) return null;
    }
    final secrets = raw['secrets'];
    if (secrets is! List ||
        secrets.length > 8 ||
        secrets.any(
          (v) => !const ['mud', 'wash', 'echo', 'leaf', 'fruit'].contains(v),
        )) {
      return null;
    }
    if (raw['home'] == true && raw['joined'] != true) return null;
    if (raw['riding'] != null && raw['riding'] is! bool) return null;
    if (raw['riding'] == true && raw['joined'] != true) return null;
    if (raw['fed'] == true && raw['home'] != true) return null;
    if (raw['bridge'] == false &&
        (raw['car'] as num) > riverStop &&
        (raw['car'] as num) < riverRight + 110) {
      return null;
    }
    final lx = (raw['log'] as num).toDouble();
    if (raw['bridge'] == false && lx > riverLeft - 35 && lx < riverRight + 35) {
      return null;
    }
    return ValleyCheckpoint(
      carX: (raw['car'] as num).toDouble(),
      logX: lx,
      bridge: raw['bridge'],
      joined: raw['joined'],
      home: raw['home'],
      mud: (raw['mud'] as num).toDouble(),
      fruitX: (raw['fruit'] as num).toDouble(),
      fruitCarried: raw['carried'],
      fed: raw['fed'],
      riding: raw['riding'] == true,
      secrets: secrets.cast<String>().toSet(),
    );
  }
}
