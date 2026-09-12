import 'dart:math' as math;
import '../../game_audio.dart';
import '../buddy_play_session.dart';

class WaterModel extends ToyModel {
  int scene = 0;
  List<int> pipes = [0, 0, 0];
  bool gate = true, plug = true, running = false;
  double tank = 0, bucket = 0, wheel = 0, clock = 0, tip = 0, duck = 0;
  bool duckMoving = false;
  int splashes = 0;
  List<int> get target => const [
    [0, 1, 2],
    [1, 2, 3],
    [2, 3, 0],
  ][scene];
  int get connected {
    var count = 0;
    for (var i = 0; i < 3; i++) {
      if (pipes[i] != target[i]) break;
      count++;
    }
    return count;
  }

  bool get supply => running && gate;
  bool get reachesTank => supply && connected == 3;
  double get outflow => !plug && tank > 0 ? .22 : 0;
  void tapPipe(int i) {
    pipes[i] = (pipes[i] + 1) % 4;
    event('turn', '转一下，让水管接起来', phrase: 'Turn the pipe!', sound: GameSound.tap);
  }

  void faucet() {
    running = !running;
    event(
      running ? 'water' : 'close',
      running ? '水来了！' : '关好水龙头',
      phrase: running ? 'Water!' : 'Close the tap!',
      sound: running ? GameSound.splash : null,
    );
  }

  void toggleGate() {
    gate = !gate;
    event(
      gate ? 'open' : 'close',
      gate ? '打开闸门' : '关上闸门',
      phrase: gate ? 'Open the gate!' : 'Close the gate!',
    );
  }

  void togglePlug() {
    plug = !plug;
    event(
      plug ? 'close' : 'flow',
      plug ? '塞好塞子，收集水' : '拔开塞子，水流向水车',
      phrase: plug ? 'Close it!' : 'Let it flow!',
      sound: GameSound.splash,
    );
  }

  void releaseDuck() {
    if (!duckMoving) {
      duck = 0;
      duckMoving = true;
      event('duck', '小鸭准备出发，给它一点流水', phrase: 'Hello, duck!');
    }
  }

  void preset(int n) {
    scene = n;
    pipes = [target[0], (target[1] + 1) % 4, (target[2] + 2) % 4];
    tank = 0;
    bucket = 0;
    tip = 0;
    running = false;
    duckMoving = false;
    duck = 0;
    gate = true;
    plug = true;
  }

  @override
  void step(double dt) {
    clock += dt;
    tip = math.max(0, tip - dt);
    final incoming = reachesTank ? .18 : 0.0;
    final old = tank;
    final available = (tank + incoming * dt).clamp(0.0, 1.0);
    final drained = plug ? 0.0 : math.min(available, .22 * dt);
    final outgoing = dt > 0 ? drained / dt : 0.0;
    tank = available - drained;
    if (old < .98 && tank >= .98) {
      event('full', '水槽满啦，拔开塞子试试', phrase: 'It is full!', discovery: 'full');
    }
    if (old > 0 && tank == 0 && !plug) {
      event('empty', '水槽空了，再装一次吧', phrase: 'It is empty!', discovery: 'empty');
    }
    if (outgoing > 0) {
      wheel += dt * 3;
      bucket = (bucket + drained).clamp(0.0, 1.0);
    }
    if (bucket >= 1) {
      bucket = 0;
      tip = 1.6;
      splashes++;
      event(
        'full',
        '哗啦！满桶翻倒啦',
        phrase: 'Splash! A full bucket!',
        sound: GameSound.splash,
        discovery: 'bucket-$scene',
      );
    }
    if (duckMoving) {
      if (duck < .38 && outgoing > 0) {
        duck += dt * .11;
      } else if (duck >= .38 && duck < .41) {
        duck = .41;
      } else if (tip > 0) {
        duck += dt * .5;
      }
      if (duck >= 1) {
        duck = 1;
        duckMoving = false;
        event(
          'duck',
          '小鸭滑到水池啦！',
          phrase: 'The duck is happy!',
          sound: GameSound.correct,
          discovery: 'duck-$scene',
        );
      }
    }
  }

  @override
  void pause() {
    running = false;
  }

  @override
  Map<String, dynamic> toJson() => {
    'v': 1,
    'scene': scene,
    'pipes': pipes,
    'gate': gate,
    'plug': plug,
  };
  @override
  void restore(Map<String, dynamic> d) {
    scene = d['scene'];
    pipes = List<int>.from(d['pipes']);
    gate = d['gate'];
    plug = d['plug'];
    running = false;
    tank = 0;
    bucket = 0;
    duck = 0;
    duckMoving = false;
    tip = 0;
  }
}
