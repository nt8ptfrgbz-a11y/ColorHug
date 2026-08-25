import 'package:color_hug/color_mixer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final red = paletteIngredients.firstWhere(
    (item) => item.seed == ColorSeed.red,
  );
  final green = paletteIngredients.firstWhere(
    (item) => item.seed == ColorSeed.green,
  );
  final yellow = paletteIngredients.firstWhere(
    (item) => item.seed == ColorSeed.yellow,
  );
  final blue = paletteIngredients.firstWhere(
    (item) => item.seed == ColorSeed.blue,
  );
  final white = paletteIngredients.firstWhere(
    (item) => item.seed == ColorSeed.white,
  );
  final black = paletteIngredients.firstWhere(
    (item) => item.seed == ColorSeed.black,
  );
  final coral = paletteIngredients.firstWhere(
    (item) => item.seed == ColorSeed.coral,
  );

  test('颜色面板提供二十四种不重复颜色', () {
    expect(paletteIngredients, hasLength(24));
    expect(paletteIngredients.map((item) => item.name).toSet(), hasLength(24));
  });

  test('红光和绿光叠加为黄色', () {
    final result = ColorMixer.mix([red, green], MixMode.light);

    expect(result.name, '黄色');
    expect(result.color.r, greaterThan(0.95));
    expect(result.color.g, greaterThan(0.80));
    expect(result.color.b, lessThan(0.55));
  });

  test('红色和绿色颜料混合为棕色', () {
    final result = ColorMixer.mix([red, green], MixMode.paint);

    expect(result.name, '棕色');
  });

  test('黄色和蓝色颜料混合为绿色', () {
    final result = ColorMixer.mix([yellow, blue], MixMode.paint);

    expect(result.name, '绿色');
  });

  test('绿色颜料加入白色会变成浅绿色而不是白色', () {
    final result = ColorMixer.mix([green, white], MixMode.paint);

    expect(result.name, '浅绿色');
    expect(result.color.g, greaterThan(result.color.r));
    expect(result.color.g, greaterThan(result.color.b));
    expect(
      ColorMixer.colorDistance(result.color, Colors.white),
      greaterThan(0.2),
    );
  });

  test('光模式中绿色与白光叠加仍是白光', () {
    final result = ColorMixer.mix([green, white], MixMode.light);

    expect(result.name, '白色');
    expect(
      ColorMixer.colorDistance(result.color, Colors.white),
      lessThan(0.02),
    );
  });

  test('白色和黑色颜料调成灰色', () {
    final result = ColorMixer.mix([white, black], MixMode.paint);

    expect(result.name, '灰色');
  });

  test('扩展颜色使用减色近似算法且不会被冲成白色', () {
    final result = ColorMixer.mix([coral, blue], MixMode.paint);

    expect(result.name, isNot('白色'));
    expect(
      ColorMixer.colorDistance(result.color, coral.color),
      greaterThan(0.1),
    );
    expect(
      ColorMixer.colorDistance(result.color, blue.color),
      greaterThan(0.1),
    );
  });
}
