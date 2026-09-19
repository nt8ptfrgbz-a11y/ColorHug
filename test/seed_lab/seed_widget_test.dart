import 'package:color_hug/game_audio.dart';
import 'package:color_hug/seed_lab/seed_model.dart';
import 'package:color_hug/seed_lab/seed_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> advance(WidgetTester tester, double seconds) async {
  for (var i = 0; i < (seconds * 20).ceil(); i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> mount(
  WidgetTester tester,
  SeedLabModel model,
  GameAudioController audio, {
  Size size = const Size(1180, 820),
  double textScale = 1,
  bool reduced = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduced,
        ),
        child: child!,
      ),
      home: SeedLabScreen(audio: audio, model: model, nativeAudio: false),
    ),
  );
  await tester.pump();
}

Future<void> close(
  WidgetTester tester,
  SeedLabModel m,
  GameAudioController audio,
) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
  m.dispose();
  audio.dispose();
}

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
    const Size(768, 1024),
    const Size(1180, 820),
    const Size(640, 520),
    const Size(800, 600),
  ]) {
    testWidgets('playable layout at ${size.width} × ${size.height}', (
      tester,
    ) async {
      final m = SeedLabModel(), audio = GameAudioController.silent();
      await mount(tester, m, audio, size: size);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(const ValueKey('nutrient-moon')));
      await tester.tap(find.byKey(const ValueKey('nutrient-moon')));
      await advance(tester, 1.5);
      await tester.tap(find.byKey(const ValueKey('nutrient-music')));
      await advance(tester, 1.5);
      await tester.ensureVisible(find.byKey(const ValueKey('seed-grow')));
      await tester.tap(find.byKey(const ValueKey('seed-grow')));
      await advance(tester, 4.2);
      expect(m.phase, LabPhase.grown);
      expect(m.discoveries, hasLength(1));
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(const ValueKey('seed-again')));
      await tester.tap(find.byKey(const ValueKey('seed-again')));
      await tester.pump();
      expect(m.phase, LabPhase.planting);
      expect(m.ingredients, isEmpty);
      await close(tester, m, audio);
    });
  }

  testWidgets(
    'dragging an ingredient, undo and rapid taps keep the recipe valid',
    (tester) async {
      final m = SeedLabModel(), audio = GameAudioController.silent();
      await mount(tester, m, audio);
      final source = tester.getCenter(
        find.byKey(const ValueKey('nutrient-soda')),
      );
      final target = tester.getCenter(find.byKey(const ValueKey('seed-pot')));
      await tester.dragFrom(source, target - source);
      await advance(tester, 1.5);
      expect(m.ingredients, [Nutrient.soda]);
      await tester.tap(find.byKey(const ValueKey('seed-undo')));
      await tester.pump();
      expect(m.ingredients, isEmpty);
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byKey(const ValueKey('nutrient-moon')));
        await tester.pump();
      }
      expect(m.ingredients, [Nutrient.moon]);
      await advance(tester, 1.5);
      expect(tester.takeException(), isNull);
      await close(tester, m, audio);
    },
  );

  testWidgets('backgrounding pauses growth and resumes it once', (
    tester,
  ) async {
    final m = SeedLabModel(), audio = GameAudioController.silent();
    await mount(tester, m, audio);
    m.add(Nutrient.moon);
    m.add(Nutrient.rainbow);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('seed-grow')));
    await advance(tester, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await advance(tester, 5);
    expect(m.phase, LabPhase.growing);
    expect(m.discoveries, isEmpty);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await advance(tester, 4);
    expect(m.phase, LabPhase.grown);
    expect(m.experiments, 1);
    await close(tester, m, audio);
  });

  testWidgets('collection and hybrid selection form a complete return path', (
    tester,
  ) async {
    final m = SeedLabModel(), audio = GameAudioController.silent();
    for (final n in [Nutrient.moon, Nutrient.music]) {
      m.newPot();
      m.add(n);
      m.add(n);
      m.startGrowing();
      m.finishGrowing();
    }
    await mount(tester, m, audio);
    await tester.tap(find.byKey(const ValueKey('seed-cross')));
    await advance(tester, .5);
    for (final p in m.discoveries) {
      await tester.tap(find.byKey(ValueKey('plant-${p.id}')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const ValueKey('seed-cross-confirm')));
    await advance(tester, .5);
    expect(m.isHybrid, isTrue);
    expect(m.ready, isTrue);
    await tester.tap(find.byKey(const ValueKey('seed-grow')));
    await advance(tester, 4.2);
    expect(m.discoveries, hasLength(3));
    await tester.tap(find.byKey(const ValueKey('seed-collection')));
    await advance(tester, .5);
    await tester.tap(find.byKey(ValueKey('plant-${m.result!.id}')));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.textContaining('两位植物朋友的魔法'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('seed-close-collection')));
    await advance(tester, .5);
    expect(find.byKey(const ValueKey('seed-pot')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await close(tester, m, audio);
  });

  testWidgets('large text and reduced motion preserve complete play', (
    tester,
  ) async {
    final m = SeedLabModel(), audio = GameAudioController.silent();
    await mount(
      tester,
      m,
      audio,
      size: const Size(390, 844),
      textScale: 1.6,
      reduced: true,
    );
    m.add(Nutrient.rainbow);
    m.add(Nutrient.rainbow);
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('seed-grow')));
    await tester.tap(find.byKey(const ValueKey('seed-grow')));
    await advance(tester, 1);
    expect(m.phase, LabPhase.grown);
    expect(tester.takeException(), isNull);
    await close(tester, m, audio);
  });
}
