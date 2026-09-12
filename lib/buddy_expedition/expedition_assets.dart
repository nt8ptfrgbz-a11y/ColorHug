import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class ExpeditionAssets {
  static const names = [
    'door',
    'basket',
    'mushroom',
    'lantern',
    'cave_arch',
    'boat',
    'flyer',
    'wing',
    'car',
    'wheel',
    'log',
    'dino_body',
    'dino_head',
    'dino_tail',
    'dino_leg',
    'tree',
    'tree_gold',
    'fern',
    'rock',
    'tent',
    'fruit',
    'mountains',
    'arm',
    'nest',
  ];
  final Map<String, ui.Image> images = {};
  bool _disposed = false;
  Future<void> load() async {
    try {
      for (final name in names) {
        if (_disposed) return;
        final data = await rootBundle.load('assets/expedition/$name.png');
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        codec.dispose();
        if (_disposed) {
          frame.image.dispose();
          return;
        }
        images[name] = frame.image;
      }
    } catch (_) {
      dispose();
      rethrow;
    }
  }

  void dispose() {
    _disposed = true;
    for (final image in images.values) {
      image.dispose();
    }
    images.clear();
  }
}
