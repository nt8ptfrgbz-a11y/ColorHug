import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:color_hug/buddy_expedition/expedition_models.dart';
import 'package:color_hug/buddy_expedition/expedition_controller.dart';
import 'package:color_hug/buddy_models.dart';
import 'package:color_hug/game_audio.dart';
import 'package:color_hug/island_progress.dart';
import 'expedition_widget_test.dart' as helper;

void main() {
  test('每个稳定检查点往返持久化，损坏样章不影响旧作品', () async {
    final previous = SharedPreferencesAsyncPlatform.instance;
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    addTearDown(() => SharedPreferencesAsyncPlatform.instance = previous);
    final p = IslandProgress.persistent();
    await p.ready;
    p.saveJuiceRecipe(JuiceRecipe(['apple']));
    p.dressBuddy(color: 2);
    for (final checkpoint in [
      const ValleyCheckpoint(),
      const ValleyCheckpoint(carX: riverStop, mud: .7),
      const ValleyCheckpoint(carX: riverStop, bridge: true, logX: bridgeCenter),
      const ValleyCheckpoint(
        carX: 700,
        bridge: true,
        logX: bridgeCenter,
        joined: true,
        riding: true,
      ),
      const ValleyCheckpoint(
        carX: 260,
        bridge: true,
        logX: bridgeCenter,
        joined: true,
        home: true,
      ),
    ]) {
      p.saveExpedition(checkpoint);
      await p.ready;
      final restored = IslandProgress.persistent();
      await restored.ready;
      expect(
        restored.expeditionJournal.checkpoint.toJson(),
        checkpoint.toJson(),
      );
      expect(restored.buddyColor, 2);
      expect(restored.juiceRecipes.length, 1);
      restored.dispose();
    }
    await SharedPreferencesAsync().setString(
      'color_hug.river_valley_v1',
      'broken',
    );
    final recovered = IslandProgress.persistent();
    await recovered.ready;
    expect(recovered.expeditionJournal.checkpoint.home, false);
    expect(recovered.buddyColor, 2);
    expect(recovered.juiceRecipes.length, 1);
    recovered.dispose();
    p.dispose();
  });
  test('完成后可以再次带伙伴出游，恢复乘车关系，再回家能下车', () {
    final m = ExpeditionController()
      ..restore(
        const ValleyCheckpoint(
          bridge: true,
          logX: bridgeCenter,
          home: true,
          joined: true,
        ),
      );
    m.interactDino();
    for (var i = 0; i < 150; i++) {
      m.update(1 / 60);
    }
    expect(m.dino, DinoAction.riding);
    m.drive(700, automatic: true);
    for (var i = 0; i < 400; i++) {
      m.update(1 / 60);
    }
    final saved = m.checkpoint();
    expect(saved.riding, true);
    m.restore(saved);
    expect(m.dino, DinoAction.riding);
    m.drive(260, automatic: true);
    for (var i = 0; i < 650; i++) {
      m.update(1 / 60);
    }
    expect(m.dino, DinoAction.home);
    m.dispose();
  });
  testWidgets('拖木时进入后台不误建桥，静音恢复仍能操作', (t) async {
    final p = IslandProgress()
      ..saveExpedition(const ValleyCheckpoint(carX: riverStop));
    final a = GameAudioController.silent();
    await helper.load(t, p, a);
    await helper.frames(t, 2);
    final g = await t.startGesture(
      helper.screenPoint(t, helper.observed(t).logPosition),
    );
    await g.moveTo(helper.screenPoint(t, const Offset(bridgeCenter, -25)));
    await helper.frames(t, .4);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await helper.frames(t, 3);
    expect(helper.observed(t).bridge, false);
    expect(helper.observed(t).paused, true);
    await g.cancel();
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    final muted = a.toggle();
    await t.pump(const Duration(milliseconds: 50));
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await t.pump(const Duration(milliseconds: 50));
    await muted;
    final before = a.lastSpokenText;
    await helper.grabBridge(t);
    expect(a.lastSpokenText, before);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    await t.pump();
    p.dispose();
    a.dispose();
  });
}
