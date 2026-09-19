import 'dart:io';
import 'package:color_hug/game_audio.dart';
import 'package:color_hug/seed_lab/seed_model.dart';
import 'package:color_hug/seed_lab/seed_art.dart';
import 'package:color_hug/seed_lab/seed_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test/seed_lab/seed_widget_test.dart' show advance;

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
    ]) {
      await (FontLoader(item.$1)
            ..addFont(File(item.$2).readAsBytes().then(ByteData.sublistView)))
          .load();
    }
  });
  for (final size in [
    const Size(1180, 820),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    testWidgets('seed lab rendered ${size.width}', (tester) async {
      final m = SeedLabModel(), audio = GameAudioController.silent();
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('capture'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              fontFamily: 'Hiragino Sans GB',
              useMaterial3: true,
            ),
            home: SeedLabScreen(audio: audio, model: m, nativeAudio: false),
          ),
        ),
      );
      await advance(tester, .5);
      await expectLater(
        find.byKey(const ValueKey('capture')),
        matchesGoldenFile('../docs/seed_lab/lab-${size.width.toInt()}.png'),
      );
      m.add(Nutrient.moon);
      m.add(Nutrient.rainbow);
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('seed-grow')));
      await tester.tap(find.byKey(const ValueKey('seed-grow')));
      await advance(tester, 4.2);
      if (size.width < 600) {
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, 700),
        );
        await advance(tester, .5);
      }
      await expectLater(
        find.byKey(const ValueKey('capture')),
        matchesGoldenFile('../docs/seed_lab/bloom-${size.width.toInt()}.png'),
      );
      if (size.width > 1000) {
        await tester.tap(find.byKey(const ValueKey('seed-collection')));
        await advance(tester, .5);
        await expectLater(
          find.byKey(const ValueKey('capture')),
          matchesGoldenFile('../docs/seed_lab/collection.png'),
        );
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      m.dispose();
      audio.dispose();
    });
  }
  testWidgets('all thirty plants and staggered growth keyframes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1320);
    tester.view.devicePixelRatio = 1;
    final plants = <PlantDiscovery>[
      for (final seed in SeedKind.values)
        for (final a in Nutrient.values)
          for (final b in Nutrient.values)
            if (a.index <= b.index)
              PlantDiscovery(seed: seed, first: a, second: b),
    ];
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('capture'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Hiragino Sans GB'),
          home: Scaffold(
            backgroundColor: labCream,
            body: GridView.count(
              crossAxisCount: 5,
              childAspectRatio: 200 / 220,
              children: [
                for (final plant in plants)
                  Column(
                    children: [
                      Expanded(
                        child: SizedBox.expand(
                          child: CustomPaint(
                            painter: PlantPainter(
                              seed: plant.seed,
                              plant: plant,
                              ambient: false,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        plant.name,
                        style: const TextStyle(color: labInk, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byKey(const ValueKey('capture')),
      matchesGoldenFile('../docs/seed_lab/plants.png'),
    );
    tester.view.physicalSize = const Size(1200, 570);
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('capture'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: labCream,
            body: Column(
              children: [
                for (final seed in SeedKind.values)
                  Expanded(
                    child: Row(
                      children: [
                        for (final growth in [.12, .3, .48, .62, .78, 1.0])
                          Expanded(
                            child: SizedBox.expand(
                              child: CustomPaint(
                                painter: PlantPainter(
                                  seed: seed,
                                  plant: PlantDiscovery(
                                    seed: seed,
                                    first: Nutrient.moon,
                                    second: Nutrient.rainbow,
                                  ),
                                  growth: growth,
                                  ambient: false,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byKey(const ValueKey('capture')),
      matchesGoldenFile('../docs/seed_lab/growth-frames.png'),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
