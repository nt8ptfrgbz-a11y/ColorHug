import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'expedition_models.dart';

class ExpeditionController extends ChangeNotifier {
  double time = 0,
      carX = campX,
      velocity = 0,
      wheelAngle = 0,
      suspension = 0,
      suspensionSpeed = 0,
      carTilt = 0;
  double cameraX = campX + 110,
      mud = 0,
      dinoX = 1615,
      dinoWalk = 0,
      dinoMood = 0,
      boarding = 0;
  double logX = 1205, logY = -27, logAngle = 0, logSwing = 0;
  double fruitX = 760, fruitY = -28, fruitV = 0, fruitRotation = 0;
  bool fruitCarried = false,
      fed = false,
      joined = false,
      home = false,
      paused = false,
      autoDrive = false;
  LogPlace logPlace = LogPlace.bank;
  DinoAction dino = DinoAction.waiting;
  Offset hook = const Offset(campX + 55, -140),
      hookTarget = const Offset(campX + 55, -140);
  ExpeditionInput input = ExpeditionInput.none;
  double? driveTarget;
  double _accumulator = 0,
      _grip = 0,
      _particleWait = 0,
      _horn = 0,
      _hintIdle = 0,
      _savedDistance = campX;
  double _lastLogBank = 1205, _landBounce = 0;
  bool _awayFromCamp = false;
  bool _changed = false, _bridgeExplained = false, _autoPlace = false;
  int revision = 0;
  final Set<String> secrets = {};
  final List<ExpeditionEvent> _events = [];
  final List<ValleyParticle> particles = [];
  final Map<String, double> _eventAt = {};
  final math.Random _random = math.Random(91);
  bool get bridge => logPlace == LogPlace.bridge;
  bool get nearRiver => carX > 920 && carX < 1660;
  bool get riverWork =>
      nearRiver &&
      velocity.abs() < 18 &&
      dino != DinoAction.boarding &&
      dino != DinoAction.alighting;
  bool get bridgeOccupied =>
      (carX > riverLeft - 105 && carX < riverRight + 105) ||
      (dino != DinoAction.riding &&
          dinoX > riverLeft - 35 &&
          dinoX < riverRight + 35);
  Offset get craneBase =>
      Offset(carX - 40, roadHeight(carX) - 110 + suspension);
  Offset get logPosition => Offset(logX, logY);
  Offset get fruitPosition => fruitCarried
      ? Offset(carX - 60, roadHeight(carX) - 97)
      : Offset(fruitX, fruitY);
  String get hint => home
      ? '想去哪里，就点点那边的路。朋友还想和你玩。'
      : joined
      ? '慢慢开回左边的营地吧，也可以继续探索。'
      : bridge
      ? '小恐龙过来啦！停稳后点它，邀请上车。'
      : carX > 900
      ? '把木头提起来，放到河的两边。'
      : carX > 420
      ? '按住前面的路开车，松手停。泥坑也可以玩！'
      : '点点小车打招呼，再按住右边的路出发。';
  String get chapter => home
      ? '我们的河谷'
      : joined
      ? '一起回家'
      : bridge
      ? '新朋友'
      : carX > 900
      ? '河边的木头'
      : '第一趟探险';
  List<ExpeditionEvent> takeEvents() {
    final result = List.of(_events);
    _events.clear();
    return result;
  }

  void emit(
    String id,
    String english,
    String chinese, {
    String? sound,
    bool important = false,
    double cooldown = 5,
  }) {
    if (time - (_eventAt[id] ?? -100) < cooldown) return;
    _eventAt[id] = time;
    if (_events.length < 12) {
      _events.add(
        ExpeditionEvent(
          id,
          english,
          chinese,
          sound: sound,
          important: important,
        ),
      );
    }
  }

  void mark() {
    revision++;
    _changed = true;
  }

  bool takeChanged() {
    final result = _changed;
    _changed = false;
    return result;
  }

  void discover(String id) {
    if (secrets.add(id)) mark();
  }

  void drive(double x, {bool automatic = false}) {
    if (paused || dino == DinoAction.boarding || dino == DinoAction.alighting) {
      return;
    }
    if (logPlace == LogPlace.hook) putLog();
    input = ExpeditionInput.road;
    driveTarget = x.clamp(120.0, valleyEnd);
    autoDrive = automatic;
    _hintIdle = 0;
    emit('drive', "Let's go!", '出发！', sound: 'engine', cooldown: 6);
  }

  void stopDrive() {
    driveTarget = null;
    autoDrive = false;
    if (input == ExpeditionInput.road) input = ExpeditionInput.none;
  }

  void releaseRoad() {
    if (!autoDrive) stopDrive();
  }

  void honk() {
    _horn = 1.2;
    dinoMood = 1.3;
    final echo = carX > 820 && carX < 1150;
    emit(
      echo ? 'echo' : 'horn',
      echo ? 'Hello, hello!' : 'Hello, little friend!',
      echo ? '山洞也在和你打招呼' : '嘀嘀！你好呀',
      sound: echo ? 'echo' : 'horn',
      cooldown: .8,
    );
    if (echo) discover('echo');
  }

  double get hornReaction => _horn;
  double get landingBounce => _landBounce;
  double get idleTime => _hintIdle;
  void beginHook(Offset point) {
    if (!riverWork) return;
    stopDrive();
    input = ExpeditionInput.hook;
    moveHook(point);
    _grip = 0;
    _hintIdle = 0;
  }

  void moveHook(Offset point) {
    if (input != ExpeditionInput.hook) return;
    var target = Offset(
      point.dx.clamp(carX - 260, carX + 345),
      point.dy.clamp(-330.0, 20.0),
    );
    final delta = target - craneBase;
    if (delta.distance > 345) target = craneBase + delta / delta.distance * 345;
    hookTarget = target;
  }

  bool pickLog() {
    if (!riverWork) return false;
    if (bridge && bridgeOccupied) {
      emit('occupied', 'Wait for your friend.', '等朋友走下桥再搬哦');
      return false;
    }
    if (logPlace == LogPlace.hook) return true;
    if ((logPosition - craneBase).distance > 420) return false;
    if (logPlace == LogPlace.bank) _lastLogBank = logX;
    logPlace = LogPlace.hook;
    input = ExpeditionInput.hook;
    hook = Offset(logX, logY - 24);
    hookTarget = hook;
    _grip = 0;
    suspensionSpeed = 22;
    emit('pick', 'Up!', '提起来啦！', sound: 'grab', important: true);
    mark();
    return true;
  }

  bool get snapReady =>
      logPlace == LogPlace.hook &&
      (logX - bridgeCenter).abs() < 92 &&
      logY > -125 &&
      logY < 40;
  void putLog({bool cancelled = false}) {
    if (logPlace != LogPlace.hook) {
      input = ExpeditionInput.none;
      return;
    }
    if (!cancelled && snapReady) {
      logPlace = LogPlace.bridge;
      logX = bridgeCenter;
      logY = -19;
      logAngle = 0;
      _landBounce = 1;
      emit('bridge', 'A bridge!', '小桥搭好啦！', sound: 'wood', important: true);
      burst(Offset(bridgeCenter, -16), const Color(0xFFD7B27D), 10);
    } else {
      final goodBank =
          !cancelled &&
          logY > -130 &&
          (logX <= riverLeft - 35 || logX >= riverRight + 35);
      logX = goodBank ? logX.clamp(950.0, 1630.0) : _lastLogBank;
      logY = roadHeight(logX) - 27;
      logPlace = LogPlace.bank;
      logAngle = 0;
      _lastLogBank = logX;
      _landBounce = .7;
      emit('put', 'Down.', '轻轻放下，还可以再拿起来', sound: 'wood');
    }
    _autoPlace = false;
    input = ExpeditionInput.none;
    mark();
  }

  void placeAt(Offset at) {
    if (logPlace != LogPlace.hook) return;
    input = ExpeditionInput.hook;
    moveHook(at - const Offset(0, 24));
    _autoPlace = true;
  }

  void tapLog() {
    if (logPlace == LogPlace.hook) {
      putLog();
    } else {
      pickLog();
    }
  }

  void interactDino() {
    dinoMood = 2;
    if (dino == DinoAction.boarding || dino == DinoAction.alighting) return;
    if (home && dino == DinoAction.home && carX < 480) {
      dino = DinoAction.boarding;
      boarding = 0;
      return;
    }
    if (bridge &&
        velocity.abs() < 16 &&
        (dinoX - carX).abs() < 200 &&
        dino != DinoAction.riding) {
      joined = true;
      dino = DinoAction.boarding;
      boarding = 0;
      stopDrive();
      emit('join', 'Come with me!', '一起坐车回家吧！', sound: 'dino', important: true);
      mark();
    } else {
      emit('dino', 'Hello!', '你好，小恐龙！', sound: 'dino', cooldown: 2);
    }
  }

  void beginFruit() {
    if ((fruitPosition - onRoad(carX)).distance > 350) return;
    input = ExpeditionInput.fruit;
    stopDrive();
    fruitCarried = false;
    fruitV = 0;
    discover('fruit');
  }

  void moveFruit(Offset point) {
    if (input != ExpeditionInput.fruit) return;
    fruitX = point.dx.clamp(
      math.max(120.0, carX - 260),
      math.min(valleyEnd, carX + 260),
    );
    fruitY = math.min(point.dy, roadHeight(fruitX) - 26);
  }

  void releaseFruit({bool cancelled = false}) {
    if (input != ExpeditionInput.fruit) return;
    if (!cancelled &&
        (fruitX - (carX - 60)).abs() < 115 &&
        fruitY < roadHeight(carX) - 45) {
      fruitCarried = true;
      emit('fruit', 'In the truck!', '把果子带给朋友吧', sound: 'grab');
    } else if (!cancelled && home && (fruitX - dinoX).abs() < 140) {
      fed = true;
      dinoMood = 3;
      emit(
        'feed',
        'Yummy! Thank you!',
        '好甜的果子，谢谢你！',
        sound: 'dino',
        important: true,
      );
    } else {
      if (fruitX > riverLeft - 30 && fruitX < riverRight + 30 && !bridge) {
        fruitX = riverLeft - 80;
      }
      fruitY = roadHeight(fruitX) - 26;
      fruitV = 0;
    }
    input = ExpeditionInput.none;
    mark();
  }

  void leaf() {
    discover('leaf');
    burst(Offset(535, roadHeight(535) - 3), const Color(0xFFABC9AA), 9);
    emit('leaf', 'Float, little leaf.', '小叶子漂呀漂', sound: 'splash');
  }

  void wash() {
    if (mud <= 0) return;
    mud = 0;
    discover('wash');
    emit('wash', 'Clean again!', '清清的小溪洗掉泥巴啦', sound: 'splash');
    burst(Offset(carX, roadHeight(carX) - 35), const Color(0xFFB6E0D8), 18);
    mark();
  }

  void burst(Offset point, Color color, int count) {
    for (var i = 0; i < count; i++) {
      if (particles.length >= 80) particles.removeAt(0);
      particles.add(
        ValleyParticle(
          point,
          Offset(
            (_random.nextDouble() - .5) * 160,
            -35 - _random.nextDouble() * 100,
          ),
          color,
          2 + _random.nextDouble() * 4,
          .5 + _random.nextDouble() * .65,
        ),
      );
    }
  }

  void update(double elapsed) {
    if (paused) return;
    _accumulator += elapsed.clamp(0.0, .1);
    var steps = 0;
    while (_accumulator >= 1 / 120 && steps < 12) {
      _step(1 / 120);
      _accumulator -= 1 / 120;
      steps++;
    }
    notifyListeners();
  }

  void _step(double dt) {
    time += dt;
    _hintIdle += dt;
    _horn = math.max(0, _horn - dt);
    dinoMood = math.max(0, dinoMood - dt);
    _landBounce = math.max(0, _landBounce - dt * 2);
    final oldX = carX;
    var targetV = 0.0;
    if (driveTarget != null &&
        input != ExpeditionInput.hook &&
        dino != DinoAction.boarding &&
        dino != DinoAction.alighting) {
      final distance = driveTarget! - carX;
      if (distance.abs() > 12) {
        targetV =
            distance.sign * math.min(115, math.sqrt(distance.abs() * 200));
      } else {
        stopDrive();
      }
    }
    velocity +=
        (targetV - velocity) * (1 - math.exp(-dt * (targetV == 0 ? 9 : 3.8)));
    if (velocity.abs() < .2) velocity = 0;
    carX = (carX + velocity * dt).clamp(120.0, valleyEnd);
    if (!bridge && carX > riverStop && oldX <= bridgeCenter) {
      carX = riverStop;
      velocity = 0;
      stopDrive();
      if (!_bridgeExplained) {
        _bridgeExplained = true;
        emit('river', 'We need a bridge.', '前面是河，把木头搭成小桥吧', important: true);
        mark();
      }
    }
    if (!bridge && carX < riverRight + 115 && oldX > bridgeCenter) {
      carX = riverRight + 115;
      velocity = 0;
      stopDrive();
    }
    final traveled = carX - oldX;
    wheelAngle += traveled / 29;
    final tilt = math.atan2(roadHeight(carX + 65) - roadHeight(carX - 65), 130);
    carTilt += (tilt + targetV * .00008 - carTilt) * (1 - math.exp(-dt * 8));
    suspensionSpeed += (-suspension * 65 - suspensionSpeed * 11) * dt;
    suspension += suspensionSpeed * dt;
    _particleWait -= dt;
    if (carX > 470 && carX < 600 && velocity.abs() > 15) {
      mud = (mud + dt * .16).clamp(0.0, 1.0);
      suspensionSpeed += math.sin(time * 18) * dt * 25;
      if (_particleWait <= 0) {
        burst(Offset(carX - 70, roadHeight(carX)), const Color(0xFFB9A078), 5);
        _particleWait = .22;
      }
      if (!secrets.contains('mud')) {
        discover('mud');
        emit('mud', 'Splash!', '哗啦！泥坑真好玩', sound: 'splash');
      }
    }
    if (carX > 355 && carX < 410 && mud > 0 && velocity.abs() < 20) wash();
    if ((carX - _savedDistance).abs() > 180) {
      _savedDistance = carX;
      mark();
    }
    if (!fruitCarried && !fed && input != ExpeditionInput.fruit) {
      if ((carX - fruitX).abs() < 115 && velocity.abs() > 10) {
        fruitV = velocity * 1.1;
        discover('fruit');
      }
      fruitX = (fruitX + fruitV * dt).clamp(130.0, valleyEnd);
      fruitRotation += fruitV * dt / 26;
      fruitV *= math.exp(-dt * 2.7);
      if (!bridge && fruitX > riverLeft - 28 && fruitX < riverRight + 28) {
        fruitX = fruitV >= 0 ? riverLeft - 28 : riverRight + 28;
        fruitV *= -.25;
      }
      fruitY = roadHeight(fruitX) - 26;
    }
    if (input != ExpeditionInput.hook && logPlace != LogPlace.hook) {
      hookTarget =
          craneBase + Offset(nearRiver ? 100 : 65, nearRiver ? -115 : -45);
    }
    final oldHook = hook;
    hook = Offset.lerp(hook, hookTarget, 1 - math.exp(-dt * 17))!;
    if (input == ExpeditionInput.hook && logPlace != LogPlace.hook) {
      if ((hook - (logPosition - const Offset(0, 24))).distance < 67) {
        _grip += dt;
        if (_grip > .13) pickLog();
      } else {
        _grip = 0;
      }
    }
    if (logPlace == LogPlace.hook) {
      logX = hook.dx;
      logY = math.min(hook.dy + 24, roadHeight(logX) - 20);
      logSwing += (-(hook.dx - oldHook.dx) * .15 - logSwing) * dt * 7;
      logAngle = (logSwing * .09).clamp(-.16, .16);
    }
    if (_autoPlace && (hook - hookTarget).distance < 3) {
      _autoPlace = false;
      putLog();
    }
    _dinosaur(dt);
    final working =
        input == ExpeditionInput.hook || nearRiver && !bridge && carX > 1060;
    final desiredCamera = working
        ? 1275.0
        : (carX + velocity.sign * 100).clamp(310.0, valleyEnd - 160);
    if (input != ExpeditionInput.hook) {
      cameraX += (desiredCamera - cameraX) * (1 - math.exp(-dt * 3.2));
    }
    for (var i = particles.length - 1; i >= 0; i--) {
      final p = particles[i];
      p.life -= dt;
      if (p.life <= 0) {
        particles.removeAt(i);
        continue;
      }
      p.position += p.velocity * dt;
      p.velocity += Offset(0, 180 * dt);
    }
  }

  void _dinosaur(double dt) {
    if (dino == DinoAction.riding) {
      if (carX > 450) _awayFromCamp = true;
      dinoX = carX - 55;
      if (carX < 360 && velocity.abs() < 22 && (!home || _awayFromCamp)) {
        home = true;
        dino = DinoAction.alighting;
        boarding = 0;
        dinoX = 210;
        _awayFromCamp = false;
        stopDrive();
        emit(
          'home',
          "We're home!",
          '到家啦！小恐龙有自己的窝了',
          sound: 'home',
          important: true,
        );
        burst(const Offset(220, -90), const Color(0xFFD7C385), 20);
        mark();
      }
      return;
    }
    if (dino == DinoAction.alighting) {
      boarding += dt * .85;
      if (boarding >= 1) {
        boarding = 1;
        dino = DinoAction.home;
        mark();
      }
      return;
    }
    if (dino == DinoAction.boarding) {
      boarding += dt * .8;
      if (boarding >= 1) {
        boarding = 1;
        dino = DinoAction.riding;
        joined = true;
        suspensionSpeed = 33;
        mark();
      }
      return;
    }
    if (home && dino == DinoAction.home) {
      dinoX += ((carX < 450 ? 215.0 : 300.0) - dinoX) * dt;
      return;
    }
    if (!bridge) {
      dino = DinoAction.waiting;
      return;
    }
    final target = carX + 145;
    if ((dinoX - target).abs() < 12) {
      dino = DinoAction.curious;
      return;
    }
    dino = DinoAction.crossing;
    final move =
        (target - dinoX).sign * math.min((target - dinoX).abs(), dt * 46);
    dinoX += move;
    dinoWalk += move / 28;
  }

  void cancel() {
    _autoPlace = false;
    stopDrive();
    if (logPlace == LogPlace.hook) putLog(cancelled: true);
    if (input == ExpeditionInput.fruit) releaseFruit(cancelled: true);
    input = ExpeditionInput.none;
    _grip = 0;
    mark();
  }

  void pause() {
    cancel();
    paused = true;
    _accumulator = 0;
  }

  void resume() {
    paused = false;
    _accumulator = 0;
  }

  ValleyCheckpoint checkpoint() {
    final safeCar = !bridge && carX > riverStop && carX < riverRight + 115
        ? riverStop
        : carX;
    return ValleyCheckpoint(
      carX: safeCar,
      logX: bridge
          ? bridgeCenter
          : logPlace == LogPlace.hook
          ? _lastLogBank
          : logX,
      bridge: bridge,
      joined: joined,
      home: home,
      mud: mud,
      fruitX: fruitX,
      fruitCarried: fruitCarried,
      fed: fed,
      riding: dino == DinoAction.riding || dino == DinoAction.boarding,
      secrets: Set.of(secrets),
    );
  }

  void restore(ValleyCheckpoint save) {
    carX = save.carX;
    velocity = 0;
    driveTarget = null;
    cameraX = carX + 100;
    logX = save.bridge ? bridgeCenter : save.logX;
    logY = save.bridge ? -19 : roadHeight(logX) - 27;
    logPlace = save.bridge ? LogPlace.bridge : LogPlace.bank;
    _lastLogBank = save.bridge ? 1205 : save.logX;
    joined = save.joined;
    home = save.home;
    mud = save.mud;
    fruitX = save.fruitX;
    fruitY = roadHeight(fruitX) - 26;
    fruitCarried = save.fruitCarried;
    fed = save.fed;
    dino = home && !save.riding
        ? DinoAction.home
        : joined
        ? DinoAction.riding
        : DinoAction.waiting;
    dinoX = home && !save.riding
        ? 215
        : joined
        ? carX - 55
        : 1615;
    secrets
      ..clear()
      ..addAll(save.secrets);
    hook = craneBase + const Offset(65, -45);
    hookTarget = hook;
    input = ExpeditionInput.none;
    particles.clear();
    _events.clear();
    _changed = false;
    _bridgeExplained = bridge;
    paused = false;
    time = 0;
    boarding = 0;
    _autoPlace = false;
    autoDrive = false;
    _accumulator = 0;
    _grip = 0;
    _hintIdle = 0;
    _horn = 0;
    _savedDistance = carX;
    suspension = 0;
    suspensionSpeed = 0;
    carTilt = 0;
    logAngle = 0;
    logSwing = 0;
    fruitV = 0;
    _awayFromCamp = carX > 450;
    _eventAt.clear();
    notifyListeners();
  }
}
