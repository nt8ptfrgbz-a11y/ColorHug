import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'game_audio.dart';
import 'island_progress.dart';

@immutable
class FruitSliceLevel {
  const FruitSliceLevel({
    required this.name,
    required this.goal,
    required this.fruitIndices,
    this.maxFruits = 3,
    this.sizeScale = 1,
    this.spawnInterval = 0.9,
    this.gravity = 340,
    this.launchFactor = 0.8,
  });

  final String name;
  final int goal;
  final List<int> fruitIndices;
  final int maxFruits;
  final double sizeScale;
  final double spawnInterval;
  final double gravity;
  final double launchFactor;
}

const fruitSliceLevels = <FruitSliceLevel>[
  FruitSliceLevel(name: '大西瓜热身', goal: 6, fruitIndices: [0], sizeScale: 1.18),
  FruitSliceLevel(name: '草莓点点', goal: 7, fruitIndices: [1], sizeScale: 1.12),
  FruitSliceLevel(name: '橙子太阳', goal: 8, fruitIndices: [2], sizeScale: 1.08),
  FruitSliceLevel(name: '苹果脆脆', goal: 8, fruitIndices: [4], sizeScale: 1.08),
  FruitSliceLevel(name: '双果朋友', goal: 9, fruitIndices: [0, 1], maxFruits: 3),
  FruitSliceLevel(name: '热带派对', goal: 9, fruitIndices: [5, 7], sizeScale: 1.06),
  FruitSliceLevel(
    name: '蓝莓泡泡',
    goal: 10,
    fruitIndices: [6],
    maxFruits: 4,
    sizeScale: 0.96,
  ),
  FruitSliceLevel(name: '绿色能量', goal: 10, fruitIndices: [0, 3], maxFruits: 4),
  FruitSliceLevel(name: '红色果园', goal: 10, fruitIndices: [1, 4], maxFruits: 4),
  FruitSliceLevel(
    name: '彩虹果篮',
    goal: 11,
    fruitIndices: [0, 1, 2, 3],
    maxFruits: 4,
  ),
  FruitSliceLevel(
    name: '橙黄旋风',
    goal: 11,
    fruitIndices: [2, 5, 7],
    maxFruits: 4,
    spawnInterval: 0.84,
  ),
  FruitSliceLevel(
    name: '清脆组合',
    goal: 11,
    fruitIndices: [0, 4, 5],
    maxFruits: 4,
  ),
  FruitSliceLevel(
    name: '软软果肉',
    goal: 12,
    fruitIndices: [1, 3, 7],
    maxFruits: 4,
  ),
  FruitSliceLevel(
    name: '莓果星星',
    goal: 12,
    fruitIndices: [1, 6],
    maxFruits: 4,
    sizeScale: 0.98,
  ),
  FruitSliceLevel(
    name: '果汁彩虹',
    goal: 12,
    fruitIndices: [0, 2, 4, 6],
    maxFruits: 4,
  ),
  FruitSliceLevel(
    name: '大果能量',
    goal: 12,
    fruitIndices: [0, 4, 5],
    maxFruits: 4,
    sizeScale: 1.12,
  ),
  FruitSliceLevel(
    name: '轻快双飞',
    goal: 13,
    fruitIndices: [1, 2, 3, 6],
    maxFruits: 4,
    spawnInterval: 0.78,
  ),
  FruitSliceLevel(
    name: '热带彩云',
    goal: 13,
    fruitIndices: [2, 5, 7],
    maxFruits: 4,
    launchFactor: 0.84,
  ),
  FruitSliceLevel(
    name: '四季果园',
    goal: 13,
    fruitIndices: [0, 1, 3, 4],
    maxFruits: 5,
  ),
  FruitSliceLevel(
    name: '水果流星',
    goal: 14,
    fruitIndices: [0, 2, 5, 6],
    maxFruits: 5,
    spawnInterval: 0.75,
  ),
  FruitSliceLevel(
    name: '紫蓝星河',
    goal: 14,
    fruitIndices: [3, 6],
    maxFruits: 5,
    sizeScale: 0.98,
  ),
  FruitSliceLevel(
    name: '红黄闪电',
    goal: 14,
    fruitIndices: [1, 2, 4, 7],
    maxFruits: 5,
  ),
  FruitSliceLevel(
    name: '果园接力',
    goal: 15,
    fruitIndices: [0, 1, 2, 3, 4],
    maxFruits: 5,
    spawnInterval: 0.72,
  ),
  FruitSliceLevel(
    name: '热带接力',
    goal: 15,
    fruitIndices: [2, 5, 6, 7],
    maxFruits: 5,
  ),
  FruitSliceLevel(
    name: '八果集合',
    goal: 15,
    fruitIndices: [0, 1, 2, 3, 4, 5, 6, 7],
    maxFruits: 5,
  ),
  FruitSliceLevel(
    name: '云端果浪',
    goal: 16,
    fruitIndices: [0, 1, 4, 5],
    maxFruits: 5,
    launchFactor: 0.86,
  ),
  FruitSliceLevel(
    name: '彩虹连连',
    goal: 16,
    fruitIndices: [1, 2, 3, 6, 7],
    maxFruits: 5,
    spawnInterval: 0.7,
  ),
  FruitSliceLevel(
    name: '英雄果园',
    goal: 17,
    fruitIndices: [0, 2, 4, 5, 6],
    maxFruits: 5,
  ),
  FruitSliceLevel(
    name: '星际盛宴',
    goal: 17,
    fruitIndices: [0, 1, 2, 3, 4, 5, 6, 7],
    maxFruits: 5,
    spawnInterval: 0.68,
  ),
  FruitSliceLevel(
    name: '彩虹果王',
    goal: 18,
    fruitIndices: [0, 1, 2, 3, 4, 5, 6, 7],
    maxFruits: 5,
    sizeScale: 1.05,
    spawnInterval: 0.66,
  ),
];

const fruitSliceRainbowBonus = 3;
const _fruitEmojis = <String>['🍉', '🍓', '🍊', '🥝', '🍎', '🍍', '🫐', '🍌'];
const _fruitColors = <Color>[
  Color(0xFF43C55B),
  Color(0xFFFF4E66),
  Color(0xFFFF9B28),
  Color(0xFF9BCB46),
  Color(0xFFF04C45),
  Color(0xFFFFC62C),
  Color(0xFF5869D8),
  Color(0xFFFFDC35),
];
const _fruitSliceSounds = <GameSound>[
  GameSound.fruitWatermelon,
  GameSound.fruitStrawberry,
  GameSound.fruitOrange,
  GameSound.fruitKiwi,
  GameSound.fruitApple,
  GameSound.fruitPineapple,
  GameSound.fruitBlueberry,
  GameSound.fruitBanana,
];

class FruitSliceGameScreen extends StatefulWidget {
  const FruitSliceGameScreen({
    super.key,
    required this.progress,
    required this.audio,
  });

  final IslandProgress progress;
  final GameAudioController audio;

  @override
  State<FruitSliceGameScreen> createState() => _FruitSliceGameScreenState();
}

class _FruitSliceGameScreenState extends State<FruitSliceGameScreen>
    with SingleTickerProviderStateMixin {
  static const _instruction = '水果切切乐！用一根手指划过大水果。漏掉也没关系，开心最重要！';

  final math.Random _random = math.Random(20260901);
  final List<_FlyingFruit> _fruits = [];
  final List<_FruitPiece> _pieces = [];
  final List<_JuiceDrop> _juice = [];
  final List<_PulpChunk> _pulp = [];
  final List<_JuiceBurst> _bursts = [];
  final List<_JuiceStain> _stains = [];
  final List<_TrailPoint> _trail = [];

  late final Ticker _ticker;
  late int _levelIndex;
  Duration _lastElapsed = Duration.zero;
  Size _arenaSize = Size.zero;
  ui.Image? _spriteSheet;
  Offset? _lastTouch;
  int _nextFruitId = 0;
  int _score = 0;
  double _spawnWait = 0;
  double _comboLife = 0;
  double _slowMotionRemaining = 0;
  String _comboLabel = '';
  int _swipeSliceCount = 0;
  int _announcedCombo = 0;
  bool _practiceFruitSpawned = false;
  bool _completed = false;

  FruitSliceLevel get _level => fruitSliceLevels[_levelIndex];
  int get _goal => _level.goal;

  @override
  void initState() {
    super.initState();
    _levelIndex = widget.progress.fruitSliceWins
        .clamp(0, fruitSliceLevels.length - 1)
        .toInt();
    _ticker = createTicker(_tick)..start();
    unawaited(_loadSpriteSheet());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(widget.audio.speak(_instruction, voice: GameVoice.child));
    });
  }

  Future<void> _loadSpriteSheet() async {
    try {
      final bytes = await rootBundle.load(
        'assets/fruit_game/fruit-sprites.png',
      );
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() => _spriteSheet = frame.image);
    } catch (_) {
      // Emoji fruit remain as a friendly fallback if an asset cannot be decoded.
    }
  }

  void _tick(Duration elapsed) {
    if (!mounted || _arenaSize.isEmpty) {
      _lastElapsed = elapsed;
      return;
    }
    final rawDelta = _lastElapsed == Duration.zero
        ? 1 / 60
        : (elapsed - _lastElapsed).inMicroseconds /
              Duration.microsecondsPerSecond;
    _lastElapsed = elapsed;
    final dt = rawDelta.clamp(0.0, 0.05);
    final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    _comboLife = math.max(0, _comboLife - dt);
    _slowMotionRemaining = math.max(0, _slowMotionRemaining - dt);
    final simulationDt = _slowMotionRemaining > 0 ? dt * 0.38 : dt;

    if (!_practiceFruitSpawned && !_completed) {
      if (_levelIndex == 0 && widget.progress.fruitSliceWins == 0) {
        _spawnFruit(practice: true);
      }
      _practiceFruitSpawned = true;
    }

    final hasPracticeFruit = _fruits.any((fruit) => fruit.practice);
    if (!_completed && !hasPracticeFruit) {
      _spawnWait -= simulationDt;
      final maximum = _level.maxFruits;
      if (_spawnWait <= 0 && _fruits.length < maximum) {
        _spawnFruit();
      }
    }

    for (final fruit in _fruits) {
      if (fruit.practice) {
        fruit.position = Offset(
          _arenaSize.width * 0.5,
          _arenaSize.height * 0.5 + math.sin(seconds * 2.8) * 7,
        );
        fruit.angle = math.sin(seconds * 2) * 0.045;
        continue;
      }
      fruit.velocity += Offset(0, _level.gravity * simulationDt);
      fruit.position += fruit.velocity * simulationDt;
      fruit.angle += fruit.spin * simulationDt;
    }
    _fruits.removeWhere(
      (fruit) =>
          !fruit.practice &&
          fruit.position.dy > _arenaSize.height + fruit.radius + 30,
    );

    for (final piece in _pieces) {
      piece.life -= simulationDt;
      piece.velocity += Offset(0, 410 * simulationDt);
      piece.position += piece.velocity * simulationDt;
      piece.angle += piece.spin * simulationDt;
    }
    _pieces.removeWhere((piece) => piece.life <= 0);

    for (final drop in _juice) {
      drop.life -= simulationDt;
      drop.velocity += Offset(0, 230 * simulationDt);
      drop.position += drop.velocity * simulationDt;
    }
    _juice.removeWhere((drop) => drop.life <= 0);

    for (final chunk in _pulp) {
      chunk.life -= simulationDt;
      chunk.velocity += Offset(0, 310 * simulationDt);
      chunk.position += chunk.velocity * simulationDt;
      chunk.angle += chunk.spin * simulationDt;
    }
    _pulp.removeWhere((chunk) => chunk.life <= 0);

    for (final burst in _bursts) {
      burst.life -= simulationDt;
      burst.radius += 260 * simulationDt;
    }
    _bursts.removeWhere((burst) => burst.life <= 0);

    for (final point in _trail) {
      point.life -= dt;
    }
    _trail.removeWhere((point) => point.life <= 0);

    setState(() {});
  }

  void _spawnFruit({bool practice = false}) {
    final shortest = math.min(_arenaSize.width, _arenaSize.height);
    final radius = (shortest * (practice ? 0.105 : 0.085) * _level.sizeScale)
        .clamp(practice ? 52.0 : 44.0, practice ? 76.0 : 66.0)
        .toDouble();
    final spriteIndex = practice
        ? 0
        : _level.fruitIndices[_random.nextInt(_level.fruitIndices.length)];
    final rainbow =
        !practice &&
        _levelIndex >= 4 &&
        !_fruits.any((fruit) => fruit.rainbow) &&
        _random.nextDouble() < 0.11;
    if (practice) {
      _fruits.add(
        _FlyingFruit(
          id: _nextFruitId++,
          spriteIndex: spriteIndex,
          position: Offset(_arenaSize.width * 0.5, _arenaSize.height * 0.5),
          velocity: Offset.zero,
          radius: radius,
          practice: true,
        ),
      );
      return;
    }

    final horizontalRoom = math.max(1.0, _arenaSize.width - radius * 2 - 28);
    final x = radius + 14 + _random.nextDouble() * horizontalRoom;
    final horizontalSpeed = (_random.nextDouble() - 0.5) * 100;
    final upwardSpeed =
        _arenaSize.height * (_level.launchFactor + _random.nextDouble() * 0.11);
    _fruits.add(
      _FlyingFruit(
        id: _nextFruitId++,
        spriteIndex: spriteIndex,
        position: Offset(x, _arenaSize.height + radius),
        velocity: Offset(horizontalSpeed, -upwardSpeed),
        radius: radius,
        spin: (_random.nextDouble() - 0.5) * 1.1,
        rainbow: rainbow,
      ),
    );
    _spawnWait = _level.spawnInterval + _random.nextDouble() * 0.2;
  }

  void _beginSwipe(DragStartDetails details) {
    _swipeSliceCount = 0;
    _announcedCombo = 0;
    _lastTouch = details.localPosition;
    _sliceAlong(details.localPosition, details.localPosition);
  }

  void _continueSwipe(DragUpdateDetails details) {
    final current = details.localPosition;
    final previous = _lastTouch ?? current;
    _lastTouch = current;
    _trail.add(_TrailPoint(current));
    if (_trail.length > 18) _trail.removeAt(0);
    _sliceAlong(previous, current);
  }

  void _endSwipe(DragEndDetails _) => _lastTouch = null;

  void _sliceAlong(Offset start, Offset end) {
    if (_completed) return;
    final hits = _fruits
        .where(
          (fruit) => fruitSliceGestureHits(
            start,
            end,
            fruit.position,
            fruit.radius * 1.08,
          ),
        )
        .toList(growable: false);
    if (hits.isEmpty) return;

    for (final fruit in hits) {
      _fruits.remove(fruit);
      _addSliceEffect(fruit);
      _score += fruitSliceScoreFor(rainbow: fruit.rainbow);
      if (fruit.rainbow) {
        _slowMotionRemaining = 1.15;
        _comboLabel = '🌈 彩虹能量 +$fruitSliceRainbowBonus';
        _comboLife = 1.15;
      }
      unawaited(widget.audio.play(fruitSliceSoundFor(fruit.spriteIndex)));
    }
    _swipeSliceCount += hits.length;
    if (_swipeSliceCount >= 2 && _swipeSliceCount > _announcedCombo) {
      _announcedCombo = _swipeSliceCount;
      if (!(_comboLife > 0 && _comboLabel.startsWith('🌈'))) {
        _comboLabel = switch (_swipeSliceCount) {
          >= 5 => '✨ 超级彩虹连切 ×$_swipeSliceCount',
          >= 3 => '⚡ 三果连切 ×$_swipeSliceCount',
          _ => '🌟 双果连切',
        };
        _comboLife = 0.92;
      }
      if (_swipeSliceCount >= 3) {
        _slowMotionRemaining = math.max(_slowMotionRemaining, 0.52);
      }
    }
    unawaited(HapticFeedback.mediumImpact());

    if (_score >= _goal) {
      _completed = true;
      _fruits.clear();
      widget.progress.recordUltraTrainingWin('fruit', _levelIndex);
      unawaited(_announceCompletion());
    }
    setState(() {});
  }

  Future<void> _announceCompletion() async {
    // Let the final crisp fruit slice finish before the quieter celebration.
    await Future<void>.delayed(const Duration(milliseconds: 390));
    if (!mounted || !_completed) return;
    await widget.audio.announce(
      '完成啦！',
      sound: GameSound.complete,
      voice: GameVoice.child,
    );
  }

  void _addSliceEffect(_FlyingFruit fruit) {
    final color = _fruitColors[fruit.spriteIndex];
    final highlight = Color.lerp(color, Colors.white, 0.42)!;
    final effectColors = fruit.rainbow ? _fruitColors : [color, highlight];
    for (var index = 0; index < (fruit.rainbow ? 5 : 1); index++) {
      _bursts.add(
        _JuiceBurst(
          position: fruit.position,
          color: effectColors[index % effectColors.length],
          radius: fruit.radius + index * 7,
        ),
      );
    }
    for (var index = 0; index < (fruit.rainbow ? 7 : 3); index++) {
      _stains.add(
        _JuiceStain(
          position:
              fruit.position +
              Offset(
                (_random.nextDouble() - 0.5) * fruit.radius * 1.35,
                (_random.nextDouble() - 0.5) * fruit.radius * 1.35,
              ),
          color: effectColors[index % effectColors.length],
          radius: fruit.radius * (0.22 + _random.nextDouble() * 0.27),
          seed: _random.nextDouble() * math.pi * 2,
        ),
      );
    }
    if (_stains.length > 36) {
      _stains.removeRange(0, _stains.length - 36);
    }
    for (final leftHalf in [true, false]) {
      _pieces.add(
        _FruitPiece(
          spriteIndex: fruit.spriteIndex,
          leftHalf: leftHalf,
          position: fruit.position + Offset(leftHalf ? -5 : 5, 0),
          velocity: Offset(
            leftHalf ? -155 : 155,
            -145 - _random.nextDouble() * 70,
          ),
          radius: fruit.radius,
          angle: fruit.angle,
          spin: leftHalf ? -3.4 : 3.4,
        ),
      );
    }
    for (var index = 0; index < 34; index++) {
      final direction = _random.nextDouble() * math.pi * 2;
      final speed = 95 + _random.nextDouble() * 310;
      _juice.add(
        _JuiceDrop(
          position:
              fruit.position +
              Offset(
                (_random.nextDouble() - 0.5) * fruit.radius * 0.45,
                (_random.nextDouble() - 0.5) * fruit.radius * 0.45,
              ),
          velocity: Offset(
            math.cos(direction) * speed,
            math.sin(direction) * speed,
          ),
          color: fruit.rainbow
              ? effectColors[index % effectColors.length]
              : (index.isEven ? color : highlight),
          radius: 3 + _random.nextDouble() * 7,
          stretch: 1.4 + _random.nextDouble() * 2.8,
          angle: direction,
        ),
      );
    }
    for (var index = 0; index < 12; index++) {
      final direction = _random.nextDouble() * math.pi * 2;
      final speed = 80 + _random.nextDouble() * 230;
      _pulp.add(
        _PulpChunk(
          position: fruit.position,
          velocity: Offset(
            math.cos(direction) * speed,
            math.sin(direction) * speed - 50,
          ),
          color: fruit.rainbow
              ? effectColors[index % effectColors.length]
              : (index.isEven ? color : highlight),
          size: 6 + _random.nextDouble() * 11,
          angle: direction,
          spin: (_random.nextDouble() - 0.5) * 8,
        ),
      );
    }
  }

  void _nextRound() {
    final next = (_levelIndex + 1) % fruitSliceLevels.length;
    _startLevel(next);
  }

  void _startLevel(int index) {
    setState(() {
      _levelIndex = index;
      _score = 0;
      _spawnWait = 0;
      _completed = false;
      _practiceFruitSpawned = false;
      _fruits.clear();
      _pieces.clear();
      _juice.clear();
      _pulp.clear();
      _bursts.clear();
      _stains.clear();
      _trail.clear();
      _comboLife = 0;
      _slowMotionRemaining = 0;
      _swipeSliceCount = 0;
      _announcedCombo = 0;
    });
  }

  Future<void> _showLevelPicker() async {
    final completed = widget.progress.fruitSliceWins;
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => _FruitLevelPicker(
        current: _levelIndex,
        unlockedThrough: math.min(completed, fruitSliceLevels.length - 1),
      ),
    );
    if (selected != null && mounted) _startLevel(selected);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _spriteSheet?.dispose();
    unawaited(widget.audio.stopSpeech());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF58CDEA),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/fruit_game/fruit-training-bg.png',
            fit: BoxFit.cover,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x33064D8A),
                  Color(0x001AC3D9),
                  Color(0x552A66A5),
                ],
              ),
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              children: [
                _FruitGameHeader(
                  audio: widget.audio,
                  levelIndex: _levelIndex,
                  stars: widget.progress.stars,
                  onChooseLevel: _showLevelPicker,
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      _arenaSize = constraints.biggest;
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            GestureDetector(
                              key: const ValueKey('fruit-slice-arena'),
                              behavior: HitTestBehavior.opaque,
                              onPanStart: _beginSwipe,
                              onPanUpdate: _continueSwipe,
                              onPanEnd: _endSwipe,
                              child: Semantics(
                                label: '水果切切乐区域，用一根手指划过水果',
                                child: CustomPaint(
                                  painter: _FruitGamePainter(
                                    spriteSheet: _spriteSheet,
                                    fruits: _fruits,
                                    pieces: _pieces,
                                    juice: _juice,
                                    pulp: _pulp,
                                    bursts: _bursts,
                                    stains: _stains,
                                    trail: _trail,
                                    rainbowTrail: _slowMotionRemaining > 0,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              left: 10,
                              right: 10,
                              child: IgnorePointer(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _HudPill(
                                      text:
                                          '第${_levelIndex + 1}/${fruitSliceLevels.length}关 · ${_level.name}',
                                      color: const Color(0xFF3164B6),
                                    ),
                                    _HudPill(
                                      key: const ValueKey('fruit-score'),
                                      text: '🍉 $_score/$_goal',
                                      color: const Color(0xFFE84C75),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_comboLife > 0)
                              Positioned(
                                top: 60,
                                left: 20,
                                right: 20,
                                child: IgnorePointer(
                                  child: Center(
                                    child: _ComboBadge(
                                      key: const ValueKey('fruit-combo'),
                                      text: _comboLabel,
                                      intensity: (_comboLife / 1.15).clamp(
                                        0.0,
                                        1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (!_completed)
                              Positioned(
                                left: 18,
                                right: 18,
                                bottom: 12,
                                child: IgnorePointer(
                                  child: Center(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: const Color(0xD9FFFFFF),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 15,
                                          vertical: 8,
                                        ),
                                        child: Text(
                                          '👆 一根手指轻轻划 · 漏掉不扣分',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFF24528D),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (_completed)
                              Positioned.fill(
                                child: _RoundCompleteCard(
                                  levelIndex: _levelIndex,
                                  onNext: _nextRound,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

@visibleForTesting
bool fruitSliceGestureHits(
  Offset start,
  Offset end,
  Offset center,
  double radius,
) {
  final segment = end - start;
  final lengthSquared = segment.dx * segment.dx + segment.dy * segment.dy;
  if (lengthSquared == 0) return (center - start).distance <= radius;
  final toCenter = center - start;
  final projection =
      ((toCenter.dx * segment.dx + toCenter.dy * segment.dy) / lengthSquared)
          .clamp(0.0, 1.0);
  final closest = start + segment * projection;
  return (center - closest).distance <= radius;
}

@visibleForTesting
GameSound fruitSliceSoundFor(int spriteIndex) =>
    _fruitSliceSounds[spriteIndex % _fruitSliceSounds.length];

@visibleForTesting
int fruitSliceScoreFor({required bool rainbow}) =>
    rainbow ? fruitSliceRainbowBonus : 1;

class _FruitGameHeader extends StatelessWidget {
  const _FruitGameHeader({
    required this.audio,
    required this.levelIndex,
    required this.stars,
    required this.onChooseLevel,
  });

  final GameAudioController audio;
  final int levelIndex;
  final int stars;
  final VoidCallback onChooseLevel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filled(
          onPressed: () => Navigator.of(context).pop(),
          tooltip: '返回奥特曼训练营',
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xD9FFFFFF),
            foregroundColor: const Color(0xFF24528D),
          ),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🍉 水果切切乐',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.black38, blurRadius: 6)],
                ),
              ),
              Text(
                '英雄训练：轻轻划过大水果',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Text(
          '⭐ $stars',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 5),
        IconButton.filled(
          key: const ValueKey('fruit-level-picker'),
          onPressed: onChooseLevel,
          tooltip: '选择水果关卡',
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xD9FFFFFF),
            foregroundColor: const Color(0xFF24528D),
          ),
          icon: const Icon(Icons.grid_view_rounded),
        ),
        const SizedBox(width: 5),
        AudioToggleButton(
          audio: audio,
          foregroundColor: const Color(0xFF24528D),
          backgroundColor: const Color(0xD9FFFFFF),
        ),
      ],
    );
  }
}

class _HudPill extends StatelessWidget {
  const _HudPill({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ComboBadge extends StatelessWidget {
  const _ComboBadge({super.key, required this.text, required this.intensity});

  final String text;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final scale = 0.86 + intensity * 0.18;
    return Transform.scale(
      scale: scale,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFE45C), Color(0xFFFF6D8D), Color(0xFF746CFF)],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x884D3CC8),
              blurRadius: 18,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 9),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundCompleteCard extends StatelessWidget {
  const _RoundCompleteCard({required this.levelIndex, required this.onNext});

  final int levelIndex;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0x66103C74),
      child: Center(
        child: Container(
          key: const ValueKey('fruit-round-complete'),
          width: 310,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF9E8),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌈✨🍉', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 4),
              const Text(
                '英雄训练完成！',
                style: TextStyle(
                  color: Color(0xFF24528D),
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${fruitSliceLevels[levelIndex].name}的水果能量收集成功',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF5072A1),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                key: const ValueKey('fruit-next-round'),
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE84C75),
                  minimumSize: const Size(210, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  levelIndex == fruitSliceLevels.length - 1 ? '再玩一轮' : '下一关',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FruitLevelPicker extends StatelessWidget {
  const _FruitLevelPicker({
    required this.current,
    required this.unlockedThrough,
  });

  final int current;
  final int unlockedThrough;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '🗺️ 选择水果关卡',
                      style: TextStyle(
                        color: Color(0xFF24528D),
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: '关闭关卡选择',
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '完成当前关卡就会解锁下一关',
                  style: TextStyle(color: Color(0xFF6781A5), fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 440 ? 5 : 4;
                    return GridView.builder(
                      itemCount: fruitSliceLevels.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.86,
                      ),
                      itemBuilder: (context, index) {
                        final unlocked = index <= unlockedThrough;
                        final selected = index == current;
                        return Material(
                          color: unlocked
                              ? (selected
                                    ? const Color(0xFFFFD866)
                                    : const Color(0xFFE9F7FF))
                              : const Color(0xFFE7E9EE),
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            key: ValueKey('fruit-select-level-$index'),
                            onTap: unlocked
                                ? () => Navigator.of(context).pop(index)
                                : null,
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    unlocked ? _fruitEmojis[index % 8] : '🔒',
                                    style: const TextStyle(fontSize: 23),
                                  ),
                                  Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: unlocked
                                          ? const Color(0xFF24528D)
                                          : const Color(0xFF9299A5),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  if (selected)
                                    const Text(
                                      '正在玩',
                                      style: TextStyle(
                                        color: Color(0xFFB85A25),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FruitGamePainter extends CustomPainter {
  const _FruitGamePainter({
    required this.spriteSheet,
    required this.fruits,
    required this.pieces,
    required this.juice,
    required this.pulp,
    required this.bursts,
    required this.stains,
    required this.trail,
    required this.rainbowTrail,
  });

  final ui.Image? spriteSheet;
  final List<_FlyingFruit> fruits;
  final List<_FruitPiece> pieces;
  final List<_JuiceDrop> juice;
  final List<_PulpChunk> pulp;
  final List<_JuiceBurst> bursts;
  final List<_JuiceStain> stains;
  final List<_TrailPoint> trail;
  final bool rainbowTrail;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stain in stains) {
      _drawStain(canvas, stain);
    }
    if (trail.length > 1) {
      final path = Path()
        ..moveTo(trail.first.position.dx, trail.first.position.dy);
      for (final point in trail.skip(1)) {
        path.lineTo(point.position.dx, point.position.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xEFFFFFFF)
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawPath(
        path,
        Paint()
          ..shader = rainbowTrail
              ? const LinearGradient(
                  colors: [
                    Color(0xFFFF4F64),
                    Color(0xFFFFD84A),
                    Color(0xFF42D7D0),
                    Color(0xFF746CFF),
                  ],
                ).createShader(Offset.zero & size)
              : null
          ..color = const Color(0xFFFFF36D)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }

    for (final burst in bursts) {
      final opacity = (burst.life / burst.maxLife).clamp(0.0, 1.0);
      final splashPaint = Paint()
        ..color = burst.color.withValues(alpha: opacity * 0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10 * opacity + 2;
      canvas.drawCircle(burst.position, burst.radius, splashPaint);
      for (var ray = 0; ray < 12; ray++) {
        final angle = ray * math.pi / 6;
        final inner = burst.radius * 0.72;
        final outer = burst.radius * (1.18 + (ray.isEven ? 0.24 : 0));
        canvas.drawLine(
          burst.position +
              Offset(math.cos(angle) * inner, math.sin(angle) * inner),
          burst.position +
              Offset(math.cos(angle) * outer, math.sin(angle) * outer),
          splashPaint..strokeCap = StrokeCap.round,
        );
      }
    }
    for (final drop in juice) {
      final opacity = (drop.life / drop.maxLife).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(drop.position.dx, drop.position.dy);
      canvas.rotate(drop.angle);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: drop.radius * drop.stretch,
          height: drop.radius,
        ),
        Paint()
          ..color = drop.color.withValues(alpha: opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8),
      );
      canvas.restore();
    }
    for (final chunk in pulp) {
      final opacity = (chunk.life / chunk.maxLife).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(chunk.position.dx, chunk.position.dy);
      canvas.rotate(chunk.angle);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: chunk.size * 1.45,
          height: chunk.size,
        ),
        Radius.circular(chunk.size * 0.32),
      );
      canvas.drawRRect(
        rect,
        Paint()..color = chunk.color.withValues(alpha: opacity),
      );
      canvas.drawCircle(
        Offset(-chunk.size * 0.2, -chunk.size * 0.15),
        chunk.size * 0.16,
        Paint()..color = Colors.white.withValues(alpha: opacity * 0.65),
      );
      canvas.restore();
    }
    for (final piece in pieces) {
      _drawFruitHalf(canvas, piece);
    }
    for (final fruit in fruits) {
      if (fruit.rainbow) _drawRainbowAura(canvas, fruit);
      _drawFruit(canvas, fruit);
      if (fruit.practice) {
        canvas.drawCircle(
          fruit.position,
          fruit.radius + 12,
          Paint()
            ..color = const Color(0xCCFFF36D)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5,
        );
      }
    }
  }

  void _drawStain(Canvas canvas, _JuiceStain stain) {
    final paint = Paint()..color = stain.color.withValues(alpha: 0.2);
    canvas.drawCircle(stain.position, stain.radius, paint);
    for (var spot = 0; spot < 7; spot++) {
      final angle = stain.seed + spot * math.pi * 2 / 7;
      final distance = stain.radius * (0.72 + (spot.isEven ? 0.24 : 0.05));
      canvas.drawCircle(
        stain.position +
            Offset(math.cos(angle) * distance, math.sin(angle) * distance),
        stain.radius * (0.22 + (spot % 3) * 0.07),
        paint,
      );
    }
  }

  void _drawRainbowAura(Canvas canvas, _FlyingFruit fruit) {
    final ring = Rect.fromCircle(
      center: fruit.position,
      radius: fruit.radius + 13,
    );
    canvas.drawCircle(
      fruit.position,
      fruit.radius + 12,
      Paint()
        ..shader = const SweepGradient(
          colors: [
            Color(0xFFFF4F64),
            Color(0xFFFFD84A),
            Color(0xFF45CE75),
            Color(0xFF42D7D0),
            Color(0xFF4687FF),
            Color(0xFF9B67E8),
            Color(0xFFFF4F64),
          ],
        ).createShader(ring)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(
      fruit.position,
      fruit.radius + 4,
      Paint()
        ..color = const Color(0xAAFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  Rect _sourceCell(int index) {
    final image = spriteSheet!;
    final cellWidth = image.width / 4;
    final cellHeight = image.height / 2;
    return Rect.fromLTWH(
      (index % 4) * cellWidth,
      (index ~/ 4) * cellHeight,
      cellWidth,
      cellHeight,
    );
  }

  void _drawFruit(Canvas canvas, _FlyingFruit fruit) {
    canvas.save();
    canvas.translate(fruit.position.dx, fruit.position.dy);
    canvas.rotate(fruit.angle);
    if (spriteSheet case final image?) {
      canvas.drawImageRect(
        image,
        _sourceCell(fruit.spriteIndex),
        Rect.fromCenter(
          center: Offset.zero,
          width: fruit.radius * 2,
          height: fruit.radius * 2,
        ),
        Paint()..filterQuality = FilterQuality.high,
      );
    } else {
      final painter = TextPainter(
        text: TextSpan(
          text: _fruitEmojis[fruit.spriteIndex],
          style: TextStyle(fontSize: fruit.radius * 1.55),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    }
    canvas.restore();
  }

  void _drawFruitHalf(Canvas canvas, _FruitPiece piece) {
    final opacity = (piece.life / piece.maxLife).clamp(0.0, 1.0);
    canvas.save();
    canvas.translate(piece.position.dx, piece.position.dy);
    canvas.rotate(piece.angle);
    if (spriteSheet case final image?) {
      final cell = _sourceCell(piece.spriteIndex);
      final source = Rect.fromLTWH(
        piece.leftHalf ? cell.left : cell.center.dx,
        cell.top,
        cell.width / 2,
        cell.height,
      );
      final destination = Rect.fromLTWH(
        piece.leftHalf ? -piece.radius : 0,
        -piece.radius,
        piece.radius,
        piece.radius * 2,
      );
      canvas.drawImageRect(
        image,
        source,
        destination,
        Paint()
          ..filterQuality = FilterQuality.high
          ..color = Colors.white.withValues(alpha: opacity),
      );
    } else {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: piece.radius,
          height: piece.radius * 1.7,
        ),
        Paint()
          ..color = _fruitColors[piece.spriteIndex].withValues(alpha: opacity),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FruitGamePainter oldDelegate) => true;
}

class _FlyingFruit {
  _FlyingFruit({
    required this.id,
    required this.spriteIndex,
    required this.position,
    required this.velocity,
    required this.radius,
    this.practice = false,
    this.spin = 0,
    this.rainbow = false,
  });

  final int id;
  final int spriteIndex;
  Offset position;
  Offset velocity;
  final double radius;
  final bool practice;
  final bool rainbow;
  double angle = 0;
  final double spin;
}

class _FruitPiece {
  _FruitPiece({
    required this.spriteIndex,
    required this.leftHalf,
    required this.position,
    required this.velocity,
    required this.radius,
    required this.angle,
    required this.spin,
  });

  final int spriteIndex;
  final bool leftHalf;
  Offset position;
  Offset velocity;
  final double radius;
  double angle;
  final double spin;
  double life = 0.9;
  final double maxLife = 0.9;
}

class _JuiceDrop {
  _JuiceDrop({
    required this.position,
    required this.velocity,
    required this.color,
    required this.radius,
    required this.stretch,
    required this.angle,
  });

  Offset position;
  Offset velocity;
  final Color color;
  final double radius;
  final double stretch;
  final double angle;
  double life = 0.78;
  final double maxLife = 0.78;
}

class _PulpChunk {
  _PulpChunk({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.angle,
    required this.spin,
  });

  Offset position;
  Offset velocity;
  final Color color;
  final double size;
  double angle;
  final double spin;
  double life = 0.92;
  final double maxLife = 0.92;
}

class _JuiceBurst {
  _JuiceBurst({
    required this.position,
    required this.color,
    required this.radius,
  });

  final Offset position;
  final Color color;
  double radius;
  double life = 0.46;
  final double maxLife = 0.46;
}

class _JuiceStain {
  const _JuiceStain({
    required this.position,
    required this.color,
    required this.radius,
    required this.seed,
  });

  final Offset position;
  final Color color;
  final double radius;
  final double seed;
}

class _TrailPoint {
  _TrailPoint(this.position);

  final Offset position;
  double life = 0.22;
}
