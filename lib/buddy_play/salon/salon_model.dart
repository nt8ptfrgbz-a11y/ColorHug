import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../game_audio.dart';
import '../buddy_play_session.dart';

class HairLook {
  HairLook(int guest)
    : lengths = List.generate(
        11,
        (i) =>
            .13 +
            (guest == 0
                ? .13
                : guest == 1
                ? (i % 2) * .10
                : .04 * i / 10),
      ),
      leans = List.generate(11, (i) => (i - 5) * .013);
  List<double> lengths, leans;
  int color = 0, decor = 0;
  Map<String, dynamic> toJson() => {
    'lengths': lengths,
    'leans': leans,
    'color': color,
    'decor': decor,
  };
  void restore(Map d) {
    lengths = (d['lengths'] as List).map((v) => (v as num).toDouble()).toList();
    leans = (d['leans'] as List).map((v) => (v as num).toDouble()).toList();
    color = d['color'];
    decor = d['decor'];
  }
}

class SalonModel extends ToyModel {
  int guest = 0, tool = 0;
  final List<HairLook> looks = List.generate(3, HairLook.new);
  HairLook get look => looks[guest];
  double clock = 0, joy = 0, wind = 0;
  bool mirror = false;
  Offset? finger;
  final List<({Offset at, double age, int color})> clippings = [];
  Offset root(int i) =>
      Offset(.28 + i * .044, .42 + math.pow((i - 5) / 5, 2) * .08);
  Offset tip(int i) =>
      root(i) +
      Offset(
        look.leans[i] + math.sin(clock * 6 + i) * wind * .015,
        -look.lengths[i],
      );
  void touch(Offset p, {Offset? previous}) {
    final count = previous == null
        ? 1
        : ((p - previous).distance / .035).ceil().clamp(1, 30);
    for (var i = 1; i <= count; i++) {
      _touchAt(
        previous == null ? p : Offset.lerp(previous, p, i / count)!,
        previous: previous,
      );
    }
    finger = p;
  }

  void _touchAt(Offset p, {Offset? previous}) {
    finger = p;
    mirror = false;
    var changed = false;
    for (var i = 0; i < 11; i++) {
      final a = root(i), b = tip(i);
      final ab = b - a;
      final t = (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / ab.distanceSquared)
          .clamp(0.0, 1.0);
      final nearest = a + ab * t;
      if ((p - nearest).distance > .085) continue;
      if (tool == 0) {
        final length = (a.dy - p.dy).clamp(.06, .35).toDouble();
        if (length < look.lengths[i] - .008) {
          clippings.add((at: b, age: 0, color: look.color));
          look.lengths[i] = length;
          changed = true;
        }
      } else if (tool == 1) {
        look.leans[i] = ((p.dx - a.dx) * .85).clamp(-.2, .2);
        changed = true;
      } else if (tool == 2) {
        wind = 1;
        look.leans[i] =
            (look.leans[i] +
                    (previous == null ? .03 : (p.dx - previous.dx) * 2))
                .clamp(-.2, .2);
        changed = true;
      } else {
        look.lengths[i] = (look.lengths[i] + .045).clamp(.06, .35);
        changed = true;
      }
    }
    if (clippings.length > 30) clippings.removeRange(0, clippings.length - 30);
    if (changed) {
      joy = 1;
      event(
        const ['cut', 'comb', 'blow', 'long'][tool],
        const ['剪到哪里，哪里变短', '梳出喜欢的方向', '头发飘起来啦', '泡泡让头发长回来'][tool],
        phrase: const [
          "Let's cut!",
          "Comb your hair!",
          "Blow, blow!",
          "Long hair!",
        ][tool],
        sound: tool == 0
            ? GameSound.snip
            : tool == 3
            ? GameSound.squish
            : null,
        discovery: 'tool-$tool',
      );
    }
  }

  void finish() {
    mirror = true;
    joy = 2;
    event(
      'hair',
      '照照镜子，真有趣！',
      phrase: 'I love my hair!',
      sound: GameSound.complete,
      discovery: 'guest-$guest',
    );
  }

  void next() {
    guest = (guest + 1) % 3;
    mirror = false;
    finger = null;
    event('hair', '欢迎新朋友！', phrase: 'Hello!');
  }

  void decorate() {
    look.decor = (look.decor + 1) % 4;
    event(
      look.decor == 3
          ? 'bird'
          : look.decor == 1
          ? 'bow'
          : 'hair',
      look.decor == 3 ? '小鸟在头上睡觉啦' : '戴上一个小装饰',
      sound: GameSound.discover,
    );
  }

  @override
  void step(double dt) {
    clock += dt;
    joy = math.max(0, joy - dt);
    wind = math.max(0, wind - dt);
    for (var i = clippings.length - 1; i >= 0; i--) {
      final v = clippings[i];
      if (v.age > 1.5) {
        clippings.removeAt(i);
      } else {
        clippings[i] = (
          at: v.at + Offset(math.sin(i.toDouble()) * dt * .06, dt * .22),
          age: v.age + dt,
          color: v.color,
        );
      }
    }
  }

  @override
  void pause() {
    finger = null;
    wind = 0;
  }

  @override
  Map<String, dynamic> toJson() => {
    'v': 1,
    'guest': guest,
    'looks': looks.map((v) => v.toJson()).toList(),
  };
  @override
  void restore(Map<String, dynamic> d) {
    guest = d['guest'];
    for (var i = 0; i < 3; i++) {
      looks[i].restore(d['looks'][i]);
    }
    finger = null;
    mirror = false;
    clippings.clear();
  }
}
