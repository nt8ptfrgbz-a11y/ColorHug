import 'dart:io';
import 'package:color_hug/game_audio.dart';
import 'package:color_hug/silly_town/town_audio.dart';
import 'package:color_hug/silly_town/town_catalog.dart';
import 'package:color_hug/silly_town/town_model.dart';
import 'package:color_hug/silly_town/town_progress.dart';
import 'package:color_hug/silly_town/town_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test/silly_town/town_widget_test.dart' show advance;

void main() {
  setUpAll(() async {
    final flutter = File(
      Process.runSync('which', ['flutter']).stdout.toString().trim(),
    ).resolveSymbolicLinksSync();
    for (final item in [
      ('Hiragino Sans GB', '/System/Library/Fonts/Hiragino Sans GB.ttc'),
      (
        'MaterialIcons',
        '${File(flutter).parent.parent.path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ),
      (
        'TownLatin',
        '/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf',
      ),
    ]) {
      await (FontLoader(item.$1)
            ..addFont(File(item.$2).readAsBytes().then(ByteData.sublistView)))
          .load();
    }
  });
  for (final size in [const Size(1100, 900), const Size(390, 844)]) {
    testWidgets('town home ${size.width}', (tester) async {
      final progress = TownProgress(), audio = GameAudioController.silent();
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('capture'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              fontFamily: 'TownLatin',
              fontFamilyFallback: const ['Hiragino Sans GB'],
            ),
            home: TownHomeScreen(
              audio: audio,
              progress: progress,
              nativeAudio: false,
            ),
          ),
        ),
      );
      await advance(tester, .5);
      await expectLater(
        find.byKey(const ValueKey('capture')),
        matchesGoldenFile('../docs/silly_town/home-${size.width.toInt()}.png'),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      progress.dispose();
      audio.dispose();
    });
  }
  for (final id in [0, 5, 11, 15, 20, 28]) {
    testWidgets('scene $id', (tester) async {
      final progress = TownProgress(),
          voice = GameAudioController.silent(),
          sound = TownAudio(
            GameAudioController.silent(),
            TownProgress(),
            native: false,
          );
      tester.view.physicalSize = const Size(780, 900);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('capture'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              fontFamily: 'TownLatin',
              fontFamilyFallback: const ['Hiragino Sans GB'],
            ),
            home: TownPlayScreen(
              level: townLevels[id],
              progress: progress,
              sound: sound,
            ),
          ),
        ),
      );
      await advance(tester, .4);
      final rect = tester.getRect(find.byKey(const ValueKey('town-canvas'))),
          l = TownLayout(rect.size);
      if (id == 5) {
        for (var i = 0; i < 2; i++) {
          await tester.dragFrom(rect.topLeft + l.slot(i), l.actor - l.slot(i));
          await advance(tester, .6);
        }
      }
      if (id == 11) {
        final gesture = await tester.startGesture(rect.topLeft + l.actor);
        await advance(tester, 2.3);
        await gesture.up();
      }
      await expectLater(
        find.byKey(const ValueKey('capture')),
        matchesGoldenFile('../docs/silly_town/scene-$id.png'),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      sound.dispose();
      sound.voice.dispose();
      sound.progress.dispose();
      progress.dispose();
      voice.dispose();
    });
  }
}
