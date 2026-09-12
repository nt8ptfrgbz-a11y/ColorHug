import 'package:flutter_test/flutter_test.dart';
import 'package:color_hug/buddy_play/sound_train/sound_train_model.dart';

void main() {
  test('声音按车厢过门顺序触发，换序真实改变声音，停止不会残响', () {
    final m = SoundTrainModel();
    m.swap(0, 3);
    m.start();
    m.takeEvents();
    final heard = [];
    for (var i = 0; i < 160; i++) {
      m.step(.05);
      for (final e in m.takeEvents()) {
        if (e.word.isEmpty && e.sound != null) heard.add(e.sound);
      }
    }
    expect(heard, m.cars.map((v) => trainSounds[v]).toList());
    expect(m.completed, 1);
    m.scene = 1;
    m.start();
    m.takeEvents();
    for (var i = 0; i < 41; i++) {
      m.step(.05);
      m.takeEvents();
    }
    m.stop();
    m.step(1);
    expect(m.takeEvents(), isEmpty);
  });
}
