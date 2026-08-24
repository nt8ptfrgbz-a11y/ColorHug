import 'dart:io';

import 'package:color_hug/color_detective_screen.dart';
import 'package:color_hug/color_gallery_screen.dart';
import 'package:color_hug/game_audio.dart';
import 'package:color_hug/island_progress.dart';
import 'package:color_hug/magic_studio_screen.dart';
import 'package:color_hug/rainbow_island_screen.dart';
import 'package:color_hug/rainbow_repair_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _captureKey = ValueKey('readme-capture');

Future<void> _loadFont(String family, String path) async {
  final loader = FontLoader(family)
    ..addFont(
      File(path).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
    );
  await loader.load();
}

Future<void> _loadMacFonts() async {
  final flutterExecutable = File(
    File(
      Process.runSync('which', ['flutter']).stdout.toString().trim(),
    ).resolveSymbolicLinksSync(),
  );
  final flutterRoot = flutterExecutable.parent.parent.path;
  await Future.wait([
    _loadFont('Hiragino Sans GB', '/System/Library/Fonts/Hiragino Sans GB.ttc'),
    _loadFont(
      'Apple Color Emoji',
      '/System/Library/Fonts/Apple Color Emoji.ttc',
    ),
    _loadFont(
      'MaterialIcons',
      '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ),
  ]);
}

Widget _previewApp(Widget screen) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7957D5),
        brightness: Brightness.light,
      ),
      fontFamily: 'Hiragino Sans GB',
      fontFamilyFallback: const ['Apple Color Emoji'],
    ),
    home: RepaintBoundary(key: _captureKey, child: screen),
  );
}

Future<void> _pumpPreview(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(800, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_previewApp(screen));
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _capture(String name) async {
  await expectLater(
    find.byKey(_captureKey),
    matchesGoldenFile('../docs/images/.raw-$name.png'),
  );
}

void main() {
  setUpAll(_loadMacFonts);

  testWidgets('生成彩虹小岛截图', (tester) async {
    await _pumpPreview(
      tester,
      RainbowIslandScreen(
        progress: IslandProgress(),
        audio: GameAudioController.silent(),
        onOpenLab: () {},
      ),
    );
    await _capture('color-hug-island');
  });

  testWidgets('生成色彩侦探截图', (tester) async {
    await _pumpPreview(
      tester,
      ColorDetectiveScreen(
        progress: IslandProgress(),
        audio: GameAudioController.silent(),
      ),
    );
    await _capture('color-hug-detective');
  });

  testWidgets('生成彩虹修复师截图', (tester) async {
    await _pumpPreview(
      tester,
      RainbowRepairScreen(
        progress: IslandProgress(),
        audio: GameAudioController.silent(),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('repair-color-黄色')));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.tap(find.byKey(const ValueKey('repair-color-蓝色')));
    await tester.pump(const Duration(milliseconds: 1200));
    await _capture('color-hug-repair');
  });

  testWidgets('生成魔法画室截图', (tester) async {
    await _pumpPreview(
      tester,
      MagicStudioScreen(
        progress: IslandProgress(),
        audio: GameAudioController.silent(),
      ),
    );
    final canvas = find.byKey(const ValueKey('studio-canvas'));
    final rect = tester.getRect(canvas);
    await tester.dragFrom(
      rect.centerLeft + const Offset(80, -35),
      const Offset(420, 100),
    );
    await tester.tap(find.byKey(const ValueKey('studio-color-蓝色')));
    await tester.dragFrom(
      rect.topCenter + const Offset(-130, 70),
      const Offset(270, 220),
    );
    await tester.tap(find.byKey(const ValueKey('studio-color-黄色')));
    await tester.dragFrom(
      rect.bottomLeft + const Offset(120, -80),
      const Offset(430, -180),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await _capture('color-hug-studio');
  });

  testWidgets('生成色彩图鉴截图', (tester) async {
    await _pumpPreview(
      tester,
      ColorGalleryScreen(
        progress: IslandProgress(),
        audio: GameAudioController.silent(),
      ),
    );
    await _capture('color-hug-gallery');
  });
}
