import 'package:color_hug/color_mixer.dart';
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
}
