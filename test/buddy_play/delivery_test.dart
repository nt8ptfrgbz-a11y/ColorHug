import 'package:flutter_test/flutter_test.dart';
import 'package:color_hug/buddy_play/delivery/delivery_model.dart';

void main() {
  test('配送必须装正确包裹并通过设施，礼物保存和重访', () {
    final m = DeliveryModel();
    m.load(1);
    expect(m.stage, DeliveryStage.loading);
    m.load(0);
    m.drive(true);
    for (var i = 0; i < 100; i++) {
      m.step(.05);
    }
    expect(m.obstacle, 'wash');
    for (var i = 0; i < 4; i++) {
      m.wash();
    }
    for (var i = 0; i < 80; i++) {
      m.step(.05);
    }
    expect(m.obstacle, 'boat');
    m.sail();
    for (var i = 0; i < 140; i++) {
      m.step(.05);
    }
    expect(m.obstacle, 'bridge');
    m.liftBridge();
    for (var i = 0; i < 150; i++) {
      m.step(.05);
    }
    expect(m.stage, DeliveryStage.doorstep);
    m.deliver();
    for (var i = 0; i < 40; i++) {
      m.step(.05);
    }
    expect(m.gifts[0], true);
    final d = m.toJson();
    m.next();
    m.restore(d);
    expect(m.stage, DeliveryStage.home);
  });
}
