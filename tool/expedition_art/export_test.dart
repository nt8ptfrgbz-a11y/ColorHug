import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'art_source.dart';
import 'island_art.dart';

void main() {
  test('export original expedition illustrations', () async {
    final entries =
        <String, ({ui.Size size, void Function(ExpeditionArt) draw})>{
          'door': (size: const ui.Size(280, 420), draw: (a) => a.door()),
          'basket': (size: const ui.Size(180, 150), draw: (a) => a.basket()),
          'mushroom': (
            size: const ui.Size(150, 155),
            draw: (a) => a.mushroom(),
          ),
          'lantern': (size: const ui.Size(125, 150), draw: (a) => a.lantern()),
          'cave_arch': (
            size: const ui.Size(450, 325),
            draw: (a) => a.caveArch(),
          ),
          'boat': (size: const ui.Size(410, 220), draw: (a) => a.boat()),
          'flyer': (size: const ui.Size(180, 145), draw: (a) => a.flyer()),
          'wing': (size: const ui.Size(170, 115), draw: (a) => a.wing()),
          'car': (size: const ui.Size(310, 175), draw: (a) => a.car()),
          'wheel': (size: const ui.Size(100, 100), draw: (a) => a.wheel()),
          'log': (size: const ui.Size(240, 85), draw: (a) => a.log()),
          'dino_body': (
            size: const ui.Size(180, 160),
            draw: (a) => a.dinoBody(),
          ),
          'dino_head': (
            size: const ui.Size(170, 125),
            draw: (a) => a.dinoHead(),
          ),
          'dino_leg': (size: const ui.Size(65, 70), draw: (a) => a.dinoLeg()),
          'dino_tail': (
            size: const ui.Size(160, 125),
            draw: (a) => a.dinoTail(),
          ),
          'tree': (size: const ui.Size(310, 480), draw: (a) => a.tree(0)),
          'tree_gold': (size: const ui.Size(310, 480), draw: (a) => a.tree(1)),
          'fern': (size: const ui.Size(220, 160), draw: (a) => a.fern()),
          'rock': (size: const ui.Size(185, 120), draw: (a) => a.rock()),
          'tent': (size: const ui.Size(290, 225), draw: (a) => a.tent()),
          'fruit': (size: const ui.Size(115, 115), draw: (a) => a.fruit()),
          'mountains': (
            size: const ui.Size(1280, 420),
            draw: (a) => a.mountains(),
          ),
          'arm': (size: const ui.Size(200, 60), draw: (a) => a.arm()),
          'nest': (size: const ui.Size(270, 140), draw: (a) => a.nest()),
        };
    for (final e in entries.entries) {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder)..scale(2);
      e.value.draw(ExpeditionArt(canvas));
      final pic = recorder.endRecording();
      final image = await pic.toImage(
        (e.value.size.width * 2).round(),
        (e.value.size.height * 2).round(),
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'assets/expedition/${e.key}.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
      pic.dispose();
    }
  });
}
