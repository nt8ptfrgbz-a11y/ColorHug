import 'dart:math' as math;
import 'package:flutter/painting.dart';

class CaveController {
  Offset light = const Offset(920, -110);
  double revealed = 0, door = 0, lever = 0, glow = 0;
  bool opened = false, lamp = false;
  static const carving = Offset(920, -115),
      switchAt = Offset(1125, -70),
      lantern = Offset(1230, -55);
  bool illuminated(Offset point, Offset source) {
    final direction = light - source, relative = point - source;
    if (direction.distance < 1 || relative.distance > 650) return false;
    final along =
        (direction.dx * relative.dx + direction.dy * relative.dy) /
        direction.distance;
    final across =
        (direction.dx * relative.dy - direction.dy * relative.dx).abs() /
        direction.distance;
    return along > 0 && across < 65 + along * .18;
  }

  void aim(Offset p) {
    light = Offset(p.dx.clamp(380, 1350), p.dy.clamp(-300, 20));
  }

  void pull(double amount) {
    if (revealed < .7) return;
    lever = amount.clamp(0, 1);
    if (lever > .75) opened = true;
  }

  void step(double dt, Offset source) {
    if (illuminated(carving, source)) {
      revealed = math.min(1, revealed + dt * .65);
    }
    glow = math.max(0, glow - dt);
    if (opened) door = math.min(1, door + dt * .7);
  }

  bool collect() {
    if (door < .95) return false;
    lamp = true;
    glow = 2;
    return true;
  }

  Map<String, dynamic> toJson() => {
    'light': [light.dx, light.dy],
    'revealed': revealed,
    'open': opened,
    'lamp': lamp,
  };
  void restore(Map d) {
    final l = d['light'];
    light = l is List && l.length == 2
        ? Offset((l[0] as num).toDouble(), (l[1] as num).toDouble())
        : const Offset(920, -110);
    revealed = (d['revealed'] as num? ?? 0).toDouble().clamp(0, 1);
    opened = d['open'] == true;
    lamp = d['lamp'] == true;
    if (lamp) opened = true;
    door = opened ? 1 : 0;
    lever = opened ? 1 : 0;
  }
}
