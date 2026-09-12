import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:color_hug/buddy_expedition/expedition_assets.dart';
import 'package:color_hug/buddy_expedition/expedition_controller.dart';
import 'package:color_hug/buddy_expedition/expedition_models.dart';
import 'package:color_hug/buddy_expedition/expedition_scene.dart';
import '../buddy_screenshot_test.dart' show loadFont;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('river valley illustration and motion preview', () async {
    await loadFont(
      'Hiragino Sans GB',
      '/System/Library/Fonts/Hiragino Sans GB.ttc',
    );
    final assets = ExpeditionAssets();
    await assets.load();
    final out = Directory('build/expedition-preview')
      ..createSync(recursive: true);
    for (final size in [const Size(390, 844), const Size(844, 390)]) {
      for (final stage in ['camp', 'river', 'riding']) {
        final m = ExpeditionController();
        if (stage == 'river') {
          m.restore(const ValleyCheckpoint(carX: riverStop));
          for (var i = 0; i < 180; i++) {
            m.update(1 / 60);
          }
          m.pickLog();
          m.moveHook(const Offset(1300, -150));
          for (var i = 0; i < 60; i++) {
            m.update(1 / 60);
          }
        }
        if (stage == 'riding') {
          m.restore(
            const ValleyCheckpoint(
              carX: 590,
              bridge: true,
              logX: bridgeCenter,
              joined: true,
              mud: .7,
            ),
          );
        }
        final r = ui.PictureRecorder();
        final canvas = Canvas(r)..scale(2);
        ExpeditionScene(m, assets, reducedMotion: false).paint(canvas, size);
        final pic = r.endRecording();
        final im = await pic.toImage(
          (size.width * 2).round(),
          (size.height * 2).round(),
        );
        final data = await im.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '${out.path}/$stage-${size.width.toInt()}.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        im.dispose();
        pic.dispose();
        m.dispose();
      }
    }
    assets.dispose();
  });
}
