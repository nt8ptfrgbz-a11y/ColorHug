import 'dart:math' as math;

import 'package:flutter/material.dart';

enum MixMode { light, paint }

enum ColorSeed { red, yellow, blue, green, cyan, purple, white, black }

@immutable
class ColorIngredient {
  const ColorIngredient({
    required this.seed,
    required this.name,
    required this.color,
  });

  final ColorSeed seed;
  final String name;
  final Color color;
}

@immutable
class MixResult {
  const MixResult({required this.color, required this.name});

  final Color color;
  final String name;
}

const paletteIngredients = <ColorIngredient>[
  ColorIngredient(seed: ColorSeed.red, name: '红色', color: Color(0xFFFF4F64)),
  ColorIngredient(seed: ColorSeed.yellow, name: '黄色', color: Color(0xFFFFD84A)),
  ColorIngredient(seed: ColorSeed.blue, name: '蓝色', color: Color(0xFF4687FF)),
  ColorIngredient(seed: ColorSeed.green, name: '绿色', color: Color(0xFF45CE75)),
  ColorIngredient(seed: ColorSeed.cyan, name: '青色', color: Color(0xFF42D7D0)),
  ColorIngredient(seed: ColorSeed.purple, name: '紫色', color: Color(0xFF9B67E8)),
  ColorIngredient(seed: ColorSeed.white, name: '白色', color: Color(0xFFF8F5EB)),
  ColorIngredient(seed: ColorSeed.black, name: '黑色', color: Color(0xFF30333D)),
];

class ColorMixer {
  const ColorMixer._();

  static MixResult mix(List<ColorIngredient> ingredients, MixMode mode) {
    assert(ingredients.isNotEmpty);

    if (ingredients.length == 1) {
      final ingredient = ingredients.single;
      return MixResult(color: ingredient.color, name: ingredient.name);
    }

    if (mode == MixMode.light) {
      return _mixLight(ingredients);
    }

    return _mixPaint(ingredients);
  }

  static MixResult _mixLight(List<ColorIngredient> ingredients) {
    var red = 0.0;
    var green = 0.0;
    var blue = 0.0;

    // Screen blending behaves like overlapping colored lamps: adding a second
    // light can only make a channel brighter. Red + green therefore becomes
    // yellow instead of the muddy olive produced by a simple RGB average.
    for (final ingredient in ingredients) {
      final light = _idealLight(ingredient.seed);
      red = 1 - ((1 - red) * (1 - light.r));
      green = 1 - ((1 - green) * (1 - light.g));
      blue = 1 - ((1 - blue) * (1 - light.b));
    }

    final color = Color.from(alpha: 1, red: red, green: green, blue: blue);
    return MixResult(color: color, name: _friendlyName(color));
  }

  static Color _idealLight(ColorSeed seed) {
    return switch (seed) {
      ColorSeed.red => const Color(0xFFFF0000),
      ColorSeed.yellow => const Color(0xFFFFFF00),
      ColorSeed.blue => const Color(0xFF0000FF),
      ColorSeed.green => const Color(0xFF00FF00),
      ColorSeed.cyan => const Color(0xFF00FFFF),
      ColorSeed.purple => const Color(0xFFFF00FF),
      ColorSeed.white => const Color(0xFFFFFFFF),
      ColorSeed.black => const Color(0xFF000000),
    };
  }

  static MixResult _mixPaint(List<ColorIngredient> ingredients) {
    if (ingredients.length == 2) {
      final first = ingredients.first;
      final second = ingredients.last;
      final exact = _paintPair(first, second);
      if (exact != null) {
        return exact;
      }
    }

    final hasWhite = ingredients.any((item) => item.seed == ColorSeed.white);
    final hasBlack = ingredients.any((item) => item.seed == ColorSeed.black);

    var red = 0.0;
    var green = 0.0;
    var blue = 0.0;
    for (final ingredient in ingredients) {
      red += ingredient.color.r;
      green += ingredient.color.g;
      blue += ingredient.color.b;
    }

    final count = ingredients.length.toDouble();
    var mixed = Color.from(
      alpha: 1,
      red: red / count,
      green: green / count,
      blue: blue / count,
    );

    // Real paint loses some brightness and saturation as more pigments are
    // combined. This is deliberately gentle so the result stays cheerful.
    if (!hasWhite && !hasBlack) {
      final hsv = HSVColor.fromColor(mixed);
      mixed = hsv
          .withSaturation((hsv.saturation * 0.82).clamp(0, 1))
          .withValue((hsv.value * 0.84).clamp(0, 1))
          .toColor();
    }

    return MixResult(color: mixed, name: _friendlyName(mixed));
  }

  static MixResult? _paintPair(ColorIngredient first, ColorIngredient second) {
    if (first.seed == second.seed) {
      return MixResult(color: first.color, name: first.name);
    }

    final pair = {first.seed, second.seed};
    if (pair.contains(ColorSeed.white)) {
      final other = first.seed == ColorSeed.white ? second : first;
      final color = Color.lerp(other.color, Colors.white, 0.48)!;
      return MixResult(color: color, name: '浅${other.name}');
    }
    if (pair.contains(ColorSeed.black)) {
      final other = first.seed == ColorSeed.black ? second : first;
      final color = Color.lerp(other.color, Colors.black, 0.50)!;
      return MixResult(color: color, name: '深${other.name}');
    }
    if (_samePair(pair, ColorSeed.red, ColorSeed.yellow)) {
      return const MixResult(color: Color(0xFFFF922E), name: '橙色');
    }
    if (_samePair(pair, ColorSeed.yellow, ColorSeed.blue)) {
      return const MixResult(color: Color(0xFF55B85A), name: '绿色');
    }
    if (_samePair(pair, ColorSeed.red, ColorSeed.blue)) {
      return const MixResult(color: Color(0xFF8B5BC3), name: '紫色');
    }
    if (_samePair(pair, ColorSeed.red, ColorSeed.green)) {
      return const MixResult(color: Color(0xFF8A654A), name: '棕色');
    }
    if (_samePair(pair, ColorSeed.blue, ColorSeed.cyan)) {
      return const MixResult(color: Color(0xFF357EC2), name: '蓝绿色');
    }
    if (_samePair(pair, ColorSeed.red, ColorSeed.purple)) {
      return const MixResult(color: Color(0xFFC25388), name: '红紫色');
    }
    if (_samePair(pair, ColorSeed.yellow, ColorSeed.green)) {
      return const MixResult(color: Color(0xFF9BC94A), name: '黄绿色');
    }
    if (_samePair(pair, ColorSeed.green, ColorSeed.purple) ||
        _samePair(pair, ColorSeed.cyan, ColorSeed.red)) {
      return const MixResult(color: Color(0xFF736B67), name: '灰棕色');
    }
    return null;
  }

  static bool _samePair(Set<ColorSeed> pair, ColorSeed a, ColorSeed b) {
    return pair.length == 2 && pair.contains(a) && pair.contains(b);
  }

  static String _friendlyName(Color color) {
    final hsv = HSVColor.fromColor(color);
    if (hsv.value < 0.18) {
      return '黑色';
    }
    if (hsv.saturation < 0.10 && hsv.value > 0.90) {
      return '白色';
    }
    if (hsv.saturation < 0.16) {
      return '灰色';
    }

    final hue = hsv.hue;
    if (hue < 14 || hue >= 344) {
      return hsv.value > 0.82 && hsv.saturation < 0.48 ? '粉色' : '红色';
    }
    if (hue < 43) {
      if (hsv.value < 0.72) {
        return '棕色';
      }
      return '橙色';
    }
    if (hue < 70) {
      return '黄色';
    }
    if (hue < 155) {
      return '绿色';
    }
    if (hue < 195) {
      return '青色';
    }
    if (hue < 252) {
      return '蓝色';
    }
    if (hue < 320) {
      return '紫色';
    }
    return '粉色';
  }

  static Color readableInk(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.53 ? const Color(0xFF30303A) : Colors.white;
  }

  static double colorDistance(Color first, Color second) {
    final dr = first.r - second.r;
    final dg = first.g - second.g;
    final db = first.b - second.b;
    return math.sqrt((dr * dr) + (dg * dg) + (db * db));
  }
}
