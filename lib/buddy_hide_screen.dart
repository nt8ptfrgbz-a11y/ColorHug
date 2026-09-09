import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'buddy_models.dart';
import 'buddy_widgets.dart';
import 'game_audio.dart';
import 'island_progress.dart';

class BuddyHideScreen extends StatefulWidget {
  const BuddyHideScreen({
    super.key,
    required this.progress,
    required this.audio,
    this.random,
  });
  final IslandProgress progress;
  final GameAudioController audio;
  final Random? random;
  @override
  State<BuddyHideScreen> createState() => _BuddyHideScreenState();
}

class _BuddyHideScreenState extends State<BuddyHideScreen> {
  late final Random _random;
  late HideRound _round;
  late int _roundIndex;
  late bool _listenOnly;
  bool _meet = true, _found = false, _childHides = false, _searching = false;
  final Set<int> _opened = {};
  String? _feedback;
  Timer? _searchTimer;
  int? _childTarget;

  String get _guide {
    if (_found) return '找到${_round.animal.name}啦！它开心地和你打招呼。';
    if (_meet) return '先认识${_round.animal.name}，听一听它的英语名字，再开始躲猫猫。';
    if (_searching) return '嘘，藏好啦！抱抱正在一个一个找。';
    if (_childHides) return '你来藏！点一个地方，把${_round.animal.name}藏进去，让抱抱来找。';
    return _feedback ??
        (_listenOnly ? '听听英语，打开箱子、窗帘或小毯子，找一找！' : _round.animal.clue);
  }

  String get _english => _found
      ? _round.answer
      : _meet
      ? _round.animal.word
      : _round.question;

  @override
  void initState() {
    super.initState();
    _random = widget.random ?? Random();
    _roundIndex = widget.progress.buddyHideRounds;
    _round = HideRound.create(_roundIndex, _random);
    _listenOnly = _roundIndex >= 6;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _narrate();
    });
  }

  void _narrate() => unawaited(widget.audio.speakLesson(_guide, _english));

  void _begin() {
    setState(() {
      _meet = false;
      _feedback = null;
    });
    _narrate();
  }

  void _open(int index) {
    if (_meet || _found || _searching || _opened.contains(index)) return;
    if (_childHides) {
      _hideForBuddy(index);
      return;
    }
    setState(() {
      _opened.add(index);
      if (index == _round.target) {
        _found = true;
      } else {
        _feedback = const [
          '哎呀，是一只小袜子！再去别处看看。',
          '呼啦，飞出了一只纸飞机！继续找找。',
          '这里放着一顶小帽子。再找一找。',
        ][index];
      }
    });
    if (_found) {
      _reward();
    } else {
      unawaited(widget.audio.play(GameSound.tap));
      _narrate();
    }
  }

  void _reward() {
    widget.progress.findBuddyAnimal(_round.animal.word);
    unawaited(widget.audio.play(GameSound.complete));
    _narrate();
  }

  void _hideForBuddy(int index) {
    setState(() {
      _childTarget = index;
      _searching = true;
    });
    unawaited(widget.audio.speakLesson('藏好啦！轮到抱抱来找你。', _round.question));
    final order = [0, 1, 2]..shuffle(_random);
    var attempt = 0;
    _searchTimer = Timer.periodic(const Duration(milliseconds: 1700), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final place = order[attempt++];
      setState(() {
        _opened.add(place);
        if (place == index) {
          _searching = false;
          _found = true;
          _round = HideRound(
            animal: _round.animal,
            target: index,
            room: _round.room,
          );
        }
      });
      unawaited(widget.audio.play(GameSound.tap));
      if (_found) {
        timer.cancel();
        _searchTimer = null;
        _reward();
      }
    });
  }

  void _next({bool? childHides}) {
    _searchTimer?.cancel();
    _searchTimer = null;
    setState(() {
      if (childHides != null) {
        _childHides = childHides;
      } else {
        _roundIndex++;
      }
      _round = HideRound.create(_roundIndex, _random);
      _opened.clear();
      _found = false;
      _meet = true;
      _searching = false;
      _childTarget = null;
      _feedback = null;
    });
    _narrate();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BuddyGameShell(
    title: '英语躲猫猫',
    subtitle: 'PEEKABOO · 听一听，找朋友',
    guide: _guide,
    english: _english,
    audio: widget.audio,
    progress: widget.progress,
    onRepeat: _narrate,
    top: Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        ChoiceChip(
          key: const ValueKey('hide-find-mode'),
          label: const Text('🔎 我来找'),
          selected: !_childHides,
          onSelected: _searching ? null : (_) => _next(childHides: false),
        ),
        ChoiceChip(
          key: const ValueKey('hide-place-mode'),
          label: const Text('🙈 我来藏'),
          selected: _childHides,
          onSelected: _searching ? null : (_) => _next(childHides: true),
        ),
        FilterChip(
          key: const ValueKey('hide-listen-mode'),
          label: Text(_listenOnly ? '👂 听英语找' : '💡 带小提示'),
          selected: _listenOnly,
          onSelected: (value) {
            setState(() {
              _listenOnly = value;
              _feedback = null;
            });
            _narrate();
          },
        ),
      ],
    ),
    scene: BuddyRoom(
      color: const [
        Color(0xFFE4E9F6),
        Color(0xFFF4E5D8),
        Color(0xFFDFECDC),
      ][_round.room],
      floor: const [
        Color(0xFFC9CDE6),
        Color(0xFFE1C4AD),
        Color(0xFFBCCFAF),
      ][_round.room],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final placeWidth = min(190.0, (width - 26) / 3);
          return Stack(
            children: [
              Positioned(
                left: 18,
                top: 16,
                child: Text(
                  const ['☀️ 阳光游戏室', '🌷 温暖小卧室', '🌳 森林树屋'][_round.room],
                  style: const TextStyle(
                    color: buddyInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Positioned(
                right: 16,
                top: 59,
                width: 82,
                height: 88,
                child: BuddyCharacter(
                  color: buddyColors[widget.progress.buddyColor],
                  outfit: widget.progress.buddyOutfit,
                  joyful: _found,
                ),
              ),
              if (_meet || _found)
                Positioned(
                  top: 48,
                  left: width * .5 - 56,
                  width: 112,
                  height: 115,
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey('$_roundIndex-$_found'),
                    tween: Tween(begin: .6, end: 1),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .65),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Text(
                        _round.animal.emoji,
                        style: const TextStyle(fontSize: 72),
                      ),
                    ),
                  ),
                ),
              if (!_meet && !_found)
                Positioned(
                  top: 76,
                  left: 24,
                  child: Text(
                    _searching
                        ? '抱抱：我来找啦…'
                        : _childHides
                        ? '藏在哪里好呢？'
                        : '谁在这里呢？',
                    style: const TextStyle(
                      color: Color(0xFF75847C),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              for (var i = 0; i < 3; i++)
                Positioned(
                  left: width * (i + .5) / 3 - placeWidth / 2,
                  bottom: 20,
                  width: placeWidth,
                  height: 165,
                  child: Semantics(
                    button: true,
                    label: const ['打开箱子', '拉开窗帘', '掀开毯子'][i],
                    child: GestureDetector(
                      key: ValueKey('hide-spot-$i'),
                      onTap: _meet || _found || _searching
                          ? null
                          : () => _open(i),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: _opened.contains(i) ? 1.0 : 0.0),
                        duration: const Duration(milliseconds: 380),
                        curve: Curves.easeOutBack,
                        builder: (context, value, _) => Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_opened.contains(i))
                              Positioned(
                                top: 33,
                                child: Text(
                                  i == (_childTarget ?? _round.target)
                                      ? _round.animal.emoji
                                      : const ['🧦', '🪁', '🧢'][i],
                                  style: TextStyle(
                                    fontSize: min(52, placeWidth * .48),
                                  ),
                                ),
                              ),
                            if (!_meet &&
                                !_found &&
                                !_listenOnly &&
                                !_childHides &&
                                i == _round.target &&
                                !_opened.contains(i))
                              Positioned(
                                top: 29,
                                child: ClipRect(
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    heightFactor: .3,
                                    child: Text(
                                      _round.animal.emoji,
                                      style: const TextStyle(fontSize: 45),
                                    ),
                                  ),
                                ),
                              ),
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _HidingPlacePainter(i, value),
                              ),
                            ),
                            if (_childTarget == i && _searching)
                              const Positioned(
                                top: 10,
                                child: Text(
                                  '🤫',
                                  style: TextStyle(fontSize: 22),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
    controls: Center(
      child: _meet
          ? BuddyAction(
              key: const ValueKey('hide-begin'),
              label: _childHides ? '🙈 我来藏朋友' : '🔎 准备好，开始找',
              onTap: _begin,
            )
          : _found
          ? BuddyAction(
              key: const ValueKey('hide-next'),
              label: '🐾 找下一个朋友',
              onTap: () => _next(),
            )
          : _searching
          ? const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                '抱抱正在找…',
                style: TextStyle(color: buddyInk, fontSize: 16),
              ),
            )
          : BuddyAction(
              key: const ValueKey('hide-hint'),
              label: '👂 再听听',
              primary: false,
              onTap: _narrate,
            ),
    ),
  );
}

class _HidingPlacePainter extends CustomPainter {
  _HidingPlacePainter(this.kind, this.open);
  final int kind;
  final double open;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 140, size.height / 170);
    final t = open.clamp(0.0, 1.0);
    void rounded(Rect rect, Color color, double radius) => canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()..color = color,
    );
    if (kind == 0) {
      rounded(const Rect.fromLTWH(17, 88, 106, 65), const Color(0xFFD9A674), 8);
      rounded(const Rect.fromLTWH(57, 92, 23, 61), const Color(0xFFEAC49C), 0);
      canvas.save();
      canvas.translate(18, 80);
      canvas.rotate(-t * .75);
      rounded(const Rect.fromLTWH(0, 0, 107, 19), const Color(0xFFE8B987), 5);
      canvas.restore();
      canvas.drawCircle(
        const Offset(35, 120),
        5,
        Paint()..color = const Color(0xFFBC865D),
      );
    } else if (kind == 1) {
      rounded(const Rect.fromLTWH(8, 36, 124, 8), const Color(0xFF9D829F), 5);
      for (var side = 0; side < 2; side++) {
        final width = 57 - t * 40;
        final left = side == 0 ? 13.0 : 127 - width;
        rounded(
          Rect.fromLTWH(left, 44, width, 110),
          const Color(0xFFC8A2C7),
          5,
        );
        for (var i = 0; i < 3; i++) {
          canvas.drawLine(
            Offset(left + 5 + i * width / 3, 46),
            Offset(left + 5 + i * width / 3, 145),
            Paint()
              ..color = const Color(0xFFB68DB9)
              ..strokeWidth = 3,
          );
        }
      }
    } else {
      rounded(
        const Rect.fromLTWH(11, 128, 119, 26),
        const Color(0xFFCBAF8A),
        10,
      );
      final top = 76 + t * 58;
      rounded(
        Rect.fromLTWH(13, top, 114, 68 - t * 53),
        const Color(0xFF8DBDBB),
        20,
      );
      if (t < .8) {
        for (var i = 0; i < 4; i++) {
          canvas.drawCircle(
            Offset(32 + i * 24.0, top + 31),
            5,
            Paint()..color = const Color(0xFFD2E6D9),
          );
        }
      }
      rounded(const Rect.fromLTWH(18, 147, 9, 17), const Color(0xFFAE9176), 3);
      rounded(const Rect.fromLTWH(113, 147, 9, 17), const Color(0xFFAE9176), 3);
    }
  }

  @override
  bool shouldRepaint(_HidingPlacePainter oldDelegate) =>
      open != oldDelegate.open || kind != oldDelegate.kind;
}
