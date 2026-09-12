import 'dart:math' as math;
import 'package:flutter/painting.dart';

class OrchardApple {
  OrchardApple(this.id, this.position);
  final int id;
  Offset position;
  double vy = 0;
  bool stored = false, eaten = false;
}

class OrchardController {
  double stoneX = 690, push = 0, shake = 0, helper = 0, pushAssist = 0;
  bool fed = false, basketLoaded = false;
  double helperX = 590, basketLift = 1;
  Offset basketAt = basket;
  bool basketHeld = false;
  int? held;
  final apples = List.generate(
    4,
    (i) => OrchardApple(i, Offset(1080 + i * 43, -190 - (i % 2) * 28)),
  );
  static const basket = Offset(1275, -20);
  bool get cleared => stoneX >= 825;
  int get count => apples.where((a) => a.stored).length;
  bool get ready => fed && basketLoaded;
  void beginPush() {
    push = 1;
    helper = 1;
  }

  void stop() {
    push = 0;
    pushAssist = 0;
    held = null;
    basketHeld = false;
    basketAt = basket;
  }

  void shakeTree() {
    shake = 1;
    for (final a in apples) {
      if (!a.stored && !a.eaten && a.position.dy < -80) a.vy = 35;
    }
  }

  void moveApple(Offset at) {
    if (held == null) return;
    apples[held!].position = Offset(
      at.dx.clamp(980, 1430),
      at.dy.clamp(-250, -18),
    );
  }

  bool storeApple() {
    if (held == null) return false;
    final a = apples[held!];
    held = null;
    if ((a.position - basket).distance < 100) {
      a.stored = true;
      a.position = basket;
      return true;
    }
    a.position = Offset(a.position.dx, -18);
    return false;
  }

  bool feed() {
    if (fed) return true;
    final items = apples.where((a) => a.stored && !a.eaten);
    if (items.isEmpty) return false;
    items.first
      ..stored = false
      ..eaten = true;
    fed = true;
    return true;
  }

  void dragBasket(Offset at) {
    if (basketHeld) {
      basketAt = Offset(at.dx.clamp(850, 1430), at.dy.clamp(-200, 0));
    }
  }

  bool loadBasket() {
    if (!fed || count < 3) return false;
    basketLoaded = true;
    basketHeld = false;
    basketAt = basket;
    basketLift = 0;
    return true;
  }

  void step(double dt) {
    if ((push > 0 || pushAssist > 0) && !cleared) {
      stoneX = math.min(835, stoneX + dt * 47);
    }
    pushAssist = math.max(0, pushAssist - dt);
    if (helper > 0 || cleared && !fed) {
      final target = cleared ? 1355.0 : stoneX - 102;
      helperX += (target - helperX).clamp(-dt * 80, dt * 80);
    }
    if (basketLoaded) basketLift = math.min(1, basketLift + dt * .9);
    helper = math.max(0, helper - dt * .12);
    shake = math.max(0, shake - dt);
    for (final a in apples) {
      if (a.stored || a.eaten || a.id == held) continue;
      if (a.vy > 0 || a.position.dy > -80 && a.position.dy < -18) {
        a.vy += dt * 230;
        a.position += Offset(math.sin(a.id + shake) * dt * 6, a.vy * dt);
        if (a.position.dy >= -18) {
          a.position = Offset(a.position.dx, -18);
          a.vy = 0;
        }
      }
    }
  }

  Map<String, dynamic> toJson() => {
    'stone': stoneX,
    'fed': fed,
    'loaded': basketLoaded,
    'apples': [
      for (final a in apples)
        {
          'x': a.position.dx,
          'y': a.position.dy,
          'stored': a.stored,
          'eaten': a.eaten,
        },
    ],
  };
  void restore(Map d) {
    stoneX = (d['stone'] as num? ?? 690).toDouble().clamp(690, 835);
    fed = d['fed'] == true;
    basketLoaded = d['loaded'] == true;
    push = 0;
    held = null;
    basketHeld = false;
    basketAt = basket;
    helperX = stoneX >= 825 ? 1355 : 590;
    basketLift = 1;
    final list = d['apples'];
    for (var i = 0; i < 4; i++) {
      final row = list is List && i < list.length && list[i] is Map
          ? list[i] as Map
          : <String, dynamic>{};
      apples[i]
        ..stored = row['stored'] == true
        ..eaten = row['eaten'] == true
        ..position = Offset(
          (row['x'] as num? ?? 1080 + i * 43).toDouble().clamp(980, 1430),
          (row['y'] as num? ?? -190).toDouble().clamp(-250, -18),
        )
        ..vy = 0;
    }
  }
}
