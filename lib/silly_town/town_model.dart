import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'town_catalog.dart';

class TownLayout {
  TownLayout(this.size);
  final Size size;
  double get scale => math.min(size.width / 720, size.height / 580);
  double get radius => math.min(size.width * .225, size.height * .245);
  Offset get actor => Offset(size.width * .5, size.height * .43);
  Offset slot(int i) => Offset(size.width * (.22 + i * .28), size.height * .83);
  Offset mark(int i) =>
      actor +
      Offset(
        math.cos(i * math.pi / 3) * radius * .65,
        math.sin(i * math.pi / 3) * radius * .65,
      );
  Offset toy(int i, double time, {bool reduce = false}) => Offset(
    size.width * (.2 + (i % 3) * .3) +
        (reduce ? 0 : math.sin(time * .9 + i * 2) * size.width * .035),
    size.height * (.3 + (i ~/ 3) * .27) +
        (reduce ? 0 : math.cos(time * 1.2 + i) * 8),
  );
  double get hitRadius => math.max(29, math.min(size.width * .085, 52));
}

class TownParticle {
  TownParticle(
    this.at,
    this.velocity,
    this.color,
    this.kind,
    this.life,
    this.size,
  );
  Offset at, velocity;
  final Color color;
  final int kind;
  double life;
  final double size;
}

class TownEvent {
  const TownEvent(this.sound, {this.wordIndex, this.finish = false});
  final String sound;
  final int? wordIndex;
  final bool finish;
}

/// Gameplay is independent from rendering and audio. Coordinates use the same
/// TownLayout as the painter, including generous touch targets on small phones.
class TownModel extends ChangeNotifier {
  TownModel(this.level);
  final TownLevel level;
  double time = 0, reaction = 0, progress = 0, idle = 0;
  double? finishedAt;
  double _lastAction = -10, _lastMove = -10;
  int actionCount = 0, lastVariant = 0, toyCycle = 0;
  int? selected, _pointer;
  Offset? dragging, gaze, _lastPoint;
  Offset? deliveryStart;
  double deliveredAt = -10;
  int deliveredItem = 0;
  bool pressing = false, paused = false, reduceMotion = false;
  bool get finished => finishedAt != null;
  double get finale => finishedAt == null ? 0 : time - finishedAt!;
  bool get showNext => finished && finale > 3.6;
  final Set<int> used = {}, cleaned = {};
  final List<TownParticle> particles = [];
  final List<TownEvent> _events = [];
  final math.Random _random = math.Random(41);
  List<TownEvent> takeEvents() {
    final result = List<TownEvent>.of(_events);
    _events.clear();
    return result;
  }

  bool get usesProps => switch (level.play) {
    TownPlay.deliver ||
    TownPlay.feed ||
    TownPlay.decorate ||
    TownPlay.grow ||
    TownPlay.tuck => true,
    _ => false,
  };
  void step(double dt, TownLayout layout) {
    if (paused) return;
    dt = dt.clamp(0, .05);
    time += dt;
    idle += dt;
    reaction = math.max(0, reaction - dt * 1.65);
    if (pressing &&
        level.play == TownPlay.inflate &&
        !finished &&
        time - _lastAction > .43) {
      _advance(layout.actor, layout);
    }
    for (final p in particles) {
      p.life -= dt;
      p.at += p.velocity * dt;
      p.velocity += Offset(0, p.kind == 1 ? -10 : 55) * dt;
    }
    particles.removeWhere((p) => p.life <= 0);
    notifyListeners();
  }

  void down(Offset point, TownLayout layout, int pointer) {
    if (paused || _pointer != null) return;
    _pointer = pointer;
    _lastPoint = point;
    gaze = point;
    idle = 0;
    if (usesProps && !finished) {
      for (var i = 0; i < 3; i++) {
        if (!used.contains(i) &&
            (point - layout.slot(i)).distance < layout.hitRadius * 1.3) {
          selected = i;
          dragging = point;
          reaction = .3;
          _events.add(TownEvent('pick', wordIndex: i));
          notifyListeners();
          return;
        }
      }
      if (selected != null && _onActor(point, layout)) _deliver(layout);
    } else if (level.play == TownPlay.catchToy && !finished) {
      for (var i = 0; i < 6; i++) {
        if (!used.contains(i) &&
            (point - layout.toy(i, time, reduce: reduceMotion)).distance <
                layout.hitRadius * 1.3) {
          used.add(i);
          _advance(point, layout, force: true);
          break;
        }
      }
    } else if (level.play == TownPlay.scrub && !finished) {
      _scrub(point, layout);
    } else if (level.play == TownPlay.music) {
      for (var i = 0; i < 3; i++) {
        if ((point - layout.slot(i)).distance < layout.hitRadius * 1.5) {
          lastVariant = i;
          _advance(point, layout, variant: i);
          notifyListeners();
          return;
        }
      }
      if (_onActor(point, layout)) _advance(point, layout);
    } else if (_onActor(point, layout)) {
      pressing = true;
      _advance(point, layout);
    } else {
      // Background touches are little discoveries, never wrong answers.
      burst(point, layout, kind: 1, count: 5);
      if (time - _lastAction > .2) {
        _events.add(const TownEvent('chime'));
        _lastAction = time;
      }
    }
    notifyListeners();
  }

  void move(Offset point, TownLayout layout, int pointer) {
    if (paused || pointer != _pointer) return;
    gaze = point;
    idle = 0;
    if (selected != null && !finished) dragging = point;
    if (level.play == TownPlay.scrub && !finished) _scrub(point, layout);
    if ((level.play == TownPlay.tickle || level.play == TownPlay.stretch) &&
        _onActor(point, layout, generous: true) &&
        time - _lastMove > .16 &&
        (point - (_lastPoint ?? point)).distance > 8) {
      _advance(point, layout);
      _lastMove = time;
      _lastPoint = point;
    }
    if (level.play == TownPlay.inflate &&
        !_onActor(point, layout, generous: true)) {
      pressing = false;
    }
    notifyListeners();
  }

  void up(Offset point, TownLayout layout, int pointer) {
    if (pointer != _pointer) return;
    if (selected != null &&
        dragging != null &&
        _onActor(point, layout, generous: true)) {
      _deliver(layout);
    }
    dragging = null;
    pressing = false;
    _pointer = null;
    notifyListeners();
  }

  void cancel() {
    _pointer = null;
    dragging = null;
    pressing = false;
    _lastPoint = null;
    notifyListeners();
  }

  bool _onActor(Offset p, TownLayout l, {bool generous = false}) =>
      (p - l.actor).distance < l.radius * (generous ? 1.85 : 1.5);
  void _deliver(TownLayout layout) {
    final item = selected;
    if (item == null || used.contains(item)) return;
    deliveryStart = dragging ?? layout.slot(item);
    deliveredAt = time;
    deliveredItem = item;
    used.add(item);
    lastVariant = item;
    _advance(layout.actor, layout, variant: item, force: true);
    selected = null;
    dragging = null;
  }

  void _scrub(Offset point, TownLayout layout) {
    for (var i = 0; i < 6; i++) {
      if (!cleaned.contains(i) &&
          (point - layout.mark(i)).distance < layout.hitRadius * 1.1) {
        cleaned.add(i);
        _advance(layout.mark(i), layout, force: true);
      }
    }
  }

  void _advance(
    Offset point,
    TownLayout layout, {
    int? variant,
    bool force = false,
  }) {
    if (!force && time - _lastAction < .16) return;
    _lastAction = time;
    reaction = 1;
    if (!finished) actionCount++;
    lastVariant = finished
        ? (lastVariant + 1) % 3
        : variant ??
              ((actionCount - 1) ~/ math.max(1, level.goal ~/ 3)).clamp(0, 2);
    if (!finished && level.play == TownPlay.inflate) {
      lastVariant = actionCount >= level.goal
          ? 2
          : actionCount >= 3
          ? 1
          : 0;
    }
    progress = (actionCount / level.goal).clamp(0, 1);
    final sound = switch (level.play) {
      TownPlay.tickle => 'giggle',
      TownPlay.feed => ['crunch', 'slurp', 'giggle'][lastVariant],
      TownPlay.scrub || TownPlay.grow => 'splash',
      TownPlay.inflate => 'bubble',
      TownPlay.music => ['marimba', 'bell', 'pluck'][lastVariant],
      TownPlay.drive || TownPlay.deliver => 'boing',
      TownPlay.tuck => 'chime',
      TownPlay.stretch => 'slurp',
      _ => 'pop',
    };
    _events.add(TownEvent(sound, wordIndex: finished ? null : lastVariant));
    burst(
      point,
      layout,
      kind: level.district == 2 ? 1 : 0,
      count: reduceMotion ? 3 : 10,
    );
    if (actionCount >= level.goal && !finished) {
      finishedAt = time;
      pressing = false;
      burst(layout.actor, layout, count: reduceMotion ? 6 : 36, kind: 2);
      _events.add(const TownEvent('celebrate', finish: true));
    }
  }

  void burst(Offset p, TownLayout l, {int count = 10, int kind = 0}) {
    final palette = [
      level.area.color,
      const Color(0xFFED937C),
      const Color(0xFF8FBEAA),
      const Color(0xFFF4CC60),
      const Color(0xFFB6A2D0),
    ];
    for (var i = 0; i < count && particles.length < 90; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = (35 + _random.nextDouble() * 120) * math.max(.6, l.scale);
      particles.add(
        TownParticle(
          p,
          Offset(math.cos(angle) * speed, math.sin(angle) * speed - 30),
          palette[i % palette.length],
          kind,
          .7 + _random.nextDouble() * 1.2,
          3 + _random.nextDouble() * 6,
        ),
      );
    }
  }
}
