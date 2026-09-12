import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:color_hug/buddy_play/buddy_play_catalog.dart';
import 'package:color_hug/buddy_play/buddy_play_routes.dart';
import 'package:color_hug/game_audio.dart';
import 'package:color_hug/island_progress.dart';
import 'buddy_screenshot_test.dart' show loadFont;
import '../test/buddy_play/play_widgets_test.dart'
    show advance, canvasDrag, canvasTap;
import '../test/buddy_games_test.dart' show tapKey;

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
  for (final wide in [false, true]) {
    for (final game in BuddyPlay.values) {
      testWidgets('${game.name} ${wide ? 'wide' : 'phone'}', (tester) async {
        tester.view.physicalSize = wide
            ? const Size(1100, 780)
            : const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final p = IslandProgress(), audio = GameAudioController.silent();
        await tester.pumpWidget(
          RepaintBoundary(
            key: const ValueKey('capture'),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                useMaterial3: true,
                fontFamily: 'Hiragino Sans GB',
                fontFamilyFallback: const ['Apple Color Emoji'],
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF367F69),
                ),
              ),
              home: buddyPlayScreen(game, p, audio),
            ),
          ),
        );
        await tester.pump();
        await advance(tester, .3);
        await expectLater(
          find.byKey(const ValueKey('capture')),
          matchesGoldenFile(
            '../docs/images/play-${game.name}-${wide ? 'wide' : 'phone'}.png',
          ),
        );
        if (!wide) {
          switch (game) {
            case BuddyPlay.rolling:
              await tapKey(tester, 'rolling-launch');
              await advance(tester, 1.8);
            case BuddyPlay.salon:
              await canvasDrag(
                tester,
                'salon-canvas',
                const Offset(.25, .31),
                const Offset(.75, .31),
              );
              await tapKey(tester, 'salon-decor');
              await tapKey(tester, 'salon-mirror');
            case BuddyPlay.water:
              await tapKey(tester, 'water-pipe-1');
              await tapKey(tester, 'water-pipe-2');
              await tapKey(tester, 'water-pipe-2');
              await tapKey(tester, 'water-tap');
              await advance(tester, 6);
              await tapKey(tester, 'water-plug');
              await advance(tester, 2);
            case BuddyPlay.delivery:
              await tapKey(tester, 'delivery-box-0');
              await tapKey(tester, 'delivery-drive');
              await advance(tester, 3);
              await tapKey(tester, 'delivery-wash');
            case BuddyPlay.squishy:
              await tapKey(tester, 'squishy-stamp');
              await tapKey(tester, 'squishy-color');
            case BuddyPlay.soundTrain:
              await tapKey(tester, 'train-start');
              await advance(tester, 1.1);
            case BuddyPlay.shadows:
              await tapKey(tester, 'shadows-hat');
              await canvasDrag(
                tester,
                'shadows-canvas',
                const Offset(.5, .94),
                const Offset(.3, .85),
              );
            case BuddyPlay.tinyWorld:
              await tapKey(tester, 'world-tool-3');
              await canvasTap(tester, 'world-canvas', const Offset(.45, .56));
              await advance(tester, 9);
          }
          await expectLater(
            find.byKey(const ValueKey('capture')),
            matchesGoldenFile('../docs/images/play-${game.name}-action.png'),
          );
        }
        await tester.pumpWidget(const SizedBox());
        p.dispose();
        audio.dispose();
      });
    }
  }
}
