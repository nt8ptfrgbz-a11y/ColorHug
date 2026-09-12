import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:color_hug/buddy_expedition/expedition_models.dart';
import 'package:color_hug/game_audio.dart';
import 'package:color_hug/island_progress.dart';
import '../test/buddy_expedition/expedition_widget_test.dart' as h;
import '../test/buddy_expedition/island_widget_test.dart' as journey;
import 'buddy_screenshot_test.dart' show loadFont;

void main() {
  setUpAll(() async {
    await loadFont(
      'Hiragino Sans GB',
      '/System/Library/Fonts/Hiragino Sans GB.ttc',
    );
  });
  for (final size in [const Size(390, 844), const Size(844, 390)]) {
    testWidgets('complete island real gestures ${size.width}', (t) async {
      final p = IslandProgress(), a = GameAudioController.silent();
      await h.load(t, p, a, size: size);
      final directory = Directory('build/island-replay')
        ..createSync(recursive: true);
      var tick = 0, frame = 0;
      if (size.width == 390) {
        h.frameCapture = (tester) async {
          if (tick++ % 6 != 0) return;
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('expedition-capture')),
          );
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 1);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '${directory.path}/frame-${(frame++).toString().padLeft(4, '0')}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        };
      }
      journey.onMilestone = (tester, id) async {
        await expectLater(
          find.byKey(const ValueKey('expedition-capture')),
          matchesGoldenFile(
            '../docs/images/island-$id-${size.width.toInt()}.png',
          ),
        );
      };
      try {
        await h.holdRoad(t, true, 16);
        await h.grabBridge(t);
        await h.frames(t, 10);
        final m = h.observed(t);
        await t.tapAt(
          h.screenPoint(t, Offset(m.dinoX, m.terrain(m.dinoX) - 65)),
        );
        await h.frames(t, 2);
        expect(m.dino, DinoAction.riding);
        await journey.continueIsland(t);
        expect(t.takeException(), isNull);
      } finally {
        h.frameCapture = null;
        journey.onMilestone = null;
        await t.pumpWidget(const SizedBox());
        await t.pump();
        p.dispose();
        a.dispose();
      }
    });
  }
}
