import 'package:flutter_test/flutter_test.dart';
import 'package:color_hug/buddy_expedition/expedition_controller.dart';
import 'package:color_hug/buddy_expedition/expedition_models.dart';
import 'package:color_hug/buddy_expedition/expedition_journal.dart';
import 'package:color_hug/buddy_expedition/expedition_world.dart';

void main() {
  test('一个章节的数据损坏不清空其他章节的完成事实', () {
    final m = ExpeditionController()
      ..restore(
        const ValleyCheckpoint(
          bridge: true,
          logX: bridgeCenter,
          joined: true,
          riding: true,
        ),
      );
    m.story.rockCleared = true;
    m.story.picnicReady = true;
    m.story.caveOpen = true;
    m.story.lampFound = true;
    m.enterRegion(IslandRegion.bay);
    final data = m.checkpoint().toJson();
    data['adventure']['orchard']['stone'] = 'broken';
    expect(ValleyCheckpoint.fromJson(data), isNull);
    final j = ExpeditionJournal()..merge(data);
    m.restore(j.checkpoint);
    expect(m.region, IslandRegion.bay);
    expect(m.story.lampFound, true);
    expect(m.story.picnicReady, true);
    expect(m.orchard.cleared, true);
    m.dispose();
  });
  test('新编辑不能被迟到的旧样章读取覆盖', () {
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
    final j = ExpeditionJournal()..save(m.checkpoint());
    j.merge(const ValleyCheckpoint().toJson());
    expect(j.checkpoint.adventure!['region'], 'orchard');
    m.dispose();
  });
}
