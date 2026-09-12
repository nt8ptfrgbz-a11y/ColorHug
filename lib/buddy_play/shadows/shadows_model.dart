import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../game_audio.dart';
import '../buddy_play_session.dart';

class ShadowToy {
  ShadowToy(this.kind, this.at, {this.hat = 0});
  int kind, hat;
  Offset at;
  Map<String, dynamic> toJson() => {
    'kind': kind,
    'at': [at.dx, at.dy],
    'hat': hat,
  };
}

class ShadowProjection {
  const ShadowProjection(this.x, this.scale);
  final double x, scale;
}

ShadowProjection projectShadow(Offset light, Offset toy) {
  final separation = (light.dy - toy.dy).clamp(.13, .8);
  final scale = ((light.dy - .12) / separation).clamp(1.0, 3.4).toDouble();
  final x = (light.dx + (toy.dx - light.dx) * scale).clamp(.1, .9).toDouble();
  return ShadowProjection(x, scale);
}

class ShadowsModel extends ToyModel {
  int scene = 0, selected = 0;
  Offset light = const Offset(.5, .96);
  List<ShadowToy> toys = [
    ShadowToy(0, const Offset(.4, .64)),
    ShadowToy(1, const Offset(.65, .61)),
  ];
  bool reveal = false;
  int? held;
  bool lampHeld = false;
  double clock = 0, revealTime = 0;
  void select(int index) {
    selected = index;
    event(
      index == 0 ? 'rabbit' : 'shadow',
      const ['兔子玩具', '小熊玩具', '香蕉玩具', '大帽子'][index],
      sound: GameSound.tap,
    );
  }

  void add() {
    if (toys.length >= 4) return;
    toys.add(ShadowToy(selected, Offset(.25 + toys.length * .12, .65)));
    event('shadow', '多一个玩具，多一个影子');
  }

  void down(Offset p) {
    lampHeld = (p - light).distance < .17 || p.dy > .83;
    held = null;
    if (!lampHeld) {
      var d = .16;
      for (var i = toys.length - 1; i >= 0; i--) {
        final n = (p - toys[i].at).distance;
        if (n < d) {
          d = n;
          held = i;
        }
      }
    }
    move(p);
  }

  void move(Offset p) {
    if (lampHeld) {
      light = Offset(p.dx.clamp(.12, .88), p.dy.clamp(.82, .99));
    } else if (held != null) {
      toys[held!].at = Offset(p.dx.clamp(.18, .82), p.dy.clamp(.53, .77));
    }
  }

  void up() {
    if (lampHeld) {
      event(
        'light',
        '光移动了，影子也跟着变',
        phrase: 'Move the light!',
        discovery: 'light',
      );
    }
    if (held != null) {
      final t = toys[held!];
      final shadow = projectShadow(light, t.at);
      event(
        shadow.scale > 2.7 ? 'big' : 'small',
        shadow.scale > 2.7 ? '靠近灯光，影子变大' : '远离灯光，影子变小',
        phrase: shadow.scale > 2.7 ? 'A big shadow!' : 'A small shadow!',
        discovery: shadow.scale > 2.7 ? 'big' : 'small',
      );
    }
    held = null;
    lampHeld = false;
  }

  void hat() {
    if (toys.isEmpty) return;
    toys.last.hat = (toys.last.hat + 1) % 3;
    event('shadow', '玩具戴帽子，影子也戴帽子', discovery: 'hat');
  }

  void peek() {
    reveal = !reveal;
    revealTime = 2;
    event(
      'shadow',
      reveal ? '原来是这些玩具！' : '关掉小灯，再看影子',
      phrase: reveal ? 'Hello, little toys!' : 'Look at the shadow!',
      sound: GameSound.discover,
      discovery: 'reveal',
    );
  }

  void preset() {
    scene = (scene + 1) % 3;
    toys = switch (scene) {
      0 => [
        ShadowToy(0, const Offset(.4, .64)),
        ShadowToy(1, const Offset(.65, .61)),
      ],
      1 => [
        ShadowToy(1, const Offset(.5, .66)),
        ShadowToy(2, const Offset(.5, .61)),
      ],
      _ => [
        ShadowToy(0, const Offset(.42, .7), hat: 1),
        ShadowToy(3, const Offset(.7, .55)),
      ],
    };
    light = const Offset(.5, .96);
    reveal = false;
  }

  @override
  void step(double dt) {
    clock += dt;
    revealTime = math.max(0, revealTime - dt);
    for (final toy in toys) {
      final projection = projectShadow(light, toy.at);
      if (toy.kind == 0 &&
          (projection.x - .73).abs() < .07 &&
          projection.scale > 2.7) {
        event(
          'moon',
          '兔耳朵碰到月亮啦！',
          phrase: 'Hello, moon!',
          sound: GameSound.bell,
          discovery: 'moon-$scene',
        );
        break;
      }
    }
  }

  final Set<String> _once = {};
  @override
  void event(
    String word,
    String meaning, {
    String? phrase,
    GameSound? sound,
    String? discovery,
  }) {
    if (discovery?.startsWith('moon-') == true && !_once.add(discovery!)) {
      return;
    }
    super.event(
      word,
      meaning,
      phrase: phrase,
      sound: sound,
      discovery: discovery,
    );
  }

  @override
  void pause() {
    held = null;
    lampHeld = false;
  }

  @override
  Map<String, dynamic> toJson() => {
    'v': 1,
    'scene': scene,
    'light': [light.dx, light.dy],
    'toys': toys.map((v) => v.toJson()).toList(),
  };
  @override
  void restore(Map<String, dynamic> d) {
    scene = d['scene'];
    light = Offset(
      (d['light'][0] as num).toDouble(),
      (d['light'][1] as num).toDouble(),
    );
    toys = (d['toys'] as List)
        .map(
          (v) => ShadowToy(
            v['kind'],
            Offset(
              (v['at'][0] as num).toDouble(),
              (v['at'][1] as num).toDouble(),
            ),
            hat: v['hat'],
          ),
        )
        .toList();
    reveal = false;
    pause();
  }
}
