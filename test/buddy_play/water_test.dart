import 'package:flutter_test/flutter_test.dart';
import 'package:color_hug/buddy_play/water/water_model.dart';

void main() {
  test('水路必须连通，闸门控制供水，拔塞后才驱动水车翻桶送鸭', () {
    final m = WaterModel()..running = true;
    m.step(.5);
    expect(m.tank, 0);
    m.pipes = List.of(m.target);
    for (var i = 0; i < 120; i++) {
      m.step(.05);
      m.takeEvents();
    }
    expect(m.tank, 1);
    expect(m.wheel, 0);
    m.togglePlug();
    m.releaseDuck();
    for (var i = 0; i < 240; i++) {
      m.step(.05);
      m.takeEvents();
    }
    expect(m.splashes, greaterThan(0));
    expect(m.duck, 1);
    m.gate = false;
    for (var i = 0; i < 150; i++) {
      m.step(.05);
    }
    expect(m.tank, 0);
    final wheel = m.wheel;
    m.step(1);
    expect(m.wheel, wheel);
  });
}
