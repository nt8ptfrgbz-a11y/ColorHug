import 'package:flutter/material.dart';

import 'color_mixer.dart';

const colorChallengeTotal = 100;

@immutable
class ColorChallenge {
  const ColorChallenge({
    required this.number,
    required this.mode,
    required this.first,
    required this.second,
    required this.decoy,
    required this.emoji,
    required this.surpriseName,
    required this.story,
  });

  final int number;
  final MixMode mode;
  final ColorSeed first;
  final ColorSeed second;
  final ColorSeed decoy;
  final String emoji;
  final String surpriseName;
  final String story;

  ColorIngredient get firstIngredient => ingredientForSeed(first);
  ColorIngredient get secondIngredient => ingredientForSeed(second);
  ColorIngredient get decoyIngredient => ingredientForSeed(decoy);

  List<ColorIngredient> get ingredients => [firstIngredient, secondIngredient];

  List<ColorIngredient> get playgroundIngredients => [
    firstIngredient,
    secondIngredient,
    decoyIngredient,
  ];

  MixResult get target => ColorMixer.mix(ingredients, mode);

  String get difficulty => number <= 20
      ? '启蒙'
      : number <= 60
      ? '进阶'
      : '挑战';

  String get prompt {
    final action = mode == MixMode.light
        ? '点亮${target.name}的光'
        : '调出${target.name}颜料';
    return '$story。找出正确的两位颜色伙伴，$action';
  }
}

ColorIngredient ingredientForSeed(ColorSeed seed) {
  return paletteIngredients.firstWhere((item) => item.seed == seed);
}

typedef _SeedPair = ({ColorSeed first, ColorSeed second});
typedef _MissionTheme = ({String place, String emoji, String reward});

const _themes = <_MissionTheme>[
  (place: '云朵城的灯塔', emoji: '🏰', reward: '魔法灯'),
  (place: '海底车站', emoji: '🐳', reward: '泡泡列车'),
  (place: '森林音乐会', emoji: '🦊', reward: '音乐果实'),
  (place: '星星邮局', emoji: '⭐', reward: '星光邮票'),
  (place: '恐龙乐园', emoji: '🦕', reward: '恐龙蛋'),
  (place: '太空基地', emoji: '🚀', reward: '能量核心'),
  (place: '糖果工坊', emoji: '🍬', reward: '彩虹果冻'),
  (place: '雪山救援站', emoji: '🐧', reward: '勇气徽章'),
  (place: '花仙子舞台', emoji: '🧚', reward: '会唱歌的花'),
  (place: '机器人学校', emoji: '🤖', reward: '聪明齿轮'),
];

const _lightStarters = <_SeedPair>[
  (first: ColorSeed.red, second: ColorSeed.green),
  (first: ColorSeed.red, second: ColorSeed.blue),
  (first: ColorSeed.green, second: ColorSeed.blue),
  (first: ColorSeed.cyan, second: ColorSeed.red),
];

const _paintStarters = <_SeedPair>[
  (first: ColorSeed.red, second: ColorSeed.yellow),
  (first: ColorSeed.yellow, second: ColorSeed.blue),
  (first: ColorSeed.red, second: ColorSeed.blue),
  (first: ColorSeed.red, second: ColorSeed.green),
  (first: ColorSeed.yellow, second: ColorSeed.green),
];

const _lightSeeds = <ColorSeed>[
  ColorSeed.red,
  ColorSeed.orange,
  ColorSeed.yellow,
  ColorSeed.lime,
  ColorSeed.green,
  ColorSeed.cyan,
  ColorSeed.turquoise,
  ColorSeed.blue,
  ColorSeed.indigo,
  ColorSeed.purple,
  ColorSeed.magenta,
];

const _paintSeeds = <ColorSeed>[
  ColorSeed.red,
  ColorSeed.orange,
  ColorSeed.yellow,
  ColorSeed.lime,
  ColorSeed.green,
  ColorSeed.mint,
  ColorSeed.cyan,
  ColorSeed.blue,
  ColorSeed.purple,
  ColorSeed.magenta,
  ColorSeed.white,
  ColorSeed.black,
];

final lightChallenges = List<ColorChallenge>.unmodifiable(
  _buildChallengeSet(
    mode: MixMode.light,
    numberOffset: 0,
    seeds: _lightSeeds,
    starters: _lightStarters,
  ),
);

final paintChallenges = List<ColorChallenge>.unmodifiable(
  _buildChallengeSet(
    mode: MixMode.paint,
    numberOffset: 50,
    seeds: _paintSeeds,
    starters: _paintStarters,
  ),
);

final colorChallenges = List<ColorChallenge>.unmodifiable([
  ...lightChallenges,
  ...paintChallenges,
]);

List<ColorChallenge> _buildChallengeSet({
  required MixMode mode,
  required int numberOffset,
  required List<ColorSeed> seeds,
  required List<_SeedPair> starters,
}) {
  final pairs = <_SeedPair>[...starters];
  final seen = starters.map(_pairKey).toSet();
  for (var firstIndex = 0; firstIndex < seeds.length; firstIndex++) {
    for (
      var secondIndex = firstIndex + 1;
      secondIndex < seeds.length;
      secondIndex++
    ) {
      final pair = (first: seeds[firstIndex], second: seeds[secondIndex]);
      if (seen.add(_pairKey(pair))) pairs.add(pair);
    }
  }

  return List<ColorChallenge>.generate(50, (index) {
    final pair = pairs[index];
    final target = ColorMixer.mix([
      ingredientForSeed(pair.first),
      ingredientForSeed(pair.second),
    ], mode);
    final theme = _themes[index % _themes.length];
    final story = mode == MixMode.light
        ? '${theme.place}需要${target.name}的能量光'
        : '${theme.place}正在寻找${target.name}颜料';
    return ColorChallenge(
      number: numberOffset + index + 1,
      mode: mode,
      first: pair.first,
      second: pair.second,
      decoy: _pickDecoy(pair, mode, target.name, index),
      emoji: theme.emoji,
      surpriseName: '${target.name}${theme.reward}',
      story: story,
    );
  });
}

String _pairKey(_SeedPair pair) {
  final first = pair.first.index;
  final second = pair.second.index;
  return first < second ? '$first-$second' : '$second-$first';
}

ColorSeed _pickDecoy(
  _SeedPair pair,
  MixMode mode,
  String targetName,
  int challengeIndex,
) {
  for (var offset = 0; offset < paletteIngredients.length; offset++) {
    final candidate =
        paletteIngredients[(challengeIndex * 5 + offset) %
            paletteIngredients.length];
    if (candidate.seed == pair.first || candidate.seed == pair.second) continue;
    final withFirst = ColorMixer.mix([
      ingredientForSeed(pair.first),
      candidate,
    ], mode);
    final withSecond = ColorMixer.mix([
      ingredientForSeed(pair.second),
      candidate,
    ], mode);
    if (withFirst.name != targetName && withSecond.name != targetName) {
      return candidate.seed;
    }
  }
  return ColorSeed.gray;
}
