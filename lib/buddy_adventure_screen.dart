import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'buddy_adventure_models.dart';
import 'buddy_effects.dart';
import 'buddy_models.dart';
import 'buddy_widgets.dart';
import 'game_audio.dart';
import 'island_progress.dart';

const buddyAdventureTitles = [
  '云朵天气工厂',
  '恐龙蛋托儿所',
  '软糖建筑师',
  '小笨怪学生活',
  '动物动作剧场',
  '星光烟花工坊',
];
const _subtitles = [
  'WEATHER MAKER · 用手指改变天气',
  'DINO NURSERY · 一颗蛋，一个新朋友',
  'JELLY BUILDER · 搭好，再试一试',
  'LITTLE TEACHER · 今天你来当老师',
  'ANIMAL THEATER · 编一个自己的故事',
  'STAR STUDIO · 把夜空画成喜欢的样子',
];
const _digPoints = [
  Offset(.28, .35),
  Offset(.5, .32),
  Offset(.72, .35),
  Offset(.28, .64),
  Offset(.5, .65),
  Offset(.72, .64),
];

class BuddyAdventureScreen extends StatefulWidget {
  const BuddyAdventureScreen({
    super.key,
    required this.adventure,
    required this.progress,
    required this.audio,
  });
  final BuddyAdventure adventure;
  final IslandProgress progress;
  final GameAudioController audio;
  @override
  State<BuddyAdventureScreen> createState() => _BuddyAdventureScreenState();
}

class _BuddyAdventureScreenState extends State<BuddyAdventureScreen>
    with SingleTickerProviderStateMixin {
  final _effects = BuddyEffectsController();
  final _sceneKey = GlobalKey();
  final Set<int> _fireShapesSeen = {};
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  Timer? _playTimer;
  String? _message;
  String? _spokenWord;
  int _mission = 0;
  bool _won = false;
  Offset? _lastTouch;

  int _weather = 1;
  final _weatherPower = [0, 0, 0];
  Offset _cloud = const Offset(.56, .25);

  final Set<int> _dug = {};
  int _dinoStage = 0, _eggTouches = 0, _dino = 0, _nest = 0;
  Offset _dinoPosition = const Offset(.5, .56);
  final List<Offset> _trail = [];

  late List<int> _building;
  int _block = 1, _buildStep = -1;
  List<int> _buildPath = [];
  bool _playing = false;

  String? _selectedItem;
  final Map<int, String> _placed = {};
  SillyMission get _silly => sillyMissions[_mission % sillyMissions.length];

  final List<int> _show = [];
  int _actor = 0, _backdrop = 0, _beat = -1;
  int _fireShape = 0, _fireColor = 0, _fireCount = 0;

  String get _guide =>
      _message ??
      switch (widget.adventure) {
        BuddyAdventure.weather => const [
          '小鸭想踩水！选雨云，再点点天空，帮它变出一个水坑。',
          '小熊的风筝飞不起来！选风，在天空划几下。',
          '小兔的毯子湿啦！选太阳，点点天空晒一晒。',
        ][_mission % 3],
        BuddyAdventure.dinosaur => const [
          '沙子下面藏着什么？擦开六处沙土，找一颗恐龙蛋！',
          '蛋宝宝有点冷，轻轻点它三下，盖好小毯子。',
          '咚咚！宝宝在敲壳。点一点击开蛋壳，迎接新朋友！',
          '小恐龙想和你玩！画条路让它跟着走，喂点水果，或帮它搭窝。',
        ][_dinoStage],
        BuddyAdventure.building => '选一块软糖，点格子或拖进去。从左到右搭一条路，让小兔过河！',
        BuddyAdventure.silly => _silly.guide,
        BuddyAdventure.theater => '点动作卡编一段故事，拖动故事里的卡片可以交换顺序，再请演员表演！',
        BuddyAdventure.fireworks => '点一下放烟花，划一划画星光！试试星星、爱心和花朵，装点整片夜空。',
      };
  String get _english =>
      _spokenWord ??
      switch (widget.adventure) {
        BuddyAdventure.weather =>
          adventureWords[BuddyAdventure.weather]![_weather],
        BuddyAdventure.dinosaur => _dinoStage < 3 ? 'egg' : 'baby',
        BuddyAdventure.building => _won ? 'A bridge!' : 'Build a bridge!',
        BuddyAdventure.silly => _silly.word,
        BuddyAdventure.theater =>
          _beat >= 0 && _beat < _show.length
              ? theaterActions[_show[_beat]]
              : 'Let’s play!',
        BuddyAdventure.fireworks =>
          adventureWords[BuddyAdventure.fireworks]![_fireShape],
      };

  @override
  void initState() {
    super.initState();
    _building = widget.progress.buddyCreation('building') ?? List.filled(12, 0);
    final show = widget.progress.buddyCreation('show');
    if (show != null) {
      _actor = show[0];
      _backdrop = show[1];
      _show.addAll(show.skip(2));
    }
    final dino = widget.progress.buddyCreation('dino');
    if (dino != null) {
      _dino = dino[0];
      _nest = dino[1];
      _dinoStage = 3;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _narrate();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _clock.stop();
    } else {
      _clock.repeat();
    }
  }

  void _narrate() => unawaited(widget.audio.speakLesson(_guide, _english));
  void _say(String word) {
    _spokenWord = word;
    unawaited(widget.audio.speakEnglish(word));
  }

  void _reward(int variant, Iterable<String> words) {
    widget.progress.recordBuddyAdventure(widget.adventure, variant, words);
    unawaited(widget.audio.play(GameSound.complete));
    _effects.burst(const Offset(.5, .45), count: 42);
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    _clock.dispose();
    _effects.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BuddyGameShell(
    title: buddyAdventureTitles[widget.adventure.index],
    subtitle: _subtitles[widget.adventure.index],
    guide: _guide,
    english: _english,
    audio: widget.audio,
    progress: widget.progress,
    onRepeat: _narrate,
    scene: BuddyEffects(
      key: _sceneKey,
      controller: _effects,
      child: AnimatedBuilder(
        animation: _clock,
        builder: (context, _) => switch (widget.adventure) {
          BuddyAdventure.weather => _weatherScene(),
          BuddyAdventure.dinosaur => _dinoScene(),
          BuddyAdventure.building => _buildingScene(),
          BuddyAdventure.silly => _sillyScene(),
          BuddyAdventure.theater => _theaterScene(),
          BuddyAdventure.fireworks => _fireworksScene(),
        },
      ),
    ),
    controls: switch (widget.adventure) {
      BuddyAdventure.weather => _weatherControls(),
      BuddyAdventure.dinosaur => _dinoControls(),
      BuddyAdventure.building => _buildingControls(),
      BuddyAdventure.silly => _sillyControls(),
      BuddyAdventure.theater => _theaterControls(),
      BuddyAdventure.fireworks => _fireworksControls(),
    },
  );

  Widget _choices(
    List<String> labels,
    int selected,
    ValueChanged<int> onSelected,
    String prefix, {
    bool enabled = true,
  }) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 8,
    runSpacing: 8,
    children: [
      for (var i = 0; i < labels.length; i++)
        ChoiceChip(
          key: ValueKey('$prefix-$i'),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Text(labels[i], style: const TextStyle(fontSize: 17)),
          ),
          selected: selected == i,
          onSelected: enabled ? (_) => onSelected(i) : null,
        ),
    ],
  );

  Widget _touchScene({
    required Widget child,
    required void Function(Offset) action,
    required String id,
  }) => LayoutBuilder(
    builder: (context, constraints) => GestureDetector(
      key: ValueKey(id),
      behavior: HitTestBehavior.opaque,
      onTapUp: (d) => action(
        Offset(
          d.localPosition.dx / constraints.maxWidth,
          d.localPosition.dy / constraints.maxHeight,
        ),
      ),
      onPanStart: (_) => _lastTouch = null,
      onPanUpdate: (d) {
        final p = Offset(
          d.localPosition.dx / constraints.maxWidth,
          d.localPosition.dy / constraints.maxHeight,
        );
        if (p.dx < 0 || p.dx > 1 || p.dy < 0 || p.dy > 1) return;
        if (_lastTouch == null || (p - _lastTouch!).distance > .045) {
          action(p);
          _lastTouch = p;
        }
      },
      onPanEnd: (_) => _lastTouch = null,
      onPanCancel: () => _lastTouch = null,
      child: child,
    ),
  );

  // Weather has persistent consequences within the scene: rain fills a pond,
  // wind lifts the kite, and sunshine opens flowers and dries the blanket.
  void _changeWeather(Offset p) {
    setState(() {
      _cloud = p;
      _weatherPower[_weather] = (_weatherPower[_weather] + 1).clamp(0, 6);
    });
    _effects.burst(
      p,
      kind: _weather == 1 ? BuddyBurst.splash : BuddyBurst.stars,
      color: _weather == 1 ? const Color(0xFF8EDCFF) : const Color(0xFFFFDC7C),
      count: 12,
    );
    unawaited(widget.audio.play(GameSound.tap));
    final needed = const [1, 2, 0][_mission % 3];
    if (!_won && _weatherPower[needed] >= 3) {
      setState(() {
        _won = true;
        _message = const [
          '水坑变出来啦！小鸭开心地踩起水花。',
          '风来了！小熊的风筝飞上天空啦！',
          '暖暖的太阳晒干了毯子，花儿也开啦！',
        ][_mission % 3];
      });
      _reward(_mission % 3, [adventureWords[BuddyAdventure.weather]![needed]]);
      _narrate();
    }
  }

  Widget _weatherScene() => _touchScene(
    id: 'weather-sky',
    action: _changeWeather,
    child: CustomPaint(
      painter: _WeatherPainter(_clock.value, _weather, _weatherPower, _cloud),
      child: Stack(
        children: [
          Align(
            alignment: const Alignment(-.65, .73),
            child: Transform.translate(
              offset: Offset(
                0,
                _weatherPower[1] >= 3
                    ? -math.sin(_clock.value * math.pi * 16).abs() * 12
                    : 0,
              ),
              child: const Text('🦆', style: TextStyle(fontSize: 58)),
            ),
          ),
          const Align(
            alignment: Alignment(.55, .65),
            child: Text('🐻', style: TextStyle(fontSize: 58)),
          ),
          Align(
            alignment: Alignment(.45, _weatherPower[2] >= 3 ? -.5 : .35),
            child: Transform.rotate(
              angle: math.sin(_clock.value * math.pi * 4) * .15,
              child: const Text('🪁', style: TextStyle(fontSize: 54)),
            ),
          ),
          Align(
            alignment: const Alignment(.04, .79),
            child: Text(
              _weatherPower[0] >= 3 ? '🌻' : '🌱',
              style: const TextStyle(fontSize: 49),
            ),
          ),
          Positioned(
            left: 18,
            top: 75,
            child: Column(
              children: [
                Container(width: 72, height: 3, color: const Color(0xFF8B987D)),
                Container(
                  width: 54,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _weatherPower[0] >= 3
                        ? const Color(0xFFFFCCBF)
                        : const Color(0xFFA1BBC6),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Center(
                    child: Text(
                      _weatherPower[0] >= 3 ? '🌸' : '💧',
                      style: const TextStyle(fontSize: 21),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            left: 18,
            top: 16,
            child: Text(
              '☁️ 你的天气小花园',
              style: TextStyle(color: buddyInk, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    ),
  );
  Widget _weatherControls() => Column(
    children: [
      _choices(const ['☀️ 太阳', '🌧️ 下雨', '🌬️ 吹风'], _weather, (i) {
        setState(() {
          _weather = i;
          _spokenWord = null;
        });
        _say(adventureWords[BuddyAdventure.weather]![i]);
      }, 'weather-tool'),
      const SizedBox(height: 12),
      if (_won)
        BuddyAction(
          key: const ValueKey('weather-next'),
          label: '🌈 再帮一个朋友',
          onTap: () {
            setState(() {
              _mission++;
              _won = false;
              _message = null;
              _spokenWord = null;
              _weatherPower.fillRange(0, 3, 0);
            });
            _narrate();
          },
        )
      else
        const Text('选好天气后，点点或划动天空', style: TextStyle(color: buddyInk)),
    ],
  );

  void _dinoTouch(Offset point) {
    if (_dinoStage == 0) {
      var changed = false;
      for (var i = 0; i < _digPoints.length; i++) {
        if ((point - _digPoints[i]).distance < .17) {
          changed = _dug.add(i) || changed;
        }
      }
      if (!changed) return;
      _effects.burst(
        point,
        color: const Color(0xFFE4BB86),
        kind: BuddyBurst.splash,
        count: 14,
      );
      setState(() {
        if (_dug.length == 6) {
          _dinoStage = 1;
          _message = null;
        }
      });
      if (_dinoStage == 1) _narrate();
    } else if (_dinoStage < 3) {
      if ((point - const Offset(.5, .48)).distance > .3) return;
      setState(() {
        _eggTouches++;
        if (_eggTouches >= 3) {
          _eggTouches = 0;
          _dinoStage++;
        }
      });
      _effects.burst(
        point,
        count: 18,
        kind: _dinoStage == 1 ? BuddyBurst.heart : BuddyBurst.stars,
      );
      if (_dinoStage == 3) {
        _reward(_dino, ['egg', 'baby']);
        _saveDino();
      }
      _narrate();
    } else {
      setState(() {
        _dinoPosition = Offset(
          point.dx.clamp(.14, .86),
          point.dy.clamp(.28, .75),
        );
        _trail.add(_dinoPosition);
        if (_trail.length > 30) _trail.removeAt(0);
      });
      if (point.dx > .69 && point.dy > .6) {
        _effects.burst(
          point,
          kind: BuddyBurst.splash,
          color: const Color(0xFF85D7F5),
        );
        _say('Jump!');
      }
    }
    unawaited(widget.audio.play(GameSound.tap));
  }

  void _saveDino() => widget.progress.saveBuddyCreation('dino', [_dino, _nest]);
  Widget _dinoScene() => _touchScene(
    id: 'dino-ground',
    action: _dinoTouch,
    child: BuddyRoom(
      color: const Color(0xFFE5EDCD),
      floor: const Color(0xFFD3BD8F),
      child: LayoutBuilder(
        builder: (context, c) => Stack(
          children: [
            const Positioned(
              left: 18,
              top: 17,
              child: Text(
                '🌿 蛋宝宝的秘密花园',
                style: TextStyle(color: buddyInk, fontWeight: FontWeight.w800),
              ),
            ),
            Positioned(
              right: 18,
              bottom: 22,
              width: c.maxWidth * .26,
              height: 38,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF86CFD8),
                  borderRadius: BorderRadius.circular(60),
                ),
              ),
            ),
            if (_dinoStage < 3)
              Align(
                alignment: const Alignment(0, -.04),
                child: Transform.rotate(
                  angle: _dinoStage == 2
                      ? math.sin(_clock.value * 40) * .06
                      : 0,
                  child: SizedBox(
                    width: 155,
                    height: 190,
                    child: CustomPaint(
                      painter: _EggPainter(
                        _dino,
                        _dinoStage == 2 ? _eggTouches + 1 : 0,
                        _dinoStage == 1,
                      ),
                    ),
                  ),
                ),
              ),
            if (_dinoStage == 0)
              for (var i = 0; i < _digPoints.length; i++)
                if (!_dug.contains(i))
                  Positioned(
                    left: _digPoints[i].dx * c.maxWidth - 45,
                    top: _digPoints[i].dy * c.maxHeight - 42,
                    width: 90,
                    height: 84,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            const Color(0xFFD2AC77),
                            const Color(0xFFE8C899),
                            i / 6,
                          ),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Center(
                          child: Text(
                            '· · ·',
                            style: TextStyle(
                              color: Color(0xFFAB854F),
                              fontSize: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
            if (_dinoStage == 3) ...[
              for (var i = 0; i < _trail.length; i += 3)
                Positioned(
                  left: _trail[i].dx * c.maxWidth,
                  top: _trail[i].dy * c.maxHeight + 37,
                  child: const Text(
                    '·',
                    style: TextStyle(color: Color(0xFF8B9973), fontSize: 30),
                  ),
                ),
              Positioned(
                left: 24,
                bottom: 20,
                child: Text(
                  _nest == 0 ? '🍃' : '🪵' * _nest,
                  style: const TextStyle(fontSize: 30),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                left: _dinoPosition.dx * c.maxWidth - 53,
                top: _dinoPosition.dy * c.maxHeight - 66,
                child: Transform.translate(
                  offset: Offset(0, math.sin(_clock.value * math.pi * 10) * 4),
                  child: Text(
                    const ['🦕', '🦖', '🐉'][_dino],
                    style: const TextStyle(fontSize: 105),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
  Widget _dinoControls() => Column(
    children: [
      if (_dinoStage == 0)
        Text(
          '找到蛋宝宝  ${_dug.length}/6',
          style: const TextStyle(color: buddyInk, fontWeight: FontWeight.w800),
        ),
      if (_dinoStage == 1 || _dinoStage == 2)
        Text(
          '${_dinoStage == 1 ? '轻轻暖一暖' : '帮宝宝敲开壳'}  $_eggTouches/3',
          style: const TextStyle(color: buddyInk, fontWeight: FontWeight.w800),
        ),
      if (_dinoStage == 3)
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            BuddyAction(
              key: const ValueKey('dino-feed'),
              label: '🍌 喂一口',
              onTap: () {
                setState(() {
                  _message = '啊呜！小恐龙吃饱了，开心地甩甩尾巴。';
                });
                _effects.burst(_dinoPosition, kind: BuddyBurst.heart);
                _reward(3 + _dino, ['eat']);
                _say('Eat! Yummy!');
              },
            ),
            BuddyAction(
              key: const ValueKey('dino-nest'),
              label: '🪵 搭小窝',
              primary: false,
              onTap: () {
                setState(() {
                  _nest = (_nest + 1).clamp(0, 3);
                  _message = _nest == 3
                      ? '小窝搭好啦！下次回来，小恐龙还在这里等你。'
                      : '给小窝添一块软软的木头。';
                });
                _saveDino();
                _effects.burst(
                  const Offset(.2, .8),
                  color: const Color(0xFFCBAA75),
                );
              },
            ),
            BuddyAction(
              key: const ValueKey('dino-new'),
              label: '🥚 找新蛋',
              primary: false,
              onTap: () {
                setState(() {
                  _dino = (_dino + 1) % 3;
                  _dinoStage = 0;
                  _nest = 0;
                  _eggTouches = 0;
                  _dug.clear();
                  _trail.clear();
                  _message = null;
                  _spokenWord = null;
                });
                _narrate();
              },
            ),
          ],
        ),
    ],
  );

  void _placeBlock(int cell, int value) {
    if (_playing) return;
    setState(() {
      _building[cell] = value;
      _won = false;
      _buildStep = -1;
      _message = null;
    });
    widget.progress.saveBuddyCreation('building', _building);
    _effects.burst(
      Offset(.2 + (cell % 4) * .2, .29 + (cell ~/ 4) * .2),
      count: 12,
      color: buddyColors[(value + 1) % 4],
    );
    unawaited(widget.audio.play(GameSound.tap));
  }

  void _tryBuilding() {
    if (_playing) return;
    _focusScene();
    setState(() {
      _playing = true;
      _buildStep = -1;
      _buildPath = jellyBridgePath(_building);
      _message = '小兔出发啦！看看你的软糖路。';
    });
    _playTimer?.cancel();
    _playTimer = Timer.periodic(const Duration(milliseconds: 680), (timer) {
      if (!mounted) return;
      setState(() => _buildStep++);
      if ((_buildPath.isEmpty && _buildStep >= 1) || _buildStep >= 4) {
        timer.cancel();
        setState(() {
          _playing = false;
          _won = _buildPath.isNotEmpty;
          _message = _won
              ? '小兔到家啦！软糖桥弹一弹，真有趣！'
              : '噗通，落进软软的泡泡垫！把左边到右边的空格连起来，再试试。';
        });
        if (_won) {
          _reward(_building.where((v) => v > 0).toSet().length - 1, [
            'build',
            'bridge',
          ]);
        } else {
          _effects.burst(
            const Offset(.3, .78),
            kind: BuddyBurst.bubbles,
            count: 40,
          );
        }
        _narrate();
      }
    });
  }

  Widget _buildingScene() => BuddyRoom(
    color: const Color(0xFFE3EAF3),
    floor: const Color(0xFFADD9E2),
    child: LayoutBuilder(
      builder: (context, c) {
        final cellW = c.maxWidth * .2;
        final cellH = c.maxHeight * .2;
        final pathCell = _buildPath.isNotEmpty && _buildStep >= 0
            ? _buildPath[_buildStep.clamp(0, 3)]
            : 8;
        final x = _buildStep < 0
            ? .02
            : _buildPath.isEmpty
            ? .3
            : _buildStep >= 4
            ? .9
            : .1 + (pathCell % 4) * .2;
        final y = _buildPath.isEmpty && _buildStep >= 1
            ? .74
            : .12 + (pathCell ~/ 4) * .2;
        return Stack(
          children: [
            const Positioned(
              left: 16,
              top: 12,
              child: Text(
                '🏡 从左边搭到右边',
                style: TextStyle(color: buddyInk, fontWeight: FontWeight.w800),
              ),
            ),
            const Positioned(
              right: 10,
              bottom: 18,
              child: Text('🏡', style: TextStyle(fontSize: 45)),
            ),
            for (var i = 0; i < 12; i++)
              Positioned(
                left: c.maxWidth * .1 + (i % 4) * cellW,
                top: c.maxHeight * .2 + (i ~/ 4) * cellH,
                width: cellW - 5,
                height: cellH - 5,
                child: DragTarget<int>(
                  onWillAcceptWithDetails: (_) => !_playing,
                  onAcceptWithDetails: (d) => _placeBlock(i, d.data),
                  builder: (context, candidates, _) => GestureDetector(
                    key: ValueKey('building-cell-$i'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _placeBlock(i, _block),
                    child: _JellyBlock(
                      value: _building[i],
                      highlight: candidates.isNotEmpty,
                      squash: _playing && pathCell == i
                          ? math.sin(_clock.value * 60).abs() * .14
                          : 0,
                    ),
                  ),
                ),
              ),
            IgnorePointer(
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 500),
                alignment: Alignment(x * 2 - 1, y * 2 - 1),
                child: Transform.rotate(
                  angle: _buildPath.isEmpty && _buildStep >= 1
                      ? .4
                      : math.sin(_clock.value * 25) * .07,
                  child: const Text('🐰', style: TextStyle(fontSize: 40)),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
  Widget _buildingControls() => Column(
    children: [
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          for (var i = 0; i < 4; i++)
            Draggable<int>(
              data: i,
              maxSimultaneousDrags: _playing ? 0 : 1,
              feedback: SizedBox(
                width: 66,
                height: 58,
                child: _JellyBlock(value: i),
              ),
              child: ChoiceChip(
                key: ValueKey('building-tool-$i'),
                selected: _block == i,
                label: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    const ['🧽', '🟩', '🔺', '🟪'][i],
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
                onSelected: _playing ? null : (_) => setState(() => _block = i),
              ),
            ),
        ],
      ),
      const SizedBox(height: 12),
      BuddyAction(
        key: const ValueKey('building-try'),
        label: _playing ? '🐰 小兔在过桥…' : '🐰 让小兔试一试',
        onTap: _playing ? null : _tryBuilding,
      ),
    ],
  );

  void _placeItem(int target, String item) {
    if (_won) return;
    setState(() {
      _placed[target] = item;
      _won = target == _silly.target && item == _silly.item;
      _message = _won ? '你教会抱抱啦！谢谢小老师，抱抱开心地转一圈。' : '哈哈，这样也很有趣！${_silly.guide}';
    });
    _effects.burst(
      sillyTargets[target],
      kind: _won ? BuddyBurst.stars : BuddyBurst.bubbles,
    );
    if (_won) _reward(_mission % sillyMissions.length, [_silly.word]);
    _narrate();
  }

  Widget _sillyScene() => BuddyRoom(
    color: const Color(0xFFF4E4D8),
    floor: const Color(0xFFE6C6B5),
    child: LayoutBuilder(
      builder: (context, c) => Stack(
        children: [
          Align(
            alignment: const Alignment(0, .3),
            child: SizedBox(
              width: 230,
              height: 260,
              child: Transform.rotate(
                angle: _won ? math.sin(_clock.value * 25) * .13 : 0,
                child: BuddyCharacter(
                  color: buddyColors[widget.progress.buddyColor],
                  outfit: '',
                  joyful: _won,
                ),
              ),
            ),
          ),
          if (!_won && _placed.isEmpty)
            Positioned(
              left: c.maxWidth / 2 - 24,
              top: 33,
              child: Text(_silly.before, style: const TextStyle(fontSize: 44)),
            ),
          for (var i = 0; i < sillyTargets.length; i++)
            if (i == _silly.target || _placed.containsKey(i))
              Positioned(
                left: sillyTargets[i].dx * c.maxWidth - 32,
                top: sillyTargets[i].dy * c.maxHeight - 30,
                width: 64,
                height: 60,
                child: DragTarget<String>(
                  onWillAcceptWithDetails: (_) => !_won,
                  onAcceptWithDetails: (d) => _placeItem(i, d.data),
                  builder: (context, candidates, _) => GestureDetector(
                    key: ValueKey('silly-target-$i'),
                    onTap: () {
                      if (_selectedItem != null) _placeItem(i, _selectedItem!);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: candidates.isNotEmpty ? .75 : .25,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        _placed[i] ?? '👇',
                        style: const TextStyle(fontSize: 36),
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    ),
  );
  Widget _sillyControls() => Column(
    children: [
      if (!_won)
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          children: [
            for (var i = 0; i < _silly.choices.length; i++)
              Draggable<String>(
                data: _silly.choices[i],
                feedback: Material(
                  color: Colors.transparent,
                  child: Text(
                    _silly.choices[i],
                    style: const TextStyle(fontSize: 55),
                  ),
                ),
                child: ChoiceChip(
                  key: ValueKey('silly-item-$i'),
                  label: Padding(
                    padding: const EdgeInsets.all(9),
                    child: Text(
                      _silly.choices[i],
                      style: const TextStyle(fontSize: 35),
                    ),
                  ),
                  selected: _selectedItem == _silly.choices[i],
                  onSelected: (_) =>
                      setState(() => _selectedItem = _silly.choices[i]),
                ),
              ),
          ],
        ),
      const SizedBox(height: 12),
      if (_won)
        BuddyAction(
          key: const ValueKey('silly-next'),
          label: '🎒 再教一个小本领',
          onTap: () {
            setState(() {
              _mission++;
              _won = false;
              _placed.clear();
              _selectedItem = null;
              _message = null;
              _spokenWord = null;
            });
            _narrate();
          },
        )
      else
        const Text(
          '把物品拖过去，或先选物品再点小手',
          style: TextStyle(color: buddyInk, fontSize: 13),
        ),
    ],
  );

  void _saveShow() =>
      widget.progress.saveBuddyCreation('show', [_actor, _backdrop, ..._show]);
  void _addAction(int action) {
    if (_playing || _show.length >= 6) return;
    setState(() {
      _show.add(action);
      _message = null;
    });
    _saveShow();
    _say(theaterActions[action]);
  }

  void _focusScene() {
    final sceneContext = _sceneKey.currentContext;
    if (sceneContext != null) {
      unawaited(
        Scrollable.ensureVisible(
          sceneContext,
          alignment: .1,
          duration: const Duration(milliseconds: 260),
        ),
      );
    }
  }

  void _perform() {
    if (_show.isEmpty || _playing) return;
    _focusScene();
    setState(() {
      _playing = true;
      _beat = 0;
      _message = '开演啦！看看你安排的动作故事。';
    });
    _say(theaterActions[_show[0]]);
    _playTimer?.cancel();
    _playTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (!mounted) return;
      setState(() => _beat++);
      if (_beat >= _show.length) {
        timer.cancel();
        setState(() {
          _playing = false;
          _beat = -1;
          _message = '演出结束！小故事已经保存，下次还可以换个演员再演。';
        });
        _reward(_actor, _show.map((i) => theaterActions[i]));
        _say('Great show!');
      } else {
        _effects.burst(
          const Offset(.5, .55),
          count: 12,
          kind: _show[_beat] == 2 ? BuddyBurst.bubbles : BuddyBurst.stars,
        );
        _say(theaterActions[_show[_beat]]);
      }
    });
  }

  Widget _theaterScene() {
    final action = _beat >= 0 && _beat < _show.length ? _show[_beat] : -1;
    final phase = _clock.value * math.pi * 16;
    final dx = action == 1 ? math.sin(phase / 3) * 95 : 0.0;
    final dy = action == 0
        ? -math.sin(phase).abs() * 65
        : action == 3
        ? -math.sin(phase).abs() * 12
        : 0.0;
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: const [
                  [Color(0xFF39406D), Color(0xFF858FC6)],
                  [Color(0xFF57967B), Color(0xFFB6D8B3)],
                  [Color(0xFFAA7087), Color(0xFFEFBDAC)],
                ][_backdrop],
              ),
            ),
          ),
        ),
        const Positioned(
          left: 20,
          top: 18,
          child: Text(
            '🎭 抱抱小剧场',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 75,
          child: Container(color: const Color(0xFFB98970)),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 50,
          width: 36,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFA45B70),
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(28)),
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 50,
          width: 36,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFA45B70),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28)),
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0, .3),
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.rotate(
              angle: action == 2
                  ? math.pi / 2
                  : action == 3
                  ? math.sin(phase) * .25
                  : 0,
              child: Text(
                theaterAnimals[_actor],
                style: const TextStyle(fontSize: 110),
              ),
            ),
          ),
        ),
        if (action == 2)
          const Align(
            alignment: Alignment(.45, -.25),
            child: Text('💤', style: TextStyle(fontSize: 45)),
          ),
        if (action == 3)
          const Align(
            alignment: Alignment(-.5, -.25),
            child: Text('🎵', style: TextStyle(fontSize: 40)),
          ),
        Positioned(
          bottom: 18,
          left: 20,
          right: 20,
          child: Text(
            action < 0
                ? '等你安排小故事'
                : '${theaterActions[action]}  ${_beat + 1}/${_show.length}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _theaterControls() => Column(
    children: [
      _choices(
        theaterAnimals,
        _actor,
        (i) {
          setState(() => _actor = i);
          _saveShow();
        },
        'theater-actor',
        enabled: !_playing,
      ),
      const SizedBox(height: 8),
      _choices(
        const ['🌙 夜空', '🌳 森林', '🌅 夕阳'],
        _backdrop,
        (i) {
          setState(() => _backdrop = i);
          _saveShow();
        },
        'theater-scene',
        enabled: !_playing,
      ),
      const SizedBox(height: 10),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < 4; i++)
            ActionChip(
              key: ValueKey('theater-action-$i'),
              label: Padding(
                padding: const EdgeInsets.all(7),
                child: Text(
                  '${theaterActionIcons[i]} ${const ['跳一跳', '跑一跑', '睡觉', '跳舞'][i]}',
                ),
              ),
              onPressed: _playing || _show.length >= 6
                  ? null
                  : () => _addAction(i),
            ),
        ],
      ),
      const SizedBox(height: 12),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < _show.length; i++)
            DragTarget<int>(
              onWillAcceptWithDetails: (_) => !_playing,
              onAcceptWithDetails: (d) {
                setState(() {
                  final temp = _show[i];
                  _show[i] = _show[d.data];
                  _show[d.data] = temp;
                });
                _saveShow();
              },
              builder: (context, candidates, _) => Draggable<int>(
                data: i,
                maxSimultaneousDrags: _playing ? 0 : 1,
                feedback: Material(
                  color: Colors.transparent,
                  child: Text(
                    theaterActionIcons[_show[i]],
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
                child: Container(
                  key: ValueKey('theater-slot-$i'),
                  width: 45,
                  height: 49,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _beat == i || candidates.isNotEmpty
                        ? const Color(0xFFFFD67D)
                        : const Color(0xFFE8E4F4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    theaterActionIcons[_show[i]],
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 12),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          BuddyAction(
            key: const ValueKey('theater-play'),
            label: _playing ? '🎭 正在表演…' : '🎬 开始表演',
            onTap: _playing || _show.isEmpty ? null : _perform,
          ),
          BuddyAction(
            key: const ValueKey('theater-undo'),
            label: '撤回一步',
            primary: false,
            icon: Icons.undo_rounded,
            onTap: _playing || _show.isEmpty
                ? null
                : () {
                    setState(() => _show.removeLast());
                    _saveShow();
                  },
          ),
        ],
      ),
    ],
  );

  void _fire(Offset p) {
    final kind = [
      BuddyBurst.stars,
      BuddyBurst.heart,
      BuddyBurst.flower,
    ][_fireShape];
    _effects.burst(
      p,
      kind: kind,
      color: const [
        Color(0xFF6CFFD8),
        Color(0xFFC59AFF),
        Color(0xFFFF80BE),
        Color(0xFFFFDF73),
      ][_fireColor],
      count: 40,
      trails: true,
    );
    _fireCount++;
    if (_fireCount % 4 == 1) unawaited(widget.audio.play(GameSound.discover));
    if (_fireShapesSeen.add(_fireShape)) {
      widget.progress.recordBuddyAdventure(
        BuddyAdventure.fireworks,
        _fireShape,
        [adventureWords[BuddyAdventure.fireworks]![_fireShape]],
      );
    }
  }

  Widget _fireworksScene() => _touchScene(
    id: 'fireworks-sky',
    action: _fire,
    child: CustomPaint(
      painter: _NightPainter(_clock.value),
      child: const Stack(
        children: [
          Positioned(
            left: 20,
            top: 18,
            child: Text(
              '🌙 点亮属于你的夜空',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Align(
            alignment: Alignment(0, .8),
            child: Text('🏡     🌲     🏠', style: TextStyle(fontSize: 45)),
          ),
        ],
      ),
    ),
  );
  Widget _fireworksControls() => Column(
    children: [
      _choices(const ['⭐ 星星', '💗 爱心', '🌸 花朵'], _fireShape, (i) {
        setState(() {
          _fireShape = i;
          _spokenWord = null;
        });
        _say(adventureWords[BuddyAdventure.fireworks]![i]);
      }, 'firework-shape'),
      const SizedBox(height: 10),
      _choices(
        const ['🟢 薄荷', '🟣 葡萄', '🩷 蜜桃', '🟡 奶油'],
        _fireColor,
        (i) => setState(() => _fireColor = i),
        'firework-color',
      ),
    ],
  );
}

class _JellyBlock extends StatelessWidget {
  const _JellyBlock({
    required this.value,
    this.highlight = false,
    this.squash = 0,
  });
  final int value;
  final bool highlight;
  final double squash;
  @override
  Widget build(BuildContext context) => Transform.scale(
    scaleY: 1 - squash,
    scaleX: 1 + squash / 2,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: value == 0
            ? Colors.white.withValues(alpha: highlight ? .65 : .18)
            : const [
                Colors.transparent,
                Color(0xFF83C9A2),
                Color(0xFFF1B391),
                Color(0xFFAF9EDB),
              ][value],
        borderRadius: BorderRadius.circular(value == 3 ? 24 : 12),
        border: Border.all(color: Colors.white.withValues(alpha: .8), width: 2),
        boxShadow: value == 0
            ? []
            : const [
                BoxShadow(
                  color: Color(0x226E829B),
                  offset: Offset(0, 4),
                  blurRadius: 1,
                ),
              ],
      ),
      child: value == 0
          ? null
          : Text(
              value == 2 ? '▲' : '•  •',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .9),
                fontSize: value == 2 ? 32 : 20,
                decoration: TextDecoration.none,
              ),
            ),
    ),
  );
}

class _EggPainter extends CustomPainter {
  _EggPainter(this.color, this.cracks, this.blanket);
  final int color, cracks;
  final bool blanket;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 155, size.height / 190);
    final path = Path()
      ..moveTo(77, 12)
      ..cubicTo(115, 12, 151, 93, 141, 139)
      ..cubicTo(128, 194, 27, 194, 14, 139)
      ..cubicTo(4, 93, 39, 12, 77, 12)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFF3D6));
    for (var i = 0; i < 7; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            40 + (i * 23 % 77).toDouble(),
            50 + (i * 37 % 102).toDouble(),
          ),
          width: 17,
          height: 22,
        ),
        Paint()..color = buddyColors[color],
      );
    }
    if (blanket) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(9, 114, 137, 57),
          const Radius.circular(22),
        ),
        Paint()..color = const Color(0xFFEAA9B8),
      );
    }
    if (cracks > 0) {
      final crack = Path()..moveTo(76, 40);
      for (var i = 0; i < cracks * 3; i++) {
        crack.lineTo(70 + (i.isEven ? 16 : 0), 50 + i * 12.0);
      }
      canvas.drawPath(
        crack,
        Paint()
          ..color = const Color(0xFFAA9174)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_EggPainter oldDelegate) =>
      color != oldDelegate.color ||
      cracks != oldDelegate.cracks ||
      blanket != oldDelegate.blanket;
}

class _WeatherPainter extends CustomPainter {
  _WeatherPainter(this.time, this.weather, this.power, this.cloud);
  final double time;
  final int weather;
  final List<int> power;
  final Offset cloud;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: weather == 1
              ? const [Color(0xFF92BAD1), Color(0xFFD0E6E8)]
              : const [Color(0xFFAEE1F0), Color(0xFFF3F2CD)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawOval(
      Rect.fromLTWH(
        -size.width * .2,
        size.height * .66,
        size.width * 1.4,
        size.height,
      ),
      Paint()..color = const Color(0xFFA6CDB0),
    );
    if (power[1] > 0) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * .23, size.height * .86),
          width: 45 + power[1] * 12.0,
          height: 16 + power[1] * 3.0,
        ),
        Paint()..color = const Color(0xFF79C9E0),
      );
    }
    final p = Offset(
      cloud.dx * size.width,
      cloud.dy.clamp(.12, .45) * size.height,
    );
    if (weather == 0) {
      canvas.drawCircle(p, 39, Paint()..color = const Color(0xFFFFDF7A));
      for (var i = 0; i < 10; i++) {
        final a = i * math.pi / 5 + time * math.pi * 2;
        canvas.drawLine(
          p + Offset(math.cos(a), math.sin(a)) * 48,
          p + Offset(math.cos(a), math.sin(a)) * 59,
          Paint()
            ..color = const Color(0xFFFFD16C)
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round,
        );
      }
    } else {
      for (var i = 0; i < 3; i++) {
        canvas.drawCircle(
          p + Offset((i - 1) * 25.0, i == 1 ? -12 : 0),
          27,
          Paint()..color = Colors.white.withValues(alpha: .92),
        );
      }
    }
    if (weather == 1) {
      for (var i = 0; i < 28; i++) {
        final x = (i * 53 + 13) % size.width;
        final y = (i * 39 + time * size.height * 4) % (size.height * .78);
        canvas.drawLine(
          Offset(x, y),
          Offset(x - 4, y + 12),
          Paint()
            ..color = const Color(0xFFEEF9FF).withValues(alpha: .8)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
      }
    }
    if (weather == 2) {
      for (var i = 0; i < 8; i++) {
        final x = (time * size.width * 3 + i * 63) % size.width;
        final y = 58 + i * 24.0;
        canvas.drawArc(
          Rect.fromLTWH(x, y, 50, 18),
          .3,
          2.3,
          false,
          Paint()
            ..color = Colors.white.withValues(alpha: .65)
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_WeatherPainter oldDelegate) => true;
}

class _NightPainter extends CustomPainter {
  _NightPainter(this.time);
  final double time;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF242B55), Color(0xFF56568E), Color(0xFFAA80A6)],
        ).createShader(Offset.zero & size),
    );
    for (var i = 0; i < 50; i++) {
      canvas.drawCircle(
        Offset((i * 67 + 19) % size.width, (i * 31 + 17) % (size.height * .7)),
        i % 3 == 0 ? 2 : 1,
        Paint()
          ..color = Colors.white.withValues(
            alpha: .3 + (math.sin(time * math.pi * 2 + i) + 1) * .25,
          ),
      );
    }
    canvas.drawOval(
      Rect.fromLTWH(-20, size.height * .84, size.width + 40, size.height * .3),
      Paint()..color = const Color(0xFF334C62),
    );
  }

  @override
  bool shouldRepaint(_NightPainter oldDelegate) => true;
}
