import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'buddy_models.dart';
import 'game_audio.dart';
import 'island_progress.dart';

const buddyInk = Color(0xFF344D55);
const buddyCream = Color(0xFFFFFBF1);

class BuddyGameShell extends StatefulWidget {
  const BuddyGameShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.guide,
    required this.audio,
    required this.progress,
    required this.scene,
    required this.controls,
    required this.onRepeat,
    this.english,
    this.backLabel = '返回小伙伴乐园',
    this.top,
  });
  final String title, subtitle, guide, backLabel;
  final String? english;
  final GameAudioController audio;
  final IslandProgress progress;
  final Widget scene, controls;
  final Widget? top;
  final VoidCallback onRepeat;

  @override
  State<BuddyGameShell> createState() => _BuddyGameShellState();
}

class _BuddyGameShellState extends State<BuddyGameShell> {
  @override
  void dispose() {
    unawaited(widget.audio.stopSpeech());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: buddyCream,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 600;
          return SingleChildScrollView(
            padding: EdgeInsets.all(narrow ? 14 : 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: widget.backLabel,
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: TextStyle(
                                  color: buddyInk,
                                  fontSize: narrow ? 21 : 27,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                widget.subtitle,
                                style: const TextStyle(
                                  color: Color(0xFF738580),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AudioToggleButton(audio: widget.audio),
                      ],
                    ),
                    if (widget.top != null) ...[
                      const SizedBox(height: 16),
                      widget.top!,
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE6EBDD)),
                      ),
                      child: Row(
                        children: [
                          const Text('💬', style: TextStyle(fontSize: 26)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.guide,
                              key: const ValueKey('buddy-guide'),
                              style: const TextStyle(
                                color: buddyInk,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: widget.onRepeat,
                            tooltip: '再听一遍玩法',
                            icon: const Icon(
                              Icons.record_voice_over_rounded,
                              color: Color(0xFF418F77),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: SizedBox(
                        height: narrow ? 340 : 370,
                        child: widget.scene,
                      ),
                    ),
                    if (widget.english != null) ...[
                      const SizedBox(height: 10),
                      Center(
                        child: ActionChip(
                          avatar: const Icon(Icons.volume_up_rounded, size: 19),
                          label: Text(
                            widget.english!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          onPressed: () =>
                              widget.audio.speakEnglish(widget.english!),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    widget.controls,
                    const SizedBox(height: 16),
                    AnimatedBuilder(
                      animation: widget.progress,
                      builder: (context, _) => Text(
                        '一起发现 ${widget.progress.buddyWords.length} 个英语词语  ·  ⭐ ${widget.progress.stars}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF738580),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class BuddyAction extends StatelessWidget {
  const BuddyAction({
    super.key,
    required this.label,
    required this.onTap,
    this.primary = true,
    this.icon,
  });
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onTap,
    icon: Icon(icon ?? Icons.touch_app_rounded, size: 22),
    label: Text(
      label,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    ),
    style: FilledButton.styleFrom(
      minimumSize: const Size(64, 56),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
      backgroundColor: primary
          ? const Color(0xFF367F69)
          : const Color(0xFFEBEFDE),
      foregroundColor: primary ? Colors.white : buddyInk,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}

class BuddyStepStrip extends StatelessWidget {
  const BuddyStepStrip({super.key, required this.steps, required this.current});
  final List<String> steps;
  final int current;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < steps.length; i++)
        Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i == steps.length - 1 ? 0 : 5),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
            decoration: BoxDecoration(
              color: i <= current
                  ? const Color(0xFFDCEEDC)
                  : const Color(0xFFF0EEE6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${i < current ? '✓ ' : ''}${steps[i]}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: i <= current
                    ? const Color(0xFF34705A)
                    : const Color(0xFF8E9388),
              ),
            ),
          ),
        ),
    ],
  );
}

class BuddyRoom extends StatelessWidget {
  const BuddyRoom({
    super.key,
    required this.child,
    this.color = const Color(0xFFF6E4C6),
    this.floor = const Color(0xFFE5C598),
  });
  final Widget child;
  final Color color, floor;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: color),
    child: Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _RoomPainter(floor))),
        Positioned(
          right: 22,
          top: 18,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .45),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.wb_sunny_rounded,
              color: Color(0xFFD4A947),
              size: 30,
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    ),
  );
}

class _RoomPainter extends CustomPainter {
  _RoomPainter(this.floor);
  final Color floor;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: .2);
    for (double x = 14; x < size.width; x += 38) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 12, size.height * .77), paint);
    }
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * .77, size.width, size.height * .23),
      Paint()..color = floor,
    );
    canvas.drawLine(
      Offset(0, size.height * .77),
      Offset(size.width, size.height * .77),
      Paint()
        ..color = Colors.white.withValues(alpha: .5)
        ..strokeWidth = 5,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .5, size.height * .91),
        width: size.width * .7,
        height: 34,
      ),
      Paint()..color = Colors.white.withValues(alpha: .2),
    );
  }

  @override
  bool shouldRepaint(_RoomPainter oldDelegate) => floor != oldDelegate.floor;
}

class BuddyCharacter extends StatefulWidget {
  const BuddyCharacter({
    super.key,
    this.color = const Color(0xFF80CBB2),
    this.outfit = 'bow',
    this.reaction,
    this.joyful = false,
    this.bubbles = 0,
    this.dirt = const {},
    this.wet = false,
  });
  final Color color;
  final String outfit;
  final JuiceReaction? reaction;
  final bool joyful, wet;
  final int bubbles;
  final Set<int> dirt;
  @override
  State<BuddyCharacter> createState() => _BuddyCharacterState();
}

class _BuddyCharacterState extends State<BuddyCharacter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _idle.stop();
    } else {
      _idle.repeat();
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _idle,
    builder: (context, _) => CustomPaint(
      painter: _BuddyPainter(widget, _idle.value),
      size: const Size(240, 260),
    ),
  );
}

// Normalized touch spots match the illustrated body, shared by bath gestures.
const buddyBathSpots = [
  Offset(.35, .40),
  Offset(.65, .40),
  Offset(.36, .62),
  Offset(.64, .62),
  Offset(.32, .80),
  Offset(.68, .80),
];

class _BuddyPainter extends CustomPainter {
  _BuddyPainter(this.buddy, this.time);
  final BuddyCharacter buddy;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 240, size.height / 260);
    final bounce = math.sin(time * math.pi * 2) * (buddy.joyful ? 5 : 2);
    canvas.drawOval(
      const Rect.fromLTWH(46, 231, 148, 15),
      Paint()..color = const Color(0xFF426C57).withValues(alpha: .12),
    );
    canvas.translate(0, bounce);
    final edge = Color.lerp(buddy.color, const Color(0xFF366559), .22)!;
    void oval(Rect rect, Color color) =>
        canvas.drawOval(rect, Paint()..color = color);
    oval(const Rect.fromLTWH(31, 186, 65, 53), edge);
    oval(const Rect.fromLTWH(145, 186, 65, 53), edge);
    oval(const Rect.fromLTWH(14, 131, 44, 69), buddy.color);
    oval(const Rect.fromLTWH(182, 131, 44, 69), buddy.color);
    oval(const Rect.fromLTWH(33, 27, 46, 73), edge);
    oval(const Rect.fromLTWH(162, 27, 46, 73), edge);
    oval(const Rect.fromLTWH(44, 41, 23, 42), const Color(0xFFF8D1B6));
    oval(const Rect.fromLTWH(173, 41, 23, 42), const Color(0xFFF8D1B6));
    final body = Rect.fromLTWH(31, 53, 178, 174);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(77)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(buddy.color, Colors.white, .16)!,
            buddy.color,
            edge,
          ],
        ).createShader(body),
    );
    oval(
      const Rect.fromLTWH(72, 158, 96, 60),
      const Color(0xFFFFF6D9).withValues(alpha: .65),
    );
    final blink = time > .91 && time < .95;
    final eyePaint = Paint()
      ..color = buddyInk
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final x in [84.0, 156.0]) {
      if (blink || buddy.reaction == JuiceReaction.sour) {
        canvas.drawPath(
          Path()
            ..moveTo(x - 10, 104)
            ..lineTo(x + 1, 111)
            ..lineTo(x - 10, 119),
          eyePaint,
        );
      } else {
        oval(
          Rect.fromCenter(center: Offset(x, 111), width: 28, height: 33),
          Colors.white,
        );
        oval(
          Rect.fromCenter(center: Offset(x + 2, 113), width: 13, height: 20),
          buddyInk,
        );
        oval(
          Rect.fromCircle(center: Offset(x + 4, 107), radius: 3),
          Colors.white,
        );
      }
    }
    oval(
      const Rect.fromLTWH(53, 129, 25, 13),
      const Color(0xFFF4A6A0).withValues(alpha: .8),
    );
    oval(
      const Rect.fromLTWH(164, 129, 25, 13),
      const Color(0xFFF4A6A0).withValues(alpha: .8),
    );
    canvas.drawPath(
      Path()
        ..moveTo(104, 135)
        ..quadraticBezierTo(120, buddy.joyful ? 162 : 153, 136, 135),
      eyePaint..strokeWidth = 4,
    );
    if (buddy.outfit == 'bow') {
      final bow = Path()
        ..moveTo(120, 169)
        ..lineTo(97, 157)
        ..quadraticBezierTo(88, 173, 97, 186)
        ..close()
        ..moveTo(120, 169)
        ..lineTo(143, 157)
        ..quadraticBezierTo(152, 173, 143, 186)
        ..close();
      canvas.drawPath(bow, Paint()..color = const Color(0xFFE68083));
      oval(const Rect.fromLTWH(113, 165, 15, 15), const Color(0xFFF9B6A2));
    } else if (buddy.outfit == 'crown') {
      canvas.drawPath(
        Path()
          ..moveTo(85, 61)
          ..lineTo(80, 26)
          ..lineTo(104, 39)
          ..lineTo(120, 15)
          ..lineTo(137, 39)
          ..lineTo(160, 26)
          ..lineTo(154, 61)
          ..close(),
        Paint()..color = const Color(0xFFFFD56D),
      );
      oval(const Rect.fromLTWH(114, 41, 12, 12), const Color(0xFFE99781));
    } else if (buddy.outfit == 'star') {
      _star(canvas, const Offset(120, 177), 18, const Color(0xFFFFD369));
    }
    for (final index in buddy.dirt) {
      final p = buddyBathSpots[index];
      oval(
        Rect.fromCenter(
          center: Offset(p.dx * 240, p.dy * 260),
          width: 27,
          height: 20,
        ),
        const Color(0xFF9A7957),
      );
      oval(
        Rect.fromCenter(
          center: Offset(p.dx * 240 + 10, p.dy * 260 - 7),
          width: 12,
          height: 12,
        ),
        const Color(0xFF9A7957),
      );
    }
    for (var i = 0; i < buddy.bubbles; i++) {
      final x = 43.0 + (i * 43 % 160);
      final y = 66.0 + (i * 31 % 135);
      oval(
        Rect.fromCircle(center: Offset(x, y), radius: 10 + i % 4 * 2),
        Colors.white.withValues(alpha: .65),
      );
      oval(
        Rect.fromCircle(center: Offset(x - 3, y - 4), radius: 3),
        Colors.white,
      );
    }
    if (buddy.wet) {
      for (var i = 0; i < 8; i++) {
        final x = 40.0 + (i * 23 % 165);
        final y = 76.0 + ((i * 31 + time * 80) % 135);
        canvas.drawLine(
          Offset(x, y),
          Offset(x - 2, y + 11),
          Paint()
            ..color = const Color(0xFFB7E8F0)
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round,
        );
      }
    }
    if (buddy.reaction == JuiceReaction.rainbow) {
      for (var i = 0; i < 5; i++) {
        canvas.drawArc(
          Rect.fromLTWH(84 - i * 2, 129, 73 + i * 4, 20 + i * 8),
          0,
          math.pi,
          false,
          Paint()
            ..color = [
              Colors.pinkAccent,
              Colors.orangeAccent,
              Colors.amber,
              Colors.teal,
              Colors.deepPurpleAccent,
            ][i]
            ..strokeWidth = 5
            ..style = PaintingStyle.stroke,
        );
      }
    }
    if (buddy.reaction == JuiceReaction.bubbles) {
      oval(const Rect.fromLTWH(78, 158, 85, 53), const Color(0xFF9EDCDD));
      for (var i = 0; i < 8; i++) {
        final p = Offset(
          86 + (i * 17 % 67).toDouble(),
          206 - ((i * 11 + time * 45) % 42),
        );
        canvas.drawCircle(
          p,
          3 + i % 3.toDouble(),
          Paint()
            ..color = Colors.white.withValues(alpha: .8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
      canvas.drawPath(
        Path()
          ..moveTo(113, 183)
          ..lineTo(102, 176)
          ..lineTo(102, 192)
          ..close(),
        Paint()..color = const Color(0xFFFFBD78),
      );
      oval(const Rect.fromLTWH(111, 178, 22, 13), const Color(0xFFFFBD78));
    }
    if (buddy.reaction == JuiceReaction.snow) {
      for (var i = 0; i < 9; i++) {
        final p = Offset(
          20 + (i * 37 % 205).toDouble(),
          20 + ((i * 43 + time * 90) % 205),
        );
        _star(canvas, p, 5, Colors.white);
      }
    }
    if (buddy.reaction == JuiceReaction.rosy) {
      for (var i = 0; i < 4; i++) {
        _star(
          canvas,
          Offset(27 + (i % 2) * 186.0, 80 + (i ~/ 2) * 82.0 + bounce),
          8,
          const Color(0xFFFFB968),
        );
      }
    }
    canvas.restore();
  }

  void _star(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? radius : radius * .45;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final point = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BuddyPainter oldDelegate) => true;
}
