import 'dart:math';

import 'package:color_hug/buddy_bath_screen.dart';
import 'package:color_hug/buddy_hide_screen.dart';
import 'package:color_hug/buddy_home_screen.dart';
import 'package:color_hug/buddy_juice_screen.dart';
import 'package:color_hug/buddy_models.dart';
import 'package:color_hug/buddy_widgets.dart';
import 'package:color_hug/game_audio.dart';
import 'package:color_hug/island_progress.dart';
import 'package:color_hug/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Future<void> pumpGame(
  WidgetTester tester,
  Widget game, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(home: game));
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.pump(const Duration(milliseconds: 80));
  await tester.tap(target);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
}

Future<void> finishJuice(WidgetTester tester) async {
  await tapKey(tester, 'juice-start-blend');
  for (var i = 0; i < 3; i++) {
    await tapKey(tester, 'juice-blend');
  }
  await tapKey(tester, 'juice-serve');
}

void main() {
  test('配方忽略加入顺序，保留份数，并拒绝损坏的存档', () {
    expect(
      JuiceRecipe(['apple', 'banana']).id,
      JuiceRecipe(['banana', 'apple']).id,
    );
    expect(
      JuiceRecipe(['apple', 'apple']).id,
      isNot(JuiceRecipe(['apple']).id),
    );
    expect(JuiceRecipe(['watermelon']).reaction, JuiceReaction.bubbles);
    expect(JuiceRecipe(['lemon']).reaction, JuiceReaction.sour);
    expect(
      JuiceRecipe(['apple', 'banana', 'grape']).reaction,
      JuiceReaction.rainbow,
    );
    expect(JuiceRecipe(['apple'], iced: true).reaction, JuiceReaction.snow);
    for (final value in [
      null,
      {},
      {'fruits': []},
      {
        'fruits': ['unknown'],
      },
      {
        'fruits': ['apple', 12],
      },
    ]) {
      expect(JuiceRecipe.fromJson(value), isNull);
    }
  });

  test('配方、装扮、英语与旧星星进度能一起恢复，重复奖励不会累加', () async {
    final previous = SharedPreferencesAsyncPlatform.instance;
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    addTearDown(() => SharedPreferencesAsyncPlatform.instance = previous);
    final progress = IslandProgress.persistent();
    await progress.ready;
    progress.recordDetectiveWin(0, '黄色');
    progress.dressBuddy(color: 2, outfit: 'crown');
    progress.saveJuiceRecipe(JuiceRecipe(['watermelon', 'apple']));
    progress.saveJuiceRecipe(JuiceRecipe(['apple', 'watermelon']));
    progress.completeBuddyBath('star');
    progress.findBuddyAnimal('cat');
    progress.findBuddyAnimal('cat');
    progress.saveBuddyCreation('building', [
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      1,
      1,
      1,
      1,
    ]);
    progress.saveBuddyCreation('show', [1, 2, 0, 3]);
    progress.saveBuddyCreation('dino', [2, 3]);
    await progress.ready;
    final restored = IslandProgress.persistent();
    await restored.ready;
    expect(restored.buddyColor, 2);
    expect(restored.buddyOutfit, 'star');
    expect(restored.juiceRecipes, hasLength(1));
    expect(restored.buddyBaths, 1);
    expect(restored.buddyHideRounds, 2);
    expect(restored.buddyWords, containsAll(['cat', 'watermelon', 'wash']));
    expect(restored.stars, 4);
    expect(restored.detectiveWins, 1);
    expect(restored.buddyCreation('building')!.skip(8), [1, 1, 1, 1]);
    expect(restored.buddyCreation('show'), [1, 2, 0, 3]);
    expect(restored.buddyCreation('dino'), [2, 3]);
    progress.dispose();
    restored.dispose();
  });

  test('损坏的小伙伴记录不影响已有小岛进度，加载时保留新装扮', () async {
    final previous = SharedPreferencesAsyncPlatform.instance;
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    addTearDown(() => SharedPreferencesAsyncPlatform.instance = previous);
    final prefs = SharedPreferencesAsync();
    await prefs.setString('color_hug.buddy_journal_v1', '{broken');
    await prefs.setInt('color_hug.stars', 9);
    final progress = IslandProgress.persistent();
    progress.dressBuddy(color: 3);
    await progress.ready;
    expect(progress.stars, 9);
    expect(progress.buddyColor, 3);
    expect(progress.juiceRecipes, isEmpty);
    progress.dispose();
  });

  testWidgets('从彩虹小岛进入小伙伴乐园，再打开三个游戏并返回', (tester) async {
    final progress = IslandProgress();
    final audio = GameAudioController.silent();
    await pumpGame(tester, ColorHugApp(progress: progress, audio: audio));
    await tapKey(tester, 'island-map');
    await tapKey(tester, 'activity-buddy');
    for (final game in ['juice', 'bath', 'hide']) {
      await tapKey(tester, 'buddy-game-$game');
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byTooltip('返回小伙伴乐园'));
      await tester.tap(find.byTooltip('返回小伙伴乐园'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('小伙伴乐园'), findsOneWidget);
    }
    await tester.pumpWidget(const SizedBox());
    progress.dispose();
    audio.dispose();
  });

  testWidgets('一指划过两份水果后可搅拌、喂食、存档，再次喂食不重复保存', (tester) async {
    final progress = IslandProgress();
    final audio = GameAudioController.silent();
    await pumpGame(tester, BuddyJuiceScreen(progress: progress, audio: audio));
    final start = tester.getCenter(
      find.byKey(const ValueKey('juice-fruit-apple')),
    );
    final end = tester.getCenter(
      find.byKey(const ValueKey('juice-fruit-banana')),
    );
    await tester.dragFrom(
      start - const Offset(20, 0),
      end - start + const Offset(20, 0),
    );
    await tester.pump();
    expect(find.text('🌀 去搅拌 · 2/3 份水果'), findsOneWidget);
    await finishJuice(tester);
    expect(progress.juiceRecipes, hasLength(1));
    expect(progress.juiceRecipes.single.fruits, ['apple', 'banana']);
    expect(progress.stars, 1);
    await tester.ensureVisible(find.byKey(const ValueKey('juice-buddy')));
    await tester.tap(find.byKey(const ValueKey('juice-buddy')));
    await tester.pump();
    expect(progress.stars, 1);
    expect(find.byKey(const ValueKey('juice-again')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    progress.dispose();
    audio.dispose();
  });

  testWidgets('订单模式缺少指定水果时可清空重做，杯子最多三份', (tester) async {
    final progress = IslandProgress();
    final audio = GameAudioController.silent();
    await pumpGame(tester, BuddyJuiceScreen(progress: progress, audio: audio));
    await tapKey(tester, 'juice-order-mode');
    for (var i = 0; i < 4; i++) {
      await tapKey(tester, 'juice-fruit-banana');
    }
    expect(find.text('🌀 去搅拌 · 3/3 份水果'), findsOneWidget);
    await tapKey(tester, 'juice-start-blend');
    expect(find.byKey(const ValueKey('juice-blend')), findsNothing);
    await tapKey(tester, 'juice-clear');
    await tapKey(tester, 'juice-fruit-apple');
    await finishJuice(tester);
    expect(progress.juiceRecipes.single.fruits, ['apple']);
    await tester.pumpWidget(const SizedBox());
    progress.dispose();
    audio.dispose();
  });

  testWidgets('洗澡需要清洁不同部位，完成冲洗擦干后可保存装扮', (tester) async {
    final progress = IslandProgress();
    final audio = GameAudioController.silent();
    await pumpGame(tester, BuddyBathScreen(progress: progress, audio: audio));
    final surface = find.byKey(const ValueKey('bath-surface'));
    var rect = tester.getRect(surface);
    final first =
        rect.topLeft +
        Offset(
          rect.width * buddyBathSpots.first.dx,
          rect.height * buddyBathSpots.first.dy,
        );
    for (var i = 0; i < 10; i++) {
      await tester.tapAt(first);
    }
    await tester.pump();
    expect(find.text('搓出泡泡  1/6'), findsOneWidget);
    for (var stage = 0; stage < 3; stage++) {
      rect = tester.getRect(surface);
      for (final spot in buddyBathSpots) {
        await tester.tapAt(
          rect.topLeft + Offset(rect.width * spot.dx, rect.height * spot.dy),
        );
        await tester.pump(const Duration(milliseconds: 30));
      }
    }
    expect(find.byKey(const ValueKey('bath-finish')), findsOneWidget);
    await tapKey(tester, 'bath-outfit-crown');
    await tapKey(tester, 'bath-finish');
    expect(progress.buddyOutfit, 'crown');
    expect(progress.buddyBaths, 1);
    expect(progress.buddyWords, containsAll(['wash', 'water', 'dry']));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    progress.dispose();
    audio.dispose();
  });

  testWidgets('躲猫猫点错可继续找，正确后才保存，下轮换动物', (tester) async {
    final progress = IslandProgress();
    final audio = GameAudioController.silent();
    final target = HideRound.create(0, Random(4)).target;
    await pumpGame(
      tester,
      BuddyHideScreen(progress: progress, audio: audio, random: Random(4)),
    );
    expect(audio.lastLanguage, GameLanguage.english);
    expect(audio.lastSpokenText, 'cat');
    await tapKey(tester, 'hide-begin');
    await tapKey(tester, 'hide-spot-${(target + 1) % 3}');
    expect(progress.buddyHideRounds, 0);
    await tapKey(tester, 'hide-spot-$target');
    expect(progress.buddyHideRounds, 1);
    expect(progress.buddyWords, contains('cat'));
    await tapKey(tester, 'hide-next');
    expect(audio.lastSpokenText, 'dog');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    progress.dispose();
    audio.dispose();
  });

  testWidgets('孩子藏动物后抱抱会找出来，离开时停止寻找计时器', (tester) async {
    final progress = IslandProgress();
    final audio = GameAudioController.silent();
    await pumpGame(
      tester,
      BuddyHideScreen(progress: progress, audio: audio, random: Random(3)),
    );
    await tapKey(tester, 'hide-place-mode');
    await tapKey(tester, 'hide-begin');
    await tapKey(tester, 'hide-spot-2');
    await tester.pump(const Duration(seconds: 6));
    expect(find.byKey(const ValueKey('hide-next')), findsOneWidget);
    expect(progress.buddyHideRounds, 1);
    await tapKey(tester, 'hide-next');
    await tapKey(tester, 'hide-begin');
    await tapKey(tester, 'hide-spot-0');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 8));
    expect(progress.buddyHideRounds, 1);
    expect(tester.takeException(), isNull);
    progress.dispose();
    audio.dispose();
  });

  for (final size in [
    const Size(320, 568),
    const Size(844, 390),
    const Size(1024, 768),
  ]) {
    testWidgets('新乐园与三个游戏适配 $size', (tester) async {
      final progress = IslandProgress();
      final audio = GameAudioController.silent();
      for (final screen in [
        BuddyHomeScreen(progress: progress, audio: audio),
        BuddyJuiceScreen(progress: progress, audio: audio),
        BuddyBathScreen(progress: progress, audio: audio),
        BuddyHideScreen(progress: progress, audio: audio),
      ]) {
        await pumpGame(tester, screen, size: size);
        expect(
          tester.takeException(),
          isNull,
          reason: screen.runtimeType.toString(),
        );
      }
      await tester.pumpWidget(const SizedBox());
      progress.dispose();
      audio.dispose();
    });
  }
}
