import 'dart:collection';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../game_audio.dart';
import '../buddy_play_session.dart';

const worldColumns = 10, worldRows = 8;
const worldWords = ['leaf', 'bridge', 'house', 'cookie', 'flower', 'rest'];

class WorldObject {
  WorldObject(this.kind, this.cell);
  int kind, cell;
  int bites = 0;
  Map<String, dynamic> toJson() => {'kind': kind, 'cell': cell};
}

class TinyAnimal {
  TinyAnimal(this.cell, this.kind) : position = cellCenter(cell);
  int cell, kind;
  Offset position;
  List<int> path = [];
  int? target;
  double wait = 0, travel = 0;
  bool using = false, carrying = false;
  int visits = 0;
}

Offset cellCenter(int cell) =>
    Offset((cell % 10 + .5) / 10, (cell ~/ 10 + .5) / 8);
int worldCell(Offset p) =>
    (p.dy * 8).floor().clamp(0, 7) * 10 + (p.dx * 10).floor().clamp(0, 9);
List<int> cellNeighbors(int cell) => [
  if (cell % 10 > 0) cell - 1,
  if (cell % 10 < 9) cell + 1,
  if (cell >= 10) cell - 10,
  if (cell < 70) cell + 10,
];
List<int> worldPath(int start, int goal, bool Function(int) walkable) {
  if (start == goal) return [];
  final parents = <int, int>{start: -1};
  final queue = Queue<int>()..add(start);
  while (queue.isNotEmpty) {
    final at = queue.removeFirst();
    for (final n in cellNeighbors(at)) {
      if (parents.containsKey(n) || !walkable(n)) continue;
      parents[n] = at;
      if (n == goal) {
        final result = <int>[];
        var end = goal;
        while (end != start) {
          result.add(end);
          end = parents[end]!;
        }
        return result.reversed.toList();
      }
      queue.add(n);
    }
  }
  return [];
}

class TinyWorldModel extends ToyModel {
  TinyWorldModel() {
    preset(0);
  }
  int scene = 0, tool = 0;
  bool rain = false;
  List<int> ground = List.filled(80, 0);
  List<WorldObject> objects = [];
  List<TinyAnimal> animals = [];
  double clock = 0;
  int revision = 0;
  final Set<String> _discoveries = {};
  WorldObject? objectAt(int cell) {
    for (final item in objects) {
      if (item.cell == cell) return item;
    }
    return null;
  }

  bool walkable(int cell) => ground[cell] != 2 || objectAt(cell)?.kind == 1;
  bool occupied(int cell) => animals.any(
    (a) => a.cell == cell || a.path.isNotEmpty && a.path.first == cell,
  );
  void preset(int n) {
    scene = n;
    ground = List.filled(80, 0);
    for (var y = 0; y < 8; y++) {
      ground[y * 10 + (n == 2 ? 5 : 4)] = 2;
    }
    for (var x = 0; x < 10; x++) {
      if (ground[40 + x] != 2) ground[40 + x] = 1;
    }
    objects = [WorldObject(2, 21), WorldObject(3, 27), WorldObject(4, 66)];
    if (n == 1) objects.add(WorldObject(0, 61));
    if (n == 2) objects.add(WorldObject(5, 12));
    animals = [TinyAnimal(41, 0), TinyAnimal(51, 1), TinyAnimal(31, 2)];
    rain = n == 1;
  }

  void touch(int cell) {
    final old = objectAt(cell);
    if (tool == 0) {
      if (ground[cell] != 2) {
        ground[cell] = 1;
        event('road', '画一条小路，朋友走得更轻快', phrase: 'A little road!');
      }
    } else if (tool == 1) {
      if (occupied(cell) || old != null) {
        event('water', '朋友站在这里，换个空地挖池塘吧');
        return;
      }
      ground[cell] = 2;
      event('water', '压出一个小池塘', sound: GameSound.splash);
    } else if (tool == 8) {
      if (occupied(cell) && old?.kind == 1) {
        event('bridge', '朋友正在过桥，等一下再收起来');
        return;
      }
      objects.removeWhere((v) => v.cell == cell);
      if (ground[cell] == 2) ground[cell] = 0;
      event('home', '收好啦，还可以重新布置');
    } else {
      final kind = tool - 2;
      if (ground[cell] == 2 && kind != 1) {
        event('bridge', '这里有水，先放铅笔桥吧');
        return;
      }
      if (old != null && old.kind == kind) {
        if (kind == 3) {
          old.bites = 0;
          event('cookie', '饼干补好啦', sound: GameSound.tap);
        }
        return;
      }
      if (old != null && old.kind == 1 && occupied(cell)) {
        event('bridge', '等朋友走下桥再换');
        return;
      }
      if (old == null && objects.length >= 12) {
        event('house', '小家具满啦，先收一个再放');
        return;
      }
      objects.removeWhere((v) => v.cell == cell);
      objects.add(WorldObject(kind, cell));
      event(
        worldWords[kind],
        const ['叶子变雨棚', '铅笔变小桥', '茶杯变小家', '大家来吃饼干', '花朵真香', '软垫可以休息'][kind],
        sound: GameSound.tap,
      );
    }
    revision++;
    for (final a in animals) {
      if (a.path.any((c) => !walkable(c)) ||
          a.target != null && objectAt(a.target!) == null) {
        a.path.clear();
        a.target = null;
        a.using = false;
        a.travel = 0;
      }
    }
  }

  void moveObject(int from, int to) {
    final object = objectAt(from);
    if (object == null || from == to) return;
    if (objectAt(to) != null || (ground[to] == 2 && object.kind != 1)) {
      event('house', '这里放不下，试试旁边的空地吧');
      return;
    }
    if (object.kind == 1 && occupied(from)) {
      event('bridge', '等朋友走下桥再移动哦');
      return;
    }
    object.cell = to;
    for (final animal in animals) {
      if (animal.target == from || animal.path.any((c) => !walkable(c))) {
        animal.target = null;
        animal.path.clear();
        animal.using = false;
        animal.wait = 0;
        animal.travel = 0;
      }
    }
    revision++;
    event(worldWords[object.kind], '搬好啦，朋友会找新的路', sound: GameSound.tap);
  }

  void toggleRain() {
    rain = !rain;
    for (final a in animals) {
      a.wait = 0;
      a.target = null;
      a.path.clear();
      a.using = false;
    }
    event(
      'rain',
      rain ? '下雨啦，朋友会去找雨棚' : '雨停啦，出来玩吧',
      phrase: rain ? "It's raining!" : "Let's play!",
      sound: rain ? GameSound.splash : null,
    );
  }

  void choose(TinyAnimal a) {
    final options = objects
        .where((o) => o.kind != 1 && (o.kind != 3 || o.bites < 5))
        .toList();
    if (options.isEmpty) {
      a.wait = 1;
      return;
    }
    final shift = (a.kind + a.visits) % options.length;
    final rotated = [...options.skip(shift), ...options.take(shift)];
    options.setAll(0, rotated);
    if (a.carrying) {
      options.sort(
        (x, y) => (x.kind == 2 ? 0 : 1).compareTo(y.kind == 2 ? 0 : 1),
      );
    } else if (rain) {
      options.sort(
        (x, y) => (x.kind == 0 || x.kind == 2 ? 0 : 1).compareTo(
          y.kind == 0 || y.kind == 2 ? 0 : 1,
        ),
      );
    }
    for (final o in options) {
      final path = worldPath(a.cell, o.cell, walkable);
      if (path.isNotEmpty || o.cell == a.cell) {
        a.path = path;
        a.target = o.cell;
        a.travel = 0;
        if (path.isEmpty) arrive(a);
        return;
      }
    }
    a.wait = 2;
  }

  void arrive(TinyAnimal a) {
    final target = objectAt(a.target ?? -1);
    if (target == null) {
      a.target = null;
      return;
    }
    a.using = true;
    a.wait = rain && (target.kind == 0 || target.kind == 2) ? 5 : 2.4;
    a.visits++;
    if (target.kind == 3) {
      target.bites = math.min(5, target.bites + 1);
      a.carrying = true;
    } else if (target.kind == 2) {
      a.carrying = false;
    }
    final id = 'use-${target.kind}';
    event(
      worldWords[target.kind],
      const [
        '叶子下面不会淋湿',
        '小桥连通啦',
        '朋友搬进茶杯小屋',
        '拿一小块饼干带回家',
        '闻一闻小花',
        '躺在软垫休息',
      ][target.kind],
      phrase: target.kind == 2
          ? 'Thank you for the house!'
          : target.kind == 3
          ? 'A cookie! Thank you!'
          : null,
      sound: GameSound.discover,
      discovery: _discoveries.add(id) ? id : null,
    );
  }

  @override
  void step(double dt) {
    clock += dt;
    for (final a in animals) {
      if (a.wait > 0) {
        a.wait -= dt;
        if (a.wait <= 0) {
          a.using = false;
          a.target = null;
        }
        continue;
      }
      if (a.path.isEmpty) {
        choose(a);
        continue;
      }
      final next = a.path.first;
      if (!walkable(next)) {
        a.path.clear();
        a.target = null;
        continue;
      }
      a.travel += dt * (ground[next] == 1 ? 1.7 : 1.1);
      a.position = Offset.lerp(
        cellCenter(a.cell),
        cellCenter(next),
        a.travel.clamp(0.0, 1.0),
      )!;
      if (a.travel >= 1) {
        a.cell = next;
        a.position = cellCenter(next);
        a.path.removeAt(0);
        a.travel = 0;
        if (objectAt(next)?.kind == 1 && _discoveries.add('cross-bridge')) {
          event(
            'bridge',
            '朋友真的走过小桥啦',
            phrase: 'Cross the bridge!',
            discovery: 'cross-bridge',
          );
        }
        if (a.path.isEmpty) arrive(a);
      }
    }
  }

  @override
  Map<String, dynamic> toJson() => {
    'v': 1,
    'scene': scene,
    'rain': rain,
    'ground': ground,
    'objects': objects.map((v) => v.toJson()).toList(),
  };
  @override
  void restore(Map<String, dynamic> d) {
    scene = d['scene'];
    rain = d['rain'];
    ground = List<int>.from(d['ground']);
    objects = (d['objects'] as List)
        .map((o) => WorldObject(o['kind'], o['cell']))
        .toList();
    final safe = List.generate(80, (i) => i).where(walkable).toList();
    if (safe.isEmpty) {
      ground[41] = 0;
      safe.add(41);
    }
    animals = List.generate(
      3,
      (i) => TinyAnimal(safe[(i * 7) % safe.length], i),
    );
  }
}
