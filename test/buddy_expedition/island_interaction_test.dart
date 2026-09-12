import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:color_hug/buddy_expedition/expedition_models.dart';
import 'package:color_hug/buddy_expedition/expedition_world.dart';
import 'package:color_hug/buddy_expedition/chapters/orchard_controller.dart';
import 'package:color_hug/buddy_expedition/chapters/cave_controller.dart';
import 'package:color_hug/buddy_expedition/chapters/bay_controller.dart';
import 'package:color_hug/game_audio.dart';
import 'package:color_hug/island_progress.dart';
import 'expedition_widget_test.dart' as h;

void main() {
  test('物品放错可取回、推石保留进度、灯光必须真正照中目标', () {
    final o = OrchardController();
    o.beginPush();
    o.step(1);
    o.stop();
    final x = o.stoneX;
    o.step(2);
    expect(o.stoneX, x);
    expect(o.cleared, false);
    o.held = 0;
    o.moveApple(const Offset(990, -50));
    expect(o.storeApple(), false);
    expect(o.count, 0);
    o.held = 0;
    o.moveApple(OrchardController.basket);
    expect(o.storeApple(), true);
    expect(o.feed(), true);
    expect(o.loadBasket(), false);
    final c = CaveController();
    c.aim(const Offset(400, -250));
    for (var i = 0; i < 180; i++) {
      c.step(1 / 60, const Offset(700, -90));
    }
    expect(c.revealed, 0);
    c.pull(1);
    expect(c.opened, false);
    c.aim(CaveController.carving);
    for (var i = 0; i < 180; i++) {
      c.step(1 / 60, const Offset(700, -90));
    }
    expect(c.revealed, 1);
    c.pull(1);
    expect(c.opened, true);
  });
  test('吊篮要停靠接到伙伴再回岸，取消不能假救援，渡船未靠岸不能登船', () {
    final b = BayController();
    expect(b.embark(1630), false);
    b.grab();
    b.move(BayController.perch);
    for (var i = 0; i < 130; i++) {
      b.step(1 / 60);
    }
    expect(b.babyInBasket, true);
    b.cancel();
    expect(b.rescued, false);
    expect(b.babyInBasket, false);
    b.grab();
    b.move(BayController.perch);
    for (var i = 0; i < 130; i++) {
      b.step(1 / 60);
    }
    b.move(BayController.landing);
    for (var i = 0; i < 90; i++) {
      b.step(1 / 60);
    }
    expect(b.drop(), true);
    b.callBoat();
    for (var i = 0; i < 240; i++) {
      b.step(1 / 60);
    }
    expect(b.embark(1500), false);
    expect(b.embark(1630), true);
    b.sail();
    final saved = b.toJson();
    b.restore(saved);
    expect(b.ferry, FerryPhase.boarded);
  });
  testWidgets('暂停菜单在系统恢复后仍暂停，关闭菜单才继续', (t) async {
    final p = IslandProgress(), a = GameAudioController.silent();
    await h.load(t, p, a);
    await t.tap(find.byKey(const ValueKey('expedition-pause')));
    await h.frames(t, .5);
    expect(h.observed(t).paused, true);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    expect(h.observed(t).paused, true);
    await t.tap(find.text('继续探险'));
    await h.frames(t, .5);
    expect(h.observed(t).paused, false);
    await t.pumpWidget(const SizedBox());
    await t.pump();
    p.dispose();
    a.dispose();
  });
  testWidgets('上车动画期间按住道路，坐稳后可以继续向右开', (t) async {
    final p = IslandProgress()
      ..saveExpedition(
        const ValleyCheckpoint(
          carX: riverStop,
          bridge: true,
          logX: bridgeCenter,
        ),
      );
    final a = GameAudioController.silent();
    await h.load(t, p, a);
    await h.frames(t, 10);
    final m = h.observed(t);
    await t.tapAt(h.screenPoint(t, Offset(m.dinoX, m.terrain(m.dinoX) - 65)));
    await t.pump();
    expect(m.dino, DinoAction.boarding);
    await h.holdRoad(t, true, 3);
    expect(m.carX, greaterThan(riverStop));
    expect(m.region, IslandRegion.valley);
    await t.pumpWidget(const SizedBox());
    await t.pump();
    p.dispose();
    a.dispose();
  });
}
