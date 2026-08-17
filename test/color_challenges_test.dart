import 'package:color_hug/color_challenges.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('光模式题库覆盖四种目标颜色', () {
    expect(lightChallenges.map((challenge) => challenge.target.name), [
      '黄色',
      '紫色',
      '青色',
      '白色',
    ]);
  });

  test('颜料模式题库覆盖五种目标颜色', () {
    expect(paintChallenges.map((challenge) => challenge.target.name), [
      '橙色',
      '绿色',
      '紫色',
      '棕色',
      '黄绿色',
    ]);
  });
}
