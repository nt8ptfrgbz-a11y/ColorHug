import 'package:flutter_test/flutter_test.dart';
import 'package:color_hug/buddy_play/rolling/rolling_model.dart';

void main() {
  test('机关真实作用，变大卡管可救出，设计快照不受运行中修改影响', () {
    final m = RollingModel()..parts = [1, 2, 4];
    m.launch();
    m.parts[0] = 0;
    for (var i = 0; i < 140; i++) {
      m.step(.05);
      m.takeEvents();
    }
    expect(m.balls.single.big, true);
    expect(m.balls.single.duck, true);
    expect(m.balls.single.stuck, true);
    m.rescue();
    for (var i = 0; i < 60; i++) {
      m.step(.05);
      m.takeEvents();
    }
    expect(m.landed, 1);
    expect(m.balls, isEmpty);
  });
  test('小球数量有上限，暂停与恢复设计安全', () {
    final m = RollingModel();
    for (var i = 0; i < 20; i++) {
      m.launch();
    }
    expect(m.balls.length, 5);
    m.pause();
    m.step(1);
    expect(m.balls.first.t, 0);
    final d = m.toJson();
    m.restore(d);
    expect(m.balls, isEmpty);
    expect(m.parts, [0, 4, 3]);
  });
}
