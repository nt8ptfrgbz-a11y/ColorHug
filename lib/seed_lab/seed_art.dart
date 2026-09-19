import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'seed_model.dart';

const labInk = Color(0xFF355C50);
const labGreen = Color(0xFF568B70);
const labCream = Color(0xFFFFFCF3);
const nutrientColors = [
  Color(0xFFB4A2E7),
  Color(0xFFF1AE86),
  Color(0xFF7DC6CF),
  Color(0xFFEA9CB1),
];

Paint _fill(Color c) => Paint()..color = c;
Paint _line(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

void _oval(Canvas c, double x, double y, double w, double h, Color color) =>
    c.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: w, height: h),
      _fill(color),
    );

void _round(Canvas c, Rect r, double radius, Color color) => c.drawRRect(
  RRect.fromRectAndRadius(r, Radius.circular(radius)),
  _fill(color),
);

void _gradient(Canvas c, Path path, Rect bounds, List<Color> colors) =>
    c.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ).createShader(bounds),
    );

Path _star(Offset center, double radius, [int points = 5]) {
  final p = Path();
  for (var i = 0; i < points * 2; i++) {
    final a = i * math.pi / points - math.pi / 2,
        r = i.isEven ? radius : radius * .48;
    final v = center + Offset(math.cos(a) * r, math.sin(a) * r);
    if (i == 0) {
      p.moveTo(v.dx, v.dy);
    } else {
      p.lineTo(v.dx, v.dy);
    }
  }
  return p..close();
}

void _sparkle(Canvas c, Offset p, double r, Color color) {
  final path = Path()
    ..moveTo(p.dx, p.dy - r)
    ..quadraticBezierTo(p.dx + r * .16, p.dy - r * .16, p.dx + r, p.dy)
    ..quadraticBezierTo(p.dx + r * .16, p.dy + r * .16, p.dx, p.dy + r)
    ..quadraticBezierTo(p.dx - r * .16, p.dy + r * .16, p.dx - r, p.dy)
    ..quadraticBezierTo(p.dx - r * .16, p.dy - r * .16, p.dx, p.dy - r)
    ..close();
  c.drawPath(path, _fill(color));
}

void _leaf(Canvas c, Offset base, Offset tip, double width, Color color) {
  final d = tip - base, normal = Offset(-d.dy, d.dx) / d.distance * width;
  final mid = Offset.lerp(base, tip, .5)!;
  final path = Path()
    ..moveTo(base.dx, base.dy)
    ..quadraticBezierTo(mid.dx + normal.dx, mid.dy + normal.dy, tip.dx, tip.dy)
    ..quadraticBezierTo(
      mid.dx - normal.dx * .6,
      mid.dy - normal.dy * .6,
      base.dx,
      base.dy,
    )
    ..close();
  _gradient(c, path, path.getBounds(), [
    Color.lerp(color, Colors.white, .22)!,
    color,
  ]);
  c.drawLine(
    base,
    Offset.lerp(base, tip, .8)!,
    _line(Colors.white.withValues(alpha: .36), 1.5),
  );
}

void _face(
  Canvas c,
  Offset center,
  double scale,
  double time, {
  bool happy = false,
}) {
  c.save();
  c.translate(center.dx, center.dy);
  c.scale(scale);
  final blink = time % 5.4 > 5.16;
  for (final x in [-12.0, 12.0]) {
    if (blink || happy) {
      c.drawPath(
        Path()
          ..moveTo(x - 3, -1)
          ..quadraticBezierTo(x, -6, x + 3, -1),
        _line(labInk, 2.4),
      );
    } else {
      _oval(c, x, -2, 5.5, 7, labInk);
      _oval(c, x + 1, -3.5, 1.7, 2, Colors.white);
    }
    _oval(
      c,
      x * 1.45,
      7,
      9,
      4.5,
      const Color(0xFFEEA6A0).withValues(alpha: .65),
    );
  }
  c.drawPath(
    Path()
      ..moveTo(-4, 6)
      ..quadraticBezierTo(0, 12, 4, 6),
    _line(labInk, 1.8),
  );
  c.restore();
}

class GreenhousePainter extends CustomPainter {
  const GreenhousePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final c = canvas;
    c.save();
    c.scale(size.width / 800, size.height / 620);
    c.drawRect(
      const Rect.fromLTWH(0, 0, 800, 620),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF3F5E7), Color(0xFFFFF8E9)],
        ).createShader(const Rect.fromLTWH(0, 0, 800, 620)),
    );
    // Soft recessed architecture and an open moon window.
    final arch = Path()
      ..moveTo(92, 490)
      ..lineTo(92, 238)
      ..cubicTo(92, -50, 708, -50, 708, 238)
      ..lineTo(708, 490);
    c.drawPath(arch, _line(const Color(0xFFDCE5D6), 28));
    c.drawPath(arch, _line(const Color(0xFFFDFBF0), 17));
    final window = Rect.fromCircle(center: const Offset(400, 262), radius: 187);
    c.drawCircle(
      const Offset(400, 267),
      195,
      _fill(const Color(0xFFCADAC7).withValues(alpha: .45)),
    );
    c.drawCircle(const Offset(400, 260), 193, _fill(const Color(0xFF91B4A0)));
    c.drawCircle(const Offset(400, 260), 184, _fill(const Color(0xFFFEFCED)));
    c.save();
    c.clipPath(Path()..addOval(window.deflate(10)));
    c.drawRect(
      window,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD2EBE5), Color(0xFFF8F9DE)],
        ).createShader(window),
    );
    _oval(c, 474, 155, 68, 68, const Color(0xFFFFF7C8));
    for (var i = 0; i < 3; i++) {
      final y = 315 + i * 40.0;
      final mountain = Path()
        ..moveTo(140, 460)
        ..lineTo(140, y + 20)
        ..cubicTo(220, y - 95, 264, y - 110, 338, y - 22)
        ..cubicTo(398, y + 40, 473, y - 96, 532, y - 32)
        ..cubicTo(586, y + 6, 634, y - 85, 660, y - 30)
        ..lineTo(660, 470)
        ..close();
      c.drawPath(
        mountain,
        _fill(
          [
            const Color(0xFFB8D9CC),
            const Color(0xFFCAE0C3),
            const Color(0xFFE0E8C8),
          ][i],
        ),
      );
    }
    for (final cloud in [const Offset(300, 174), const Offset(525, 238)]) {
      _oval(c, cloud.dx, cloud.dy, 76, 12, Colors.white.withValues(alpha: .7));
      _oval(
        c,
        cloud.dx - 7,
        cloud.dy - 5,
        30,
        17,
        Colors.white.withValues(alpha: .7),
      );
    }
    c.restore();
    // Branches with peach blossoms, drawn as little layered porcelain petals.
    c.drawPath(
      Path()
        ..moveTo(730, 85)
        ..quadraticBezierTo(666, 103, 586, 154)
        ..moveTo(654, 120)
        ..quadraticBezierTo(654, 78, 630, 55)
        ..moveTo(620, 138)
        ..quadraticBezierTo(593, 99, 560, 95),
      _line(const Color(0xFF97AA86), 4),
    );
    for (final p in [
      const Offset(630, 62),
      const Offset(653, 105),
      const Offset(588, 147),
      const Offset(561, 94),
      const Offset(699, 98),
    ]) {
      for (var j = 0; j < 5; j++) {
        final a = j * math.pi * 2 / 5;
        _oval(
          c,
          p.dx + math.cos(a) * 8,
          p.dy + math.sin(a) * 8,
          14,
          14,
          const Color(0xFFF5C9C3),
        );
      }
      _oval(c, p.dx, p.dy, 7, 7, const Color(0xFFE7B961));
    }
    for (final x in [103.0, 697.0]) {
      c.drawLine(
        Offset(x, 0),
        Offset(x, 106),
        _line(const Color(0xFFC6B78F), 2),
      );
      _oval(c, x, 127, 43, 54, const Color(0xFFF3DFC0));
      _oval(c, x - 3, 123, 30, 48, const Color(0xFFFFF0CD));
      c.drawLine(
        Offset(x, 156),
        Offset(x, 173),
        _line(const Color(0xFFD7AE8E), 3),
      );
      _round(
        c,
        Rect.fromCenter(center: Offset(x, 100), width: 24, height: 6),
        3,
        const Color(0xFFB4BA96),
      );
    }
    // Side shelves.
    for (final right in [false, true]) {
      c.save();
      if (right) {
        c.translate(800, 0);
        c.scale(-1, 1);
      }
      _round(
        c,
        const Rect.fromLTWH(12, 344, 150, 14),
        7,
        const Color(0xFFDED0B2),
      );
      _round(
        c,
        const Rect.fromLTWH(25, 356, 9, 28),
        4,
        const Color(0xFFD7C7A7),
      );
      _round(
        c,
        const Rect.fromLTWH(137, 356, 9, 28),
        4,
        const Color(0xFFD7C7A7),
      );
      _round(
        c,
        const Rect.fromLTWH(48, 297, 52, 48),
        13,
        const Color(0xFFABC7AC),
      );
      _oval(c, 74, 298, 54, 12, const Color(0xFFD5E2C4));
      _leaf(
        c,
        const Offset(74, 296),
        const Offset(47, 257),
        24,
        const Color(0xFF87B293),
      );
      _leaf(
        c,
        const Offset(74, 289),
        const Offset(101, 250),
        21,
        const Color(0xFFA6C48B),
      );
      c.drawLine(
        const Offset(74, 302),
        const Offset(72, 256),
        _line(const Color(0xFF789E79), 3),
      );
      _round(
        c,
        const Rect.fromLTWH(119, 316, 24, 28),
        7,
        const Color(0xFFE4C3AB),
      );
      _oval(c, 130, 314, 25, 7, const Color(0xFFFAE5D0));
      c.restore();
    }
    // Sunbeam, tabletop, and fine inlaid edge.
    c.drawPath(
      Path()
        ..moveTo(555, 0)
        ..lineTo(648, 0)
        ..lineTo(294, 479)
        ..lineTo(141, 479)
        ..close(),
      _fill(Colors.white.withValues(alpha: .12)),
    );
    final table = Path()
      ..moveTo(0, 495)
      ..quadraticBezierTo(400, 462, 800, 495)
      ..lineTo(800, 620)
      ..lineTo(0, 620)
      ..close();
    _gradient(c, table, const Rect.fromLTWH(0, 480, 800, 140), [
      const Color(0xFFF2E4C9),
      const Color(0xFFE9D6B6),
    ]);
    c.drawPath(
      Path()
        ..moveTo(0, 512)
        ..quadraticBezierTo(400, 482, 800, 512),
      _line(const Color(0xFFFFF5DC), 3),
    );
    for (var i = 0; i < 7; i++) {
      c.drawPath(
        Path()
          ..moveTo(i * 135.0 - 40, 620)
          ..lineTo(i * 113.0 + 18, 500),
        _line(const Color(0xFFD8C4A3).withValues(alpha: .35), 1),
      );
    }
    // A little gardening book and pebbles make the scene feel inhabited.
    c.save();
    c.translate(670, 541);
    c.rotate(-.12);
    _round(
      c,
      const Rect.fromLTWH(-42, -25, 84, 50),
      8,
      const Color(0xFFABBE9C),
    );
    _round(
      c,
      const Rect.fromLTWH(-39, -29, 78, 47),
      6,
      const Color(0xFFF9F2D8),
    );
    c.drawLine(
      const Offset(0, -25),
      const Offset(0, 13),
      _line(const Color(0xFFD6CCA9), 1.5),
    );
    _leaf(
      c,
      const Offset(14, 5),
      const Offset(24, -16),
      12,
      const Color(0xFFADC595),
    );
    c.restore();
    _oval(c, 158, 546, 28, 13, const Color(0xFFD3CDB8));
    _oval(c, 174, 552, 17, 10, const Color(0xFFE8DBBF));
    c.restore();
  }

  @override
  bool shouldRepaint(GreenhousePainter oldDelegate) => false;
}

class SeedGlyph extends StatelessWidget {
  const SeedGlyph({super.key, this.seed, this.nutrient, this.size = 64});
  final SeedKind? seed;
  final Nutrient? nutrient;
  final double size;
  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _GlyphPainter(seed, nutrient),
  );
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.seed, this.nutrient);
  final SeedKind? seed;
  final Nutrient? nutrient;
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 80, size.height / 80);
    if (nutrient case final n?) {
      drawNutrient(c, n, const Offset(40, 40), .9);
    } else {
      drawSeed(c, seed ?? SeedKind.mushroom, const Offset(40, 44), 1);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.seed != seed || old.nutrient != nutrient;
}

void drawSeed(Canvas c, SeedKind seed, Offset at, double scale) {
  c.save();
  c.translate(at.dx, at.dy);
  c.scale(scale);
  final colors = [
    const Color(0xFFE7BF87),
    const Color(0xFFB3CDA3),
    const Color(0xFFE9B4BC),
  ];
  _oval(c, 0, 21, 42, 9, labInk.withValues(alpha: .08));
  final shape = Path()
    ..moveTo(0, -26)
    ..cubicTo(29, -17, 28, 12, 10, 22)
    ..cubicTo(-14, 34, -34, 5, -19, -14)
    ..quadraticBezierTo(-9, -24, 0, -26)
    ..close();
  _gradient(c, shape, const Rect.fromLTWH(-28, -26, 56, 53), [
    Color.lerp(colors[seed.index], Colors.white, .42)!,
    colors[seed.index],
  ]);
  _oval(c, -9, -10, 9, 16, Colors.white.withValues(alpha: .4));
  _face(c, const Offset(0, 3), .58, 0);
  _leaf(
    c,
    const Offset(0, -22),
    const Offset(15, -34),
    10,
    const Color(0xFF88B08A),
  );
  c.restore();
}

void drawNutrient(Canvas c, Nutrient kind, Offset at, double scale) {
  c.save();
  c.translate(at.dx, at.dy);
  c.scale(scale);
  final color = nutrientColors[kind.index];
  _oval(c, 0, 29, 48, 8, labInk.withValues(alpha: .08));
  // Four hand-drawn glass bottles, each with a different silhouette.
  final bottle = Path()
    ..moveTo(-9, -25)
    ..lineTo(-9, -13)
    ..cubicTo(-9, -8, -25, -4, -25, 12)
    ..quadraticBezierTo(-25, 30, 0, 30)
    ..quadraticBezierTo(25, 30, 25, 12)
    ..cubicTo(25, -4, 9, -8, 9, -13)
    ..lineTo(9, -25)
    ..close();
  _gradient(c, bottle, const Rect.fromLTWH(-25, -25, 50, 55), [
    Color.lerp(color, Colors.white, .82)!,
    Color.lerp(color, Colors.white, .3)!,
  ]);
  c.drawPath(bottle, _line(Color.lerp(color, labInk, .08)!, 1.5));
  c.save();
  c.clipPath(bottle);
  final liquid = Path()
    ..moveTo(-29, 5)
    ..quadraticBezierTo(-12, -1, 2, 5)
    ..quadraticBezierTo(15, 10, 29, 3)
    ..lineTo(29, 34)
    ..lineTo(-29, 34)
    ..close();
  _gradient(c, liquid, const Rect.fromLTWH(-28, 0, 56, 32), [
    color.withValues(alpha: .65),
    color,
  ]);
  c.restore();
  _round(c, const Rect.fromLTWH(-12, -30, 24, 10), 4, const Color(0xFFE2CBA4));
  _round(c, const Rect.fromLTWH(-10, -31, 20, 4), 2, const Color(0xFFF8E6C5));
  c.drawPath(
    Path()
      ..moveTo(-16, 1)
      ..quadraticBezierTo(-21, 9, -17, 17),
    _line(Colors.white.withValues(alpha: .7), 4),
  );
  switch (kind) {
    case Nutrient.moon:
      final moon = Path.combine(
        PathOperation.difference,
        Path()..addOval(const Rect.fromLTWH(-8, -1, 22, 22)),
        Path()..addOval(const Rect.fromLTWH(0, -6, 20, 20)),
      );
      c.drawPath(moon, _fill(const Color(0xFFFFF3B4)));
      _sparkle(c, const Offset(15, -12), 5, const Color(0xFFE4C46C));
    case Nutrient.music:
      _oval(c, -3, 15, 10, 7, const Color(0xFFFAF2D7));
      c.drawPath(
        Path()
          ..moveTo(1, 14)
          ..lineTo(1, -3)
          ..lineTo(11, -6)
          ..lineTo(11, 9),
        _line(const Color(0xFFFAF2D7), 3),
      );
      _oval(c, 7, 10, 9, 6, const Color(0xFFFAF2D7));
    case Nutrient.soda:
      for (final p in [
        const Offset(-3, 13),
        const Offset(10, 5),
        const Offset(8, 20),
        const Offset(-16, -12),
      ]) {
        c.drawCircle(p, 4.5, _line(Colors.white.withValues(alpha: .85), 1.8));
      }
    case Nutrient.rainbow:
      for (var i = 0; i < 3; i++) {
        c.drawArc(
          Rect.fromCircle(center: const Offset(2, 15), radius: 12 - i * 4.0),
          math.pi,
          math.pi,
          false,
          _line(
            [
              const Color(0xFFFFE6AA),
              const Color(0xFFB8DCC5),
              const Color(0xFFD6D0F1),
            ][i],
            3.8,
          ),
        );
      }
  }
  c.restore();
}

class PlantPainter extends CustomPainter {
  const PlantPainter({
    required this.seed,
    this.plant,
    this.time = 0,
    this.growth = 1,
    this.feed = 0,
    this.nutrient,
    this.reaction = 0,
    this.ingredients = 0,
    this.showPot = true,
    this.ambient = true,
  });
  final SeedKind seed;
  final PlantDiscovery? plant;
  final double time, growth, feed, reaction;
  final Nutrient? nutrient;
  final int ingredients;
  final bool showPot, ambient;

  @override
  void paint(Canvas c, Size size) {
    final scale = math.min(size.width / 400, size.height / 400);
    c.save();
    c.translate(
      (size.width - 400 * scale) / 2,
      (size.height - 400 * scale) / 2,
    );
    c.scale(scale);
    final t = ambient ? time : 0.0;
    final g = growth.clamp(0.0, 1.0);
    final grown = g >= .99;
    final color = plant == null
        ? const Color(0xFFE4ACA4)
        : nutrientColors[plant!.first.index];
    final second = plant == null
        ? const Color(0xFFEDC983)
        : nutrientColors[plant!.second.index];
    final sway =
        math.sin(t * 1.5) * .025 +
        (reaction > 0
            ? math.sin(reaction * math.pi * 6) * .10 * (1 - reaction)
            : 0);
    final bounce = reaction > 0 ? math.sin(reaction * math.pi) * -18 : 0.0;
    _oval(c, 200, 358, 184, 20, labInk.withValues(alpha: .10));
    if (g > .05) {
      final reveal = Curves.easeOutBack.transform(
        ((g - .08) / .78).clamp(0.0, 1.0),
      );
      c.save();
      c.translate(200, 286 + bounce);
      c.rotate(sway);
      c.scale(math.max(.01, reveal));
      c.translate(-200, -286);
      // Atmospheric halo softly fades behind the plant, never flashes.
      final glow = Rect.fromCircle(center: const Offset(200, 155), radius: 128);
      c.drawOval(
        glow,
        Paint()
          ..shader = RadialGradient(
            colors: [color.withValues(alpha: .23), color.withValues(alpha: 0)],
          ).createShader(glow),
      );
      switch (seed) {
        case SeedKind.mushroom:
          _mushroom(c, color, second, t, grown, reaction);
        case SeedKind.tree:
          _tree(c, color, second, t, grown, reaction);
        case SeedKind.flower:
          _flower(c, color, second, t, grown, reaction);
      }
      if (plant?.hybrid == true) {
        c.save();
        c.translate(296, 247);
        c.rotate(.2);
        c.scale(.37);
        c.translate(-200, -190);
        _flower(c, second, color, t, true, reaction);
        c.restore();
      }
      c.restore();
      if (g > .58) {
        final burst = ((g - .58) / .42).clamp(0.0, 1.0);
        for (var i = 0; i < 22; i++) {
          final a = i * 2.39996, r = 45 + burst * (85 + i % 5 * 9);
          final p = Offset(
            200 + math.cos(a) * r,
            165 + math.sin(a) * r * .7 + burst * burst * 35,
          );
          _sparkle(
            c,
            p,
            (1 - burst) * 8,
            [color, second, const Color(0xFFF4CC71)][i % 3],
          );
        }
      }
      if (grown && ambient) _magic(c, t, color, second);
    } else if (ingredients > 0) {
      c.drawPath(
        Path()
          ..moveTo(200, 291)
          ..quadraticBezierTo(207, 260, 196, 246),
        _line(const Color(0xFF90B387), 6),
      );
      _leaf(
        c,
        const Offset(200, 269),
        const Offset(166, 244),
        24,
        const Color(0xFFA4C58A),
      );
      if (ingredients > 1) {
        _leaf(
          c,
          const Offset(201, 263),
          const Offset(234, 230),
          27,
          const Color(0xFF8DB48B),
        );
      }
    } else {
      drawSeed(c, seed, Offset(200, 240 + math.sin(t * 2) * 4), 1.5);
      for (var i = 0; i < 3; i++) {
        _sparkle(
          c,
          Offset(154 + i * 48.0, 206 - math.sin(t + i) * 8),
          3 + math.sin(t + i).abs() * 2,
          const Color(0xFFE5C97D),
        );
      }
    }
    if (showPot) _pot(c, t, feed > 0);
    if (feed > 0 && feed < 1 && nutrient != null) {
      final f = feed;
      c.save();
      c.translate(287, 87);
      c.rotate(-.7 * math.sin(f * math.pi));
      drawNutrient(c, nutrient!, Offset.zero, 1.15);
      c.restore();
      final paintColor = nutrientColors[nutrient!.index];
      for (var i = 0; i < 18; i++) {
        final p = (f * 2 + i / 18) % 1;
        final x = 265 - 67 * p + math.sin(i * 5.2) * 12 * p;
        final y = 113 + 167 * p;
        if (nutrient == Nutrient.soda) {
          c.drawCircle(Offset(x, y), 3 + i % 3.0, _line(paintColor, 1.8));
        } else if (nutrient == Nutrient.moon || nutrient == Nutrient.rainbow) {
          _sparkle(
            c,
            Offset(x, y),
            4 + i % 4.0,
            nutrient == Nutrient.rainbow ? nutrientColors[i % 4] : paintColor,
          );
        } else {
          _note(c, Offset(x, y), .38, paintColor);
        }
      }
      c.drawOval(
        Rect.fromCenter(
          center: const Offset(200, 285),
          width: 45 + f * 65,
          height: 8 + f * 13,
        ),
        _line(paintColor.withValues(alpha: 1 - f), 3),
      );
    }
    c.restore();
  }

  void _pot(Canvas c, double t, bool happy) {
    final body = Path()
      ..moveTo(113, 283)
      ..lineTo(129, 343)
      ..quadraticBezierTo(134, 369, 200, 369)
      ..quadraticBezierTo(266, 369, 271, 343)
      ..lineTo(287, 283)
      ..close();
    _gradient(c, body, const Rect.fromLTWH(112, 280, 176, 90), [
      const Color(0xFFE5EBCF),
      const Color(0xFF93BA9F),
    ]);
    c.drawPath(body, _line(const Color(0xFF86AA90), 1.5));
    c.drawPath(
      Path()
        ..moveTo(133, 303)
        ..lineTo(143, 337)
        ..quadraticBezierTo(145, 345, 151, 346),
      _line(Colors.white.withValues(alpha: .48), 7),
    );
    _oval(c, 200, 282, 180, 43, const Color(0xFFBDD3B1));
    _oval(c, 200, 280, 155, 29, const Color(0xFF8F795E));
    _oval(c, 200, 282, 144, 22, const Color(0xFFAC9070));
    for (var i = 0; i < 13; i++) {
      _oval(
        c,
        147 + i * 8.7,
        281 + math.sin(i * 4) * 5,
        3,
        2.2,
        const Color(0xFFCEB494),
      );
    }
    c.drawArc(
      const Rect.fromLTWH(110, 259, 180, 43),
      0,
      math.pi,
      false,
      _line(const Color(0xFFE2E8CA), 6),
    );
    _face(c, const Offset(200, 326), .84, t, happy: happy);
    _leaf(
      c,
      const Offset(244, 345),
      const Offset(254, 333),
      8,
      const Color(0xFF709F80),
    );
  }

  void _mushroom(
    Canvas c,
    Color color,
    Color second,
    double t,
    bool grown,
    double reaction,
  ) {
    final stem = Path()
      ..moveTo(179, 162)
      ..cubicTo(178, 222, 164, 254, 179, 278)
      ..quadraticBezierTo(200, 292, 222, 278)
      ..cubicTo(240, 252, 219, 215, 222, 162)
      ..close();
    _gradient(c, stem, const Rect.fromLTWH(169, 162, 61, 125), [
      const Color(0xFFFFF7DD),
      const Color(0xFFF2DDB3),
    ]);
    // The stalk rises before the cap opens with a soft overshoot.
    final bloom = Curves.easeOutBack.transform(
      ((growth - .35) / .42).clamp(0.0, 1.0),
    );
    c.save();
    c.translate(200, 175);
    c.scale(math.max(.025, bloom), math.max(.025, bloom));
    c.translate(-200, -175);
    final cap = Path()
      ..moveTo(93, 159)
      ..cubicTo(106, 48, 265, 28, 310, 156)
      ..cubicTo(319, 188, 249, 200, 198, 194)
      ..cubicTo(147, 199, 85, 191, 93, 159)
      ..close();
    c.drawShadow(cap, const Color(0xFF887099).withValues(alpha: .18), 4, false);
    _gradient(c, cap, const Rect.fromLTWH(90, 67, 220, 133), [
      Color.lerp(color, Colors.white, .48)!,
      color,
      Color.lerp(color, labInk, .08)!,
    ]);
    _oval(c, 201, 174, 200, 29, Color.lerp(color, Colors.white, .63)!);
    c.drawPath(
      Path()
        ..moveTo(110, 147)
        ..cubicTo(134, 80, 209, 73, 245, 102),
      _line(Colors.white.withValues(alpha: .32), 9),
    );
    for (final dot in [
      (139.0, 127.0, 27.0),
      (190.0, 101.0, 23.0),
      (245.0, 123.0, 33.0),
      (282.0, 151.0, 18.0),
    ]) {
      _oval(
        c,
        dot.$1,
        dot.$2,
        dot.$3,
        dot.$3 * .73,
        Color.lerp(second, Colors.white, .57)!,
      );
    }
    if (plant?.second == Nutrient.moon || plant?.first == Nutrient.moon) {
      c.drawPath(
        _star(const Offset(259, 98), 15),
        _fill(const Color(0xFFFFE8A1)),
      );
    }
    c.restore();
    _face(c, const Offset(201, 224), 1.35, t, happy: reaction > .1);
    _leaf(
      c,
      const Offset(180, 264),
      const Offset(147, 243),
      17,
      const Color(0xFFA3BD82),
    );
  }

  void _tree(
    Canvas c,
    Color color,
    Color second,
    double t,
    bool grown,
    double reaction,
  ) {
    c.drawPath(
      Path()
        ..moveTo(201, 285)
        ..quadraticBezierTo(193, 206, 202, 112),
      _line(const Color(0xFF9BAF83), 15),
    );
    for (var i = 0; i < 5; i++) {
      final left = i.isEven,
          y = 245 - i * 28.0,
          end = Offset(left ? 135 : 267, y - 47);
      final unfurl = Curves.easeOutBack.transform(
        ((growth - .17 - i * .07) / .27).clamp(0.0, 1.0),
      );
      c.save();
      c.translate(200, y);
      c.scale(math.max(.01, unfurl));
      c.translate(-200, -y);
      c.drawPath(
        Path()
          ..moveTo(200, y)
          ..quadraticBezierTo(left ? 159 : 241, y - 10, end.dx, end.dy),
        _line(const Color(0xFF9EB789), 7),
      );
      _leaf(
        c,
        Offset(left ? 162 : 237, y - 23),
        Offset(left ? 112 : 283, y - 26),
        22,
        const Color(0xFFBAD092),
      );
      c.save();
      c.translate(end.dx, end.dy);
      c.rotate(math.sin(t * 1.8 + i) * .09);
      final star = _star(Offset.zero, 29);
      _gradient(c, star, const Rect.fromLTWH(-29, -29, 58, 58), [
        Color.lerp(i.isEven ? color : second, Colors.white, .53)!,
        i.isEven ? color : second,
      ]);
      _sparkle(c, const Offset(-5, -8), 6, Colors.white.withValues(alpha: .68));
      c.restore();
      c.restore();
    }
    final crownBloom = Curves.easeOutBack.transform(
      ((growth - .56) / .30).clamp(0.0, 1.0),
    );
    c.save();
    c.translate(200, 91);
    c.scale(math.max(.01, crownBloom));
    c.translate(-200, -91);
    final crown = _star(const Offset(200, 91), 54);
    _gradient(c, crown, const Rect.fromLTWH(145, 37, 110, 110), [
      const Color(0xFFFFEAA9),
      Color.lerp(second, const Color(0xFFF2CB71), .6)!,
    ]);
    _face(c, const Offset(200, 94), .86, t, happy: reaction > .1);
    c.restore();
  }

  void _flower(
    Canvas c,
    Color color,
    Color second,
    double t,
    bool grown,
    double reaction,
  ) {
    c.drawPath(
      Path()
        ..moveTo(200, 285)
        ..cubicTo(216, 238, 181, 193, 200, 132),
      _line(const Color(0xFF91B68A), 9),
    );
    _leaf(
      c,
      const Offset(204, 258),
      const Offset(134, 219),
      42,
      const Color(0xFFADC98E),
    );
    _leaf(
      c,
      const Offset(200, 228),
      const Offset(264, 190),
      39,
      const Color(0xFF8FB58A),
    );
    c.save();
    c.translate(200, 135);
    c.rotate(math.sin(t * 1.3) * .04);
    final bloom = Curves.easeOutBack.transform(
      ((growth - .35) / .40).clamp(0.0, 1.0),
    );
    c.scale(math.max(.01, bloom));
    for (var i = 0; i < 7; i++) {
      c.save();
      c.rotate(i * math.pi * 2 / 7);
      final petalBloom = Curves.easeOutBack.transform(
        ((growth - .4 - i * .027) / .25).clamp(0.0, 1.0),
      );
      c.scale(math.max(.01, petalBloom));
      final petal = Path()
        ..moveTo(-17, -10)
        ..cubicTo(-66, -34, -49, -100, 0, -83)
        ..cubicTo(49, -100, 66, -34, 17, -10)
        ..close();
      _gradient(c, petal, const Rect.fromLTWH(-48, -90, 96, 80), [
        Color.lerp(i.isEven ? color : second, Colors.white, .49)!,
        i.isEven ? color : second,
      ]);
      c.drawPath(
        Path()
          ..moveTo(0, -66)
          ..lineTo(0, -43),
        _line(Colors.white.withValues(alpha: .25), 5),
      );
      c.restore();
    }
    c.drawCircle(
      Offset.zero,
      44,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.3, -.4),
          colors: [Color(0xFFFFF4C5), Color(0xFFF4D794)],
        ).createShader(const Rect.fromLTWH(-44, -44, 88, 88)),
    );
    _face(c, const Offset(0, 0), 1.1, t, happy: reaction > .1);
    c.restore();
  }

  void _magic(Canvas c, double t, Color color, Color second) {
    final strong = reaction > 0 ? 1.7 : 1.0;
    for (var i = 0; i < 12; i++) {
      final p = (t * .13 + i / 12) % 1, a = i * 2.39996;
      final x = 200 + math.sin(a + t * .27) * (90 + p * 40) * strong;
      final y = 270 - p * 230;
      final opacity = (math.sin(p * math.pi) * .72).clamp(0.0, 1.0);
      final type = plant == null
          ? Nutrient.moon
          : (i.isEven ? plant!.first : plant!.second);
      switch (type) {
        case Nutrient.moon:
          _sparkle(
            c,
            Offset(x, y),
            4 + i % 4.0,
            const Color(0xFFEAC567).withValues(alpha: opacity),
          );
        case Nutrient.music:
          _note(c, Offset(x, y), .5, second.withValues(alpha: opacity));
        case Nutrient.soda:
          c.drawCircle(
            Offset(x, y),
            6 + i % 5.0,
            _line(color.withValues(alpha: opacity), 1.7),
          );
          _oval(c, x - 2, y - 3, 3, 2, Colors.white.withValues(alpha: opacity));
        case Nutrient.rainbow:
          _sparkle(
            c,
            Offset(x, y),
            5 + i % 4.0,
            nutrientColors[i % 4].withValues(alpha: opacity),
          );
      }
    }
  }

  void _note(Canvas c, Offset p, double s, Color color) {
    c.save();
    c.translate(p.dx, p.dy);
    c.scale(s);
    _oval(c, 0, 0, 12, 8, color);
    c.drawPath(
      Path()
        ..moveTo(5, 0)
        ..lineTo(5, -22)
        ..quadraticBezierTo(18, -21, 14, -12),
      _line(color, 3),
    );
    c.restore();
  }

  @override
  bool shouldRepaint(PlantPainter old) => true;
}

class LabAtmospherePainter extends CustomPainter {
  const LabAtmospherePainter(this.time);
  final double time;
  @override
  void paint(Canvas c, Size size) {
    for (var i = 0; i < 14; i++) {
      final p = (time * .04 + i / 14) % 1;
      final x = (i * .193 % 1) * size.width + math.sin(time * .7 + i) * 12;
      final y = size.height * (1 - p);
      c.drawCircle(
        Offset(x, y),
        i % 3 + 1.3,
        _fill(
          const Color(
            0xFFF4D78E,
          ).withValues(alpha: math.sin(p * math.pi) * .52),
        ),
      );
    }
    // Three drifting petals, away from the main interaction area.
    for (var i = 0; i < 3; i++) {
      final p = (time * .035 + i / 3) % 1;
      c.save();
      c.translate(
        size.width * (.1 + i * .36) + math.sin(time * .6 + i) * 17,
        size.height * p,
      );
      c.rotate(time * .4 + i);
      _oval(c, 0, 0, 8, 4, const Color(0xFFF1C4C0).withValues(alpha: .6));
      c.restore();
    }
  }

  @override
  bool shouldRepaint(LabAtmospherePainter old) => old.time != time;
}
