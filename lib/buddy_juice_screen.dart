import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'buddy_models.dart';
import 'buddy_widgets.dart';
import 'game_audio.dart';
import 'island_progress.dart';

class BuddyJuiceScreen extends StatefulWidget {
  const BuddyJuiceScreen({
    super.key,
    required this.progress,
    required this.audio,
    this.recipe,
  });
  final IslandProgress progress;
  final GameAudioController audio;
  final JuiceRecipe? recipe;
  @override
  State<BuddyJuiceScreen> createState() => _BuddyJuiceScreenState();
}

class _BuddyJuiceScreenState extends State<BuddyJuiceScreen> {
  final List<String> _fruits = [];
  JuiceStage _stage = JuiceStage.cutting;
  bool _iced = false, _orders = false;
  int _order = 0;
  double _blend = 0;
  Timer? _blender;
  String? _cutWord;
  JuiceRecipe get _recipe => JuiceRecipe(_fruits, iced: _iced);
  JuiceFruit get _requested => juiceFruits[_order % juiceFruits.length];

  String get _guide => switch (_stage) {
    JuiceStage.cutting =>
      _orders
          ? '抱抱想喝${_requested.name}果汁。划一划水果，放进杯子吧！'
          : '划一划大水果，选一到三份，调出你的神奇果汁！',
    JuiceStage.blending => '按住搅拌按钮，或者点几下，让水果转起来！',
    JuiceStage.serving => '果汁做好啦！点一下杯子，或者把它拖给抱抱。',
    JuiceStage.celebrated => switch (_recipe.reaction) {
      JuiceReaction.sour => '哎呀，好酸呀！抱抱的脸皱成了一团！',
      JuiceReaction.bubbles => '咕噜咕噜！抱抱的肚子里游来了一条小鱼！',
      JuiceReaction.rainbow => '哇！你调出了彩虹胡子果汁！',
      JuiceReaction.snow => '阿嚏！冰冰的果汁变成了小雪花！',
      JuiceReaction.rosy => '甜甜的果汁，让抱抱开心得闪闪发光！',
    },
  };
  String get _english => switch (_stage) {
    JuiceStage.cutting =>
      _cutWord ??
          (_orders
              ? '${_requested.id[0].toUpperCase()}${_requested.id.substring(1)}, please!'
              : 'Apple'),
    JuiceStage.blending => 'Mix, mix, mix!',
    JuiceStage.serving => 'Here you are!',
    JuiceStage.celebrated => 'Thank you!',
  };

  @override
  void initState() {
    super.initState();
    final saved = widget.recipe;
    if (saved != null) {
      _fruits.addAll(saved.fruits);
      _iced = saved.iced;
      _stage = JuiceStage.blending;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _narrate();
    });
  }

  void _narrate() => unawaited(widget.audio.speakLesson(_guide, _english));

  void _cut(JuiceFruit fruit) {
    if (_stage != JuiceStage.cutting || _fruits.length >= 3) return;
    setState(() {
      _fruits.add(fruit.id);
      _cutWord = fruit.id;
    });
    unawaited(
      widget.audio.play(switch (fruit.id) {
        'apple' => GameSound.fruitApple,
        'banana' => GameSound.fruitBanana,
        'watermelon' => GameSound.fruitWatermelon,
        'grape' => GameSound.fruitBlueberry,
        _ => GameSound.fruitOrange,
      }),
    );
    unawaited(widget.audio.speakEnglish(fruit.id));
  }

  void _prepareBlend() {
    if (_fruits.isEmpty) return;
    if (_orders && !_fruits.contains(_requested.id)) {
      unawaited(
        widget.audio.speakLesson(
          '抱抱还想尝一尝${_requested.name}。清空杯子，再加一份吧。',
          '${_requested.id}, please!',
        ),
      );
      setState(() => _cutWord = '${_requested.id}, please!');
      return;
    }
    setState(() {
      _stage = JuiceStage.blending;
      _blend = 0;
    });
    _narrate();
  }

  void _mix(double amount) {
    if (!mounted || _stage != JuiceStage.blending) return;
    setState(() {
      _blend = (_blend + amount).clamp(0, 1);
      if (_blend >= 1) _stage = JuiceStage.serving;
    });
    if (_stage == JuiceStage.serving) {
      _stopBlender();
      unawaited(widget.audio.play(GameSound.discover));
      _narrate();
    }
  }

  void _holdBlender() {
    _stopBlender();
    _mix(.08);
    _blender = Timer.periodic(
      const Duration(milliseconds: 80),
      (_) => _mix(.065),
    );
  }

  void _stopBlender() {
    _blender?.cancel();
    _blender = null;
  }

  void _serve() {
    if (_stage != JuiceStage.serving) return;
    setState(() => _stage = JuiceStage.celebrated);
    widget.progress.saveJuiceRecipe(_recipe);
    unawaited(widget.audio.play(GameSound.complete));
    _narrate();
  }

  void _restart() {
    _stopBlender();
    setState(() {
      _fruits.clear();
      _iced = false;
      _cutWord = null;
      _blend = 0;
      _stage = JuiceStage.cutting;
      _order++;
    });
    _narrate();
  }

  @override
  void dispose() {
    _stopBlender();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BuddyGameShell(
    title: '怪兽果汁屋',
    subtitle: 'LITTLE JUICE BAR · 调一杯小惊喜',
    guide: _guide,
    english: _english,
    audio: widget.audio,
    progress: widget.progress,
    onRepeat: _narrate,
    top: BuddyStepStrip(
      steps: const ['🍎 切水果', '🌀 搅一搅', '🥤 喂抱抱', '✨ 看变化'],
      current: _stage.index,
    ),
    scene: BuddyRoom(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cutting = _stage == JuiceStage.cutting;
          final w = constraints.maxWidth;
          return Stack(
            children: [
              Positioned(
                top: 12,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBF1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _orders
                        ? '🧾 ${_requested.emoji} ${_requested.id}, please!'
                        : '🍹 抱抱的果汁小店',
                    style: const TextStyle(
                      color: buddyInk,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: w * .09,
                top: cutting ? 40 : 45,
                width: cutting ? 150 : math.min(w * .48, 240),
                height: cutting ? 165 : 250,
                child: DragTarget<String>(
                  onWillAcceptWithDetails: (details) =>
                      details.data == 'juice' && _stage == JuiceStage.serving,
                  onAcceptWithDetails: (_) => _serve(),
                  builder: (context, candidates, rejected) => GestureDetector(
                    key: const ValueKey('juice-buddy'),
                    onTap: _stage == JuiceStage.serving
                        ? _serve
                        : () => widget.audio.speakEnglish(
                            _stage == JuiceStage.celebrated
                                ? 'Yummy!'
                                : 'Hello!',
                          ),
                    child: AnimatedScale(
                      scale: candidates.isEmpty ? 1 : 1.08,
                      duration: const Duration(milliseconds: 160),
                      child: BuddyCharacter(
                        color: buddyColors[widget.progress.buddyColor],
                        outfit: widget.progress.buddyOutfit,
                        joyful: _stage == JuiceStage.celebrated,
                        reaction: _stage == JuiceStage.celebrated
                            ? _recipe.reaction
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
              if (_stage != JuiceStage.celebrated)
                Positioned(
                  right: w * .13,
                  top: cutting ? 62 : 115,
                  width: cutting ? 82 : 108,
                  height: cutting ? 130 : 155,
                  child: _stage == JuiceStage.serving
                      ? Draggable<String>(
                          data: 'juice',
                          feedback: SizedBox(
                            width: 108,
                            height: 155,
                            child: _JuiceCup(recipe: _recipe, blended: true),
                          ),
                          childWhenDragging: Opacity(
                            opacity: .25,
                            child: _JuiceCup(recipe: _recipe, blended: true),
                          ),
                          child: GestureDetector(
                            key: const ValueKey('juice-serve-cup'),
                            onTap: _serve,
                            child: _JuiceCup(recipe: _recipe, blended: true),
                          ),
                        )
                      : Transform.rotate(
                          angle: _stage == JuiceStage.blending
                              ? math.sin(_blend * 50) * .07
                              : 0,
                          child: _JuiceCup(
                            recipe: _recipe,
                            blended: _blend > 0,
                          ),
                        ),
                ),
              if (cutting)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  height: 130,
                  child: FruitCuttingBoard(
                    onCut: _cut,
                    selected: _fruits,
                    enabled: _fruits.length < 3,
                  ),
                ),
              if (_stage == JuiceStage.blending)
                Positioned(
                  bottom: 22,
                  left: 28,
                  right: 28,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: _blend,
                      minHeight: 14,
                      color: const Color(0xFF60A88A),
                      backgroundColor: Colors.white70,
                    ),
                  ),
                ),
              if (_stage == JuiceStage.celebrated)
                Positioned(
                  right: 22,
                  bottom: 35,
                  child: Column(
                    children: [
                      Text(_recipe.label, style: const TextStyle(fontSize: 25)),
                      const SizedBox(height: 8),
                      const Text(
                        '配方放进小家啦',
                        style: TextStyle(
                          color: buddyInk,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    ),
    controls: Column(
      children: [
        if (_stage == JuiceStage.cutting) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              FilterChip(
                label: const Text('🧊 加冰块'),
                selected: _iced,
                onSelected: (value) {
                  setState(() => _iced = value);
                  unawaited(
                    widget.audio.speakEnglish(value ? 'Ice!' : 'Juice!'),
                  );
                },
              ),
              FilterChip(
                key: const ValueKey('juice-order-mode'),
                label: Text(_orders ? '🧾 招待客人' : '🎨 自由调饮料'),
                selected: _orders,
                onSelected: (value) {
                  setState(() {
                    _orders = value;
                    _cutWord = null;
                  });
                  _narrate();
                },
              ),
              ActionChip(
                key: const ValueKey('juice-clear'),
                label: const Text('🔄 清空杯子'),
                onPressed: _fruits.isEmpty
                    ? null
                    : () => setState(() {
                        _fruits.clear();
                        _cutWord = null;
                      }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          BuddyAction(
            key: const ValueKey('juice-start-blend'),
            label: '🌀 去搅拌 · ${_fruits.length}/3 份水果',
            onTap: _fruits.isEmpty ? null : _prepareBlend,
          ),
        ],
        if (_stage == JuiceStage.blending)
          Semantics(
            button: true,
            label: '按住或点几下搅拌果汁',
            onTap: () => _mix(.34),
            child: GestureDetector(
              key: const ValueKey('juice-blend'),
              onTap: () => _mix(.34),
              onLongPressStart: (_) => _holdBlender(),
              onLongPressEnd: (_) => _stopBlender(),
              onLongPressCancel: _stopBlender,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 38,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF367F69),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  '🌀 按住搅一搅',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        if (_stage == JuiceStage.serving)
          BuddyAction(
            key: const ValueKey('juice-serve'),
            label: '🥤 给抱抱尝一口',
            onTap: _serve,
          ),
        if (_stage == JuiceStage.celebrated)
          BuddyAction(
            key: const ValueKey('juice-again'),
            label: '🍹 再做一杯',
            onTap: _restart,
          ),
      ],
    ),
  );
}

class FruitCuttingBoard extends StatefulWidget {
  const FruitCuttingBoard({
    super.key,
    required this.onCut,
    required this.selected,
    required this.enabled,
  });
  final ValueChanged<JuiceFruit> onCut;
  final List<String> selected;
  final bool enabled;
  @override
  State<FruitCuttingBoard> createState() => _FruitCuttingBoardState();
}

class _FruitCuttingBoardState extends State<FruitCuttingBoard> {
  final Set<int> _hit = {};
  Offset? _previous;
  List<Offset> _centers(Size size) => [
    for (var i = 0; i < 6; i++)
      Offset(
        size.width * ((i % 3) + .5) / 3,
        size.height * ((i ~/ 3) + .5) / 2,
      ),
  ];
  void _trace(Offset point, Size size) {
    if (!widget.enabled) return;
    final from = _previous ?? point;
    final delta = point - from;
    final centers = _centers(size);
    for (var i = 0; i < centers.length; i++) {
      final relative = centers[i] - from;
      final t = delta.distanceSquared == 0
          ? 0.0
          : ((relative.dx * delta.dx + relative.dy * delta.dy) /
                    delta.distanceSquared)
                .clamp(0.0, 1.0);
      if ((centers[i] - (from + delta * t)).distance < 28 && _hit.add(i)) {
        widget.onCut(juiceFruits[i]);
      }
    }
    _previous = point;
  }

  void _reset() {
    _previous = null;
    _hit.clear();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = constraints.biggest;
      final centers = _centers(size);
      return GestureDetector(
        key: const ValueKey('juice-cutting-board'),
        dragStartBehavior: DragStartBehavior.down,
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) {
          _reset();
          _trace(details.localPosition, size);
        },
        onPanUpdate: (details) => _trace(details.localPosition, size),
        onPanEnd: (_) => _reset(),
        onPanCancel: _reset,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E6),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFD4B181), width: 3),
          ),
          child: Stack(
            children: [
              for (var i = 0; i < juiceFruits.length; i++)
                Positioned(
                  left: centers[i].dx - 36,
                  top: centers[i].dy - 29,
                  width: 72,
                  height: 58,
                  child: Semantics(
                    button: true,
                    label: '切${juiceFruits[i].name}',
                    child: GestureDetector(
                      key: ValueKey('juice-fruit-${juiceFruits[i].id}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => widget.onCut(juiceFruits[i]),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _SlicingFruit(
                            emoji: juiceFruits[i].emoji,
                            slices: widget.selected
                                .where((id) => id == juiceFruits[i].id)
                                .length,
                          ),
                          if (widget.selected.contains(juiceFruits[i].id))
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: CircleAvatar(
                                radius: 11,
                                backgroundColor: const Color(0xFF367F69),
                                child: Text(
                                  '${widget.selected.where((id) => id == juiceFruits[i].id).length}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _SlicingFruit extends StatefulWidget {
  const _SlicingFruit({required this.emoji, required this.slices});
  final String emoji;
  final int slices;
  @override
  State<_SlicingFruit> createState() => _SlicingFruitState();
}

class _SlicingFruitState extends State<_SlicingFruit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slice = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
    value: 1,
  );
  @override
  void didUpdateWidget(_SlicingFruit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.slices > oldWidget.slices &&
        !MediaQuery.disableAnimationsOf(context)) {
      _slice.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _slice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _slice,
    builder: (context, _) {
      final split = math.sin(_slice.value * math.pi);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final side in [-1, 1])
            Transform.translate(
              offset: Offset(side * split * 10, -split * 9),
              child: Transform.rotate(
                angle: side * split * .18,
                child: ClipRect(
                  child: Align(
                    widthFactor: .5,
                    alignment: side == -1
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Text(
                      widget.emoji,
                      style: const TextStyle(fontSize: 42),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _JuiceCup extends StatelessWidget {
  const _JuiceCup({required this.recipe, required this.blended});
  final JuiceRecipe recipe;
  final bool blended;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _CupPainter(recipe, blended));
}

class _CupPainter extends CustomPainter {
  _CupPainter(this.recipe, this.blended);
  final JuiceRecipe recipe;
  final bool blended;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 150);
    final cup = Path()
      ..moveTo(9, 28)
      ..lineTo(91, 28)
      ..lineTo(80, 139)
      ..quadraticBezierTo(50, 148, 20, 139)
      ..close();
    canvas.drawPath(cup, Paint()..color = Colors.white.withValues(alpha: .55));
    canvas.save();
    canvas.clipPath(cup);
    final h = recipe.fruits.isEmpty ? 0.0 : 35.0 + recipe.fruits.length * 20;
    canvas.drawRect(
      Rect.fromLTWH(0, 143 - h, 100, h),
      Paint()..color = recipe.color,
    );
    if (!blended) {
      for (var i = 0; i < recipe.ingredients.length; i++) {
        final center = Offset(32 + (i % 2) * 32.0, 123 - i * 20.0);
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: 17),
          0,
          math.pi,
          true,
          Paint()
            ..color = Color.lerp(recipe.ingredients[i].color, buddyInk, .15)!,
        );
      }
    }
    if (recipe.iced) {
      for (var i = 0; i < 3; i++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(25 + i * 14.0, 65 + (i % 2) * 19, 22, 23),
            const Radius.circular(5),
          ),
          Paint()..color = Colors.white.withValues(alpha: .6),
        );
      }
    }
    canvas.restore();
    canvas.drawPath(
      cup,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke,
    );
    canvas.drawLine(
      const Offset(65, 79),
      const Offset(70, 6),
      Paint()
        ..color = const Color(0xFFDA8287)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      const Offset(70, 6),
      const Offset(85, 1),
      Paint()
        ..color = const Color(0xFFDA8287)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      const Offset(24, 45),
      const Offset(30, 89),
      Paint()
        ..color = Colors.white.withValues(alpha: .7)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CupPainter oldDelegate) => true;
}
