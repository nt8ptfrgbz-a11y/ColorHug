import 'dart:math' as math;

import 'package:flutter/material.dart';

enum MixMode { light, paint }

enum ColorSeed {
  red,
  coral,
  orange,
  amber,
  yellow,
  lime,
  green,
  mint,
  cyan,
  turquoise,
  blue,
  navy,
  indigo,
  purple,
  lavender,
  magenta,
  pink,
  rose,
  peach,
  brown,
  beige,
  white,
  gray,
  black,
}

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
  ColorIngredient(seed: ColorSeed.coral, name: '珊瑚色', color: Color(0xFFFF766C)),
  ColorIngredient(seed: ColorSeed.orange, name: '橙色', color: Color(0xFFFF922E)),
  ColorIngredient(seed: ColorSeed.amber, name: '琥珀色', color: Color(0xFFFFB52E)),
  ColorIngredient(seed: ColorSeed.yellow, name: '黄色', color: Color(0xFFFFD84A)),
  ColorIngredient(seed: ColorSeed.lime, name: '黄绿色', color: Color(0xFF9BC94A)),
  ColorIngredient(seed: ColorSeed.green, name: '绿色', color: Color(0xFF45CE75)),
  ColorIngredient(seed: ColorSeed.mint, name: '薄荷色', color: Color(0xFF72DEB1)),
  ColorIngredient(seed: ColorSeed.cyan, name: '青色', color: Color(0xFF42D7D0)),
  ColorIngredient(
    seed: ColorSeed.turquoise,
    name: '湖蓝色',
    color: Color(0xFF31B9D8),
  ),
  ColorIngredient(seed: ColorSeed.blue, name: '蓝色', color: Color(0xFF4687FF)),
  ColorIngredient(seed: ColorSeed.navy, name: '深蓝色', color: Color(0xFF3158A6)),
  ColorIngredient(
    seed: ColorSeed.indigo,
    name: '靛蓝色',
    color: Color(0xFF5C58C9),
  ),
  ColorIngredient(seed: ColorSeed.purple, name: '紫色', color: Color(0xFF9B67E8)),
  ColorIngredient(
    seed: ColorSeed.lavender,
    name: '薰衣草色',
    color: Color(0xFFB99AEF),
  ),
  ColorIngredient(
    seed: ColorSeed.magenta,
    name: '品红色',
    color: Color(0xFFE45AB7),
  ),
  ColorIngredient(seed: ColorSeed.pink, name: '粉色', color: Color(0xFFFF9DB1)),
  ColorIngredient(seed: ColorSeed.rose, name: '玫红色', color: Color(0xFFE84F84)),
  ColorIngredient(seed: ColorSeed.peach, name: '桃色', color: Color(0xFFFFB38D)),
  ColorIngredient(seed: ColorSeed.brown, name: '棕色', color: Color(0xFF8A654A)),
  ColorIngredient(seed: ColorSeed.beige, name: '米色', color: Color(0xFFE6D2A8)),
  ColorIngredient(seed: ColorSeed.white, name: '白色', color: Color(0xFFF8F5EB)),
  ColorIngredient(seed: ColorSeed.gray, name: '灰色', color: Color(0xFF8C8F99)),
  ColorIngredient(seed: ColorSeed.black, name: '黑色', color: Color(0xFF30333D)),
];

const quickPaletteSeeds = <ColorSeed>[
  ColorSeed.red,
  ColorSeed.yellow,
  ColorSeed.blue,
  ColorSeed.green,
  ColorSeed.cyan,
  ColorSeed.purple,
  ColorSeed.white,
  ColorSeed.black,
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
      final light = _idealLight(ingredient);
      red = 1 - ((1 - red) * (1 - light.r));
      green = 1 - ((1 - green) * (1 - light.g));
      blue = 1 - ((1 - blue) * (1 - light.b));
    }

    final color = Color.from(alpha: 1, red: red, green: green, blue: blue);
    return MixResult(color: color, name: _friendlyName(color));
  }

  static Color _idealLight(ColorIngredient ingredient) {
    if (ingredient.seed == ColorSeed.white) return Colors.white;
    if (ingredient.seed == ColorSeed.black) return Colors.black;
    if (ingredient.seed == ColorSeed.gray) {
      return const Color(0xFF8C8C8C);
    }
    final hsv = HSVColor.fromColor(ingredient.color);
    return hsv.withSaturation(1).withValue(1).toColor();
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

    var redLog = 0.0;
    var greenLog = 0.0;
    var blueLog = 0.0;
    for (final ingredient in ingredients) {
      redLog += math.log(math.max(0.018, _toLinear(ingredient.color.r)));
      greenLog += math.log(math.max(0.018, _toLinear(ingredient.color.g)));
      blueLog += math.log(math.max(0.018, _toLinear(ingredient.color.b)));
    }

    final count = ingredients.length.toDouble();
    final mixed = Color.from(
      alpha: 1,
      red: _toSrgb(math.exp(redLog / count)),
      green: _toSrgb(math.exp(greenLog / count)),
      blue: _toSrgb(math.exp(blueLog / count)),
    );
    return MixResult(color: mixed, name: _friendlyName(mixed));
  }

  static MixResult? _paintPair(ColorIngredient first, ColorIngredient second) {
    if (first.seed == second.seed) {
      return MixResult(color: first.color, name: first.name);
    }

    final pair = {first.seed, second.seed};
    if (_samePair(pair, ColorSeed.white, ColorSeed.black)) {
      return const MixResult(color: Color(0xFF96959A), name: '灰色');
    }
    if (pair.contains(ColorSeed.white)) {
      final other = first.seed == ColorSeed.white ? second : first;
      final color = Color.lerp(other.color, Colors.white, 0.32)!;
      final name = other.seed == ColorSeed.red ? '粉色' : '浅${other.name}';
      return MixResult(color: color, name: name);
    }
    if (pair.contains(ColorSeed.black)) {
      final other = first.seed == ColorSeed.black ? second : first;
      final color = Color.lerp(other.color, Colors.black, 0.34)!;
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
    if (_samePair(pair, ColorSeed.blue, ColorSeed.green)) {
      return const MixResult(color: Color(0xFF2F9E91), name: '蓝绿色');
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

  static double _toLinear(double channel) {
    return channel <= 0.04045
        ? channel / 12.92
        : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  }

  static double _toSrgb(double channel) {
    final value = channel <= 0.0031308
        ? channel * 12.92
        : (1.055 * math.pow(channel, 1 / 2.4)) - 0.055;
    return value.clamp(0.0, 1.0);
  }

  static bool _samePair(Set<ColorSeed> pair, ColorSeed a, ColorSeed b) {
    return pair.length == 2 && pair.contains(a) && pair.contains(b);
  }

  static String _friendlyName(Color color) {
    final hsv = HSVColor.fromColor(color);
    if (hsv.value < 0.18) {
      return '黑色';
    }
    if (hsv.saturation < 0.10 && hsv.value > 0.88) {
      return '白色';
    }
    if (hsv.saturation < 0.16) {
      return '灰色';
    }

    final hue = hsv.hue;
    if (hue < 12 || hue >= 348) {
      return hsv.value > 0.82 && hsv.saturation < 0.48 ? '粉色' : '红色';
    }
    if (hue < 24) return '珊瑚色';
    if (hue < 43) {
      if (hsv.value < 0.72) {
        return '棕色';
      }
      return '橙色';
    }
    if (hue < 66) {
      return '黄色';
    }
    if (hue < 92) return '黄绿色';
    if (hue < 153) {
      return '绿色';
    }
    if (hue < 174) return '薄荷色';
    if (hue < 192) {
      return '青色';
    }
    if (hue < 210) return '湖蓝色';
    if (hue < 245) {
      return '蓝色';
    }
    if (hue < 266) return '靛蓝色';
    if (hue < 303) {
      return '紫色';
    }
    if (hue < 330) return '品红色';
    return '玫红色';
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
