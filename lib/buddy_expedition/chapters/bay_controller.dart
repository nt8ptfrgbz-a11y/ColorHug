import 'dart:math' as math;
import 'package:flutter/painting.dart';

enum FerryPhase { offshore, docking, docked, boarded, sailing, arrived }

class BayController {
  Offset basket = const Offset(700, -25), target = const Offset(700, -25);
  bool holding = false, babyInBasket = false, rescued = false;
  double boarding = 0, boat = 0, voyage = 0, wave = 0;
  FerryPhase ferry = FerryPhase.offshore;
  static const perch = Offset(860, -170),
      landing = Offset(725, -25),
      rope = Offset(1450, -50);
  double get boatX => ferry == FerryPhase.sailing || ferry == FerryPhase.arrived
      ? 1650 + voyage * 350
      : 1900 - boat * 250;
  void grab() {
    holding = true;
    target = basket;
  }

  void move(Offset p) {
    if (holding) target = Offset(p.dx.clamp(600, 1000), p.dy.clamp(-240, -10));
  }

  bool drop() {
    holding = false;
    if (babyInBasket && (basket - landing).distance < 105) {
      rescued = true;
      babyInBasket = false;
      basket = landing;
      return true;
    }
    basket = landing;
    target = basket;
    return false;
  }

  void cancel() {
    holding = false;
    basket = landing;
    target = basket;
    babyInBasket = false;
    boarding = 0;
  }

  void callBoat() {
    if (ferry == FerryPhase.offshore) ferry = FerryPhase.docking;
  }

  bool embark(double carX) {
    if (ferry != FerryPhase.docked || carX < 1540) return false;
    ferry = FerryPhase.boarded;
    return true;
  }

  void sail() {
    if (ferry == FerryPhase.boarded && rescued) ferry = FerryPhase.sailing;
  }

  void step(double dt) {
    wave += dt;
    if (holding) {
      basket = Offset.lerp(basket, target, 1 - math.exp(-dt * 12))!;
      if (!rescued && !babyInBasket && (basket - perch).distance < 65) {
        boarding += dt;
        if (boarding > .7) babyInBasket = true;
      } else if (!babyInBasket) {
        boarding = 0;
      }
    }
    if (ferry == FerryPhase.docking) {
      boat = math.min(1, boat + dt * .3);
      if (boat == 1) ferry = FerryPhase.docked;
    }
    if (ferry == FerryPhase.sailing) {
      voyage = math.min(1, voyage + dt * .10);
      if (voyage == 1) ferry = FerryPhase.arrived;
    }
  }

  Map<String, dynamic> toJson() => {
    'rescued': rescued,
    'ferry': ferry.name,
    'voyage': voyage,
  };
  void restore(Map d) {
    rescued = d['rescued'] == true;
    ferry = FerryPhase.values.firstWhere(
      (f) => f.name == d['ferry'],
      orElse: () => FerryPhase.offshore,
    );
    if (ferry == FerryPhase.sailing) ferry = FerryPhase.boarded;
    if (ferry == FerryPhase.docking) ferry = FerryPhase.docked;
    boat = ferry == FerryPhase.offshore ? 0 : 1;
    voyage = ferry == FerryPhase.arrived ? 1 : 0;
    cancel();
  }
}
