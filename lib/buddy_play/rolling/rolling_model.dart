import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../game_audio.dart';
import '../buddy_play_session.dart';

class RollingBall {
  RollingBall(this.parts, this.style, this.scene, this.right);
  final List<int> parts;
  final int style, scene;
  bool right, big = false, duck = false, stuck = false, rescued = false;
  int segment = 0;
  double t = 0;
  int lastPart = -1;
  bool get finished => segment >= 4;
  Offset get position {
    final points = rollingPoints(scene, right);
    final i = segment.clamp(0, 3);
    final a = points[i], b = points[i + 1];
    var point = Offset.lerp(a, b, t)!;
    if (i > 0 && parts[i - 1] == 0) {
      point -= Offset(0, math.sin(t * math.pi) * .12);
    }
    return point;
  }
}

List<Offset> rollingPoints(int scene, bool right) {
  final base = [
    const Offset(.14, .12),
    const Offset(.79, .29),
    const Offset(.22, .49),
    const Offset(.77, .69),
    Offset(right ? .81 : .26, .91),
  ];
  if (scene == 1) return base.map((p) => Offset(1 - p.dx, p.dy)).toList();
  if (scene == 2) {
    return [
      const Offset(.5, .1),
      const Offset(.2, .29),
      const Offset(.8, .49),
      const Offset(.24, .69),
      Offset(right ? .8 : .22, .91),
    ];
  }
  return base;
}

class RollingModel extends ToyModel {
  List<int> parts = [0, 4, 3];
  int scene = 0, ballStyle = 0, landed = 0;
  bool right = true, paused = false;
  final List<RollingBall> balls = [];
  double clock = 0;
  void launch() {
    if (balls.length >= 5) return;
    balls.add(RollingBall(List.of(parts), ballStyle, scene, right));
    event('roll', '小球出发啦', phrase: 'Roll the ball!', sound: GameSound.bounce);
    paused = false;
  }

  void setPart(int slot, int part) {
    parts[slot] = part;
    event(
      part == 1
          ? 'big'
          : part == 0
          ? 'up'
          : 'ball',
      const ['弹起来！', '变大山洞', '小鸭山洞', '左右岔路', '叮当铃铛'][part],
    );
  }

  void rescue() {
    for (final b in balls) {
      if (b.stuck) {
        b.stuck = false;
        b.rescued = true;
        event(
          'go',
          '啊嚏！小球出来啦！',
          phrase: 'Here we go!',
          sound: GameSound.squish,
          discovery: 'sneeze',
        );
      }
    }
  }

  void preset(int value) {
    scene = value;
    parts = const [
      [0, 4, 3],
      [1, 2, 4],
      [2, 0, 3],
    ][value].toList();
    balls.clear();
    paused = false;
  }

  @override
  void step(double dt) {
    if (paused) return;
    clock += dt;
    for (final b in balls) {
      if (b.stuck || b.finished) continue;
      b.t += dt / (scene == 2 ? 1.05 : 1.35);
      if (b.segment == 3 && b.big && !b.rescued && b.t >= .4) {
        b.t = .4;
        b.stuck = true;
        event('stop', '大球卡住啦，点点管道打喷嚏', phrase: 'Stop! A big ball!');
        continue;
      }
      if (b.t >= 1) {
        b.t -= 1;
        if (b.segment < 3) {
          final part = b.parts[b.segment];
          b.lastPart = part;
          if (part == 1) {
            b.big = true;
            event(
              'big',
              '小球变大了',
              phrase: 'A big ball!',
              sound: GameSound.squish,
              discovery: 'big',
            );
          }
          if (part == 2) {
            b.duck = true;
            event('duck', '嘎嘎！鸭子球！', sound: GameSound.frog, discovery: 'duck');
          }
          if (part == 0) {
            event(
              'up',
              '跳床把球弹起来',
              phrase: 'Up we go!',
              sound: GameSound.bounce,
              discovery: 'bounce',
            );
          }
          if (part == 3) {
            b.right = right;
            event(
              'down',
              '换一条路滚下去',
              sound: GameSound.tap,
              discovery: right ? 'right' : 'left',
            );
          }
          if (part == 4) {
            event(
              'bell',
              '叮！经过小铃铛',
              phrase: 'Ring the bell!',
              sound: GameSound.bell,
              discovery: 'bell',
            );
          }
        }
        b.segment++;
        if (b.finished) {
          landed++;
          event(
            'down',
            '小球到家啦！再改一个机关试试',
            phrase: 'Down we go!',
            sound: GameSound.correct,
            discovery: 'basket-${b.scene}',
          );
        }
      }
    }
    balls.removeWhere((b) => b.finished);
  }

  @override
  void pause() {
    paused = true;
  }

  @override
  Map<String, dynamic> toJson() => {
    'v': 1,
    'parts': parts,
    'scene': scene,
    'ball': ballStyle,
    'right': right,
  };
  @override
  void restore(Map<String, dynamic> d) {
    parts = List<int>.from(d['parts']);
    scene = d['scene'];
    ballStyle = d['ball'];
    right = d['right'];
    balls.clear();
    paused = false;
  }
}
