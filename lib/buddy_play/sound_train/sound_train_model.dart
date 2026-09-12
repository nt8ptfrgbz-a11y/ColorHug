import '../../game_audio.dart';
import '../buddy_play_session.dart';

const trainSounds = [
  GameSound.frog,
  GameSound.drum,
  GameSound.cat,
  GameSound.bell,
];
const trainWords = ['frog', 'drum', 'cat', 'bell'];

class SoundTrainModel extends ToyModel {
  List<int> cars = [0, 1, 2, 3];
  int speed = 1, scene = 0, selected = 0, active = -1, completed = 0;
  bool playing = false;
  double clock = 0, travel = 0, flash = 0, echo = -1;
  int nextNote = 0, echoCar = 0;
  double get interval => const [1.1, .8, .58][speed];
  double carX(int i) => .95 + i * .18 - travel * .18;
  void choose(int role) {
    selected = role;
    event(
      trainWords[role],
      const ['青蛙的呱呱声', '咚咚小鼓', '小猫喵喵', '叮叮铃铛'][role],
      sound: trainSounds[role],
    );
  }

  void add() {
    stop();
    if (cars.length < 6) {
      cars.add(selected);
      event(trainWords[selected], '加上一节声音车厢');
    }
  }

  void setCar(int index) {
    stop();
    cars[index] = selected;
    event(trainWords[selected], '车厢声音换好了');
  }

  void swap(int a, int b) {
    stop();
    if (a == b) return;
    final temp = cars[a];
    cars[a] = cars[b];
    cars[b] = temp;
  }

  void remove() {
    stop();
    if (cars.length > 2) cars.removeLast();
  }

  void start() {
    playing = true;
    travel = 0;
    nextNote = 0;
    active = -1;
    flash = 0;
    echo = -1;
    event('train', '火车准备出发！', phrase: 'All aboard!');
  }

  void stop() {
    playing = false;
    active = -1;
    echo = -1;
    flash = 0;
  }

  void changeSpeed() {
    stop();
    speed = (speed + 1) % 3;
    event(
      speed == 2 ? 'fast' : 'slow',
      speed == 2 ? '快快的小游行' : '慢慢地听声音',
      phrase: speed == 2 ? "Let's go fast." : "Let's go slowly.",
    );
  }

  void preset() {
    stop();
    scene = (scene + 1) % 3;
    cars = const [
      [0, 1, 2, 3],
      [3, 0, 3, 2],
      [3, 1, 3, 1],
    ][scene].toList();
    speed = scene == 2 ? 0 : 1;
  }

  @override
  void step(double dt) {
    clock += dt;
    flash = (flash - dt).clamp(0.0, 1.0);
    if (!playing) return;
    travel += dt / interval;
    if (echo >= 0) {
      echo -= dt;
      if (echo < 0) event('', '', sound: trainSounds[echoCar]);
    }
    // The gate is x=.50; each car triggers exactly as it crosses.
    if (nextNote < cars.length && travel >= 2.5 + nextNote) {
      active = nextNote;
      flash = .35;
      event('', '', sound: trainSounds[cars[nextNote]]);
      if (scene == 1) {
        echo = .16;
        echoCar = cars[nextNote];
      }
      nextNote++;
    }
    if (travel >= cars.length + 3.5) {
      playing = false;
      active = -1;
      echo = -1;
      completed++;
      event(
        'again',
        '到站啦！换个顺序再听一遍',
        phrase: 'Again?',
        sound: GameSound.complete,
        discovery: 'song-$scene',
      );
    }
  }

  @override
  void pause() => stop();
  @override
  Map<String, dynamic> toJson() => {
    'v': 1,
    'cars': cars,
    'speed': speed,
    'scene': scene,
  };
  @override
  void restore(Map<String, dynamic> d) {
    cars = List<int>.from(d['cars']);
    speed = d['speed'];
    scene = d['scene'];
    travel = 0;
    stop();
  }
}
