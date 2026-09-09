import 'package:flutter/material.dart';

enum BuddyAdventure { weather, dinosaur, building, silly, theater, fireworks }

const adventureWords = <BuddyAdventure, List<String>>{
  BuddyAdventure.weather: ['sun', 'rain', 'wind'],
  BuddyAdventure.dinosaur: ['egg', 'baby', 'eat', 'jump'],
  BuddyAdventure.building: ['build', 'bridge', 'up', 'down'],
  BuddyAdventure.silly: [
    'shoes',
    'hat',
    'umbrella',
    'toothbrush',
    'blanket',
    'cup',
  ],
  BuddyAdventure.theater: ['jump', 'run', 'sleep', 'dance'],
  BuddyAdventure.fireworks: ['star', 'heart', 'flower'],
};

// Four columns and three rows. A creature can cross connected neighboring
// blocks, climbing at most one row at each step.
List<int> jellyBridgePath(List<int> cells) {
  if (cells.length != 12) return const [];
  List<int>? visit(int column, int row, List<int> path) {
    final index = row * 4 + column;
    if (cells[index] == 0) return null;
    final next = [...path, index];
    if (column == 3) return next;
    for (final r in [row, row - 1, row + 1]) {
      if (r < 0 || r >= 3) continue;
      final result = visit(column + 1, r, next);
      if (result != null) return result;
    }
    return null;
  }

  for (var row = 2; row >= 0; row--) {
    final result = visit(0, row, []);
    if (result != null) return result;
  }
  return const [];
}

@immutable
class SillyMission {
  const SillyMission(
    this.word,
    this.item,
    this.guide,
    this.target,
    this.choices,
    this.before,
  );
  final String word, item, guide, before;
  final int target;
  final List<String> choices;
}

const sillyMissions = [
  SillyMission('shoes', '👟', '抱抱把鞋戴到了耳朵上！帮它把鞋放到脚边。', 2, [
    '👟',
    '🍌',
    '🧢',
  ], '👟'),
  SillyMission('hat', '🧢', '出门玩啦！给抱抱的头顶戴一顶帽子。', 0, ['🥤', '🧢', '🧦'], '🧦'),
  SillyMission('umbrella', '☂️', '下雨啦！把小伞放到抱抱手里。', 1, ['🍦', '👟', '☂️'], '🍦'),
  SillyMission('toothbrush', '🪥', '起床啦！拿起牙刷，帮抱抱刷刷牙。', 3, [
    '🪥',
    '🍌',
    '🌷',
  ], '🍌'),
  SillyMission('blanket', '🛏️', '抱抱要睡觉了！给它的肚子盖上小被子。', 4, [
    '☂️',
    '🛏️',
    '🧢',
  ], '🍃'),
  SillyMission('cup', '🥤', '抱抱口渴啦！把小水杯送到它嘴边。', 3, ['🧦', '🌷', '🥤'], '🌷'),
];

const sillyTargets = [
  Offset(.5, .15),
  Offset(.82, .52),
  Offset(.5, .86),
  Offset(.5, .46),
  Offset(.5, .69),
];
const theaterAnimals = ['🦆', '🐻', '🐰', '🐸'];
const theaterActions = ['jump', 'run', 'sleep', 'dance'];
const theaterActionIcons = ['⬆️', '👟', '💤', '🎵'];
