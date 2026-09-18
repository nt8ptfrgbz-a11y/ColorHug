import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dress_catalog.dart';

const dressInk = Color(0xFF55463F);
const dressCream = Color(0xFFFFFAF2);
const dressRose = Color(0xFFAB7478);
const dressMuted = Color(0xFF9B8C7F);

class DressItemArt extends StatelessWidget {
  const DressItemArt(this.item, {super.key, this.size = 88});
  final DressItem item;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _ItemPainter(item)),
  );
}

class _ItemPainter extends CustomPainter {
  _ItemPainter(this.item);
  final DressItem item;
  late Canvas c;
  void shape(Path path, Color color, {bool outline = true}) {
    c.drawPath(
      path.shift(const Offset(0, 2)),
      Paint()
        ..color = const Color(0x12563D30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    c.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, .18)!,
            color,
            Color.lerp(color, const Color(0xFF6D594C), .08)!,
          ],
        ).createShader(const Rect.fromLTWH(5, 5, 90, 90)),
    );
    if (outline) {
      c.drawPath(
        path,
        Paint()
          ..color = Color.lerp(color, dressInk, .16)!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  void oval(Rect rect, Color color) => c.drawOval(rect, Paint()..color = color);
  void line(List<Offset> points, Color color, [double width = 2]) {
    final p = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      p.lineTo(point.dx, point.dy);
    }
    c.drawPath(
      p,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void bow(double x, double y, Color color, [double scale = 1]) {
    c.save();
    c.translate(x, y);
    c.scale(scale);
    shape(
      Path()
        ..moveTo(0, 0)
        ..cubicTo(-24, -18, -23, 16, 0, 1)
        ..cubicTo(24, 16, 24, -18, 0, 0),
      color,
    );
    oval(
      const Rect.fromLTWH(-3, -4, 6, 8),
      Color.lerp(color, Colors.white, .2)!,
    );
    c.restore();
  }

  void flower(double x, double y, double r) {
    for (var i = 0; i < 5; i++) {
      final a = i * math.pi * 2 / 5;
      oval(
        Rect.fromCircle(
          center: Offset(x + math.sin(a) * r * .55, y + math.cos(a) * r * .55),
          radius: r * .45,
        ),
        item.accent,
      );
    }
    oval(
      Rect.fromCircle(center: Offset(x, y), radius: r * .28),
      const Color(0xFFD5AA57),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    c = canvas;
    c.save();
    c.scale(size.width / 100, size.height / 100);
    final col = item.color, acc = item.accent;
    switch (item.category) {
      case DressCategory.outfit:
      case DressCategory.top:
        final full = item.category == DressCategory.outfit;
        final pants = ['pajamas', 'safari'].contains(item.shape);
        final long = [
          'coat',
          'pajamas',
          'cardigan',
          'knit',
          'hoodie',
        ].contains(item.shape);
        final hem = full && !pants ? 84.0 : 62.0;
        shape(
          Path()
            ..moveTo(38, 18)
            ..lineTo(26, 23)
            ..lineTo(long ? 12 : 18, long ? 59 : 39)
            ..quadraticBezierTo(
              18,
              long ? 64 : 44,
              long ? 25 : 30,
              long ? 60 : 45,
            )
            ..lineTo(33, 34)
            ..lineTo(full && !pants ? 21 : 31, hem)
            ..quadraticBezierTo(50, hem + 8, full && !pants ? 79 : 69, hem)
            ..lineTo(67, 34)
            ..lineTo(long ? 75 : 70, long ? 60 : 45)
            ..quadraticBezierTo(
              83,
              long ? 64 : 44,
              long ? 88 : 82,
              long ? 59 : 39,
            )
            ..lineTo(74, 23)
            ..lineTo(62, 18)
            ..quadraticBezierTo(50, 29, 38, 18)
            ..close(),
          col,
        );
        c.drawArc(
          const Rect.fromLTWH(38, 13, 24, 17),
          0,
          math.pi,
          false,
          Paint()
            ..color = acc
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
        if (full && !pants) {
          line([const Offset(32, 47), const Offset(68, 47)], acc, 3);
          for (var i = 0; i < 5; i++) {
            line(
              [Offset(38 + i * 6, 52), Offset(29 + i * 10, 79)],
              col.withValues(alpha: .6),
              1.4,
            );
          }
        }
        if (item.shape == 'dress') {
          bow(50, 48, acc, .6);
          for (var i = 0; i < 4; i++) {
            flower(31 + i * 13, 74, 3);
          }
        }
        if (item.shape == 'pinafore') {
          shape(
            Path()..addRRect(
              RRect.fromRectAndRadius(
                const Rect.fromLTWH(39, 57, 22, 17),
                const Radius.circular(4),
              ),
            ),
            acc,
          );
          flower(50, 65, 4);
        }
        if (item.shape == 'tutu') {
          line([const Offset(26, 66), const Offset(74, 66)], acc, 3);
          for (var i = 0; i < 3; i++) {
            flower(35 + i * 15, 76, 3);
          }
        }
        if ([
          'coat',
          'cardigan',
          'pajamas',
          'blouse',
          'safari',
        ].contains(item.shape)) {
          line([const Offset(50, 29), Offset(50, hem - 5)], acc, 2);
          for (var i = 0; i < 3; i++) {
            oval(
              Rect.fromCircle(center: Offset(54, 34 + i * 11), radius: 1.8),
              acc,
            );
          }
        }
        if (item.shape == 'stripe') {
          for (var i = 0; i < 4; i++) {
            line([Offset(34, 34 + i * 7), Offset(66, 34 + i * 7)], acc, 3);
          }
        }
        if (item.shape == 'knit') {
          for (var j = 0; j < 4; j++) {
            for (var i = 0; i < 4; i++) {
              line(
                [
                  Offset(38 + i * 7, 31 + j * 7),
                  Offset(40 + i * 7, 34 + j * 7),
                  Offset(42 + i * 7, 31 + j * 7),
                ],
                acc,
                1,
              );
            }
          }
        }
        if (item.shape == 'hoodie') {
          shape(
            Path()..addRRect(
              RRect.fromRectAndRadius(
                const Rect.fromLTWH(39, 45, 22, 11),
                const Radius.circular(4),
              ),
            ),
            acc,
          );
        }
        if (item.shape == 'sailor') {
          line(
            [const Offset(34, 23), const Offset(50, 39), const Offset(66, 23)],
            acc,
            6,
          );
          bow(50, 42, acc, .45);
        }
        if (pants) {
          for (var i = 0; i < 2; i++) {
            shape(
              Path()..addRRect(
                RRect.fromRectAndRadius(
                  Rect.fromLTWH(
                    32 + i * 20,
                    60,
                    17,
                    item.shape == 'pajamas' ? 25 : 15,
                  ),
                  const Radius.circular(3),
                ),
              ),
              col,
            );
          }
        }
      case DressCategory.bottom:
        final skirt = ['pleats', 'tutu'].contains(item.shape),
            long = ['pants', 'dungarees'].contains(item.shape);
        if (skirt) {
          shape(
            Path()
              ..moveTo(33, 27)
              ..lineTo(67, 27)
              ..lineTo(82, 75)
              ..quadraticBezierTo(50, 87, 18, 75)
              ..close(),
            col,
          );
          for (var i = 0; i < 6; i++) {
            line([Offset(35 + i * 6, 31), Offset(24 + i * 10, 76)], acc, 1.4);
          }
          line([const Offset(34, 29), const Offset(66, 29)], acc, 4);
        } else {
          shape(
            Path()
              ..moveTo(28, 27)
              ..lineTo(72, 27)
              ..lineTo(76, long ? 84 : 64)
              ..lineTo(54, long ? 84 : 64)
              ..lineTo(50, 49)
              ..lineTo(46, long ? 84 : 64)
              ..lineTo(24, long ? 84 : 64)
              ..close(),
            col,
          );
          line([const Offset(29, 30), const Offset(71, 30)], acc, 3);
          for (var s = 0; s < 2; s++) {
            line(
              [
                Offset(27 + s * 29, long ? 80 : 61),
                Offset(44 + s * 29, long ? 80 : 61),
              ],
              acc,
              4,
            );
          }
          if (item.shape == 'dungarees') {
            shape(
              Path()..addRRect(
                RRect.fromRectAndRadius(
                  const Rect.fromLTWH(35, 15, 30, 22),
                  const Radius.circular(4),
                ),
              ),
              col,
            );
            line([const Offset(37, 8), const Offset(37, 26)], col, 5);
            line([const Offset(63, 8), const Offset(63, 26)], col, 5);
          }
        }
      case DressCategory.shoes:
        for (var i = 0; i < 2; i++) {
          c.save();
          c.translate(i * 33 + 2, i * 5.0);
          final boots = item.shape == 'boots';
          shape(
            Path()
              ..moveTo(21, boots ? 22 : 45)
              ..lineTo(42, boots ? 22 : 45)
              ..lineTo(44, 58)
              ..cubicTo(67, 61, 65, 78, 51, 79)
              ..lineTo(21, 79)
              ..quadraticBezierTo(15, 74, 18, 67)
              ..close(),
            col,
          );
          line([const Offset(21, 77), const Offset(56, 77)], acc, 4);
          if (boots) {
            line([const Offset(22, 25), const Offset(41, 25)], acc, 3);
          }
          if (item.shape == 'maryjane') {
            line([const Offset(28, 59), const Offset(47, 63)], acc, 3);
          }
          if (item.shape == 'sneakers') {
            for (var j = 0; j < 3; j++) {
              line(
                [
                  Offset(32 + j * 4, 57 + j * 3),
                  Offset(40 + j * 4, 54 + j * 3),
                ],
                acc,
                2,
              );
            }
          }
          if (item.shape == 'ballet') bow(41, 65, acc, .4);
          if (item.shape == 'bunny') {
            oval(const Rect.fromLTWH(33, 38, 7, 24), col);
            oval(const Rect.fromLTWH(43, 38, 7, 24), col);
            oval(const Rect.fromLTWH(35, 44, 3, 12), acc);
            oval(const Rect.fromLTWH(45, 44, 3, 12), acc);
          }
          c.restore();
        }
      case DressCategory.hair:
        oval(const Rect.fromLTWH(25, 23, 50, 59), const Color(0xFFEAD0B5));
        shape(
          Path()
            ..moveTo(26, 59)
            ..cubicTo(12, 10, 86, 0, 77, 61)
            ..lineTo(67, 40)
            ..quadraticBezierTo(50, 46, 39, 34)
            ..lineTo(26, 59)
            ..close(),
          col,
        );
        if (item.shape == 'buns') {
          for (final x in [14.0, 66.0]) {
            oval(Rect.fromLTWH(x, 13, 21, 23), col);
          }
        }
        if (['pigtails', 'braids', 'waves', 'bob'].contains(item.shape)) {
          for (var s = 0; s < 2; s++) {
            for (var i = 0; i < (item.shape == 'braids' ? 5 : 3); i++) {
              oval(
                Rect.fromLTWH(
                  19 + s * 47.0,
                  37 + i * 8.0,
                  item.shape == 'braids' ? 12 : 17,
                  20,
                ),
                col,
              );
            }
          }
        }
        if (item.shape == 'pigtails') {
          bow(23, 47, acc, .4);
          bow(76, 47, acc, .4);
        }
        oval(const Rect.fromLTWH(36, 56, 5, 6), dressInk);
        oval(const Rect.fromLTWH(58, 56, 5, 6), dressInk);
        c.drawArc(
          const Rect.fromLTWH(45, 64, 11, 7),
          0,
          math.pi,
          false,
          Paint()
            ..color = dressRose
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      case DressCategory.accessory:
        if (item.shape == 'bow') bow(50, 49, col, 1.65);
        if (item.shape == 'flower') {
          c.drawCircle(
            const Offset(50, 50),
            26,
            Paint()
              ..color = const Color(0xFF9BAB84)
              ..strokeWidth = 4
              ..style = PaintingStyle.stroke,
          );
          for (var i = 0; i < 7; i++) {
            final a = i * math.pi * 2 / 7;
            flower(50 + math.sin(a) * 26, 50 + math.cos(a) * 26, 8);
          }
        }
        if (item.shape == 'beret') {
          shape(
            Path()
              ..moveTo(19, 64)
              ..cubicTo(-3, 25, 84, 17, 86, 49)
              ..quadraticBezierTo(84, 64, 19, 64)
              ..close(),
            col,
          );
          line([const Offset(25, 65), const Offset(73, 60)], acc, 5);
          line([const Offset(55, 28), const Offset(53, 20)], col, 4);
        }
        if (item.shape == 'crown') {
          shape(
            Path()
              ..moveTo(22, 71)
              ..lineTo(14, 33)
              ..lineTo(34, 44)
              ..lineTo(50, 22)
              ..lineTo(66, 44)
              ..lineTo(86, 33)
              ..lineTo(78, 71)
              ..close(),
            col,
          );
          line([const Offset(24, 64), const Offset(76, 64)], acc, 3);
          for (final x in [33.0, 50.0, 67.0]) {
            oval(Rect.fromCircle(center: Offset(x, 56), radius: 3), acc);
          }
        }
        if (item.shape == 'ears') {
          c.drawArc(
            const Rect.fromLTWH(21, 42, 58, 51),
            math.pi,
            math.pi,
            false,
            Paint()
              ..color = col
              ..style = PaintingStyle.stroke
              ..strokeWidth = 8,
          );
          for (final x in [24.0, 59.0]) {
            oval(Rect.fromLTWH(x, 12, 18, 49), col);
            oval(Rect.fromLTWH(x + 5, 19, 8, 33), acc);
          }
        }
        if (item.shape == 'bag') {
          c.drawArc(
            const Rect.fromLTWH(28, 14, 43, 58),
            math.pi,
            math.pi,
            false,
            Paint()
              ..color = col
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4,
          );
          shape(
            Path()..addRRect(
              RRect.fromRectAndRadius(
                const Rect.fromLTWH(20, 42, 61, 41),
                const Radius.circular(13),
              ),
            ),
            col,
          );
          shape(
            Path()..addRRect(
              RRect.fromRectAndRadius(
                const Rect.fromLTWH(22, 43, 57, 20),
                const Radius.circular(8),
              ),
            ),
            acc,
          );
          flower(51, 65, 7);
        }
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_ItemPainter oldDelegate) => oldDelegate.item != item;
}
