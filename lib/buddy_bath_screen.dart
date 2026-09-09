import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'buddy_models.dart';
import 'buddy_widgets.dart';
import 'game_audio.dart';
import 'island_progress.dart';

class BuddyBathScreen extends StatefulWidget {
  const BuddyBathScreen({
    super.key,
    required this.progress,
    required this.audio,
  });
  final IslandProgress progress;
  final GameAudioController audio;
  @override
  State<BuddyBathScreen> createState() => _BuddyBathScreenState();
}

class _BuddyBathScreenState extends State<BuddyBathScreen> {
  BathStage _stage = BathStage.soap;
  final Set<int> _touched = {};
  String? _feedback;
  Offset? _previous;
  Offset? _toolPosition;
  int _pointerStage = 0;
  late String _outfit;
  Timer? _feedbackTimer;
  bool _tickled = false;

  String get _guide =>
      _feedback ??
      switch (_stage) {
        BathStage.soap => '抱抱滚了一身泥！用手指擦擦六个泥巴点，搓出泡泡。',
        BathStage.rinse => '泡泡真多呀！移动小花洒，把全身冲干净。',
        BathStage.dry => '用柔软的小毛巾擦擦身体，水珠就不见啦。',
        BathStage.dress => '干干净净！挑一个喜欢的装扮，再和抱抱说晚安。',
        BathStage.complete => '谢谢你照顾我！这个装扮会陪我去果汁屋和小家。',
      };
  String get _english => switch (_stage) {
    BathStage.soap => 'Wash, wash, wash!',
    BathStage.rinse => 'Water!',
    BathStage.dry => 'Dry, dry, dry!',
    BathStage.dress => 'Good night!',
    BathStage.complete => 'Thank you!',
  };

  @override
  void initState() {
    super.initState();
    _outfit = widget.progress.buddyOutfit;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _narrate();
    });
  }

  void _narrate() => unawaited(widget.audio.speakLesson(_guide, _english));

  void _touch(Offset position, Size size) {
    if (_stage.index > BathStage.dry.index || _pointerStage != _stage.index) {
      return;
    }
    final point = Offset(position.dx / size.width, position.dy / size.height);
    if (point.dx < 0 || point.dx > 1 || point.dy < 0 || point.dy > 1) return;
    setState(() => _toolPosition = position);
    final from = _previous ?? point;
    final delta = point - from;
    var changed = false;
    for (var i = 0; i < buddyBathSpots.length; i++) {
      final relative = buddyBathSpots[i] - from;
      final t = delta.distanceSquared == 0
          ? 0.0
          : ((relative.dx * delta.dx + relative.dy * delta.dy) /
                    delta.distanceSquared)
                .clamp(0.0, 1.0);
      if ((buddyBathSpots[i] - (from + delta * t)).distance < .14) {
        changed = _touched.add(i) || changed;
      }
    }
    _previous = point;
    if (!changed) return;
    unawaited(widget.audio.play(GameSound.tap));
    setState(() {
      _tickled = true;
      if (_touched.length == buddyBathSpots.length) {
        _stage = BathStage.values[_stage.index + 1];
        _touched.clear();
        _previous = null;
        _toolPosition = null;
        _feedback = null;
      }
    });
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _tickled = false);
    });
    if (_pointerStage != _stage.index) {
      unawaited(widget.audio.play(GameSound.correct));
      _narrate();
    }
  }

  void _startTouch(Offset position, Size size) {
    _previous = null;
    _pointerStage = _stage.index;
    _touch(position, size);
  }

  void _endTouch() {
    _previous = null;
    setState(() => _toolPosition = null);
  }

  void _finish() {
    if (_stage != BathStage.dress) return;
    widget.progress.completeBuddyBath(_outfit);
    setState(() => _stage = BathStage.complete);
    unawaited(widget.audio.play(GameSound.complete));
    _narrate();
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BuddyGameShell(
    title: '小怪兽洗澡澡',
    subtitle: 'BUBBLE BATH · 温柔照顾小伙伴',
    guide: _guide,
    english: _english,
    audio: widget.audio,
    progress: widget.progress,
    onRepeat: _narrate,
    top: BuddyStepStrip(
      steps: const ['🫧 搓泡泡', '🚿 冲干净', '🧺 擦一擦', '🎀 换装扮'],
      current: math.min(3, _stage.index),
    ),
    scene: BuddyRoom(
      color: const Color(0xFFD9ECEB),
      floor: const Color(0xFFB8D9D2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          const bodySize = Size(240, 260);
          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 22,
                top: 18,
                child: Text(
                  _stage == BathStage.complete ? '🌙 晚安，小伙伴' : '🫧 抱抱的泡泡浴室',
                  style: const TextStyle(
                    color: buddyInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Positioned(
                left: w * .5 - 135,
                bottom: 14,
                width: 270,
                height: 70,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFEF6),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x224A8E85),
                        blurRadius: 10,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'B U B B L E',
                      style: TextStyle(
                        color: Color(0xFF8CBEB0),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 39,
                width: bodySize.width,
                height: bodySize.height,
                child: GestureDetector(
                  key: const ValueKey('bath-surface'),
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) {
                    _startTouch(details.localPosition, bodySize);
                    _endTouch();
                  },
                  onPanStart: (details) =>
                      _startTouch(details.localPosition, bodySize),
                  onPanUpdate: (details) =>
                      _touch(details.localPosition, bodySize),
                  onPanEnd: (_) => _endTouch(),
                  onPanCancel: _endTouch,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: BuddyCharacter(
                          color: buddyColors[widget.progress.buddyColor],
                          outfit: _stage.index >= BathStage.dress.index
                              ? _outfit
                              : '',
                          joyful: _tickled || _stage == BathStage.complete,
                          dirt: _stage == BathStage.soap
                              ? {
                                  for (var i = 0; i < 6; i++)
                                    if (!_touched.contains(i)) i,
                                }
                              : {},
                          bubbles: switch (_stage) {
                            BathStage.soap => _touched.length * 3,
                            BathStage.rinse => (6 - _touched.length) * 3,
                            _ => 0,
                          },
                          wet:
                              _stage == BathStage.rinse ||
                              _stage == BathStage.dry,
                        ),
                      ),
                      if (_stage == BathStage.rinse || _stage == BathStage.dry)
                        for (var i = 0; i < buddyBathSpots.length; i++)
                          if (!_touched.contains(i))
                            Positioned(
                              left: buddyBathSpots[i].dx * bodySize.width - 15,
                              top: buddyBathSpots[i].dy * bodySize.height - 15,
                              child: IgnorePointer(
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    color: Colors.white.withValues(alpha: .3),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _stage == BathStage.rinse ? '🫧' : '💧',
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                      if (_toolPosition != null && _stage.index < 3)
                        Positioned(
                          left: _toolPosition!.dx - 18,
                          top: _toolPosition!.dy - 34,
                          child: IgnorePointer(
                            child: Text(
                              const ['🧼', '🚿', '🧺'][_stage.index],
                              style: const TextStyle(fontSize: 38),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (_stage.index < 3)
                Positioned(
                  right: 18,
                  top: 65,
                  child: Text(
                    const ['🧼', '🚿', '🧺'][_stage.index],
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              if (_tickled)
                const Positioned(
                  left: 20,
                  top: 65,
                  child: Text(
                    '嘻嘻！',
                    style: TextStyle(
                      color: Color(0xFF418D78),
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              if (_stage == BathStage.complete)
                const Positioned(
                  right: 20,
                  top: 75,
                  child: Text('💤', style: TextStyle(fontSize: 40)),
                ),
            ],
          );
        },
      ),
    ),
    controls: Column(
      children: [
        if (_stage.index < 3) ...[
          Text(
            '${const ['搓出泡泡', '冲掉泡泡', '擦干水珠'][_stage.index]}  ${_touched.length}/6',
            style: const TextStyle(
              color: buddyInk,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 6; i++)
                Container(
                  width: 22,
                  height: 9,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: i < _touched.length
                        ? const Color(0xFF62A58D)
                        : const Color(0xFFDFE8DC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '一根手指擦一擦，也可以点一点',
            style: TextStyle(color: Color(0xFF738580), fontSize: 13),
          ),
        ],
        if (_stage == BathStage.dress) ...[
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            children: [
              for (var i = 0; i < buddyOutfits.length; i++)
                ChoiceChip(
                  key: ValueKey('bath-outfit-${buddyOutfits[i]}'),
                  label: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      buddyOutfitEmojis[i],
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                  selected: _outfit == buddyOutfits[i],
                  onSelected: (_) {
                    setState(() => _outfit = buddyOutfits[i]);
                    unawaited(widget.audio.play(GameSound.discover));
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          BuddyAction(
            key: const ValueKey('bath-finish'),
            label: '🌙 晚安，抱抱',
            onTap: _finish,
          ),
        ],
        if (_stage == BathStage.complete)
          BuddyAction(
            key: const ValueKey('bath-again'),
            label: '🫧 再玩一次泡泡浴',
            onTap: () {
              setState(() {
                _stage = BathStage.soap;
                _touched.clear();
                _previous = null;
                _feedback = null;
              });
              _narrate();
            },
          ),
      ],
    ),
  );
}
