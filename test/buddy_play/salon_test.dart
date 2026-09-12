import 'package:flutter_test/flutter_test.dart';
import 'package:color_hug/buddy_play/salon/salon_model.dart';

void main() {
  test('剪发按空间接触，泡泡恢复，三位客人造型独立', () {
    final m = SalonModel();
    final before = List.of(m.look.lengths);
    m.touch(const Offset(.02, .95));
    expect(m.look.lengths, before);
    m.touch(const Offset(.5, .32));
    expect(m.look.lengths[5], lessThan(before[5]));
    expect(m.look.lengths[0], before[0]);
    m.tool = 3;
    m.touch(const Offset(.5, .34));
    expect(m.look.lengths[5], greaterThan(.1));
    final data = m.toJson();
    m.next();
    m.restore(data);
    expect(m.guest, 0);
    expect(m.look.lengths[0], before[0]);
  });
}
