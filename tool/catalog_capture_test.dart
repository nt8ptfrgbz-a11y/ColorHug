import 'dart:io';

import 'package:color_hug/game_audio.dart';
import 'package:color_hug/island_progress.dart';
import 'package:color_hug/game_catalog_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    final flutter = File(
      Process.runSync('which', ['flutter']).stdout.toString().trim(),
    ).resolveSymbolicLinksSync();
    for (final (name, path) in [
      ('Hiragino Sans GB', '/System/Library/Fonts/Hiragino Sans GB.ttc'),
      ('Apple Color Emoji', '/System/Library/Fonts/Apple Color Emoji.ttc'),
      (
        'MaterialIcons',
        '${File(flutter).parent.parent.path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ),
    ]) {
      await (FontLoader(
        name,
      )..addFont(File(path).readAsBytes().then(ByteData.sublistView))).load();
    }
  });

  for (final (name, size) in [
    ('phone', const Size(390, 844)),
    ('desktop', const Size(1024, 768)),
  ]) {
    testWidgets('catalog $name', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final progress = IslandProgress();
      final audio = GameAudioController.silent();
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('capture'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              fontFamily: 'Hiragino Sans GB',
              fontFamilyFallback: const ['Apple Color Emoji'],
            ),
            home: GameCatalogScreen(
              progress: progress,
              audio: audio,
              nativeAudio: false,
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        final context = tester.element(find.byType(GameCatalogScreen));
        await Future.wait([
          for (final image in tester.widgetList<Image>(find.byType(Image)))
            precacheImage(image.image, context),
        ]);
      });
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const ValueKey('capture')),
        matchesGoldenFile('../docs/images/game-catalog-$name.png'),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      progress.dispose();
      audio.dispose();
    });
  }
}
