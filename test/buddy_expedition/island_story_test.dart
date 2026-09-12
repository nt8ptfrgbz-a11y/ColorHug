import 'package:flutter_test/flutter_test.dart';
import 'package:color_hug/buddy_expedition/expedition_controller.dart';
import 'package:color_hug/buddy_expedition/expedition_models.dart';
import 'package:color_hug/buddy_expedition/expedition_world.dart';
import 'package:color_hug/buddy_expedition/chapters/bay_controller.dart';

void advance(ExpeditionController m, double seconds) {
  for (var i = 0; i < seconds * 60; i++) {
    m.update(1 / 60);
    m.takeEvents();
  }
}

void drive(ExpeditionController m, double x, double seconds) {
  m.drive(x, automatic: true);
  advance(m, seconds);
}

void tap(ExpeditionController m, String id) {
  final t = m.chapterTargets.firstWhere((v) => v.id == id);
  m.chapterDown(id, t.at);
  m.chapterUp(tapped: true);
  advance(m, .8);
}

void main() {
  test('上车后向右突破旧样章终点，四区主线、渡船、团聚和重访完整可玩', () {
    final m = ExpeditionController()
      ..restore(
        const ValleyCheckpoint(
          carX: riverStop,
          bridge: true,
          logX: bridgeCenter,
          joined: true,
          riding: true,
        ),
      );
    drive(m, 2250, 12);
    expect(m.region, IslandRegion.orchard);
    drive(m, 1800, 6);
    expect(m.carX, 535);
    m.chapterDown(
      'stone',
      m.chapterTargets.firstWhere((v) => v.id == 'stone').at,
    );
    advance(m, 4);
    m.chapterUp();
    expect(m.orchard.cleared, true);
    drive(m, 1170, 8);
    tap(m, 'tree');
    advance(m, 2);
    for (var i = 0; i < 4; i++) {
      tap(m, 'apple-$i');
    }
    expect(m.orchard.count, 4);
    tap(m, 'share');
    tap(m, 'basket');
    expect(m.story.picnicReady, true);
    drive(m, 1900, 8);
    expect(m.region, IslandRegion.cave);
    drive(m, 980, 9);
    tap(m, 'mural');
    advance(m, 2);
    expect(m.cave.revealed, 1);
    tap(m, 'lever');
    advance(m, 2);
    tap(m, 'lamp');
    expect(m.story.lampFound, true);
    drive(m, 1550, 7);
    expect(m.region, IslandRegion.bay);
    drive(m, 1000, 6);
    expect(m.carX, 690);
    tap(m, 'perch');
    advance(m, 2);
    expect(m.bay.babyInBasket, true);
    tap(m, 'landing');
    advance(m, 2);
    expect(m.story.flyerRescued, true);
    drive(m, 1450, 9);
    tap(m, 'rope');
    advance(m, 4);
    expect(m.bay.ferry, FerryPhase.docked);
    drive(m, 1670, 4);
    expect(m.bay.ferry, FerryPhase.boarded);
    tap(m, 'rope');
    advance(m, 12);
    expect(m.region, IslandRegion.valley);
    expect(m.story.sailedHome, true);
    drive(m, 260, 4);
    advance(m, 3);
    expect(m.story.celebrated, true);
    expect(m.story.memories, 1);
    expect(ValleyCheckpoint.fromJson(m.checkpoint().toJson()), isNotNull);
    for (final r in IslandRegion.values) {
      m.travel(r);
      advance(m, 1);
      expect(m.region, r);
      expect(m.story.celebrated, true);
    }
    m.replayStory();
    expect(m.story.celebrated, false);
    expect(m.story.memories, 1);
    m.dispose();
  });
  test('新旧存档兼容：旧的回营不当作全岛结局，新章节断点往返', () {
    final m = ExpeditionController();
    final old = const ValleyCheckpoint(
      bridge: true,
      logX: bridgeCenter,
      home: true,
      joined: true,
    ).toJson()..['v'] = 1;
    final loaded = ValleyCheckpoint.fromJson(old)!;
    m.restore(loaded);
    expect(m.home, true);
    expect(m.story.celebrated, false);
    expect(m.story.visited, {IslandRegion.valley});
    m.enterRegion(IslandRegion.orchard);
    advance(m, 1);
    final saved = m.checkpoint().toJson();
    final parsed = ValleyCheckpoint.fromJson(saved);
    expect(parsed, isNotNull);
    m.restore(parsed!);
    expect(m.region, IslandRegion.orchard);
    final bad = m.checkpoint().toJson();
    bad['adventure']['orchard']['apples'][0]['x'] = double.nan;
    expect(ValleyCheckpoint.fromJson(bad), isNull);
    m.dispose();
  });
  test('章节阻挡有提示且可后退，乘船中断恢复到安全甲板', () {
    final m = ExpeditionController()
      ..restore(
        const ValleyCheckpoint(
          bridge: true,
          logX: bridgeCenter,
          joined: true,
          riding: true,
        ),
      );
    m.enterRegion(IslandRegion.orchard);
    advance(m, 1);
    drive(m, 800, 7);
    expect(m.carX, 535);
    drive(m, 120, 5);
    expect(m.region, IslandRegion.valley);
    m.enterRegion(IslandRegion.bay);
    advance(m, 1);
    m.bay.rescued = true;
    m.bay.ferry = FerryPhase.sailing;
    final saved = m.checkpoint();
    m.restore(ValleyCheckpoint.fromJson(saved.toJson())!);
    expect(m.bay.ferry, FerryPhase.boarded);
    expect(m.carX, 1630);
    m.dispose();
  });
}
