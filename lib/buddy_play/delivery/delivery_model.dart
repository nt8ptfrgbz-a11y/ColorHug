import 'dart:math' as math;
import '../../game_audio.dart';
import '../buddy_play_session.dart';

enum DeliveryStage { loading, driving, doorstep, opening, home }

class DeliveryModel extends ToyModel {
  int guest = 0, paint = 0;
  List<bool> gifts = [false, false, false];
  DeliveryStage stage = DeliveryStage.loading;
  double distance = 0,
      clock = 0,
      dirt = 1,
      opening = 0,
      reaction = 0,
      boat = 0,
      bridge = 0;
  bool driving = false, washed = false, ferried = false, crossed = false;
  String get obstacle => !washed && distance >= .22
      ? 'wash'
      : !ferried && distance >= .47
      ? 'boat'
      : !crossed && distance >= .7
      ? 'bridge'
      : '';
  void load(int recipient) {
    if (stage != DeliveryStage.loading) return;
    if (recipient != guest) {
      event('box', '看看门牌，找同一位朋友的包裹', phrase: 'Find the box!');
      return;
    }
    stage = DeliveryStage.driving;
    event(
      'box',
      '装好了！按住开车，也可以点自动开车',
      phrase: 'A box for my friend!',
      sound: GameSound.tap,
    );
  }

  void drive(bool value) {
    if (stage != DeliveryStage.driving) return;
    driving = value;
    event(
      value ? 'go' : 'stop',
      value ? '出发！路上也有好玩的' : '小车停好了',
      phrase: value ? "Let's go!" : 'Stop!',
    );
  }

  void wash() {
    if (obstacle != 'wash') return;
    dirt = (dirt - .26).clamp(0.0, 1.0);
    event(
      'wash',
      '刷刷刷，车子越来越干净',
      phrase: 'Wash the car!',
      sound: GameSound.splash,
    );
    if (dirt == 0) {
      washed = true;
      event('car', '干干净净，继续开车吧', discovery: 'car-wash');
    }
  }

  void sail() {
    if (obstacle == 'boat' && boat == 0) {
      boat = .001;
      event('boat', '连车一起坐小船', phrase: 'On the boat!', sound: GameSound.horn);
    }
  }

  void liftBridge() {
    if (obstacle == 'bridge' && bridge == 0) {
      bridge = .001;
      event(
        'bridge',
        '先让小船过去，再把桥放下',
        phrase: 'A big bridge!',
        sound: GameSound.tap,
      );
    }
  }

  void honk() {
    reaction = 1;
    event('car', '嘀嘀！小鸟也回应你', sound: GameSound.horn);
  }

  void deliver() {
    if (stage != DeliveryStage.doorstep) return;
    stage = DeliveryStage.opening;
    opening = 0;
    event(
      'gift',
      '包裹送到啦！一起打开',
      phrase: 'Here is your box!',
      sound: GameSound.discover,
    );
  }

  void playGift() {
    if (stage != DeliveryStage.home) return;
    reaction = 3;
    event(
      'gift',
      const ['长长围巾绕一圈', '枕头蹦蹦跳', '雪花机开起来'][guest],
      phrase: 'Thank you!',
      sound: guest == 1 ? GameSound.bounce : GameSound.bell,
    );
  }

  void visit(int who) {
    if (!gifts[who]) return;
    guest = who;
    stage = DeliveryStage.home;
    reaction = 2;
    driving = false;
  }

  void next() {
    guest = (guest + 1) % 3;
    stage = DeliveryStage.loading;
    distance = 0;
    dirt = 1;
    washed = false;
    ferried = false;
    crossed = false;
    driving = false;
    boat = 0;
    bridge = 0;
    opening = 0;
  }

  @override
  void step(double dt) {
    clock += dt;
    reaction = math.max(0, reaction - dt);
    if (boat > 0 && !ferried) {
      boat += dt * .4;
      if (boat >= 1) {
        boat = 1;
        ferried = true;
        event('boat', '上岸啦！继续走吧', discovery: 'ferry');
      }
    }
    if (bridge > 0 && !crossed) {
      bridge += dt * .35;
      if (bridge >= 1) {
        bridge = 1;
        crossed = true;
        event('bridge', '小船过去了，桥放下来啦', discovery: 'bridge');
      }
    }
    if (stage == DeliveryStage.driving && driving && obstacle.isEmpty) {
      final nextStop = !washed
          ? .22
          : !ferried
          ? .47
          : !crossed
          ? .7
          : 1.0;
      distance = math.min(nextStop, distance + dt * .095);
      if (distance >= 1) {
        distance = 1;
        driving = false;
        stage = DeliveryStage.doorstep;
        event('stop', '到朋友家啦，把盒子送给它', phrase: 'Here we are!');
      }
    }
    if (stage == DeliveryStage.opening) {
      opening += dt * .6;
      if (opening >= 1) {
        opening = 1;
        gifts[guest] = true;
        stage = DeliveryStage.home;
        reaction = 3;
        event(
          'gift',
          '礼物会一直留在朋友家里',
          phrase: 'Thank you for the gift!',
          sound: GameSound.complete,
          discovery: 'gift-$guest',
        );
      }
    }
  }

  @override
  void pause() {
    driving = false;
  }

  @override
  Map<String, dynamic> toJson() => {
    'v': 1,
    'guest': guest,
    'gifts': gifts,
    'paint': paint,
  };
  @override
  void restore(Map<String, dynamic> d) {
    guest = d['guest'];
    gifts = List<bool>.from(d['gifts']);
    paint = d['paint'];
    stage = gifts[guest] ? DeliveryStage.home : DeliveryStage.loading;
    distance = 0;
    driving = false;
    washed = false;
    ferried = false;
    crossed = false;
    boat = 0;
    bridge = 0;
    dirt = 1;
  }
}
