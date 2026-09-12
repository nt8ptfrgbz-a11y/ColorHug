import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../game_audio.dart';
import '../buddy_play_session.dart';

class SquishyModel extends ToyModel {
  int color = 0, mood = 0, tool = 0;
  List<Offset> face = [
    const Offset(.42, .49),
    const Offset(.58, .49),
    const Offset(.5, .61),
  ];
  final List<Offset> rest = List.generate(20, (i) {
    final a = i * 2 * math.pi / 20;
    return Offset(.5 + math.cos(a) * .28, .54 + math.sin(a) * .31);
  });
  late List<Offset> points = List.of(rest);
  List<Offset> velocity = List.filled(20, Offset.zero);
  int? held, faceHeld;
  Offset? finger;
  double clock = 0, laugh = 0, jump = 0;
  void down(Offset p) {
    finger = p;
    if (tool == 4) {
      var distance = .1;
      for (var i = 0; i < face.length; i++) {
        final d = (face[i] - p).distance;
        if (d < distance) {
          distance = d;
          faceHeld = i;
        }
      }
      return;
    }
    if (tool == 1) {
      laugh = 2;
      mood = 0;
      event(
        'happy',
        '羽毛挠痒痒，咯咯笑',
        phrase: "I'm happy!",
        sound: GameSound.squish,
        discovery: 'tickle',
      );
      return;
    }
    if (tool == 2) {
      for (var i = 0; i < 20; i++) {
        velocity[i] += Offset(.5, -.05);
      }
      event(
        'soft',
        '软软的小怪被吹歪啦',
        phrase: 'So soft!',
        sound: GameSound.squish,
        discovery: 'fan',
      );
      return;
    }
    if (tool == 3) {
      jump = 1.7;
      for (var i = 0; i < 20; i++) {
        velocity[i] += const Offset(0, -.5);
      }
      event(
        'bounce',
        '弹簧垫，跳起来！',
        phrase: 'Bounce, bounce!',
        sound: GameSound.bounce,
        discovery: 'bounce',
      );
      return;
    }
    var distance = 2.0;
    for (var i = 0; i < 20; i++) {
      final d = (points[i] - p).distance;
      if (d < distance) {
        distance = d;
        held = i;
      }
    }
    if ((p - const Offset(.5, .54)).distance < .15) {
      for (var i = 0; i < 20; i++) {
        points[i] = Offset(
          .5 + (points[i].dx - .5) * 1.1,
          .54 + (points[i].dy - .54) * .72,
        );
      }
      event(
        'squeeze',
        '肚子压扁扁！',
        phrase: 'Squeeze!',
        sound: GameSound.squish,
        discovery: 'squeeze',
      );
    } else {
      event(
        'stretch',
        '轻轻拉，再放开',
        phrase: 'Stretch!',
        sound: GameSound.squish,
        discovery: 'stretch',
      );
    }
  }

  void move(Offset p) {
    finger = p;
    if (faceHeld != null) {
      face[faceHeld!] = Offset(p.dx.clamp(.32, .68), p.dy.clamp(.32, .68));
      return;
    }
    if (held == null || tool != 0) return;
    final safe = Offset(p.dx.clamp(.08, .92), p.dy.clamp(.1, .9));
    points[held!] = safe;
    velocity[held!] = Offset.zero;
    for (final offset in [-2, -1, 1, 2]) {
      final index = (held! + offset + 20) % 20;
      final blend = offset.abs() == 1 ? .3 : .1;
      points[index] = Offset.lerp(
        points[index],
        rest[index] + (safe - rest[held!]) * .7,
        blend,
      )!;
    }
  }

  void release() {
    if (faceHeld != null) {
      event(
        faceHeld == 2 ? 'mouth' : 'eyes',
        faceHeld == 2 ? '嘴巴摆好啦' : '眼睛摆好啦',
      );
    }
    held = null;
    faceHeld = null;
    finger = null;
  }

  void stamp() {
    mood = (mood + 1) % 3;
    event(
      mood == 1 ? 'sleepy' : 'happy',
      const ['笑脸印章', '困困印章', '惊喜印章'][mood],
      phrase: mood == 1 ? "I'm sleepy!" : "I'm happy!",
      sound: GameSound.tap,
    );
  }

  @override
  void step(double dt) {
    clock += dt;
    laugh = math.max(0, laugh - dt);
    jump = math.max(0, jump - dt);
    for (var i = 0; i < 20; i++) {
      if (i == held) continue;
      final neighbor =
          (points[(i + 19) % 20] -
              rest[(i + 19) % 20] +
              points[(i + 1) % 20] -
              rest[(i + 1) % 20]) *
          .5;
      final force = (rest[i] - points[i]) * 26 + neighbor * 3 - velocity[i] * 8;
      velocity[i] += force * dt;
      points[i] += velocity[i] * dt;
      points[i] = Offset(
        points[i].dx.clamp(.06, .94),
        points[i].dy.clamp(.08, .93),
      );
    }
  }

  @override
  void pause() => release();
  @override
  Map<String, dynamic> toJson() => {
    'v': 1,
    'color': color,
    'mood': mood,
    'face': face.map((p) => [p.dx, p.dy]).toList(),
  };
  @override
  void restore(Map<String, dynamic> d) {
    color = d['color'];
    mood = d['mood'];
    face = (d['face'] as List)
        .map((p) => Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()))
        .toList();
    points = List.of(rest);
    velocity = List.filled(20, Offset.zero);
    release();
  }
}
