import 'package:flutter/material.dart';

import 'color_mixer.dart';

@immutable
class ColorChallenge {
  const ColorChallenge({
    required this.mode,
    required this.first,
    required this.second,
    required this.emoji,
    required this.surpriseName,
  });

  final MixMode mode;
  final ColorSeed first;
  final ColorSeed second;
  final String emoji;
  final String surpriseName;

  ColorIngredient get firstIngredient => _ingredient(first);
  ColorIngredient get secondIngredient => _ingredient(second);

  List<ColorIngredient> get ingredients => [firstIngredient, secondIngredient];

  MixResult get target => ColorMixer.mix(ingredients, mode);

  String get prompt =>
      mode == MixMode.light ? '请抱出${target.name}的光' : '请调出${target.name}颜料';

  static ColorIngredient _ingredient(ColorSeed seed) {
    return paletteIngredients.firstWhere((item) => item.seed == seed);
  }
}

const lightChallenges = <ColorChallenge>[
  ColorChallenge(
    mode: MixMode.light,
    first: ColorSeed.red,
    second: ColorSeed.green,
    emoji: '☀️',
    surpriseName: '小太阳',
  ),
  ColorChallenge(
    mode: MixMode.light,
    first: ColorSeed.red,
    second: ColorSeed.blue,
    emoji: '🎇',
    surpriseName: '紫色烟花',
  ),
  ColorChallenge(
    mode: MixMode.light,
    first: ColorSeed.green,
    second: ColorSeed.blue,
    emoji: '🐳',
    surpriseName: '青色小鲸鱼',
  ),
  ColorChallenge(
    mode: MixMode.light,
    first: ColorSeed.cyan,
    second: ColorSeed.red,
    emoji: '🌟',
    surpriseName: '白色小星星',
  ),
];

const paintChallenges = <ColorChallenge>[
  ColorChallenge(
    mode: MixMode.paint,
    first: ColorSeed.red,
    second: ColorSeed.yellow,
    emoji: '🍊',
    surpriseName: '小橙子',
  ),
  ColorChallenge(
    mode: MixMode.paint,
    first: ColorSeed.yellow,
    second: ColorSeed.blue,
    emoji: '🌱',
    surpriseName: '小芽',
  ),
  ColorChallenge(
    mode: MixMode.paint,
    first: ColorSeed.red,
    second: ColorSeed.blue,
    emoji: '🍇',
    surpriseName: '小葡萄',
  ),
  ColorChallenge(
    mode: MixMode.paint,
    first: ColorSeed.red,
    second: ColorSeed.green,
    emoji: '🐻',
    surpriseName: '棕色小熊',
  ),
  ColorChallenge(
    mode: MixMode.paint,
    first: ColorSeed.yellow,
    second: ColorSeed.green,
    emoji: '🍐',
    surpriseName: '绿色小梨',
  ),
];
