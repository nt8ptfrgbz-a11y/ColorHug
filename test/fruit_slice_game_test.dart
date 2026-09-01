import 'package:color_hug/fruit_slice_game_screen.dart';
import 'package:color_hug/game_audio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('划线穿过水果时会命中', () {
    expect(
      fruitSliceGestureHits(
        const Offset(0, 100),
        const Offset(200, 100),
        const Offset(100, 100),
        40,
      ),
      isTrue,
    );
  });

  test('离水果较远的划线不会误判', () {
    expect(
      fruitSliceGestureHits(
        const Offset(0, 10),
        const Offset(200, 10),
        const Offset(100, 100),
        40,
      ),
      isFalse,
    );
  });

  test('三十个关卡目标逐步增加且每关都有水果', () {
    expect(fruitSliceLevels, hasLength(30));
    expect(fruitSliceLevels.first.goal, 6);
    expect(fruitSliceLevels.last.goal, 18);
    expect(
      fruitSliceLevels.every((level) => level.fruitIndices.isNotEmpty),
      isTrue,
    );
  });

  test('八种水果分别使用自己的切开音效', () {
    expect(List.generate(8, fruitSliceSoundFor).toSet(), {
      GameSound.fruitWatermelon,
      GameSound.fruitStrawberry,
      GameSound.fruitOrange,
      GameSound.fruitKiwi,
      GameSound.fruitApple,
      GameSound.fruitPineapple,
      GameSound.fruitBlueberry,
      GameSound.fruitBanana,
    });
  });

  test('彩虹能量果提供三份进度但普通水果仍计一份', () {
    expect(fruitSliceScoreFor(rainbow: false), 1);
    expect(fruitSliceScoreFor(rainbow: true), fruitSliceRainbowBonus);
    expect(fruitSliceRainbowBonus, 3);
  });
}
