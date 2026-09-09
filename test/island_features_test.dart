import 'package:color_hug/game_audio.dart';
import 'package:color_hug/island_progress.dart';
import 'package:color_hug/main.dart';
import 'package:color_hug/rainbow_repair_levels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpDesktopApp(
  WidgetTester tester, {
  GameAudioController? audio,
}) async {
  tester.view.physicalSize = const Size(1024, 768);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ColorHugApp(
      progress: IslandProgress(),
      audio: audio ?? GameAudioController.silent(),
    ),
  );
  await tester.pump(const Duration(milliseconds: 80));
}

Future<void> _openIsland(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('island-map')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _openTrainingCamp(WidgetTester tester) async {
  final target = find.byKey(const ValueKey('activity-guardian'));
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('彩虹小岛与全部新页面适配 iPhone 小屏', (tester) async {
    tester.view.physicalSize = const Size(390, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ColorHugApp(
        progress: IslandProgress(),
        audio: GameAudioController.silent(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 80));
    await _openIsland(tester);

    for (final activity in [
      'activity-detective',
      'activity-repair',
      'activity-studio',
      'activity-gallery',
      'activity-guardian',
    ]) {
      final target = find.byKey(ValueKey(activity));
      await tester.ensureVisible(target);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(target);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull, reason: activity);
      await tester.tap(find.byTooltip('返回彩虹小岛'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
  });

  testWidgets('奥特曼训练营的五种玩法适配 iPhone 小屏', (tester) async {
    tester.view.physicalSize = const Size(390, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ColorHugApp(
        progress: IslandProgress(),
        audio: GameAudioController.silent(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 80));
    await _openIsland(tester);
    await _openTrainingCamp(tester);

    for (final game in [
      'ultra-game-fruit-slice',
      'ultra-game-radar',
      'ultra-game-beam',
      'ultra-game-rescue',
      'ultra-game-guardian',
    ]) {
      final target = find.byKey(ValueKey(game));
      await tester.ensureVisible(target);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(target);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      expect(tester.takeException(), isNull, reason: game);
      await tester.tap(find.byTooltip('返回奥特曼训练营'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
  });

  testWidgets('彩虹小岛展示七个活动入口', (tester) async {
    await _pumpDesktopApp(tester);
    await _openIsland(tester);

    expect(find.text('🏝️ 彩虹小岛'), findsOneWidget);
    expect(find.byKey(const ValueKey('activity-buddy')), findsOneWidget);
    expect(find.byKey(const ValueKey('activity-lab')), findsOneWidget);
    expect(find.byKey(const ValueKey('activity-detective')), findsOneWidget);
    expect(find.byKey(const ValueKey('activity-repair')), findsOneWidget);
    expect(find.byKey(const ValueKey('activity-studio')), findsOneWidget);
    expect(find.byKey(const ValueKey('activity-gallery')), findsOneWidget);
    expect(find.byKey(const ValueKey('activity-guardian')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('色彩侦探答对后获得星星并进入下一题', (tester) async {
    await _pumpDesktopApp(tester);
    await _openIsland(tester);
    await tester.tap(find.byKey(const ValueKey('activity-detective')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('太阳公公'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('detective-option-黄色')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('找到了'), findsOneWidget);
    expect(find.byKey(const ValueKey('detective-next')), findsOneWidget);
    expect(find.textContaining('⭐ 1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('detective-next')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('小鲸鱼'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('色彩侦探会朗读线索并用声音回应答案', (tester) async {
    final audio = GameAudioController.silent();
    await tester.pumpWidget(
      ColorHugApp(progress: IslandProgress(), audio: audio),
    );
    await tester.pump(const Duration(milliseconds: 80));
    await _openIsland(tester);
    await tester.tap(find.byKey(const ValueKey('activity-detective')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(audio.lastSpokenText, contains('太阳公公'));
    await tester.tap(find.byKey(const ValueKey('detective-option-黄色')));
    await tester.pump(const Duration(milliseconds: 100));

    expect(audio.lastSpokenText, contains('找到了'));
    expect(audio.lastSound, GameSound.correct);
  });

  testWidgets('彩虹修复师完成五关后会解锁下一张地图', (tester) async {
    await _pumpDesktopApp(tester);
    await _openIsland(tester);
    await tester.tap(find.byKey(const ValueKey('activity-repair')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('👆 点一点'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('repair-color-黄色')));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('🖐️ 拖一拖'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('repair-color-蓝色')));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('🧪 调一调'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('repair-mix-黄色')));
    await tester.tap(find.byKey(const ValueKey('repair-mix-蓝色')));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('👂 听声音'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('repair-color-红色')));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.tap(find.byKey(const ValueKey('repair-color-紫色')));
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.byKey(const ValueKey('repair-map-completed')), findsOneWidget);
    expect(find.textContaining('晨光花园修复完成'), findsOneWidget);
    expect(find.textContaining('⭐ 5'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('repair-next-map')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('repair-map-1')), findsOneWidget);
    expect(find.textContaining('扶起椰树'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('彩虹修复师会同步进度并允许选择已解锁关卡', (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final progress = IslandProgress();
    final audio = GameAudioController.silent();
    await tester.pumpWidget(ColorHugApp(progress: progress, audio: audio));
    await tester.pump(const Duration(milliseconds: 80));
    await _openIsland(tester);
    await tester.tap(find.byKey(const ValueKey('activity-repair')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    progress.repairPart(7, repairTasks[6].colorName);
    await tester.pump();
    expect(find.byKey(const ValueKey('repair-step-7')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('repair-level-picker')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('🗺️ 选择关卡'), findsOneWidget);
    expect(find.byKey(const ValueKey('repair-select-level-2')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('repair-select-level-2')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('repair-step-2')), findsOneWidget);
    expect(find.text('第3关 · 种出草地'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('魔法画室可以绘画并完成作品', (tester) async {
    await _pumpDesktopApp(tester);
    await _openIsland(tester);
    await tester.tap(find.byKey(const ValueKey('activity-studio')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final canvas = find.byKey(const ValueKey('studio-canvas'));
    final center = tester.getCenter(canvas);
    await tester.dragFrom(center - const Offset(80, 30), const Offset(160, 60));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const ValueKey('studio-save')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('作品完成啦！'), findsOneWidget);
    expect(find.textContaining('1种颜色'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('色彩图鉴区分已发现与待发现颜色', (tester) async {
    await _pumpDesktopApp(tester);
    await _openIsland(tester);
    await tester.tap(find.byKey(const ValueKey('activity-gallery')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const ValueKey('gallery-progress')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('gallery-progress'))).data,
      '🎨 4/26',
    );
    expect(find.byKey(const ValueKey('gallery-color-红色')), findsOneWidget);
    expect(find.byKey(const ValueKey('gallery-color-紫色')), findsOneWidget);
    expect(find.text('等待发现'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('奥特曼训练营展示五种语音引导玩法', (tester) async {
    await _pumpDesktopApp(tester);
    await _openIsland(tester);
    await _openTrainingCamp(tester);

    expect(find.text('🚀 奥特曼训练营'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('ultra-game-fruit-slice')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('ultra-game-radar')), findsOneWidget);
    expect(find.byKey(const ValueKey('ultra-game-beam')), findsOneWidget);
    expect(find.byKey(const ValueKey('ultra-game-rescue')), findsOneWidget);
    expect(find.byKey(const ValueKey('ultra-game-guardian')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('水果切切乐只需一根手指且漏掉不扣分', (tester) async {
    final audio = GameAudioController.silent();
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ColorHugApp(progress: IslandProgress(), audio: audio),
    );
    await tester.pump(const Duration(milliseconds: 80));
    await _openIsland(tester);
    await _openTrainingCamp(tester);

    final entry = find.byKey(const ValueKey('ultra-game-fruit-slice'));
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('🍉 水果切切乐'), findsOneWidget);
    expect(find.textContaining('漏掉不扣分'), findsOneWidget);
    expect(audio.lastSpokenText, contains('一根手指'));
    expect(audio.lastVoice, GameVoice.child);

    final arena = find.byKey(const ValueKey('fruit-slice-arena'));
    final center = tester.getCenter(arena);
    await tester.dragFrom(center - const Offset(120, 0), const Offset(240, 0));
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('🍉 1/6'), findsOneWidget);
    expect(audio.lastSound, GameSound.fruitWatermelon);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('fruit-level-picker')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('🗺️ 选择水果关卡'), findsOneWidget);
    expect(find.byKey(const ValueKey('fruit-select-level-0')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('fruit-select-level-29')),
      260,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.byKey(const ValueKey('fruit-select-level-29')), findsOneWidget);
  });

  testWidgets('怪兽雷达根据语音特征找到目标', (tester) async {
    final audio = GameAudioController.silent();
    await _pumpDesktopApp(tester, audio: audio);
    await _openIsland(tester);
    await _openTrainingCamp(tester);
    await tester.tap(find.byKey(const ValueKey('ultra-game-radar')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byKey(const ValueKey('radar-monster-1')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('特征不一样'), findsOneWidget);
    expect(audio.lastVoice, GameVoice.monster);

    await tester.tap(find.byKey(const ValueKey('radar-monster-0')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('雷达锁定成功'), findsOneWidget);
    expect(audio.lastVoice, GameVoice.hero);
    expect(find.byKey(const ValueKey('radar-next')), findsOneWidget);
    expect(find.textContaining('⭐ 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('宇宙救援会对工具选择给出语音反馈', (tester) async {
    await _pumpDesktopApp(tester);
    await _openIsland(tester);
    await _openTrainingCamp(tester);
    await tester.tap(find.byKey(const ValueKey('ultra-game-rescue')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byKey(const ValueKey('rescue-tool-snack')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('帮不上忙'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('rescue-tool-rope')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('救援成功'), findsOneWidget);
    expect(find.byKey(const ValueKey('rescue-next')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('光线发射在能量球进入目标时完成训练', (tester) async {
    await _pumpDesktopApp(tester);
    await _openIsland(tester);
    await _openTrainingCamp(tester);
    await tester.tap(find.byKey(const ValueKey('ultra-game-beam')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    for (var attempt = 0; attempt < 24; attempt++) {
      if (find.byKey(const ValueKey('beam-next')).evaluate().isNotEmpty) break;
      await tester.pump(const Duration(milliseconds: 70));
      await tester.tap(find.byKey(const ValueKey('beam-launch')));
      await tester.pump();
    }

    expect(find.textContaining('奥特光线发射成功'), findsOneWidget);
    expect(find.byKey(const ValueKey('beam-next')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('奥特曼能量护盾使用互补色完成任务', (tester) async {
    await _pumpDesktopApp(tester);
    await _openIsland(tester);
    await _openTrainingCamp(tester);
    await tester.tap(find.byKey(const ValueKey('ultra-game-guardian')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('⚡ 奥特曼·能量护盾'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('guardian-energy-蓝色')));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.textContaining('还没有平衡护盾'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('guardian-energy-青色')));
    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.textContaining('能量平衡成功'), findsOneWidget);
    expect(find.byKey(const ValueKey('guardian-next')), findsOneWidget);
    expect(find.textContaining('⭐ 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
