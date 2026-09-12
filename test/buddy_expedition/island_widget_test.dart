import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:color_hug/buddy_expedition/expedition_models.dart';
import 'package:color_hug/buddy_expedition/expedition_controller.dart';
import 'package:color_hug/buddy_expedition/expedition_world.dart';
import 'package:color_hug/game_audio.dart';
import 'package:color_hug/island_progress.dart';
import 'expedition_widget_test.dart' as h;

Future<void> tapTarget(WidgetTester t, String id) async {
  final m = h.observed(t);
  final target = m.chapterTargets.firstWhere((x) => x.id == id);
  await t.tapAt(h.screenPoint(t, target.at));
  await h.frames(t, .8);
}

Future<void> holdTarget(WidgetTester t, String id, double seconds) async {
  final target = h.observed(t).chapterTargets.firstWhere((x) => x.id == id);
  final gesture = await t.startGesture(h.screenPoint(t, target.at));
  await h.frames(t, seconds);
  await gesture.up();
  await h.frames(t, .5);
}

Future<void> clickRoad(WidgetTester t, double target, double seconds) async {
  await t.tapAt(
    h.screenPoint(t, Offset(target, h.observed(t).terrain(target) + 45)),
  );
  await h.frames(t, seconds);
}

Future<void> Function(WidgetTester, String)? onMilestone;
Future<void> milestone(WidgetTester t, String id) async {
  if (onMilestone != null) await onMilestone!(t, id);
}

Future<void> continueIsland(WidgetTester t) async {
  await h.holdRoad(t, true, 15);
  expect(h.observed(t).region, IslandRegion.orchard);
  await h.holdRoad(t, true, 5);
  expect(h.observed(t).carX, 535);
  await milestone(t, 'orchard-entry');
  await holdTarget(t, 'stone', 4);
  expect(h.observed(t).orchard.cleared, true);
  await h.holdRoad(t, true, 4.8);
  expect(h.observed(t).carX, greaterThan(980));
  expect(h.observed(t).carX, lessThan(1300));
  await tapTarget(t, 'tree');
  await h.frames(t, 2);
  for (var i = 0; i < 4; i++) {
    await tapTarget(t, 'apple-$i');
  }
  expect(h.observed(t).orchard.count, 4);
  await tapTarget(t, 'share');
  await tapTarget(t, 'basket');
  expect(h.observed(t).story.picnicReady, true);
  await milestone(t, 'orchard-complete');
  await h.holdRoad(t, true, 10);
  expect(h.observed(t).region, IslandRegion.cave);
  await h.holdRoad(t, true, 9);
  expect(h.observed(t).carX, 980);
  await milestone(t, 'cave-entry');
  await tapTarget(t, 'mural');
  await h.frames(t, 2);
  await tapTarget(t, 'lever');
  await h.frames(t, 2);
  await tapTarget(t, 'lamp');
  expect(h.observed(t).story.lampFound, true);
  await milestone(t, 'cave-complete');
  await h.holdRoad(t, true, 9);
  expect(h.observed(t).region, IslandRegion.bay);
  await h.holdRoad(t, true, 7);
  expect(h.observed(t).carX, 690);
  await tapTarget(t, 'perch');
  await h.frames(t, 2);
  expect(h.observed(t).bay.babyInBasket, true);
  await milestone(t, 'bay-rescue');
  await tapTarget(t, 'landing');
  await h.frames(t, 2);
  expect(h.observed(t).story.flyerRescued, true);
  await h.holdRoad(t, true, 9);
  expect(h.observed(t).carX, 1480);
  await tapTarget(t, 'rope');
  await h.frames(t, 4);
  await h.holdRoad(t, true, 3);
  await tapTarget(t, 'rope');
  await h.frames(t, 3);
  await milestone(t, 'sailing');
  await h.frames(t, 9);
  expect(h.observed(t).region, IslandRegion.valley);
  expect(h.observed(t).story.sailedHome, true);
  await h.holdRoad(t, false, 4);
  await h.frames(t, 3);
  expect(h.observed(t).story.celebrated, true);
  await milestone(t, 'reunion');
}

void main() {
  for (final size in [const Size(390, 844), const Size(844, 390)]) {
    testWidgets('旧断点向前到四区结局：真实手势 ${size.width}', (t) async {
      final p = IslandProgress()
        ..saveExpedition(
          const ValleyCheckpoint(
            carX: riverStop,
            bridge: true,
            logX: bridgeCenter,
            joined: true,
            riding: true,
          ),
        );
      final audio = GameAudioController.silent();
      await h.load(t, p, audio, size: size);
      await continueIsland(t);
      expect(t.takeException(), isNull);
      await t.tap(find.byKey(const ValueKey('expedition-map')));
      await h.frames(t, .5);
      expect(find.text('朋友们的旅行纪念'), findsOneWidget);
      await t.ensureVisible(find.byKey(const ValueKey('island-map-orchard')));
      await t.pump(const Duration(milliseconds: 100));
      await t.tap(find.byKey(const ValueKey('island-map-orchard')));
      await h.frames(t, 1);
      expect(h.observed(t).region, IslandRegion.orchard);
      expect(h.observed(t).orchard.cleared, true);
      await t.pumpWidget(const SizedBox());
      await t.pump();
      p.dispose();
      audio.dispose();
    });
  }
}
