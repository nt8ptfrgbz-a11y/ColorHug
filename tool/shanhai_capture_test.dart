import 'dart:io';
import 'package:color_hug/game_audio.dart';
import 'package:color_hug/shanhai/shanhai_model.dart';
import 'package:color_hug/shanhai/shanhai_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// This validates Flutter layouts against real SceneKit render snapshots.
// The production app always uses the live native viewport, never these images.
void main() {
  setUpAll(() async {
    final flutter = File(
      Process.runSync('which', ['flutter']).stdout.toString().trim(),
    ).resolveSymbolicLinksSync();
    for (final font in [
      ('Hiragino Sans GB', '/System/Library/Fonts/Hiragino Sans GB.ttc'),
      (
        'MaterialIcons',
        '${File(flutter).parent.parent.path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ),
    ]) {
      await (FontLoader(font.$1)
            ..addFont(File(font.$2).readAsBytes().then(ByteData.sublistView)))
          .load();
    }
  });
  for (final size in [
    const Size(1280, 820),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    for (final phase in [
      ShanPhase.sleeping,
      ShanPhase.companion,
      ShanPhase.flying,
    ]) {
      testWidgets('${phase.name} at $size', (t) async {
        final m = ShanhaiModel(), audio = GameAudioController.silent();
        if (phase != ShanPhase.sleeping) {
          for (var i = 0; i < 3; i++) {
            m.traceSeal(i);
          }
          for (var i = 0; i < 60; i++) {
            m.advance(.1);
          }
          m.feed();
          for (var i = 0; i < 30; i++) {
            m.advance(.1);
          }
        }
        if (phase == ShanPhase.flying) m.startFlight();
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        final file = File(
          'docs/shanhai/${phase == ShanPhase.sleeping
              ? 'sleeping'
              : phase == ShanPhase.flying
              ? 'flight'
              : size.width < 500
              ? 'portrait'
              : 'lake'}.png',
        );
        final bytes = file.readAsBytesSync();
        await t.pumpWidget(
          RepaintBoundary(
            key: const ValueKey('capture'),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                useMaterial3: true,
                fontFamily: 'Hiragino Sans GB',
              ),
              home: ShanhaiScreen(
                audio: audio,
                model: m,
                nativeAudio: false,
                stageBuilder: (c, v) => Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ),
        );
        await t.pump(const Duration(milliseconds: 300));
        await t.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 80));
        });
        await t.pump();
        await expectLater(
          find.byKey(const ValueKey('capture')),
          matchesGoldenFile(
            '../docs/shanhai/ui-${phase.name}-${size.width.toInt()}.png',
          ),
        );
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        await t.pump();
        m.dispose();
        audio.dispose();
        t.view.resetPhysicalSize();
        t.view.resetDevicePixelRatio();
      });
    }
  }
}
