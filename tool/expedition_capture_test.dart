import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:color_hug/buddy_expedition/expedition_models.dart';
import 'package:color_hug/game_audio.dart';
import 'package:color_hug/island_progress.dart';
import '../test/buddy_expedition/expedition_widget_test.dart' as driver;
import 'buddy_screenshot_test.dart' show loadFont;

void main() {
  setUpAll(() async {
    await loadFont(
      'Hiragino Sans GB',
      '/System/Library/Fonts/Hiragino Sans GB.ttc',
    );
  });
  for (final size in [const Size(390, 844), const Size(844, 390)]) {
    testWidgets('river valley real gestures ${size.width}', (t) async {
      final p = IslandProgress(), audio = GameAudioController.silent();
      await driver.load(t, p, audio, size: size);
      final record = size.width == 390;
      final dir = Directory('build/expedition-replay')
        ..createSync(recursive: true);
      var tick = 0, frame = 0;
      if (record) {
        driver.frameCapture = (tester) async {
          if (tick++ % 4 != 0) return;
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('expedition-capture')),
          );
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 1);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '${dir.path}/frame-${(frame++).toString().padLeft(4, '0')}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        };
      }
      Future<void> shot(String stage) async {
        await expectLater(
          find.byKey(const ValueKey('expedition-capture')),
          matchesGoldenFile(
            '../docs/images/expedition-$stage-${size.width.toInt()}.png',
          ),
        );
      }

      try {
        await driver.frames(t, .5);
        await shot('camp');
        await driver.holdRoad(t, true, 3);
        await shot('puddle');
        await driver.holdRoad(t, true, 13);
        expect(driver.observed(t).carX, riverStop);
        await t.tapAt(driver.screenPoint(t, driver.observed(t).logPosition));
        await driver.frames(t, .4);
        final drag = await t.startGesture(
          driver.screenPoint(t, driver.observed(t).hook),
        );
        await drag.moveTo(driver.screenPoint(t, const Offset(1300, -160)));
        await driver.frames(t, 1);
        await shot('lifting');
        await drag.moveTo(
          driver.screenPoint(t, const Offset(bridgeCenter, -24)),
        );
        await driver.frames(t, .6);
        await drag.up();
        await driver.frames(t, 10);
        expect(driver.observed(t).bridge, true);
        await shot('bridge');
        final m = driver.observed(t);
        await t.tapAt(
          driver.screenPoint(t, Offset(m.dinoX, roadHeight(m.dinoX) - 65)),
        );
        await driver.frames(t, 2);
        expect(driver.observed(t).dino, DinoAction.riding);
        await shot('riding');
        await driver.holdRoad(t, false, 18);
        await driver.frames(t, 2);
        expect(driver.observed(t).home, true);
        await shot('home');
        expect(t.takeException(), isNull);
      } finally {
        driver.frameCapture = null;
        await t.pumpWidget(const SizedBox());
        await t.pump();
        p.dispose();
        audio.dispose();
      }
    });
  }
}
