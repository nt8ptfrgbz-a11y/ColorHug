import 'package:flutter_test/flutter_test.dart';
import 'package:color_hug/buddy_expedition/expedition_controller.dart';
import 'package:color_hug/buddy_expedition/expedition_models.dart';
import 'package:color_hug/buddy_expedition/expedition_journal.dart';

void advance(ExpeditionController m, double seconds) {
  for (var i = 0; i < (seconds * 60).ceil(); i++) {
    m.update(1 / 60);
    m.takeEvents();
  }
}

void main() {
  test('完整旅程：安全停河岸，吊木搭桥，恐龙过桥上车再回营地', () {
    final m = ExpeditionController();
    m.drive(1800, automatic: true);
    advance(m, 12);
    expect(m.carX, riverStop);
    expect(m.velocity, 0);
    expect(m.secrets, contains('mud'));
    expect(m.pickLog(), true);
    m.moveHook(const Offset(bridgeCenter, -70));
    advance(m, 1);
    expect(m.snapReady, true);
    m.putLog();
    expect(m.bridge, true);
    advance(m, 10);
    expect((m.dinoX - m.carX).abs(), lessThan(200));
    m.interactDino();
    advance(m, 2);
    expect(m.dino, DinoAction.riding);
    m.drive(campX, automatic: true);
    advance(m, 12);
    expect(m.home, true);
    expect(ValleyCheckpoint.fromJson(m.checkpoint().toJson()), isNotNull);
    m.dispose();
  });
  test('错误释放和取消不丢木头，点选也会平滑放桥，桥被占用不可拆', () {
    final m = ExpeditionController()
      ..restore(const ValleyCheckpoint(carX: riverStop));
    expect(m.pickLog(), true);
    m.moveHook(const Offset(1355, -280));
    advance(m, 1);
    m.putLog();
    expect(m.bridge, false);
    expect(m.logX, 1205);
    m.pickLog();
    m.placeAt(const Offset(bridgeCenter, -19));
    advance(m, 1);
    expect(m.bridge, true);
    m.carX = bridgeCenter;
    expect(m.pickLog(), false);
    m.pause();
    final x = m.carX;
    advance(m, 5);
    expect(m.carX, x);
    m.dispose();
  });
  test('存档拒绝损坏和矛盾事实，不保存瞬时抓取且保留新修改', () {
    final m = ExpeditionController()
      ..restore(const ValleyCheckpoint(carX: riverStop));
    m.pickLog();
    advance(m, .2);
    final save = m.checkpoint();
    expect(save.bridge, false);
    expect(save.logX, 1205);
    final j = ExpeditionJournal();
    j.save(save);
    j.merge(const ValleyCheckpoint().toJson());
    expect(j.checkpoint.carX, riverStop);
    expect(
      ValleyCheckpoint.fromJson({...save.toJson(), 'car': double.nan}),
      isNull,
    );
    expect(
      ValleyCheckpoint.fromJson({
        ...save.toJson(),
        'home': true,
        'joined': false,
      }),
      isNull,
    );
    expect(ValleyCheckpoint.fromJson({...save.toJson(), 'car': 1350}), isNull);
    m.dispose();
  });
}
