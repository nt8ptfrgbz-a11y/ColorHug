import 'package:flutter_test/flutter_test.dart';
import 'package:color_hug/buddy_play/squishy/squishy_model.dart';

void main() {
  test('局部拉伸不是整体缩放，松手回弹，五官限制在身体内', () {
    final m = SquishyModel();
    m.down(const Offset(.78, .54));
    m.move(const Offset(.95, .4));
    expect(m.points[0].dx, greaterThan(.85));
    expect(m.points[10], m.rest[10]);
    m.release();
    for (var i = 0; i < 500; i++) {
      m.step(.016);
    }
    expect((m.points[0] - m.rest[0]).distance, lessThan(.001));
    m.tool = 4;
    m.down(m.face[0]);
    m.move(const Offset(0, 1));
    m.release();
    expect(m.face[0], const Offset(.32, .68));
  });
}
