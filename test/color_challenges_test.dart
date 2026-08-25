import 'package:color_hug/color_challenges.dart';
import 'package:color_hug/color_mixer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('题库包含一百道有编号的颜色任务', () {
    expect(colorChallenges, hasLength(colorChallengeTotal));
    expect(lightChallenges, hasLength(50));
    expect(paintChallenges, hasLength(50));
    expect(
      colorChallenges.map((challenge) => challenge.number),
      List<int>.generate(100, (index) => index + 1),
    );
  });

  test('每种模式的五十道题都使用不同颜色配方', () {
    String recipe(ColorChallenge challenge) {
      final seeds = [challenge.first.index, challenge.second.index]..sort();
      return '${seeds.first}-${seeds.last}';
    }

    expect(lightChallenges.map(recipe).toSet(), hasLength(50));
    expect(paintChallenges.map(recipe).toSet(), hasLength(50));
  });

  test('前三个启蒙任务保留经典混色结果', () {
    expect(lightChallenges.take(3).map((item) => item.target.name), [
      '黄色',
      '紫色',
      '青色',
    ]);
    expect(paintChallenges.take(3).map((item) => item.target.name), [
      '橙色',
      '绿色',
      '紫色',
    ]);
  });

  test('每道题都有一个不会误合成目标色的干扰颜色', () {
    for (final challenge in colorChallenges) {
      expect(challenge.decoy, isNot(challenge.first));
      expect(challenge.decoy, isNot(challenge.second));
      final withFirst = ColorMixer.mix([
        challenge.firstIngredient,
        challenge.decoyIngredient,
      ], challenge.mode);
      final withSecond = ColorMixer.mix([
        challenge.secondIngredient,
        challenge.decoyIngredient,
      ], challenge.mode);
      expect(withFirst.name, isNot(challenge.target.name));
      expect(withSecond.name, isNot(challenge.target.name));
    }
  });
}
