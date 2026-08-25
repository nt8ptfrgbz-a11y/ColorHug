import 'package:color_hug/main.dart';
import 'package:color_hug/island_progress.dart';
import 'package:color_hug/game_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('主界面可以在光与颜料模式间切换', (tester) async {
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
    await tester.pump();

    expect(find.text('颜色抱抱'), findsOneWidget);
    expect(find.text('光'), findsOneWidget);
    expect(find.text('颜料'), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

    await tester.tap(find.text('颜料'));
    await tester.pump(const Duration(milliseconds: 550));

    expect(find.textContaining('小颜料们'), findsOneWidget);
  });

  testWidgets('iPhone 小屏布局没有溢出', (tester) async {
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
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const ValueKey('color-playground')), findsOneWidget);
    expect(find.text('光'), findsOneWidget);
    expect(find.text('颜料'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('challenge-toggle')));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('黄色的能量光'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('拖动红光与绿光可以完成抱抱混合', (tester) async {
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
    await tester.pump(const Duration(milliseconds: 50));

    final playground = find.byKey(const ValueKey('color-playground'));
    final origin = tester.getTopLeft(playground);
    final size = tester.getSize(playground);
    final red = origin + Offset(size.width * 0.18, size.height * 0.48);
    final green = origin + Offset(size.width * 0.41, size.height * 0.30);

    await tester.dragFrom(red, green - red);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));

    expect(find.textContaining('黄色的光'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('颜色小任务可以获得星星并进入下一关', (tester) async {
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
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const ValueKey('challenge-toggle')));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('黄色的能量光'), findsOneWidget);
    expect(find.text('⭐ 0'), findsOneWidget);

    final playground = find.byKey(const ValueKey('color-playground'));
    final origin = tester.getTopLeft(playground);
    final size = tester.getSize(playground);
    final red = origin + Offset(size.width * 0.24, size.height * 0.60);
    final green = origin + Offset(size.width * 0.76, size.height * 0.60);

    await tester.dragFrom(red, green - red);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));

    expect(find.textContaining('太棒啦'), findsOneWidget);
    expect(find.text('⭐ 1'), findsOneWidget);
    expect(find.byKey(const ValueKey('next-challenge')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('next-challenge')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('紫色的能量光'), findsOneWidget);
    expect(find.text('⭐ 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('颜色面板可以选择二十四种颜色精灵', (tester) async {
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
    await tester.tap(find.byKey(const ValueKey('open-color-panel')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('颜色精灵面板'), findsOneWidget);
    expect(find.byKey(const ValueKey('panel-color-珊瑚色')), findsOneWidget);
    expect(find.byKey(const ValueKey('panel-color-薰衣草色')), findsOneWidget);

    final coral = find.byKey(const ValueKey('panel-color-珊瑚色'));
    await tester.ensureVisible(coral);
    await tester.pump();
    await tester.tap(coral);
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.textContaining('珊瑚色小精灵来啦'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
