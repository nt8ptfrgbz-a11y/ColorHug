import 'dart:math';

import 'package:flutter/material.dart';

enum BuddyBurst { stars, bubbles, splash, heart, flower }

class BuddyEffectsController extends ChangeNotifier {
  final List<_Burst> _bursts = [];
  void burst(
    Offset at, {
    Color color = const Color(0xFFFFC96B),
    BuddyBurst kind = BuddyBurst.stars,
    int count = 28,
    bool trails = false,
  }) {
    _bursts.add(_Burst(at, color, kind, count.clamp(6, 42), trails));
    if (_bursts.length > 14) _bursts.removeAt(0);
    notifyListeners();
  }
}

class _Burst {
  _Burst(this.at, this.color, this.kind, this.count, this.trails);
  final Offset at;
  final Color color;
  final BuddyBurst kind;
  final int count;
  final bool trails;
  double age = 0;
}

class BuddyEffects extends StatefulWidget {
  const BuddyEffects({
    super.key,
    required this.controller,
    required this.child,
  });
  final BuddyEffectsController controller;
  final Widget child;
  @override
  State<BuddyEffects> createState() => _BuddyEffectsState();
}

class _BuddyEffectsState extends State<BuddyEffects>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );
  Duration? _last;
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_wake);
    _clock.addListener(_tick);
  }

  void _wake() {
    if (!_clock.isAnimating) {
      _last = null;
      _clock.repeat();
    }
    setState(() {});
  }

  void _tick() {
    final elapsed = _clock.lastElapsedDuration ?? Duration.zero;
    final dt = _last == null
        ? 0.0
        : (elapsed - _last!).inMicroseconds / 1000000;
    _last = elapsed;
    for (final burst in widget.controller._bursts) {
      burst.age += dt;
    }
    widget.controller._bursts.removeWhere((burst) => burst.age > 1.5);
    if (widget.controller._bursts.isEmpty) _clock.stop();
    setState(() {});
  }

  @override
  void didUpdateWidget(BuddyEffects oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_wake);
      widget.controller.addListener(_wake);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_wake);
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      widget.child,
      Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(
            painter: _EffectsPainter(
              widget.controller._bursts,
              MediaQuery.disableAnimationsOf(context),
            ),
          ),
        ),
      ),
    ],
  );
}

class _EffectsPainter extends CustomPainter {
  _EffectsPainter(this.bursts, this.reducedMotion);
  final List<_Burst> bursts;
  final bool reducedMotion;
  @override
  void paint(Canvas canvas, Size size) {
    for (final burst in bursts) {
      final t = burst.age / 1.5;
      final center = Offset(
        burst.at.dx * size.width,
        burst.at.dy * size.height,
      );
      final spread = reducedMotion
          ? 18.0
          : burst.trails
          ? 230.0
          : 95.0;
      for (var i = 0; i < burst.count; i++) {
        final angle = i * pi * 2 / burst.count;
        var radial = 1.0;
        if (burst.trails && burst.kind == BuddyBurst.stars) {
          final segment = (angle + pi / 2) / (pi / 5);
          final startRadius = segment.floor().isEven ? 1.0 : .46;
          final endRadius = segment.floor().isEven ? .46 : 1.0;
          radial =
              startRadius +
              (endRadius - startRadius) * (segment - segment.floor());
        }
        if (burst.kind == BuddyBurst.flower) {
          radial = .6 + .4 * cos(5 * angle).abs();
        }
        final speed = (burst.trails || i.isEven ? 1.0 : .65) * radial;
        final direction = burst.kind == BuddyBurst.heart
            ? Offset(
                pow(sin(angle), 3).toDouble(),
                -(13 * cos(angle) -
                        5 * cos(2 * angle) -
                        2 * cos(3 * angle) -
                        cos(4 * angle)) /
                    16,
              )
            : Offset(cos(angle) * speed, sin(angle) * speed);
        final point =
            center +
            direction * spread * t +
            Offset(0, burst.kind == BuddyBurst.bubbles ? -55 * t : 35 * t * t);
        final color = Color.lerp(
          burst.color,
          const [
            Color(0xFFFFA3C4),
            Color(0xFF80DEEA),
            Color(0xFFFFDB7B),
            Color(0xFFA69AFF),
          ][i % 4],
          .45,
        )!.withValues(alpha: (1 - t).clamp(0, 1));
        final paint = Paint()..color = color;
        if (burst.trails && !reducedMotion) {
          canvas.drawLine(
            point - direction * 22,
            point,
            Paint()
              ..color = color
              ..strokeWidth = 2
              ..strokeCap = StrokeCap.round,
          );
        }
        final radius = (i % 3 + 3.0) * (1 - t * .5);
        if (burst.kind == BuddyBurst.bubbles) {
          canvas.drawCircle(
            point,
            radius * 1.8,
            paint
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
          canvas.drawCircle(
            point - const Offset(2, 2),
            1.5,
            Paint()..color = Colors.white.withValues(alpha: 1 - t),
          );
        } else {
          canvas.drawCircle(
            point,
            radius * 2.6,
            Paint()..color = color.withValues(alpha: color.a * .13),
          );
          canvas.drawCircle(point, radius, paint);
          if (i % 3 == 0) {
            canvas.drawLine(
              point - Offset(radius * 2, 0),
              point + Offset(radius * 2, 0),
              paint..strokeWidth = 1.3,
            );
            canvas.drawLine(
              point - Offset(0, radius * 2),
              point + Offset(0, radius * 2),
              paint,
            );
          }
        }
      }
      if (!reducedMotion) {
        canvas.drawCircle(
          center,
          60 * t,
          Paint()
            ..color = burst.color.withValues(alpha: (1 - t) * .25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_EffectsPainter oldDelegate) => true;
}
