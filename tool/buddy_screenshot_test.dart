import 'dart:io';
import 'dart:math';

import 'package:color_hug/buddy_bath_screen.dart';
import 'package:color_hug/buddy_hide_screen.dart';
import 'package:color_hug/buddy_home_screen.dart';
import 'package:color_hug/buddy_juice_screen.dart';
import 'package:color_hug/game_audio.dart';
import 'package:color_hug/island_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> loadFont(String family, String path) async {
  await (FontLoader(family)..addFont(
        File(path).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
      ))
      .load();
}

Future<void> preview(WidgetTester tester, Widget screen, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    RepaintBoundary(
      key: const ValueKey('buddy-preview'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Hiragino Sans GB',
          fontFamilyFallback: const ['Apple Color Emoji'],
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF367F69)),
        ),
        home: screen,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> capture(String name) => expectLater(
  find.byKey(const ValueKey('buddy-preview')),
  matchesGoldenFile('../docs/images/$name.png'),
);

void main() {
  setUpAll(() async {
    final flutter = File(
      Process.runSync('which', ['flutter']).stdout.toString().trim(),
    ).resolveSymbolicLinksSync();
    await Future.wait([
      loadFont(
        'Hiragino Sans GB',
        '/System/Library/Fonts/Hiragino Sans GB.ttc',
      ),
      loadFont(
        'Apple Color Emoji',
        '/System/Library/Fonts/Apple Color Emoji.ttc',
      ),
      loadFont(
        'MaterialIcons',
        '${File(flutter).parent.parent.path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ),
    ]);
  });

  testWidgets('小伙伴乐园画面', (tester) async {
    await preview(
      tester,
      BuddyHomeScreen(
        progress: IslandProgress(),
        audio: GameAudioController.silent(),
      ),
      const Size(1024, 900),
    );
    await capture('buddy-home');
  });
  testWidgets('果汁屋手机画面', (tester) async {
    await preview(
      tester,
      BuddyJuiceScreen(
        progress: IslandProgress(),
        audio: GameAudioController.silent(),
      ),
      const Size(390, 844),
    );
    await capture('buddy-juice');
  });
  testWidgets('泡泡浴手机画面', (tester) async {
    await preview(
      tester,
      BuddyBathScreen(
        progress: IslandProgress(),
        audio: GameAudioController.silent(),
      ),
      const Size(390, 844),
    );
    await capture('buddy-bath');
  });
  testWidgets('躲猫猫手机画面', (tester) async {
    await preview(
      tester,
      BuddyHideScreen(
        progress: IslandProgress(),
        audio: GameAudioController.silent(),
        random: Random(4),
      ),
      const Size(390, 844),
    );
    await tester.tap(find.byKey(const ValueKey('hide-begin')));
    await tester.pump(const Duration(milliseconds: 600));
    await capture('buddy-hide');
  });
}
