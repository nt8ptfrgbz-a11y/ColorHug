import 'package:color_hug/game_audio.dart';
import 'package:color_hug/island_progress.dart';
import 'package:color_hug/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpDesktopApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1024, 768);
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
}

Future<void> _openIsland(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('island-map')));
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

  testWidgets('彩虹小岛展示五个活动入口', (tester) async {
    await _pumpDesktopApp(tester);
    await _openIsland(tester);

    expect(find.text('🏝️ 彩虹小岛'), findsOneWidget);
    expect(find.byKey(const ValueKey('activity-lab')), findsOneWidget);
    expect(find.byKey(const ValueKey('activity-detective')), findsOneWidget);
    expect(find.byKey(const ValueKey('activity-repair')), findsOneWidget);
    expect(find.byKey(const ValueKey('activity-studio')), findsOneWidget);
    expect(find.byKey(const ValueKey('activity-gallery')), findsOneWidget);
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

  testWidgets('彩虹修复师可以依次恢复整座花园', (tester) async {
    await _pumpDesktopApp(tester);
    await _openIsland(tester);
    await tester.tap(find.byKey(const ValueKey('activity-repair')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    for (final color in ['黄色', '蓝色', '绿色', '红色']) {
      await tester.tap(find.byKey(ValueKey('repair-color-$color')));
      await tester.pump(const Duration(milliseconds: 1200));
    }

    expect(find.byKey(const ValueKey('repair-completed')), findsOneWidget);
    expect(find.textContaining('整座花园都恢复颜色'), findsOneWidget);
    expect(find.textContaining('⭐ 4'), findsOneWidget);
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
      '🎨 4/15',
    );
    expect(find.byKey(const ValueKey('gallery-color-红色')), findsOneWidget);
    expect(find.byKey(const ValueKey('gallery-color-紫色')), findsOneWidget);
    expect(find.text('等待发现'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
