import 'package:flutter_test/flutter_test.dart';
import 'package:color_hug/buddy_play/tiny_world/tiny_world_model.dart';

void main() {
  test('河水阻断导航，铅笔桥改变可达性，动物持续使用物品', () {
    final m = TinyWorldModel();
    expect(worldPath(41, 27, m.walkable), isEmpty);
    m.tool = 3;
    m.touch(44);
    expect(worldPath(41, 27, m.walkable), isNotEmpty);
    for (var i = 0; i < 1500; i++) {
      m.step(.05);
      m.takeEvents();
    }
    expect(m.objects.firstWhere((o) => o.kind == 3).bites, greaterThan(0));
    expect(m.animals.any((a) => a.visits > 1), true);
  });
  test('不能在动物脚下挖池塘，物品总数限制，损坏桥可重新导航', () {
    final m = TinyWorldModel();
    m.tool = 1;
    m.touch(41);
    expect(m.ground[41], isNot(2));
    m.tool = 2;
    for (var i = 0; i < 40; i++) {
      m.touch(i);
    }
    expect(m.objects.length, 12);
    final d = m.toJson();
    m.restore(d);
    expect(m.animals.length, 3);
    expect(m.animals.every((a) => m.walkable(a.cell)), true);
  });
}
