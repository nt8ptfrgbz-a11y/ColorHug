import 'package:color_hug/buddy_adventure_models.dart';
import 'package:color_hug/buddy_adventure_screen.dart';
import 'package:color_hug/buddy_home_screen.dart';
import 'package:color_hug/game_audio.dart';
import 'package:color_hug/island_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'buddy_games_test.dart' show pumpGame, tapKey;

Future<void> touch(WidgetTester tester, String key, Offset point) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 60));
  final rect = tester.getRect(finder);
  await tester.tapAt(
    rect.topLeft + Offset(point.dx * rect.width, point.dy * rect.height),
  );
  await tester.pump(const Duration(milliseconds: 70));
}

void main() {
  test('软糖路径允许一级台阶，但空洞与跨两层都不算桥', () {
    expect(jellyBridgePath(List.filled(12, 0)), isEmpty);
    expect(jellyBridgePath([0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1]), [
      8,
      9,
      10,
      11,
    ]);
    expect(jellyBridgePath([0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 0]), [8, 5, 2, 3]);
    expect(jellyBridgePath([0, 1, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0]), isEmpty);
  });

  test('创作数据按种类校验，发现奖励去重', () {
    final p = IslandProgress();
    p.saveBuddyCreation('building', [1, 2]);
    p.saveBuddyCreation('show', [0, 4, 0]);
    p.saveBuddyCreation('dino', [-1, 1]);
    expect(p.buddyCreation('building'), isNull);
    expect(p.buddyCreation('show'), isNull);
    expect(p.buddyCreation('dino'), isNull);
    p.recordBuddyAdventure(BuddyAdventure.weather, 0, ['rain', 'unrelated']);
    p.recordBuddyAdventure(BuddyAdventure.weather, 0, ['rain']);
    expect(p.stars, 1);
    expect(p.buddyWords, {'rain'});
    p.dispose();
  });

  testWidgets('天气改变水坑、风筝和日晒目标，三种任务各记一次', (tester) async {
    final p = IslandProgress();
    final audio = GameAudioController.silent();
    await pumpGame(
      tester,
      BuddyAdventureScreen(
        adventure: BuddyAdventure.weather,
        progress: p,
        audio: audio,
      ),
    );
    for (var mission = 0; mission < 3; mission++) {
      await tapKey(tester, 'weather-tool-${[1, 2, 0][mission]}');
      for (var i = 0; i < 3; i++) {
        await touch(tester, 'weather-sky', const Offset(.5, .35));
      }
      expect(p.buddyAdventureWins(BuddyAdventure.weather), mission + 1);
      if (mission < 2) await tapKey(tester, 'weather-next');
    }
    expect(p.buddyWords, containsAll(['sun', 'rain', 'wind']));
    await tester.pumpWidget(const SizedBox());
    p.dispose();
    audio.dispose();
  });

  testWidgets('恐龙从刷土暖蛋到破壳照顾，小窝与恐龙会保存', (tester) async {
    final p = IslandProgress();
    final audio = GameAudioController.silent();
    await pumpGame(
      tester,
      BuddyAdventureScreen(
        adventure: BuddyAdventure.dinosaur,
        progress: p,
        audio: audio,
      ),
    );
    for (final point in [
      const Offset(.28, .35),
      const Offset(.5, .32),
      const Offset(.72, .35),
      const Offset(.28, .64),
      const Offset(.5, .65),
      const Offset(.72, .64),
    ]) {
      await touch(tester, 'dino-ground', point);
    }
    for (var i = 0; i < 6; i++) {
      await touch(tester, 'dino-ground', const Offset(.5, .48));
    }
    expect(find.byKey(const ValueKey('dino-feed')), findsOneWidget);
    expect(p.buddyCreation('dino'), [0, 0]);
    await tapKey(tester, 'dino-feed');
    for (var i = 0; i < 3; i++) {
      await tapKey(tester, 'dino-nest');
    }
    expect(p.buddyCreation('dino'), [0, 3]);
    expect(p.buddyWords, containsAll(['egg', 'baby', 'eat']));
    await tester.pumpWidget(const SizedBox());
    p.dispose();
    audio.dispose();
  });

  testWidgets('搭桥失败可以修改，连通以后小兔过桥并保存设计', (tester) async {
    final p = IslandProgress();
    final audio = GameAudioController.silent();
    await pumpGame(
      tester,
      BuddyAdventureScreen(
        adventure: BuddyAdventure.building,
        progress: p,
        audio: audio,
      ),
    );
    await tapKey(tester, 'building-try');
    await tester.pump(const Duration(seconds: 2));
    expect(p.buddyAdventureWins(BuddyAdventure.building), 0);
    for (var i = 8; i < 12; i++) {
      await tapKey(tester, 'building-cell-$i');
    }
    await tapKey(tester, 'building-try');
    await tester.pump(const Duration(seconds: 4));
    expect(p.buddyAdventureWins(BuddyAdventure.building), 1);
    expect(p.buddyCreation('building')!.skip(8), [1, 1, 1, 1]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    p.dispose();
    audio.dispose();
  });

  testWidgets('小老师先试错再教会穿鞋，下一题换成帽子', (tester) async {
    final p = IslandProgress();
    final audio = GameAudioController.silent();
    await pumpGame(
      tester,
      BuddyAdventureScreen(
        adventure: BuddyAdventure.silly,
        progress: p,
        audio: audio,
      ),
    );
    await tapKey(tester, 'silly-item-1');
    await tapKey(tester, 'silly-target-2');
    expect(p.buddyAdventureWins(BuddyAdventure.silly), 0);
    await tapKey(tester, 'silly-item-0');
    await tapKey(tester, 'silly-target-2');
    expect(p.buddyWords, contains('shoes'));
    await tapKey(tester, 'silly-next');
    expect(audio.lastSpokenText, 'hat');
    await tester.pumpWidget(const SizedBox());
    p.dispose();
    audio.dispose();
  });

  testWidgets('动物剧场播放完整动作序列并存档，退出后计时器停止', (tester) async {
    final p = IslandProgress();
    final audio = GameAudioController.silent();
    await pumpGame(
      tester,
      BuddyAdventureScreen(
        adventure: BuddyAdventure.theater,
        progress: p,
        audio: audio,
      ),
    );
    for (final i in [0, 2, 3]) {
      await tapKey(tester, 'theater-action-$i');
    }
    await tapKey(tester, 'theater-play');
    expect(audio.lastSpokenText, 'jump');
    await tester.pump(const Duration(seconds: 5));
    expect(p.buddyCreation('show'), [0, 0, 0, 2, 3]);
    expect(p.buddyWords, containsAll(['jump', 'sleep', 'dance']));
    await tapKey(tester, 'theater-play');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
    expect(tester.takeException(), isNull);
    p.dispose();
    audio.dispose();
  });

  testWidgets('烟花支持三种形状，连续划动不会重复奖励', (tester) async {
    final p = IslandProgress();
    final audio = GameAudioController.silent();
    await pumpGame(
      tester,
      BuddyAdventureScreen(
        adventure: BuddyAdventure.fireworks,
        progress: p,
        audio: audio,
      ),
    );
    for (var shape = 0; shape < 3; shape++) {
      await tapKey(tester, 'firework-shape-$shape');
      for (var i = 0; i < 5; i++) {
        await touch(tester, 'fireworks-sky', Offset(.2 + .1 * i, .4));
      }
    }
    expect(p.buddyAdventureWins(BuddyAdventure.fireworks), 3);
    expect(p.stars, 3);
    await tester.pumpWidget(const SizedBox());
    p.dispose();
    audio.dispose();
  });

  for (final size in [
    const Size(320, 568),
    const Size(844, 390),
    const Size(1024, 768),
  ]) {
    testWidgets('九个入口和新增六个游戏适配 $size', (tester) async {
      final p = IslandProgress();
      final audio = GameAudioController.silent();
      await pumpGame(
        tester,
        BuddyHomeScreen(progress: p, audio: audio),
        size: size,
      );
      for (final game in BuddyAdventure.values) {
        expect(find.byKey(ValueKey('buddy-game-${game.name}')), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      for (final game in BuddyAdventure.values) {
        await tester.pumpWidget(const SizedBox());
        await pumpGame(
          tester,
          BuddyAdventureScreen(adventure: game, progress: p, audio: audio),
          size: size,
        );
        expect(tester.takeException(), isNull, reason: game.name);
      }
      await tester.pumpWidget(const SizedBox());
      p.dispose();
      audio.dispose();
    });
  }
}
