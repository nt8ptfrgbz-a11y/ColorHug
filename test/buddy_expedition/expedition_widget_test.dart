import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:color_hug/buddy_expedition/expedition_screen.dart';
import 'package:color_hug/buddy_expedition/expedition_scene.dart';
import 'package:color_hug/buddy_expedition/expedition_controller.dart';
import 'package:color_hug/buddy_expedition/expedition_models.dart';
import 'package:color_hug/game_audio.dart';
import 'package:color_hug/island_progress.dart';

Future<void> Function(WidgetTester)? frameCapture;

Future<void> frames(WidgetTester t, double seconds) async {
  for (var i = 0; i < (seconds * 30).ceil(); i++) {
    await t.pump(const Duration(milliseconds: 33));
    if (frameCapture != null) await frameCapture!(t);
  }
}

ExpeditionScene painter(WidgetTester t) => t
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((w) => w.painter)
    .whereType<ExpeditionScene>()
    .single;
ExpeditionController observed(WidgetTester t) => painter(t).model;
Offset screenPoint(WidgetTester t, Offset world) {
  final box = t.getRect(find.byKey(const ValueKey('expedition-world')));
  return box.topLeft +
      ValleyView(
        box.size,
        observed(t).cameraX,
        region: observed(t).region,
      ).toScreen(world);
}

Future<void> load(
  WidgetTester t,
  IslandProgress p,
  GameAudioController a, {
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  await t.runAsync(
    () => t.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: ExpeditionScreen(progress: p, audio: a),
        ),
      ),
    ),
  );
  await t.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 400)),
  );
  await t.pump();
  for (
    var i = 0;
    i < 20 && find.byKey(const ValueKey('expedition-world')).evaluate().isEmpty;
    i++
  ) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await t.pump();
  }
  expect(find.byKey(const ValueKey('expedition-world')), findsOneWidget);
}

Future<void> holdRoad(WidgetTester t, bool right, double seconds) async {
  final box = t.getRect(find.byKey(const ValueKey('expedition-world')));
  final view = ValleyView(
    box.size,
    observed(t).cameraX,
    region: observed(t).region,
  );
  final touch = await t.startGesture(
    box.topLeft +
        Offset(box.width * (right ? .91 : .08), view.horizon + 35 * view.scale),
  );
  await frames(t, seconds);
  await touch.up();
  await frames(t, .8);
}

Future<void> grabBridge(WidgetTester t) async {
  await t.tapAt(screenPoint(t, observed(t).logPosition));
  await frames(t, .3);
  expect(observed(t).logPlace, LogPlace.hook);
  await t.tapAt(screenPoint(t, const Offset(bridgeCenter, -20)));
  await frames(t, 1.2);
  expect(observed(t).bridge, true);
}

void main() {
  testWidgets('真实一指完整旅程和续玩，不使用模型指令推进', (t) async {
    final p = IslandProgress(), a = GameAudioController.silent();
    await load(t, p, a);
    await holdRoad(t, true, 16);
    expect(observed(t).carX, riverStop);
    await grabBridge(t);
    await frames(t, 10);
    await t.tapAt(
      screenPoint(
        t,
        Offset(observed(t).dinoX, roadHeight(observed(t).dinoX) - 65),
      ),
    );
    await frames(t, 2);
    expect(observed(t).dino, DinoAction.riding);
    await holdRoad(t, false, 18);
    expect(observed(t).home, true);
    await frames(t, .5);
    expect(p.expeditionJournal.checkpoint.home, true);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await t.pump();
    await load(t, p, a);
    expect(observed(t).home, true);
    await t.pumpWidget(const SizedBox());
    await t.pump();
    p.dispose();
    a.dispose();
  });
  testWidgets('真实拖动吊木，取消安全恢复，第二指不夺走物品', (t) async {
    final p = IslandProgress()
      ..saveExpedition(const ValleyCheckpoint(carX: riverStop));
    final a = GameAudioController.silent();
    await load(t, p, a);
    await frames(t, 2);
    final g = await t.startGesture(
      screenPoint(t, observed(t).logPosition),
      pointer: 1,
    );
    await frames(t, .2);
    expect(observed(t).logPlace, LogPlace.hook);
    final other = await t.startGesture(const Offset(300, 680), pointer: 2);
    await other.up();
    expect(observed(t).logPlace, LogPlace.hook);
    await g.moveTo(screenPoint(t, const Offset(1355, -170)));
    await frames(t, .4);
    await g.cancel();
    await frames(t, .5);
    expect(observed(t).logPlace, LogPlace.bank);
    expect(observed(t).bridge, false);
    final drag = await t.startGesture(screenPoint(t, observed(t).logPosition));
    await drag.moveTo(screenPoint(t, const Offset(1355, -25)));
    await frames(t, .5);
    await drag.up();
    await frames(t, .5);
    expect(observed(t).bridge, true);
    await t.pumpWidget(const SizedBox());
    await t.pump();
    p.dispose();
    a.dispose();
  });
  for (final size in [
    const Size(320, 568),
    const Size(844, 390),
    const Size(1024, 768),
  ]) {
    testWidgets('画面和大字体 ${size.width}×${size.height}', (t) async {
      final p = IslandProgress(), a = GameAudioController.silent();
      await load(t, p, a, size: size, textScale: 1.5);
      await frames(t, .2);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await t.pump();
      p.dispose();
      a.dispose();
    });
  }
}
