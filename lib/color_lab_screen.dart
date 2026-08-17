import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'color_challenges.dart';
import 'color_mixer.dart';

class ColorLabScreen extends StatefulWidget {
  const ColorLabScreen({super.key});

  @override
  State<ColorLabScreen> createState() => _ColorLabScreenState();
}

class _ColorLabScreenState extends State<ColorLabScreen>
    with TickerProviderStateMixin {
  late final AnimationController _breathingController;
  late final AnimationController _mergeController;
  late final AnimationController _splitController;
  late final AnimationController _celebrationController;
  late final AnimationController _reactionController;

  final List<ColorBlob> _blobs = [];
  final math.Random _random = math.Random(2408);

  MixMode _mode = MixMode.light;
  Size _canvasSize = Size.zero;
  int _nextId = 1;
  int? _draggingId;
  int? _nearbyId;
  Offset _pointerOffset = Offset.zero;
  Offset _lastDragDelta = Offset.zero;
  MergeAnimation? _activeMerge;
  ColorChallenge? _challenge;
  CelebrationScene? _celebration;
  TapReaction? _reaction;
  Set<int> _splittingIds = const {};
  String _message = '拖动两只颜色精灵，让它们抱一抱';
  int _messageRevision = 0;
  int _lightChallengeIndex = 0;
  int _paintChallengeIndex = 0;
  int _stars = 0;
  bool _challengeCompleted = false;

  bool get _isBusy => _activeMerge != null;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
    _mergeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    )..addStatusListener(_finishMerge);
    _splitController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 700),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() => _splittingIds = const {});
          }
        });
    _celebrationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1900),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() => _celebration = null);
          }
        });
    _reactionController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 850),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() => _reaction = null);
          }
        });
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _mergeController.dispose();
    _splitController.dispose();
    _celebrationController.dispose();
    _reactionController.dispose();
    super.dispose();
  }

  void _layoutCanvas(Size size) {
    if (size.isEmpty || size == _canvasSize) {
      return;
    }
    final previous = _canvasSize;
    _canvasSize = size;
    if (_blobs.isEmpty && _activeMerge == null) {
      _seedPlayground();
      return;
    }
    if (!previous.isEmpty) {
      final scaleX = size.width / previous.width;
      final scaleY = size.height / previous.height;
      for (final blob in _blobs) {
        blob.position = _clampPosition(
          Offset(blob.position.dx * scaleX, blob.position.dy * scaleY),
          blob.radius,
        );
      }
    }
  }

  void _seedPlayground() {
    if (_canvasSize.isEmpty) return;
    final challenge = _challenge;
    if (challenge != null) {
      _seedChallenge(challenge);
      return;
    }
    final compact = _canvasSize.width < 560;
    final radius = _blobRadius;
    final seeds = compact
        ? [paletteIngredients[0], paletteIngredients[3], paletteIngredients[1]]
        : [
            paletteIngredients[0],
            paletteIngredients[3],
            paletteIngredients[1],
            paletteIngredients[2],
          ];
    final fractions = compact
        ? const [Offset(0.24, 0.32), Offset(0.73, 0.30), Offset(0.48, 0.70)]
        : const [
            Offset(0.18, 0.48),
            Offset(0.41, 0.30),
            Offset(0.64, 0.55),
            Offset(0.82, 0.30),
          ];
    for (var index = 0; index < seeds.length; index++) {
      _blobs.add(
        ColorBlob(
          id: _nextId++,
          ingredients: [seeds[index]],
          color: seeds[index].color,
          name: seeds[index].name,
          position: Offset(
            _canvasSize.width * fractions[index].dx,
            _canvasSize.height * fractions[index].dy,
          ),
          radius: radius,
          phase: _random.nextDouble() * math.pi * 2,
        ),
      );
    }
  }

  void _seedChallenge(ColorChallenge challenge) {
    final radius = _blobRadius;
    final ingredients = challenge.ingredients;
    final positions = [
      Offset(_canvasSize.width * 0.28, _canvasSize.height * 0.52),
      Offset(_canvasSize.width * 0.72, _canvasSize.height * 0.52),
    ];
    for (var index = 0; index < ingredients.length; index++) {
      final ingredient = ingredients[index];
      _blobs.add(
        ColorBlob(
          id: _nextId++,
          ingredients: [ingredient],
          color: ingredient.color,
          name: ingredient.name,
          position: _clampPosition(positions[index], radius),
          radius: radius,
          phase: _random.nextDouble() * math.pi * 2,
        ),
      );
    }
  }

  double get _blobRadius {
    if (_canvasSize.width < 420) return 43;
    if (_canvasSize.width < 700) return 50;
    return 58;
  }

  void _setMode(MixMode mode) {
    if (_mode == mode || _isBusy) return;
    HapticFeedback.selectionClick();
    setState(() {
      _mode = mode;
      if (_challenge != null) {
        _challenge = _takeNextChallenge(mode);
        _challengeCompleted = false;
      }
      _blobs.clear();
      _nearbyId = null;
      _draggingId = null;
      _message =
          _challenge?.prompt ??
          (mode == MixMode.light ? '小灯光们见面后，会越来越亮' : '小颜料们见面后，会慢慢搅在一起');
      _messageRevision++;
      _seedPlayground();
    });
  }

  void _reset() {
    if (_isBusy) return;
    HapticFeedback.lightImpact();
    setState(() {
      _blobs.clear();
      _draggingId = null;
      _nearbyId = null;
      _challengeCompleted = false;
      _message = _challenge?.prompt ?? '颜色精灵们准备好啦！';
      _messageRevision++;
      _seedPlayground();
    });
  }

  ColorChallenge _takeNextChallenge(MixMode mode) {
    if (mode == MixMode.light) {
      final challenge =
          lightChallenges[_lightChallengeIndex % lightChallenges.length];
      _lightChallengeIndex++;
      return challenge;
    }
    final challenge =
        paintChallenges[_paintChallengeIndex % paintChallenges.length];
    _paintChallengeIndex++;
    return challenge;
  }

  void _toggleChallenge() {
    if (_isBusy || _canvasSize.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _blobs.clear();
      _challengeCompleted = false;
      if (_challenge == null) {
        _challenge = _takeNextChallenge(_mode);
        _message = _challenge!.prompt;
      } else {
        _challenge = null;
        _message = '回到自由抱抱，想怎么混都可以！';
      }
      _messageRevision++;
      _seedPlayground();
    });
  }

  void _nextChallenge() {
    if (_isBusy || _canvasSize.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _blobs.clear();
      _challenge = _takeNextChallenge(_mode);
      _challengeCompleted = false;
      _message = _challenge!.prompt;
      _messageRevision++;
      _seedPlayground();
    });
  }

  void _addIngredient(ColorIngredient ingredient) {
    if (_isBusy || _canvasSize.isEmpty) return;
    if (_blobs.length >= 10) {
      setState(() {
        _message = '小精灵有点多啦，先让它们抱一抱吧！';
        _messageRevision++;
      });
      HapticFeedback.mediumImpact();
      return;
    }

    final radius = _blobRadius;
    final lane = _blobs.length % 5;
    final x = _canvasSize.width * (0.18 + lane * 0.16);
    final y = math.max(radius + 18, _canvasSize.height * 0.72);
    final blob = ColorBlob(
      id: _nextId++,
      ingredients: [ingredient],
      color: ingredient.color,
      name: ingredient.name,
      position: _clampPosition(Offset(x, y), radius),
      radius: radius,
      phase: _random.nextDouble() * math.pi * 2,
    );
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.selectionClick();
    setState(() {
      _blobs.add(blob);
      _splittingIds = {blob.id};
      _message = '${ingredient.name}小精灵来啦！';
      _messageRevision++;
    });
    _splitController.forward(from: 0);
  }

  void _onPanStart(DragStartDetails details) {
    if (_isBusy) return;
    final blob = _hitTest(details.localPosition);
    if (blob == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _draggingId = blob.id;
      _pointerOffset = details.localPosition - blob.position;
      _lastDragDelta = Offset.zero;
      _blobs.remove(blob);
      _blobs.add(blob);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final id = _draggingId;
    if (id == null || _isBusy) return;
    final blob = _blobById(id);
    if (blob == null) return;

    final desired = details.localPosition - _pointerOffset;
    final candidate = _nearestMergeCandidate(blob, desired);
    var nextPosition = desired;
    if (candidate != null) {
      final distance = (candidate.position - desired).distance;
      final magneticRange = blob.radius + candidate.radius + 52;
      final strength = ((magneticRange - distance) / magneticRange).clamp(
        0.0,
        0.18,
      );
      nextPosition = Offset.lerp(desired, candidate.position, strength)!;
    }

    setState(() {
      _lastDragDelta = details.delta;
      blob.position = _clampPosition(nextPosition, blob.radius);
      _nearbyId = candidate?.id;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final draggingId = _draggingId;
    final nearbyId = _nearbyId;
    setState(() {
      _draggingId = null;
      _nearbyId = null;
      _lastDragDelta = Offset.zero;
    });
    if (draggingId == null || nearbyId == null || _isBusy) return;
    final first = _blobById(draggingId);
    final second = _blobById(nearbyId);
    if (first != null && second != null) _beginMerge(first, second);
  }

  void _onPanCancel() {
    if (_draggingId == null) return;
    setState(() {
      _draggingId = null;
      _nearbyId = null;
      _lastDragDelta = Offset.zero;
    });
  }

  void _onTapUp(TapUpDetails details) {
    if (_isBusy) return;
    final blob = _hitTest(details.localPosition);
    if (blob == null) {
      final emojis = ['✨', '🫧', '🌟', '🌈'];
      _showTapReaction(
        details.localPosition,
        emojis[_messageRevision % emojis.length],
        Colors.white,
      );
      return;
    }
    if (blob.ingredients.length > 1) {
      _splitBlob(blob);
    } else {
      final emojis = ['🥰', '😄', '👋', '⭐'];
      final messages = [
        '哈哈，好痒呀！',
        '我是${blob.name}小精灵！',
        '帮我找一个颜色朋友吧',
        '再点一下，我会跳舞哦！',
      ];
      final reactionIndex = (blob.id + _messageRevision) % emojis.length;
      HapticFeedback.selectionClick();
      setState(() {
        _splittingIds = {blob.id};
        _reaction = TapReaction(
          position: blob.position,
          emoji: emojis[reactionIndex],
          color: blob.color,
        );
        _message = messages[reactionIndex];
        _messageRevision++;
      });
      _splitController.forward(from: 0);
      _reactionController.forward(from: 0);
    }
  }

  void _showTapReaction(Offset position, String emoji, Color color) {
    HapticFeedback.selectionClick();
    setState(() {
      _reaction = TapReaction(position: position, emoji: emoji, color: color);
    });
    _reactionController.forward(from: 0);
  }

  ColorBlob? _hitTest(Offset point) {
    for (final blob in _blobs.reversed) {
      if ((point - blob.position).distance <= blob.radius + 18) return blob;
    }
    return null;
  }

  ColorBlob? _nearestMergeCandidate(ColorBlob source, Offset position) {
    ColorBlob? nearest;
    var bestDistance = double.infinity;
    for (final candidate in _blobs) {
      if (candidate.id == source.id) continue;
      final distance = (candidate.position - position).distance;
      final range = source.radius + candidate.radius + 52;
      if (distance < range && distance < bestDistance) {
        nearest = candidate;
        bestDistance = distance;
      }
    }
    return nearest;
  }

  ColorBlob? _blobById(int id) {
    for (final blob in _blobs) {
      if (blob.id == id) return blob;
    }
    return null;
  }

  void _beginMerge(ColorBlob first, ColorBlob second) {
    final ingredients = [...first.ingredients, ...second.ingredients];
    final result = ColorMixer.mix(ingredients, _mode);
    final target = Offset.lerp(first.position, second.position, 0.5)!;
    final resultRadius = math.min(
      _blobRadius * 1.32,
      math.sqrt(
            (first.radius * first.radius) + (second.radius * second.radius),
          ) *
          0.92,
    );
    final particles = List.generate(18, (index) {
      final angle = (math.pi * 2 * index / 18) + _random.nextDouble() * 0.18;
      return MergeParticle(
        angle: angle,
        distance: 42 + _random.nextDouble() * 65,
        radius: 2.5 + _random.nextDouble() * 5.5,
        color: index.isEven ? first.color : second.color,
      );
    });

    setState(() {
      _blobs.remove(first);
      _blobs.remove(second);
      _activeMerge = MergeAnimation(
        first: first.copy(),
        second: second.copy(),
        target: _clampPosition(target, resultRadius),
        result: result,
        ingredients: ingredients,
        resultRadius: resultRadius,
        particles: particles,
      );
      _message = '快看，它们正在抱抱……';
      _messageRevision++;
    });
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
    _mergeController.forward(from: 0);
  }

  void _finishMerge(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    final merge = _activeMerge;
    if (merge == null) return;

    final blob = ColorBlob(
      id: _nextId++,
      ingredients: merge.ingredients,
      color: merge.result.color,
      name: merge.result.name,
      position: merge.target,
      radius: merge.resultRadius,
      phase: _random.nextDouble() * math.pi * 2,
    );
    final firstName = merge.first.name;
    final secondName = merge.second.name;
    final challenge = _challenge;
    final challengeSuccess =
        challenge != null &&
        !_challengeCompleted &&
        blob.name == challenge.target.name;
    setState(() {
      _activeMerge = null;
      _blobs.add(blob);
      _splittingIds = {blob.id};
      if (challengeSuccess) {
        _challengeCompleted = true;
        _stars++;
        _message = '太棒啦！${challenge.emoji} ${challenge.surpriseName}来做客了！';
      } else if (challenge != null) {
        _message = '差一点点！点一下${blob.name}拆开，再试一次';
      } else {
        _message = _mode == MixMode.light
            ? '$firstName的光 + $secondName的光 = ${blob.name}的光！'
            : '$firstName颜料 + $secondName颜料 = ${blob.name}颜料！';
      }
      _messageRevision++;
    });
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
    _splitController.forward(from: 0);
    _startCelebration(
      position: blob.position,
      color: blob.color,
      emoji: challengeSuccess ? challenge.emoji : _surpriseEmojiFor(blob.name),
      big: challengeSuccess,
    );
  }

  void _startCelebration({
    required Offset position,
    required Color color,
    required String emoji,
    required bool big,
  }) {
    final colors = [
      color,
      const Color(0xFFFFD84A),
      const Color(0xFFFF5D7A),
      const Color(0xFF42D7D0),
      const Color(0xFF9B67E8),
    ];
    final particles = List.generate(big ? 46 : 18, (index) {
      return CelebrationParticle(
        normalizedX: _random.nextDouble(),
        delay: _random.nextDouble() * (big ? 0.34 : 0.18),
        speed: 0.72 + _random.nextDouble() * 0.50,
        size: 5 + _random.nextDouble() * 8,
        spin: (_random.nextDouble() - 0.5) * math.pi * 5,
        color: colors[index % colors.length],
      );
    });
    setState(() {
      _celebration = CelebrationScene(
        position: position,
        emoji: emoji,
        color: color,
        particles: particles,
        big: big,
      );
    });
    _celebrationController.forward(from: 0);
  }

  String _surpriseEmojiFor(String colorName) {
    if (colorName.contains('黄')) return '☀️';
    if (colorName.contains('绿')) return '🌱';
    if (colorName.contains('紫')) return '🍇';
    if (colorName.contains('橙')) return '🍊';
    if (colorName.contains('棕')) return '🐻';
    if (colorName.contains('蓝') || colorName.contains('青')) return '🐳';
    if (colorName.contains('白')) return '⭐';
    if (colorName.contains('粉') || colorName.contains('红')) return '🌸';
    return '✨';
  }

  void _splitBlob(ColorBlob blob) {
    final count = blob.ingredients.length;
    final radius = _blobRadius;
    final created = <ColorBlob>[];
    for (var index = 0; index < count; index++) {
      final ingredient = blob.ingredients[index];
      final angle = (-math.pi / 2) + (math.pi * 2 * index / count);
      final distance = math.min(radius * 1.55, 42.0 + count * 7.0);
      final position = _clampPosition(
        blob.position + Offset(math.cos(angle), math.sin(angle)) * distance,
        radius,
      );
      created.add(
        ColorBlob(
          id: _nextId++,
          ingredients: [ingredient],
          color: ingredient.color,
          name: ingredient.name,
          position: position,
          radius: radius,
          phase: _random.nextDouble() * math.pi * 2,
        ),
      );
    }
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
    setState(() {
      _blobs.remove(blob);
      _blobs.addAll(created);
      _splittingIds = created.map((item) => item.id).toSet();
      _message = _challenge == null
          ? '啪！${blob.name}小精灵又变回了原来的颜色'
          : _challengeCompleted
          ? '这一关已经完成啦，点箭头去下一关吧！'
          : '再试一次：${_challenge!.prompt}';
      _messageRevision++;
    });
    _splitController.forward(from: 0);
  }

  Offset _clampPosition(Offset position, double radius) {
    if (_canvasSize.isEmpty) return position;
    final padding = radius + 12;
    final bottomPadding = radius + 30;
    return Offset(
      position.dx.clamp(
        padding,
        math.max(padding, _canvasSize.width - padding),
      ),
      position.dy.clamp(
        padding,
        math.max(padding, _canvasSize.height - bottomPadding),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final compact = media.size.width < 650 || media.size.height < 620;
    final isLight = _mode == MixMode.light;
    return Scaffold(
      backgroundColor: isLight
          ? const Color(0xFF10172E)
          : const Color(0xFFFFF3D9),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isLight
                ? const [
                    Color(0xFF10172E),
                    Color(0xFF251B50),
                    Color(0xFF132943),
                  ]
                : const [
                    Color(0xFFFFF8E9),
                    Color(0xFFFFE7C4),
                    Color(0xFFFFF3DA),
                  ],
          ),
        ),
        child: SafeArea(
          minimum: EdgeInsets.fromLTRB(
            compact ? 10 : 18,
            8,
            compact ? 10 : 18,
            10,
          ),
          child: Column(
            children: [
              _buildHeader(compact),
              SizedBox(height: compact ? 7 : 12),
              _buildMessage(compact),
              SizedBox(height: compact ? 7 : 12),
              Expanded(child: _buildPlayground()),
              SizedBox(height: compact ? 8 : 12),
              _buildPalette(compact),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool compact) {
    final textColor = _mode == MixMode.light
        ? Colors.white
        : const Color(0xFF523E35);
    return Row(
      children: [
        Container(
          width: compact ? 42 : 54,
          height: compact ? 42 : 54,
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: _mode == MixMode.light ? 0.13 : 0.62,
            ),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text('🌈', style: TextStyle(fontSize: compact ? 23 : 30)),
        ),
        SizedBox(width: compact ? 8 : 12),
        if (!compact || MediaQuery.sizeOf(context).width > 480)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '颜色抱抱',
                  style: TextStyle(
                    color: textColor,
                    fontSize: compact ? 20 : 27,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                if (!compact)
                  Text(
                    '拖动小精灵，发现新颜色',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.68),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          )
        else
          const Spacer(),
        _ModeSelector(mode: _mode, compact: compact, onChanged: _setMode),
        const SizedBox(width: 8),
        Semantics(
          button: true,
          selected: _challenge != null,
          label: _challenge == null ? '开始颜色小任务' : '退出颜色小任务',
          child: IconButton.filledTonal(
            key: const ValueKey('challenge-toggle'),
            onPressed: _isBusy ? null : _toggleChallenge,
            tooltip: _challenge == null ? '颜色小任务' : '回到自由玩',
            iconSize: compact ? 21 : 25,
            icon: Icon(
              _challenge == null ? Icons.flag_rounded : Icons.close_rounded,
            ),
            style: IconButton.styleFrom(
              foregroundColor: _challenge != null
                  ? const Color(0xFFFFB423)
                  : textColor,
              backgroundColor: Colors.white.withValues(
                alpha: _mode == MixMode.light ? 0.13 : 0.62,
              ),
            ),
          ),
        ),
        SizedBox(width: compact ? 4 : 8),
        Semantics(
          button: true,
          label: '重新开始',
          child: IconButton.filledTonal(
            onPressed: _isBusy ? null : _reset,
            tooltip: '重新开始',
            iconSize: compact ? 21 : 25,
            icon: const Icon(Icons.refresh_rounded),
            style: IconButton.styleFrom(
              foregroundColor: textColor,
              backgroundColor: Colors.white.withValues(
                alpha: _mode == MixMode.light ? 0.13 : 0.62,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessage(bool compact) {
    final isLight = _mode == MixMode.light;
    final messageStyle = TextStyle(
      color: isLight ? Colors.white : const Color(0xFF624A3C),
      fontSize: compact ? 14 : 17,
      fontWeight: FontWeight.w800,
    );
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 340),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.96, end: 1.0).animate(animation),
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey(_messageRevision),
        constraints: const BoxConstraints(minHeight: 42),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 13 : 20,
          vertical: compact ? 9 : 11,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isLight ? 0.12 : 0.72),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withValues(alpha: isLight ? 0.12 : 0.76),
          ),
        ),
        alignment: Alignment.center,
        child: _challenge == null
            ? Text(
                _message,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: messageStyle,
              )
            : Row(
                children: [
                  Container(
                    width: compact ? 31 : 38,
                    height: compact ? 31 : 38,
                    decoration: BoxDecoration(
                      color: _challenge!.target.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: _challenge!.target.color.withValues(
                            alpha: 0.42,
                          ),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _challengeCompleted ? '✓' : '?',
                      style: TextStyle(
                        color: ColorMixer.readableInk(_challenge!.target.color),
                        fontWeight: FontWeight.w900,
                        fontSize: compact ? 16 : 20,
                      ),
                    ),
                  ),
                  SizedBox(width: compact ? 8 : 11),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🎯 颜色小任务',
                          style: TextStyle(
                            color: messageStyle.color?.withValues(alpha: 0.72),
                            fontSize: compact ? 10 : 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          _message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: messageStyle,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 7 : 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD84A).withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '⭐ $_stars',
                      style: messageStyle.copyWith(fontSize: compact ? 12 : 14),
                    ),
                  ),
                  if (_challengeCompleted) ...[
                    const SizedBox(width: 4),
                    IconButton.filled(
                      key: const ValueKey('next-challenge'),
                      onPressed: _nextChallenge,
                      tooltip: '下一个任务',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildPlayground() {
    final isLight = _mode == MixMode.light;
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isLight
              ? const Color(0xFF0C132A).withValues(alpha: 0.66)
              : const Color(0xFFFFFCF3).withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withValues(alpha: isLight ? 0.12 : 0.92),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isLight ? 0.20 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            if (size != _canvasSize) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _layoutCanvas(size));
              });
            }
            return Semantics(
              label: '颜色精灵游戏区，拖动一只精灵靠近另一只',
              child: GestureDetector(
                key: const ValueKey('color-playground'),
                behavior: HitTestBehavior.opaque,
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                onPanCancel: _onPanCancel,
                onTapUp: _onTapUp,
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _breathingController,
                    _mergeController,
                    _splitController,
                    _celebrationController,
                    _reactionController,
                  ]),
                  builder: (context, child) => CustomPaint(
                    size: Size.infinite,
                    painter: ColorPlaygroundPainter(
                      mode: _mode,
                      blobs: _blobs,
                      time: _breathingController.value,
                      draggingId: _draggingId,
                      nearbyId: _nearbyId,
                      dragDelta: _lastDragDelta,
                      merge: _activeMerge,
                      mergeProgress: _mergeController.value,
                      splittingIds: _splittingIds,
                      splitProgress: _splitController.value,
                      celebration: _celebration,
                      celebrationProgress: _celebrationController.value,
                      reaction: _reaction,
                      reactionProgress: _reactionController.value,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPalette(bool compact) {
    final isLight = _mode == MixMode.light;
    final textColor = isLight ? Colors.white : const Color(0xFF624A3C);
    return Container(
      height: compact ? 88 : 112,
      padding: EdgeInsets.fromLTRB(compact ? 10 : 14, 8, compact ? 10 : 14, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isLight ? 0.11 : 0.72),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: isLight ? 0.10 : 0.80),
        ),
      ),
      child: Row(
        children: [
          if (!compact) ...[
            Padding(
              padding: const EdgeInsets.only(left: 5, right: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app_rounded, color: textColor, size: 25),
                  const SizedBox(height: 4),
                  Text(
                    '叫来颜色',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 58,
              color: textColor.withValues(alpha: 0.18),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: paletteIngredients.length,
              separatorBuilder: (_, _) => SizedBox(width: compact ? 8 : 12),
              itemBuilder: (context, index) {
                final ingredient = paletteIngredients[index];
                return _PaletteButton(
                  ingredient: ingredient,
                  compact: compact,
                  darkBackground: isLight,
                  onPressed: () => _addIngredient(ingredient),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.mode,
    required this.compact,
    required this.onChanged,
  });

  final MixMode mode;
  final bool compact;
  final ValueChanged<MixMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: mode == MixMode.light ? 0.13 : 0.66,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeButton(
            selected: mode == MixMode.light,
            icon: Icons.light_mode_rounded,
            label: '光',
            compact: compact,
            darkBackground: mode == MixMode.light,
            onTap: () => onChanged(MixMode.light),
          ),
          _ModeButton(
            selected: mode == MixMode.paint,
            icon: Icons.brush_rounded,
            label: '颜料',
            compact: compact,
            darkBackground: mode == MixMode.light,
            onTap: () => onChanged(MixMode.paint),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.compact,
    required this.darkBackground,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final bool compact;
  final bool darkBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unselectedColor = darkBackground
        ? Colors.white70
        : const Color(0xFF6E5D61);
    return Semantics(
      button: true,
      selected: selected,
      label: '$label模式',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 9 : 13,
            vertical: compact ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: compact ? 18 : 20,
                color: selected ? const Color(0xFF5B477A) : unselectedColor,
              ),
              if (!compact || selected) ...[
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? const Color(0xFF4A3A65) : unselectedColor,
                    fontWeight: FontWeight.w900,
                    fontSize: compact ? 13 : 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PaletteButton extends StatelessWidget {
  const _PaletteButton({
    required this.ingredient,
    required this.compact,
    required this.darkBackground,
    required this.onPressed,
  });

  final ColorIngredient ingredient;
  final bool compact;
  final bool darkBackground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 58.0 : 78.0;
    final ink = ColorMixer.readableInk(ingredient.color);
    return Semantics(
      button: true,
      label: '添加${ingredient.name}精灵',
      child: Tooltip(
        message: '添加${ingredient.name}',
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: compact ? 45 : 56,
                  height: compact ? 45 : 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.28, -0.35),
                      colors: [
                        Color.lerp(ingredient.color, Colors.white, 0.26)!,
                        ingredient.color,
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.76),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ingredient.color.withValues(alpha: 0.40),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.add_rounded,
                    color: ink,
                    size: compact ? 21 : 25,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 4),
                  Text(
                    ingredient.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: darkBackground
                          ? Colors.white
                          : const Color(0xFF554A57),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ColorBlob {
  ColorBlob({
    required this.id,
    required this.ingredients,
    required this.color,
    required this.name,
    required this.position,
    required this.radius,
    required this.phase,
  });

  final int id;
  final List<ColorIngredient> ingredients;
  final Color color;
  final String name;
  Offset position;
  final double radius;
  final double phase;

  ColorBlob copy() => ColorBlob(
    id: id,
    ingredients: List.of(ingredients),
    color: color,
    name: name,
    position: position,
    radius: radius,
    phase: phase,
  );
}

class MergeParticle {
  const MergeParticle({
    required this.angle,
    required this.distance,
    required this.radius,
    required this.color,
  });

  final double angle;
  final double distance;
  final double radius;
  final Color color;
}

class MergeAnimation {
  const MergeAnimation({
    required this.first,
    required this.second,
    required this.target,
    required this.result,
    required this.ingredients,
    required this.resultRadius,
    required this.particles,
  });

  final ColorBlob first;
  final ColorBlob second;
  final Offset target;
  final MixResult result;
  final List<ColorIngredient> ingredients;
  final double resultRadius;
  final List<MergeParticle> particles;
}

class TapReaction {
  const TapReaction({
    required this.position,
    required this.emoji,
    required this.color,
  });

  final Offset position;
  final String emoji;
  final Color color;
}

class CelebrationParticle {
  const CelebrationParticle({
    required this.normalizedX,
    required this.delay,
    required this.speed,
    required this.size,
    required this.spin,
    required this.color,
  });

  final double normalizedX;
  final double delay;
  final double speed;
  final double size;
  final double spin;
  final Color color;
}

class CelebrationScene {
  const CelebrationScene({
    required this.position,
    required this.emoji,
    required this.color,
    required this.particles,
    required this.big,
  });

  final Offset position;
  final String emoji;
  final Color color;
  final List<CelebrationParticle> particles;
  final bool big;
}

class ColorPlaygroundPainter extends CustomPainter {
  ColorPlaygroundPainter({
    required this.mode,
    required this.blobs,
    required this.time,
    required this.draggingId,
    required this.nearbyId,
    required this.dragDelta,
    required this.merge,
    required this.mergeProgress,
    required this.splittingIds,
    required this.splitProgress,
    required this.celebration,
    required this.celebrationProgress,
    required this.reaction,
    required this.reactionProgress,
  });

  final MixMode mode;
  final List<ColorBlob> blobs;
  final double time;
  final int? draggingId;
  final int? nearbyId;
  final Offset dragDelta;
  final MergeAnimation? merge;
  final double mergeProgress;
  final Set<int> splittingIds;
  final double splitProgress;
  final CelebrationScene? celebration;
  final double celebrationProgress;
  final TapReaction? reaction;
  final double reactionProgress;

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackgroundDetails(canvas, size);
    _paintMagneticBridge(canvas);
    for (final blob in blobs) {
      var scale = 1.0;
      if (splittingIds.contains(blob.id)) {
        scale = Curves.elasticOut.transform(splitProgress.clamp(0, 1));
      }
      _paintBlob(
        canvas,
        blob,
        scale: scale,
        selected: blob.id == draggingId,
        excited:
            blob.id == nearbyId || (blob.id == draggingId && nearbyId != null),
      );
    }
    final active = merge;
    if (active != null) _paintMerge(canvas, active);
    final activeReaction = reaction;
    if (activeReaction != null) _paintReaction(canvas, activeReaction);
    final activeCelebration = celebration;
    if (activeCelebration != null) {
      _paintCelebration(canvas, size, activeCelebration);
    }
  }

  void _paintReaction(Canvas canvas, TapReaction active) {
    final t = reactionProgress.clamp(0.0, 1.0);
    final eased = Curves.easeOutCubic.transform(t);
    final fade = (1 - Curves.easeIn.transform(t)).clamp(0.0, 1.0);
    final ringPaint = Paint()
      ..color = active.color.withValues(alpha: fade * 0.48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * fade;
    canvas.drawCircle(active.position, 16 + eased * 38, ringPaint);

    final emoji = TextPainter(
      text: TextSpan(
        text: active.emoji,
        style: TextStyle(fontSize: 24 + 10 * math.sin(t * math.pi)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final position =
        active.position + Offset(-emoji.width / 2, -42 - eased * 44);
    canvas.saveLayer(
      null,
      Paint()..color = Colors.white.withValues(alpha: fade),
    );
    emoji.paint(canvas, position);
    canvas.restore();
  }

  void _paintCelebration(Canvas canvas, Size size, CelebrationScene active) {
    final t = celebrationProgress.clamp(0.0, 1.0);
    for (final particle in active.particles) {
      final localT = ((t - particle.delay) / (1 - particle.delay)).clamp(
        0.0,
        1.0,
      );
      final y = -24 + localT * (size.height + 58) * particle.speed;
      final x =
          particle.normalizedX * size.width +
          math.sin(localT * math.pi * 4 + particle.spin) * 13;
      final opacity = math.sin(localT * math.pi).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = particle.color.withValues(alpha: opacity * 0.92);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.spin * localT);
      if ((particle.normalizedX * 100).round().isEven) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: particle.size,
              height: particle.size * 1.8,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, particle.size * 0.58, paint);
      }
      canvas.restore();
    }

    final revealT = (t / 0.62).clamp(0.0, 1.0);
    final scale = Curves.elasticOut.transform(revealT);
    final fade = t < 0.72 ? 1.0 : ((1 - t) / 0.28).clamp(0.0, 1.0);
    final ringPaint = Paint()
      ..color = active.color.withValues(alpha: fade * 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = active.big ? 5 : 3;
    canvas.drawCircle(
      active.position,
      55 + Curves.easeOut.transform(t) * (active.big ? 70 : 36),
      ringPaint,
    );

    final emoji = TextPainter(
      text: TextSpan(
        text: active.emoji,
        style: TextStyle(fontSize: active.big ? 72 : 52),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final center =
        active.position + Offset(0, -74 - math.sin(t * math.pi) * 22);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    canvas.saveLayer(
      Rect.fromCenter(
        center: Offset.zero,
        width: emoji.width + 20,
        height: emoji.height + 20,
      ),
      Paint()..color = Colors.white.withValues(alpha: fade),
    );
    emoji.paint(canvas, Offset(-emoji.width / 2, -emoji.height / 2));
    canvas.restore();
    canvas.restore();
  }

  void _paintBackgroundDetails(Canvas canvas, Size size) {
    final paint = Paint();
    if (mode == MixMode.light) {
      for (var index = 0; index < 34; index++) {
        final x = ((index * 83.0) % 997) / 997 * size.width;
        final y = ((index * 47.0 + 31) % 839) / 839 * size.height;
        final twinkle =
            0.25 + 0.50 * (0.5 + 0.5 * math.sin(time * math.pi * 2 + index));
        paint.color = Colors.white.withValues(alpha: twinkle);
        canvas.drawCircle(Offset(x, y), index % 5 == 0 ? 1.8 : 1.1, paint);
      }
    } else {
      paint.color = const Color(0xFFCFAF84).withValues(alpha: 0.13);
      for (var index = 0; index < 46; index++) {
        final x = ((index * 67.0) % 953) / 953 * size.width;
        final y = ((index * 101.0 + 17) % 887) / 887 * size.height;
        canvas.drawCircle(Offset(x, y), 1.2 + (index % 3) * 0.35, paint);
      }
    }
  }

  void _paintMagneticBridge(Canvas canvas) {
    final fromId = draggingId;
    final toId = nearbyId;
    if (fromId == null || toId == null) return;
    final from = _findBlob(fromId);
    final to = _findBlob(toId);
    if (from == null || to == null) return;

    final pulse = 0.5 + 0.5 * math.sin(time * math.pi * 8);
    final bridge = Paint()
      ..shader = ui.Gradient.linear(from.position, to.position, [
        from.color.withValues(alpha: 0.65),
        to.color.withValues(alpha: 0.65),
      ])
      ..strokeWidth = 6 + pulse * 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(from.position, to.position, bridge);

    final ring = Paint()
      ..color = Colors.white.withValues(alpha: 0.36 + pulse * 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(to.position, to.radius + 10 + pulse * 5, ring);
  }

  ColorBlob? _findBlob(int id) {
    for (final blob in blobs) {
      if (blob.id == id) return blob;
    }
    return null;
  }

  void _paintMerge(Canvas canvas, MergeAnimation active) {
    final t = mergeProgress.clamp(0.0, 1.0);
    final approach = Curves.easeInOutCubic.transform((t / 0.64).clamp(0, 1));
    final orbit = math.sin(approach * math.pi) * 28;
    final direction = active.second.position - active.first.position;
    final length = math.max(1.0, direction.distance);
    final normal = Offset(-direction.dy / length, direction.dx / length);

    if (t < 0.68) {
      final firstPosition =
          Offset.lerp(active.first.position, active.target, approach)! +
          normal * orbit;
      final secondPosition =
          Offset.lerp(active.second.position, active.target, approach)! -
          normal * orbit;
      final sourceScale =
          1 - 0.50 * Curves.easeIn.transform((t / 0.68).clamp(0, 1));
      final first = active.first.copy()..position = firstPosition;
      final second = active.second.copy()..position = secondPosition;
      _paintBlob(canvas, first, scale: sourceScale, excited: true);
      _paintBlob(canvas, second, scale: sourceScale, excited: true);
    }

    if (t > 0.43) {
      final reveal = Curves.elasticOut.transform(
        ((t - 0.43) / 0.57).clamp(0, 1),
      );
      final resultBlob = ColorBlob(
        id: -1,
        ingredients: active.ingredients,
        color: active.result.color,
        name: active.result.name,
        position: active.target,
        radius: active.resultRadius,
        phase: 1.2,
      );
      _paintBlob(
        canvas,
        resultBlob,
        scale: reveal,
        excited: true,
        showLabel: t > 0.72,
      );
    }

    if (t > 0.48) {
      final particleT = ((t - 0.48) / 0.52).clamp(0.0, 1.0);
      final fade = 1 - Curves.easeIn.transform(particleT);
      for (final particle in active.particles) {
        final distance =
            particle.distance * Curves.easeOutCubic.transform(particleT);
        final position =
            active.target +
            Offset(math.cos(particle.angle), math.sin(particle.angle)) *
                distance;
        final paint = Paint()
          ..color = particle.color.withValues(alpha: fade * 0.88);
        canvas.drawCircle(position, particle.radius * fade, paint);
      }
    }
  }

  void _paintBlob(
    Canvas canvas,
    ColorBlob blob, {
    double scale = 1,
    bool selected = false,
    bool excited = false,
    bool showLabel = true,
  }) {
    if (scale <= 0.001) return;
    final breathing = 1 + math.sin(time * math.pi * 2 + blob.phase) * 0.025;
    final dragSpeed = selected ? dragDelta.distance.clamp(0, 16) : 0.0;
    final stretch = 1 + dragSpeed / 85;
    final angle = selected && dragDelta.distance > 0.1
        ? dragDelta.direction
        : 0.0;

    canvas.save();
    canvas.translate(blob.position.dx, blob.position.dy);
    canvas.rotate(angle);
    canvas.scale(
      scale * breathing * stretch,
      scale * breathing / math.sqrt(stretch),
    );

    final radius = blob.radius;
    final path = _wobblyPath(radius, blob.phase, selected ? 0.070 : 0.045);
    canvas.drawShadow(
      path,
      Colors.black.withValues(alpha: mode == MixMode.light ? 0.48 : 0.24),
      14,
      true,
    );

    if (mode == MixMode.light) {
      final glow = Paint()
        ..color = blob.color.withValues(alpha: selected ? 0.38 : 0.24)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
      canvas.drawCircle(Offset.zero, radius * 1.13, glow);
    }

    final fill = Paint()
      ..shader = ui.Gradient.radial(
        Offset(-radius * 0.28, -radius * 0.34),
        radius * 1.35,
        [
          Color.lerp(
            blob.color,
            Colors.white,
            mode == MixMode.light ? 0.34 : 0.25,
          )!,
          blob.color,
          Color.lerp(blob.color, Colors.black, 0.20)!,
        ],
        const [0, 0.62, 1],
      );
    canvas.drawPath(path, fill);

    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(2, radius * 0.065);
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: radius * 0.74),
      math.pi * 1.05,
      math.pi * 0.42,
      false,
      highlight,
    );

    _paintFace(canvas, blob, excited: excited);
    canvas.restore();
    if (showLabel && scale > 0.72) _paintLabel(canvas, blob, scale);
  }

  Path _wobblyPath(double radius, double phase, double amount) {
    const segments = 36;
    final path = Path();
    for (var index = 0; index <= segments; index++) {
      final angle = math.pi * 2 * index / segments;
      final wave =
          math.sin(angle * 3 + time * math.pi * 2 + phase) * amount +
          math.sin(angle * 5 - time * math.pi * 2 + phase * 0.7) *
              amount *
              0.45;
      final r = radius * (1 + wave);
      final point = Offset(math.cos(angle) * r, math.sin(angle) * r);
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  void _paintFace(Canvas canvas, ColorBlob blob, {required bool excited}) {
    final radius = blob.radius;
    final ink = ColorMixer.readableInk(blob.color);
    final eyeColor = ink == Colors.white
        ? Colors.white
        : const Color(0xFFFDFBF7);
    final blinkWave = math.sin(time * math.pi * 2 + blob.id * 1.83);
    final blink = blinkWave > 0.965 ? 0.15 : 1.0;
    final eyeY = -radius * 0.10;
    final eyeDx = radius * 0.21;
    final eyeWidth = radius * 0.18;
    final eyeHeight = radius * (excited ? 0.25 : 0.22) * blink;

    final eyePaint = Paint()..color = eyeColor;
    final pupilPaint = Paint()..color = const Color(0xFF2A2630);
    for (final direction in const [-1.0, 1.0]) {
      final center = Offset(direction * eyeDx, eyeY);
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: eyeWidth,
          height: math.max(2, eyeHeight),
        ),
        eyePaint,
      );
      if (blink > 0.5) {
        canvas.drawCircle(
          center + Offset(direction * radius * 0.018, radius * 0.018),
          radius * 0.052,
          pupilPaint,
        );
      }
    }

    final mouthPaint = Paint()
      ..color = ink.withValues(alpha: 0.84)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(2, radius * 0.052);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(0, excited ? radius * 0.17 : radius * 0.10),
        width: radius * 0.28,
        height: excited ? radius * 0.24 : radius * 0.22,
      ),
      excited ? 0 : 0.12,
      excited ? math.pi : math.pi - 0.24,
      false,
      mouthPaint,
    );
  }

  void _paintLabel(Canvas canvas, ColorBlob blob, double scale) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: blob.name,
        style: TextStyle(
          color: mode == MixMode.light ? Colors.white : const Color(0xFF493C3A),
          fontSize: blob.radius < 48 ? 12 : 13,
          fontWeight: FontWeight.w800,
          shadows: mode == MixMode.light
              ? const [
                  Shadow(
                    color: Colors.black45,
                    blurRadius: 5,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    final center = blob.position + Offset(0, blob.radius * scale + 12);
    textPainter.paint(canvas, center - Offset(textPainter.width / 2, 0));
  }

  @override
  bool shouldRepaint(covariant ColorPlaygroundPainter oldDelegate) => true;
}
