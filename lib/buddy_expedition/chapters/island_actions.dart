part of '../expedition_controller.dart';

extension IslandActions on ExpeditionController {
  String get chapter => story.celebrated && region == IslandRegion.valley
      ? '我们的恐龙岛'
      : region == IslandRegion.valley
      ? valleyChapter
      : islandRegions[region]!.title;
  String get hint => switch (region) {
    IslandRegion.valley => joined ? '向右开去果林，和朋友继续探险！' : valleyHint,
    IslandRegion.orchard =>
      !orchard.cleared
          ? '车停稳，按住大石头，和恐龙一起推。'
          : !orchard.fed
          ? '摇摇果树，把果子拖到篮子，再点恐龙分享。'
          : !orchard.basketLoaded
          ? '把剩下三个果子放进篮子，再把篮子装车。'
          : '向右开，去萤火山洞看看。',
    IslandRegion.cave =>
      cave.revealed < .7
          ? '拖车灯照亮壁画，看看里面藏着什么。'
          : !cave.opened
          ? '找到拉杆啦，向下拉开石门。'
          : !cave.lamp
          ? '点亮那盏星星灯，把它带回家。'
          : '出口亮起来了！向右去海湾。',
    IslandRegion.bay =>
      !bay.rescued
          ? '把吊篮移到小翼龙身边，接到后放回岸边。'
          : bay.ferry == FerryPhase.offshore
          ? '拉拉码头的船绳，把小船叫过来。'
          : bay.ferry == FerryPhase.docked
          ? '跳板放好啦，把车开上船。'
          : bay.ferry == FerryPhase.boarded
          ? '朋友都坐好啦，点船绳开船！'
          : '一起坐船回家，看看海里的小鱼。',
  };
  List<IslandTarget> get chapterTargets => switch (region) {
    IslandRegion.valley => [
      if (story.readyForHome)
        const IslandTarget('picnic', Offset(280, -45), '分享野餐'),
      if (story.lampFound)
        const IslandTarget('camp-lamp', Offset(320, -160), '点亮营地星灯'),
    ],
    IslandRegion.orchard => [
      IslandTarget(
        'stone',
        Offset(orchard.stoneX, -42),
        '和伙伴一起推石头',
        radius: 62,
      ),
      const IslandTarget('tree', Offset(1150, -95), '摇果树', radius: 55),
      if (!orchard.basketLoaded)
        IslandTarget('basket', orchard.basketAt, '装好果篮'),
      for (final a in orchard.apples)
        if (!a.stored && !a.eaten && !orchard.basketLoaded)
          IslandTarget('apple-${a.id}', a.position, '把苹果放进篮子'),
      const IslandTarget('share', Offset(1355, -80), '请恐龙吃果子'),
    ],
    IslandRegion.cave => [
      IslandTarget('light', Offset(carX + 70, terrain(carX) - 90), '拖动车灯照亮洞穴'),
      const IslandTarget('mural', CaveController.carving, '照亮壁画', radius: 80),
      if (cave.revealed >= .7)
        const IslandTarget('lever', CaveController.switchAt, '向下拉开门'),
      if (cave.door > .95 && !cave.lamp)
        const IslandTarget('lamp', CaveController.lantern, '带走星灯'),
    ],
    IslandRegion.bay => [
      if (!bay.rescued)
        IslandTarget('rescue-basket', bay.basket, '提起吊篮', radius: 60),
      if (!bay.rescued)
        const IslandTarget('perch', BayController.perch, '接小翼龙', radius: 60),
      if (!bay.rescued)
        const IslandTarget(
          'landing',
          BayController.landing,
          '放回岸边',
          radius: 55,
        ),
      const IslandTarget(
        'rope',
        BayController.rope,
        '拉绳靠岸，坐好后再点开船',
        radius: 55,
      ),
      if (bay.rescued)
        IslandTarget('flyer', Offset(carX + 25, -165), '和小翼龙打招呼'),
    ],
  };
  bool get chapterBusy => chapterGesture != null || onBoat;
  void chapterDown(String id, Offset at) {
    if (paused || transition > 0) return;
    if ((at.dx - carX).abs() > 540) {
      emit('closer', 'Come closer!', '先把车开近一点吧');
      return;
    }
    stopDrive();
    chapterGesture = id;
    _hintIdle = 0;
    switch (id) {
      case 'stone':
        orchard.beginPush();
        emit('push', 'Push! Together!', '恐龙来帮忙，一起推！', sound: 'wood');
      case 'tree':
        orchard.shakeTree();
        emit('shake', 'Shake the tree!', '摇摇树枝，果子落下来啦', sound: 'wood');
      case 'basket':
        if (orchard.fed && orchard.count >= 3) {
          orchard.basketHeld = true;
          emit('basket-lift', 'Lift the basket.', '拖到车厢，也可以轻点装车。');
        } else {
          emit('basket-help', 'In the basket!', '给朋友吃一颗，再把剩下三颗装进篮子。');
        }
      case 'share':
        if (orchard.feed()) {
          emit('share', 'Yummy! Thank you!', '小恐龙吃饱啦，把剩下的果子带回家', sound: 'dino');
        } else {
          emit('share-help', 'An apple, please.', '先捡一颗果子放进篮子。');
        }
      case 'light':
        cave.aim(at);
      case 'mural':
        cave.aim(CaveController.carving);
        emit('look', 'Look!', '让灯光照一会儿，壁画在发亮', sound: 'echo');
      case 'lever':
        emit('lever-help', 'Pull down!', '往下拉，也可以轻点拉杆开门。');
      case 'lamp':
        if (cave.collect()) {
          story.lampFound = true;
          emit(
            'lamp',
            'We found it!',
            '星灯放到车上啦，向右去海湾！',
            sound: 'home',
            important: true,
          );
        }
      case 'rescue-basket':
        bay.grab();
        emit('basket-up', 'Up, gently!', '吊篮轻轻提起来', sound: 'grab');
      case 'perch':
        if (!bay.holding) bay.grab();
        bay.move(BayController.perch);
        emit('come', 'Come here!', '在平台边停一会儿，等小翼龙进篮子', sound: 'dino');
      case 'landing':
        if (bay.babyInBasket) {
          bay.move(BayController.landing);
        } else {
          bay.cancel();
        }
      case 'rope':
        if (!bay.rescued) {
          emit('friend-first', 'Help our little friend.', '先把小翼龙接回岸边。');
        } else if (bay.ferry == FerryPhase.boarded) {
          bay.sail();
          emit(
            'sail',
            "Let's go home!",
            '开船啦！一起回营地',
            sound: 'splash',
            important: true,
          );
        } else {
          bay.callBoat();
          emit('boat', 'Come, little boat!', '拉绳让船靠岸，跳板放好就能上车', sound: 'wood');
        }
      case 'flyer':
        emit('flyer', 'Hello, little flyer!', '小翼龙拍拍翅膀回应你', sound: 'dino');
      case 'picnic':
        dinoMood = 3;
        if (story.readyForHome) {
          if (!story.celebrated) {
            story.memories = (story.memories + 1).clamp(0, 999);
          }
          story.celebrated = true;
          emit(
            'celebrated',
            'Friends forever!',
            '野餐开始啦！这次探险圆满完成',
            sound: 'home',
            important: true,
          );
        }
      case 'camp-lamp':
        campLampOn = !campLampOn;
        emit(
          'camp-light',
          campLampOn ? 'A little star!' : 'Good night!',
          campLampOn ? '星灯亮起来啦！' : '小星灯休息啦',
          sound: 'home',
          cooldown: .5,
        );
      default:
        if (id.startsWith('apple-')) {
          final index = int.tryParse(id.substring(6));
          if (index != null && index >= 0 && index < 4) {
            orchard.held = index;
          }
        }
    }
    mark();
  }

  void chapterMove(Offset at) {
    final id = chapterGesture;
    if (id == null) return;
    if (id == 'stone') {
      if (at.dx > orchard.stoneX - 100) {
        orchard.beginPush();
      } else {
        orchard.push = 0;
      }
    }
    if (id == 'tree') {
      orchard.shakeTree();
    }
    if (id.startsWith('apple-')) orchard.moveApple(at);
    if (id == 'basket') orchard.dragBasket(at);
    if (id == 'light' || id == 'mural') cave.aim(at);
    if (id == 'lever') {
      cave.pull(((at.dy - CaveController.switchAt.dy) + 60) / 100);
    }
    if (id == 'rescue-basket' || id == 'perch' || id == 'landing') bay.move(at);
  }

  void chapterUp({bool cancelled = false, bool tapped = false}) {
    final id = chapterGesture;
    if (id == null) return;
    if (id == 'lever' && tapped && !cancelled) {
      cave.pull(1);
      emit('open', 'Open!', '拉杆动了，石门慢慢打开', sound: 'wood');
    }
    if (id == 'basket') {
      if (!cancelled &&
          orchard.basketHeld &&
          (tapped ||
              (orchard.basketAt - Offset(carX - 55, terrain(carX) - 70))
                      .distance <
                  120) &&
          orchard.loadBasket()) {
        story.picnicReady = true;
        emit(
          'basket-ready',
          'A picnic for everyone!',
          '果篮装好啦！去山洞找星灯吧',
          sound: 'grab',
          important: true,
        );
      } else {
        orchard.basketHeld = false;
        orchard.basketAt = OrchardController.basket;
      }
    }
    if (id == 'stone') {
      orchard.push = 0;
      if (tapped && !cancelled) orchard.pushAssist = .9;
    }
    if (id.startsWith('apple-')) {
      if (tapped && !cancelled) orchard.moveApple(OrchardController.basket);
      if (cancelled) {
        orchard.held = null;
      } else if (orchard.storeApple()) {
        emit('apple', 'In the basket!', '果子进篮子啦', sound: 'grab');
      }
    }
    if ((id == 'rescue-basket' || id == 'perch' || id == 'landing') &&
        !tapped) {
      if (cancelled) {
        bay.cancel();
      } else if (bay.drop()) {
        _rescueDone();
      }
    }
    if (cancelled && (id == 'perch' || id == 'landing')) bay.cancel();
    chapterGesture = null;
    mark();
  }

  void _rescueDone() {
    story.flyerRescued = true;
    emit(
      'rescued',
      'Safe and sound!',
      '小翼龙安全啦！拉船绳，一起回家',
      sound: 'dino',
      important: true,
    );
    mark();
  }

  void _chapterStep(double dt, double oldX) {
    transition = math.max(0, transition - dt);
    switch (region) {
      case IslandRegion.valley:
        if (story.readyForHome && home && !story.celebrated && carX < 400) {
          story.celebrated = true;
          story.memories = (story.memories + 1).clamp(0, 999);
          emit(
            'celebrated',
            'Friends forever!',
            '朋友、果子和星灯都到家啦！点地图还能再去玩',
            sound: 'home',
            important: true,
          );
          mark();
        }
      case IslandRegion.orchard:
        orchard.step(dt);
        if (orchard.cleared && !story.rockCleared) {
          story.rockCleared = true;
          emit(
            'clear',
            'We did it!',
            '路通啦！前面的果树结满果子',
            sound: 'dino',
            important: true,
          );
          mark();
        }
        if (!orchard.cleared && carX > 535 && oldX < 850) {
          carX = 535;
          velocity = 0;
          stopDrive();
          emit('stone-stop', 'Push together!', '大石头挡路啦，停稳和恐龙一起推。');
        }
      case IslandRegion.cave:
        cave.step(dt, Offset(carX + 70, -90));
        if (cave.revealed >= .7) {
          emit(
            'mural-found',
            'A hidden lever!',
            '壁画旁边有个拉杆！往下拉试试。',
            cooldown: 60,
          );
        }
        if (cave.opened && !story.caveOpen) {
          story.caveOpen = true;
          mark();
        }
        if (cave.door < .95 && carX > 980 && oldX < 1180) {
          carX = 980;
          velocity = 0;
          stopDrive();
          emit('cave-stop', 'Look for the light.', '拖动车灯照壁画，找到开门的拉杆。');
        }
      case IslandRegion.bay:
        bay.step(dt);
        if (bay.holding &&
            bay.babyInBasket &&
            (bay.basket - BayController.landing).distance < 25) {
          bay.drop();
          _rescueDone();
        }
        if (!bay.rescued && carX > 690 && oldX < 1200) {
          carX = 690;
          velocity = 0;
          stopDrive();
          emit('bay-stop', 'A little friend!', '平台上有小翼龙，用吊篮接它下来吧。');
        }
        if (bay.ferry == FerryPhase.offshore ||
            bay.ferry == FerryPhase.docking) {
          if (carX > 1480) {
            carX = 1480;
            velocity = 0;
            stopDrive();
            emit('dock-stop', 'Pull the rope.', '拉船绳，等跳板放好再上船。');
          }
        }
        if (bay.embark(carX)) {
          carX = 1630;
          velocity = 0;
          stopDrive();
          emit('aboard', 'On the boat!', '车和朋友都上船啦，再点船绳开船。', important: true);
          mark();
        }
        if (onBoat) {
          carX = 1630;
          velocity = 0;
          stopDrive();
        }
        if (bay.ferry == FerryPhase.arrived) {
          story.sailedHome = true;
          story.visited.add(IslandRegion.valley);
          enterRegion(IslandRegion.valley, spawn: 460);
          bay.ferry = FerryPhase.docked;
          home = false;
          _awayFromCamp = true;
          emit(
            'return',
            'Home is just ahead!',
            '船靠岸啦，向左开一点就到营地',
            important: true,
          );
          mark();
          return;
        }
    }
    if (transition > 0 || chapterGesture != null || onBoat) return;
    if (carX >= worldEnd - 20) {
      if (story.exitOpen(region, joined) && region != IslandRegion.bay) {
        enterRegion(IslandRegion.values[region.index + 1]);
      } else {
        stopDrive();
        velocity = 0;
        emit(
          'exit-help',
          region == IslandRegion.valley
              ? 'Bring your friend!'
              : 'One little thing first.',
          hint,
          cooldown: 8,
        );
      }
    }
    if (carX <= 145 &&
        carX < oldX &&
        region != IslandRegion.valley &&
        !_leftEdge) {
      _leftEdge = true;
      enterRegion(
        IslandRegion.values[region.index - 1],
        spawn: islandRegions[IslandRegion.values[region.index - 1]]!.end - 150,
      );
    }
  }

  void enterRegion(IslandRegion next, {double spawn = 220}) {
    cancel();
    region = next;
    story.visited.add(next);
    carX = spawn.clamp(120.0, worldEnd);
    cameraX = carX + 100;
    velocity = 0;
    driveTarget = null;
    autoDrive = false;
    dino = joined ? DinoAction.riding : DinoAction.waiting;
    dinoX = joined ? carX - 55 : 1615;
    input = ExpeditionInput.none;
    hook = craneBase + const Offset(65, -45);
    hookTarget = hook;
    particles.clear();
    transition = .65;
    regionRevision++;
    _leftEdge = false;
    _savedDistance = carX;
    emit(
      'enter-${next.name}',
      islandRegions[next]!.english,
      hint,
      important: true,
      cooldown: 0,
    );
    mark();
  }

  void travel(IslandRegion next) {
    if (story.visited.contains(next)) {
      enterRegion(next, spawn: next == IslandRegion.valley ? 260 : 220);
    }
  }

  void replayStory() {
    final count = story.memories;
    restore(const ValleyCheckpoint());
    story.memories = count;
    emit(
      'new-story',
      "Let's explore again!",
      '新的探险开始啦，过去的纪念还在。',
      important: true,
    );
    mark();
  }
}
