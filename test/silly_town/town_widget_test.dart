import 'package:color_hug/game_audio.dart';
import 'package:color_hug/silly_town/town_art.dart';
import 'package:color_hug/silly_town/town_audio.dart';
import 'package:color_hug/silly_town/town_catalog.dart';
import 'package:color_hug/silly_town/town_model.dart';
import 'package:color_hug/silly_town/town_progress.dart';
import 'package:color_hug/silly_town/town_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> advance(WidgetTester tester, double seconds) async {
  for (var i = 0; i < (seconds * 20).ceil(); i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> pumpTown(WidgetTester tester, Widget screen, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        splashFactory: InkRipple.splashFactory,
      ),
      home: screen,
    ),
  );
  await tester.pump();
}

TownModel sceneModel(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((p) => p.painter)
    .whereType<TownScenePainter>()
    .single
    .model;

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
    const Size(1024, 768),
  ]) {
    testWidgets('home → districts → game → return at $size', (tester) async {
      final progress = TownProgress(), audio = GameAudioController.silent();
      await pumpTown(
        tester,
        TownHomeScreen(audio: audio, progress: progress, nativeAudio: false),
        size,
      );
      for (var i = 0; i < 6; i++) {
        final card = find.byKey(ValueKey('town-district-$i'));
        await tester.scrollUntilVisible(
          card,
          220,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        await tester.tap(card);
        await advance(tester, .4);
        final level = find.byKey(ValueKey('town-level-${i * 5}'));
        await tester.tap(level);
        await advance(tester, .7);
        expect(find.byKey(const ValueKey('town-canvas')), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'district $i');
        await tester.tap(find.byKey(const ValueKey('town-repeat-english')));
        await tester.pump();
        expect(audio.lastLanguage, GameLanguage.english);
        await tester.tap(find.byKey(const ValueKey('town-back')));
        await advance(tester, .5);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      progress.dispose();
      audio.dispose();
    });
  }
  testWidgets('all 30 scenes accept gestures and present their next story', (
    tester,
  ) async {
    final progress = TownProgress(), audio = GameAudioController.silent();
    final sound = TownAudio(audio, progress, native: false);
    await pumpTown(
      tester,
      TownPlayScreen(level: townLevels.first, progress: progress, sound: sound),
      const Size(390, 844),
    );
    for (final level in townLevels) {
      final finder = find.byKey(const ValueKey('town-canvas'));
      final rect = tester.getRect(finder),
          l = TownLayout(tester.getSize(finder));
      final model = sceneModel(tester);
      expect(model.level.id, level.id);
      Future<void> tap(Offset p) async {
        await tester.tapAt(rect.topLeft + p);
        await advance(tester, .25);
      }

      if (model.usesProps) {
        for (var i = 0; i < 3; i++) {
          if (i.isEven) {
            await tester.dragFrom(
              rect.topLeft + l.slot(i),
              l.actor - l.slot(i),
            );
            await advance(tester, .3);
          } else {
            await tap(l.slot(i));
            await tap(l.actor);
          }
        }
      } else if (level.play == TownPlay.catchToy) {
        for (var i = 0; i < 6; i++) {
          await tap(l.toy(i, model.time));
        }
      } else if (level.play == TownPlay.scrub) {
        for (var i = 0; i < 6; i++) {
          await tap(l.mark(i));
        }
      } else if (level.play == TownPlay.inflate) {
        final gesture = await tester.startGesture(rect.topLeft + l.actor);
        await advance(tester, 4);
        await gesture.up();
      } else {
        for (var i = 0; i < level.goal; i++) {
          await tap(level.play == TownPlay.music ? l.slot(i % 3) : l.actor);
        }
      }
      expect(model.finished, true, reason: level.title);
      await advance(tester, 4);
      expect(find.byKey(const ValueKey('town-next')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: level.title);
      if (level.id < 29) {
        await tester.tap(find.byKey(const ValueKey('town-next')));
        await tester.pump();
      }
    }
    expect(progress.completed.length, 30);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    sound.dispose();
    progress.dispose();
    audio.dispose();
  });
  testWidgets(
    'backgrounding cancels held input and pending narration; resume stays playable',
    (tester) async {
      final progress = TownProgress(),
          audio = GameAudioController.silent(),
          sound = TownAudio(
            GameAudioController.silent(),
            TownProgress(),
            native: false,
          );
      await pumpTown(
        tester,
        TownPlayScreen(level: townLevels[11], progress: progress, sound: sound),
        const Size(390, 844),
      );
      final rect = tester.getRect(find.byKey(const ValueKey('town-canvas'))),
          l = TownLayout(rect.size);
      final gesture = await tester.startGesture(rect.topLeft + l.actor);
      await advance(tester, .3);
      final model = sceneModel(tester), count = model.actionCount;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await advance(tester, 4);
      await gesture.up();
      expect(model.actionCount, count);
      expect(model.pressing, false);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await advance(tester, .3);
      await tester.tapAt(rect.topLeft + l.actor);
      await tester.pump();
      expect(model.actionCount, greaterThan(count));
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      sound.dispose();
      sound.voice.dispose();
      sound.progress.dispose();
      progress.dispose();
      audio.dispose();
    },
  );
}
