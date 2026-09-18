import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'town_catalog.dart';
import 'town_model.dart';

const townInk = Color(0xFF3F5148);
const townCream = Color(0xFFFFFBF0);
const townCoral = Color(0xFFE9947D);
const townGreen = Color(0xFF92BAA1);
const townPurple = Color(0xFFB7A2D0);

/// Layered, resolution-independent character art. Every face, limb and prop is
/// a separate drawing so input can deform it without stretching a screenshot.
class TownArt {
  static Paint fill(Color c) => Paint()..color = c;
  static Paint stroke(Color c, [double width = 3]) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static void oval(Canvas c, Rect r, Color color, {bool shaded = false}) {
    c.drawOval(
      r,
      shaded
          ? (Paint()
              ..shader = LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(color, Colors.white, .2)!,
                  color,
                  Color.lerp(color, townInk, .10)!,
                ],
              ).createShader(r))
          : fill(color),
    );
  }

  static void round(Canvas c, Rect r, Color color, [double radius = 18]) {
    c.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(radius)),
      fill(color),
    );
  }

  static void line(
    Canvas c,
    Offset a,
    Offset b,
    Color color, [
    double width = 4,
  ]) => c.drawLine(a, b, stroke(color, width));
  static void shadow(Canvas c, Offset p, double r) => oval(
    c,
    Rect.fromCenter(center: p, width: r * 1.7, height: r * .23),
    townInk.withValues(alpha: .10),
  );
  static void star(
    Canvas c,
    Offset at,
    double r,
    Color color, {
    int points = 5,
  }) {
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final a = -math.pi / 2 + i * math.pi / points;
      final v =
          at + Offset(math.cos(a), math.sin(a)) * r * (i.isEven ? 1 : .49);
      if (i == 0) {
        path.moveTo(v.dx, v.dy);
      } else {
        path.lineTo(v.dx, v.dy);
      }
    }
    c.drawPath(path..close(), fill(color));
  }

  static void face(
    Canvas c, {
    double x = 0,
    double y = 0,
    double s = 1,
    double joy = 0,
    bool asleep = false,
    Offset gaze = Offset.zero,
  }) {
    c.save();
    c.translate(x, y);
    c.scale(s);
    for (final side in [-1.0, 1.0]) {
      final eye = Offset(side * 24, -8);
      if (asleep || joy > .7) {
        final path = Path()
          ..moveTo(eye.dx - 9, eye.dy + 2)
          ..quadraticBezierTo(
            eye.dx,
            eye.dy + (asleep ? 10 : -12),
            eye.dx + 9,
            eye.dy + 2,
          );
        c.drawPath(path, stroke(townInk, 4));
      } else {
        oval(c, Rect.fromCenter(center: eye, width: 22, height: 28), townCream);
        oval(
          c,
          Rect.fromCenter(center: eye + gaze * 3, width: 10, height: 14),
          townInk,
        );
        c.drawCircle(
          eye + gaze * 3 + const Offset(2, -3),
          2.4,
          fill(Colors.white),
        );
      }
      oval(
        c,
        Rect.fromCenter(center: Offset(side * 38, 13), width: 18, height: 10),
        townCoral.withValues(alpha: .63),
      );
    }
    if (asleep) {
      oval(
        c,
        const Rect.fromLTWH(-5, 15, 10, 13),
        townInk.withValues(alpha: .7),
      );
    } else if (joy > .2) {
      oval(c, Rect.fromLTWH(-16, 9, 32, 16 + joy * 17), townInk);
      oval(c, Rect.fromLTWH(-10, 19 + joy * 8, 20, 8), const Color(0xFFF3999A));
      round(c, const Rect.fromLTWH(-8, 10, 16, 6), townCream, 2);
    } else {
      c.drawPath(
        Path()
          ..moveTo(-11, 16)
          ..quadraticBezierTo(0, 28, 11, 16),
        stroke(townInk, 3.5),
      );
    }
    c.restore();
  }

  static void monster(
    Canvas c,
    Offset at,
    double r, {
    Color color = townGreen,
    double t = 0,
    double joy = 0,
    double squish = 0,
    bool asleep = false,
    Offset gaze = Offset.zero,
    bool party = false,
  }) {
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(r / 100);
    c.scale(1 + squish * .13, 1 - squish * .12);
    // Soft feet and a warm undershadow anchor the body in the world.
    oval(
      c,
      Rect.fromLTWH(-64, 69 + math.sin(t * 3) * 3, 45, 28),
      Color.lerp(color, townInk, .17)!,
    );
    oval(
      c,
      Rect.fromLTWH(19, 69 - math.sin(t * 3) * 3, 45, 28),
      Color.lerp(color, townInk, .17)!,
    );
    for (final side in [-1.0, 1.0]) {
      c.save();
      c.translate(side * 88, 12);
      c.rotate(side * (.2 + math.sin(t * 3) * .12 + joy * .7));
      oval(c, const Rect.fromLTWH(-15, -10, 31, 65), color, shaded: true);
      c.restore();
      final horn = Path()
        ..moveTo(side * 26, -68)
        ..quadraticBezierTo(side * 36, -134, side * 56, -112)
        ..quadraticBezierTo(side * 68, -92, side * 57, -64)
        ..close();
      c.drawPath(horn, fill(const Color(0xFFF2D485)));
      line(
        c,
        Offset(side * 35, -91),
        Offset(side * 54, -90),
        const Color(0xFFD7B765),
        3,
      );
    }
    final body = Path()
      ..moveTo(0, -90)
      ..cubicTo(75, -97, 86, -41, 85, 15)
      ..cubicTo(88, 89, 49, 91, 0, 91)
      ..cubicTo(-69, 96, -86, 67, -85, 12)
      ..cubicTo(-84, -55, -61, -94, 0, -90)
      ..close();
    c.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, .25)!,
            color,
            Color.lerp(color, townInk, .08)!,
          ],
        ).createShader(const Rect.fromLTWH(-85, -90, 170, 185)),
    );
    oval(
      c,
      const Rect.fromLTWH(-53, 22, 106, 57),
      Colors.white.withValues(alpha: .16),
    );
    for (var i = 0; i < 9; i++) {
      c.drawCircle(
        Offset(-63 + i % 3 * 10, 23 + i ~/ 3 * 11),
        2.4,
        fill(townInk.withValues(alpha: .09)),
      );
    }
    c.drawPath(
      Path()
        ..moveTo(-63, -28)
        ..quadraticBezierTo(-66, -63, -37, -73),
      stroke(Colors.white.withValues(alpha: .30), 7),
    );
    face(c, y: -7, joy: joy, asleep: asleep, gaze: gaze);
    if (party) {
      final hat = Path()
        ..moveTo(-29, -88)
        ..lineTo(0, -145)
        ..lineTo(29, -88)
        ..close();
      c.drawPath(hat, fill(townCoral));
      c.drawCircle(const Offset(0, -145), 8, fill(townCream));
      line(c, const Offset(-18, -108), const Offset(18, -108), townCream, 5);
    }
    c.restore();
  }

  static void cloud(
    Canvas c,
    Offset at,
    double r, {
    Color color = townCream,
    bool eyes = false,
    double joy = 0,
    bool asleep = false,
  }) {
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(r / 90);
    final path = Path()
      ..moveTo(-63, 30)
      ..cubicTo(-112, 24, -96, -26, -63, -23)
      ..cubicTo(-67, -81, -2, -92, 15, -49)
      ..cubicTo(61, -79, 88, -38, 76, -15)
      ..cubicTo(125, -8, 103, 38, 64, 35)
      ..close();
    c.drawPath(path, fill(color));
    if (eyes) face(c, s: .8, joy: joy, asleep: asleep);
    c.restore();
  }

  static void object(
    Canvas c,
    String kind,
    Offset at,
    double radius, {
    Color? color,
    double t = 0,
  }) {
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(radius / 60);
    final red = color ?? townCoral;
    switch (kind) {
      case 'apple':
        oval(c, const Rect.fromLTWH(-44, -29, 52, 70), red, shaded: true);
        oval(c, const Rect.fromLTWH(-8, -29, 52, 70), red, shaded: true);
        line(c, const Offset(0, -25), const Offset(4, -47), townInk, 6);
        oval(c, const Rect.fromLTWH(4, -49, 27, 13), townGreen);
        oval(
          c,
          const Rect.fromLTWH(-28, -17, 9, 22),
          Colors.white.withValues(alpha: .45),
        );
      case 'orange' || 'melon':
        oval(
          c,
          const Rect.fromLTWH(-43, -43, 86, 86),
          kind == 'orange' ? const Color(0xFFF3B958) : townGreen,
          shaded: true,
        );
        if (kind == 'melon') {
          for (var i = -1; i < 2; i++) {
            c.drawArc(
              Rect.fromLTWH(-35 + i * 10, -41, 60, 82),
              -1.4,
              2.8,
              false,
              stroke(const Color(0xFF6D9477), 5),
            );
          }
        } else {
          for (var i = 0; i < 12; i++) {
            c.drawCircle(
              Offset(math.sin(i * 4) * 29, math.cos(i * 3) * 29),
              2,
              fill(const Color(0xFFD99839)),
            );
          }
        }
        oval(c, const Rect.fromLTWH(0, -49, 26, 13), townGreen);
      case 'banana':
        final p = Path()
          ..moveTo(-41, -34)
          ..cubicTo(-39, 43, 26, 66, 43, -18)
          ..cubicTo(10, 25, -17, 15, -33, -39)
          ..close();
        c.drawPath(p, fill(const Color(0xFFF4CE62)));
        c.drawPath(
          Path()
            ..moveTo(-33, -20)
            ..quadraticBezierTo(-7, 49, 36, -7),
          stroke(const Color(0xFFE3AF44), 4),
        );
        line(c, const Offset(-37, -34), const Offset(-41, -45), townInk, 6);
      case 'berry' || 'cherry':
        if (kind == 'berry') {
          final p = Path()
            ..moveTo(-38, -20)
            ..cubicTo(-53, 5, -15, 51, 0, 49)
            ..cubicTo(22, 41, 49, 4, 37, -20)
            ..quadraticBezierTo(0, -48, -38, -20)
            ..close();
          c.drawPath(p, fill(const Color(0xFFE89092)));
          for (var i = 0; i < 8; i++) {
            oval(
              c,
              Rect.fromCenter(
                center: Offset((i % 3 - 1) * 17.0, (i ~/ 3) * 18 - 11.0),
                width: 4,
                height: 7,
              ),
              const Color(0xFFFFE8B1),
            );
          }
          star(c, const Offset(0, -30), 24, townGreen, points: 6);
        } else {
          line(c, const Offset(-15, 7), const Offset(7, -40), townGreen, 5);
          line(c, const Offset(27, 7), const Offset(7, -40), townGreen, 5);
          oval(c, const Rect.fromLTWH(-39, -6, 43, 45), red, shaded: true);
          oval(c, const Rect.fromLTWH(7, -6, 43, 45), red, shaded: true);
        }
      case 'star':
        star(c, Offset.zero, 49, color ?? const Color(0xFFF4CF6A));
        face(c, s: .4, y: 5);
      case 'heart':
        c.drawPath(
          Path()
            ..moveTo(0, 40)
            ..cubicTo(-88, -12, -31, -67, 0, -27)
            ..cubicTo(31, -67, 88, -12, 0, 40)
            ..close(),
          fill(red),
        );
      case 'drop':
        c.drawPath(
          Path()
            ..moveTo(0, -49)
            ..cubicTo(17, -16, 42, 2, 33, 25)
            ..cubicTo(24, 54, -28, 49, -34, 25)
            ..cubicTo(-42, 2, -17, -18, 0, -49)
            ..close(),
          fill(const Color(0xFF8FCBD3)),
        );
        oval(
          c,
          const Rect.fromLTWH(-22, 0, 9, 19),
          Colors.white.withValues(alpha: .6),
        );
      case 'bubble':
        c.drawCircle(
          Offset.zero,
          43,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-.4, -.5),
              colors: [
                Colors.white.withValues(alpha: .1),
                const Color(0xFFAFE2E0).withValues(alpha: .42),
                const Color(0xFFD4B8E1).withValues(alpha: .55),
              ],
            ).createShader(const Rect.fromLTWH(-43, -43, 86, 86)),
        );
        c.drawCircle(
          Offset.zero,
          43,
          stroke(Colors.white.withValues(alpha: .85), 2.5),
        );
        c.drawArc(
          const Rect.fromLTWH(-33, -33, 66, 66),
          3.5,
          1.0,
          false,
          stroke(Colors.white, 5),
        );
      case 'sock' || 'shoe':
        final p = Path()
          ..moveTo(-22, -40)
          ..lineTo(13, -40)
          ..lineTo(13, 9)
          ..quadraticBezierTo(59, 4, 50, 31)
          ..quadraticBezierTo(44, 46, -7, 39)
          ..quadraticBezierTo(-30, 35, -22, 13)
          ..close();
        c.drawPath(p, fill(red));
        line(c, const Offset(-20, -23), const Offset(11, -23), townCream, 7);
        if (kind == 'shoe') {
          line(c, const Offset(-16, 32), const Offset(39, 32), townCream, 6);
        }
      case 'hat':
        round(c, const Rect.fromLTWH(-32, -34, 64, 55), townPurple, 20);
        oval(c, const Rect.fromLTWH(-52, 8, 104, 22), townPurple);
        round(c, const Rect.fromLTWH(-30, -2, 60, 12), townCream, 3);
      case 'feather' || 'leaf':
        c.save();
        c.rotate(.45);
        oval(
          c,
          const Rect.fromLTWH(-22, -48, 44, 84),
          kind == 'leaf' ? townGreen : townPurple,
        );
        line(c, const Offset(0, -34), const Offset(0, 50), townCream, 3);
        for (var i = 0; i < 5; i++) {
          line(
            c,
            Offset(0, i * 12 - 17.0),
            Offset(15, i * 12 - 27.0),
            townCream,
            2,
          );
        }
        c.restore();
      case 'flower':
        line(c, const Offset(0, 10), const Offset(0, 52), townGreen, 7);
        oval(c, const Rect.fromLTWH(0, 24, 27, 12), townGreen);
        for (var i = 0; i < 6; i++) {
          final a = i * math.pi / 3;
          c.drawCircle(Offset(math.cos(a), math.sin(a)) * 25, 18, fill(red));
        }
        c.drawCircle(Offset.zero, 22, fill(const Color(0xFFF5D374)));
        face(c, s: .35);
      case 'bell':
        c.drawCircle(const Offset(0, 37), 8, fill(const Color(0xFFC89D40)));
        c.drawPath(
          Path()
            ..moveTo(-37, 28)
            ..quadraticBezierTo(-23, 8, -23, -18)
            ..quadraticBezierTo(0, -49, 23, -18)
            ..quadraticBezierTo(23, 8, 37, 28)
            ..close(),
          fill(const Color(0xFFF1C76A)),
        );
        c.drawCircle(const Offset(0, -39), 6, fill(const Color(0xFFF1C76A)));
        line(
          c,
          const Offset(-33, 28),
          const Offset(33, 28),
          const Color(0xFFD5AC53),
          5,
        );
      case 'drum':
        round(c, const Rect.fromLTWH(-44, -25, 88, 67), red, 12);
        for (var i = 0; i < 4; i++) {
          c.drawPath(
            Path()
              ..moveTo(-38 + i * 22, -17)
              ..lineTo(-28 + i * 22, 33)
              ..lineTo(-16 + i * 22, -17),
            stroke(townCream, 3),
          );
        }
        oval(c, const Rect.fromLTWH(-44, -38, 88, 28), const Color(0xFFF6DFAC));
        line(c, const Offset(-27, -51), const Offset(22, -19), townInk, 4);
        c.drawCircle(const Offset(22, -19), 6, fill(townCream));
      case 'mushroom':
        round(
          c,
          const Rect.fromLTWH(-13, 0, 26, 49),
          const Color(0xFFE8D7B2),
          9,
        );
        c.drawPath(
          Path()
            ..moveTo(-51, 1)
            ..quadraticBezierTo(-42, -64, 0, -49)
            ..quadraticBezierTo(43, -61, 51, 1)
            ..quadraticBezierTo(0, 19, -51, 1)
            ..close(),
          fill(red),
        );
        for (final p in [
          const Offset(-22, -16),
          const Offset(10, -29),
          const Offset(31, -7),
        ]) {
          c.drawCircle(p, 7, fill(townCream));
        }
        face(c, s: .32, y: 26);
      case 'toast':
        final p = Path()
          ..moveTo(-31, 40)
          ..lineTo(-31, -8)
          ..cubicTo(-58, -52, 56, -52, 31, -8)
          ..lineTo(31, 40)
          ..close();
        c.drawPath(p, fill(const Color(0xFFDCAA68)));
        c.save();
        c.scale(.79);
        c.drawPath(p, fill(const Color(0xFFFFE6AC)));
        c.restore();
        face(c, s: .5, y: 5);
      case 'cake':
        round(
          c,
          const Rect.fromLTWH(-39, -6, 78, 49),
          const Color(0xFFE7BB88),
          8,
        );
        round(c, const Rect.fromLTWH(-39, 4, 78, 12), townCream, 3);
        c.drawPath(
          Path()
            ..moveTo(-46, -2)
            ..cubicTo(-49, -39, -25, -33, -15, -41)
            ..cubicTo(15, -75, 53, -34, 43, -1)
            ..close(),
          fill(townCream),
        );
        c.drawCircle(const Offset(0, -42), 10, fill(red));
      case 'pillow' || 'blanket' || 'sponge':
        round(
          c,
          const Rect.fromLTWH(-44, -30, 88, 64),
          kind == 'sponge' ? const Color(0xFFF3D580) : townPurple,
          17,
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-36, -22, 72, 48),
            const Radius.circular(13),
          ),
          stroke(townCream.withValues(alpha: .65), 2),
        );
        for (var i = 0; i < 5; i++) {
          star(c, Offset(-25 + i * 12.0, math.sin(i * 2) * 14), 4, townCream);
        }
      case 'pipe':
        final p = Path()
          ..moveTo(-37, 30)
          ..lineTo(-7, 30)
          ..quadraticBezierTo(16, 30, 16, 7)
          ..lineTo(16, -37);
        c.drawPath(p, stroke(const Color(0xFF78BFC7), 30));
        c.drawPath(p, stroke(const Color(0xFFA8DDDC), 14));
        round(
          c,
          const Rect.fromLTWH(-52, 9, 16, 42),
          const Color(0xFF629FA8),
          4,
        );
        round(
          c,
          const Rect.fromLTWH(-5, -49, 42, 15),
          const Color(0xFF629FA8),
          4,
        );
      case 'duck':
        oval(
          c,
          const Rect.fromLTWH(-40, -3, 76, 47),
          const Color(0xFFF4CE69),
          shaded: true,
        );
        oval(c, const Rect.fromLTWH(0, -41, 49, 49), const Color(0xFFF4CE69));
        oval(c, const Rect.fromLTWH(36, -19, 25, 13), townCoral);
        c.drawCircle(const Offset(30, -22), 4, fill(townInk));
        oval(c, const Rect.fromLTWH(-23, 7, 29, 19), const Color(0xFFE8B44E));
      case 'cat' || 'frog':
        if (kind == 'cat') {
          c.drawPath(
            Path()
              ..moveTo(-36, -12)
              ..lineTo(-42, -51)
              ..lineTo(-10, -31)
              ..lineTo(12, -31)
              ..lineTo(42, -51)
              ..lineTo(36, -12)
              ..close(),
            fill(townCoral),
          );
        } else {
          c.drawCircle(const Offset(-24, -30), 19, fill(townGreen));
          c.drawCircle(const Offset(24, -30), 19, fill(townGreen));
        }
        oval(
          c,
          const Rect.fromLTWH(-44, -32, 88, 77),
          kind == 'cat' ? townCoral : townGreen,
          shaded: true,
        );
        face(c, s: .65);
      case 'shell':
        c.drawCircle(Offset.zero, 43, fill(townPurple));
        final p = Path();
        for (var i = 0; i < 65; i++) {
          final a = i * .18;
          final r = i * .52;
          final q = Offset(math.cos(a) * r, math.sin(a) * r);
          if (i == 0) {
            p.moveTo(q.dx, q.dy);
          } else {
            p.lineTo(q.dx, q.dy);
          }
        }
        c.drawPath(p, stroke(townCream, 4));
      case 'eyes':
        for (final side in [-1.0, 1.0]) {
          oval(
            c,
            Rect.fromCenter(
              center: Offset(side * 23, 0),
              width: 31,
              height: 39,
            ),
            townCream,
          );
          oval(
            c,
            Rect.fromCenter(
              center: Offset(side * 23, 0),
              width: 13,
              height: 20,
            ),
            townInk,
          );
          c.drawCircle(Offset(side * 23 + 3, -5), 3, fill(Colors.white));
        }
      case 'smile':
        c.drawPath(
          Path()
            ..moveTo(-35, -14)
            ..quadraticBezierTo(0, 55, 35, -14)
            ..quadraticBezierTo(0, 0, -35, -14)
            ..close(),
          fill(townInk),
        );
        oval(c, const Rect.fromLTWH(-15, 10, 30, 12), townCoral);
        round(c, const Rect.fromLTWH(-10, -7, 20, 8), townCream, 3);
      case 'cloud':
        cloud(c, Offset.zero, 50, eyes: true);
      case 'noodle' || 'fork':
        for (var i = 0; i < 3; i++) {
          c.drawPath(
            Path()
              ..moveTo(-23 + i * 22, -42)
              ..cubicTo(-50 + i * 22, -10, 15 + i * 22, 13, -20 + i * 22, 45),
            stroke(const Color(0xFFECC267), 7),
          );
        }
      default:
        star(c, Offset.zero, 42, color ?? townPurple);
    }
    c.restore();
  }

  static void subject(
    Canvas c,
    String subject,
    Offset at,
    double r, {
    double t = 0,
    double joy = 0,
    double progress = 0,
    bool finished = false,
    Offset gaze = Offset.zero,
    int variant = 0,
  }) {
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(r / 100);
    switch (subject) {
      case 'monster' || 'party':
        monster(
          c,
          Offset.zero,
          100,
          t: t,
          joy: joy,
          squish: joy,
          party: subject == 'party',
          gaze: gaze,
        );
      case 'sun':
        for (var i = 0; i < 12; i++) {
          final a = i * math.pi / 6 + t * .05;
          final p = Offset(math.cos(a), math.sin(a));
          line(c, p * 91, p * (111 + joy * 12), const Color(0xFFF1CB70), 13);
        }
        oval(
          c,
          const Rect.fromLTWH(-83, -83, 166, 166),
          const Color(0xFFF6D475),
          shaded: true,
        );
        face(c, s: 1.22, joy: joy, asleep: progress < .16, gaze: gaze);
      case 'cloud':
        cloud(
          c,
          Offset.zero,
          100,
          eyes: true,
          joy: joy,
          asleep: progress < .12,
        );
      case 'house':
        for (final side in [-1.0, 1.0]) {
          line(
            c,
            Offset(side * 43, 65),
            Offset(side * 43 + math.sin(t * 4 + side) * 10, 102),
            townInk,
            9,
          );
          object(c, 'shoe', Offset(side * 43, 104), 26);
        }
        round(
          c,
          const Rect.fromLTWH(-73, -47, 146, 125),
          const Color(0xFFECA58E),
          19,
        );
        final roof = Path()
          ..moveTo(-94, -41)
          ..quadraticBezierTo(-4, -141, 9, -119)
          ..lineTo(96, -41)
          ..close();
        c.drawPath(roof, fill(const Color(0xFFB77D68)));
        round(
          c,
          const Rect.fromLTWH(38, -113, 22, 42),
          const Color(0xFFB77D68),
          5,
        );
        face(c, s: 1.1, y: 4, joy: joy, gaze: gaze);
      case 'bowl':
        for (var i = 0; i < 5; i++) {
          final x = -40 + i * 20.0;
          c.drawPath(
            Path()
              ..moveTo(x, 9)
              ..cubicTo(
                x - 30,
                -25 - progress * 90,
                x + 30,
                -25 - progress * 130,
                x,
                -78 - progress * 75,
              ),
            stroke(const Color(0xFFECC875), 8),
          );
        }
        c.drawPath(
          Path()
            ..moveTo(-85, 0)
            ..quadraticBezierTo(-67, 101, 0, 93)
            ..quadraticBezierTo(73, 99, 85, 0)
            ..close(),
          fill(townCoral),
        );
        oval(
          c,
          const Rect.fromLTWH(-85, -14, 170, 31),
          const Color(0xFFFFE4AE),
        );
        face(c, y: 40, s: .8, joy: joy);
      case 'pudding':
        oval(c, const Rect.fromLTWH(-103, 75, 206, 27), townCream);
        final body = Path()
          ..moveTo(-54, -60)
          ..quadraticBezierTo(0, -88, 54, -60)
          ..lineTo(86, 63)
          ..quadraticBezierTo(0, 106, -86, 63)
          ..close();
        c.drawPath(
          body,
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFFF4BC9D), Color(0xFFE69F89)],
            ).createShader(const Rect.fromLTWH(-86, -60, 172, 150)),
        );
        oval(
          c,
          const Rect.fromLTWH(-57, -75, 114, 34),
          const Color(0xFFC98C65),
        );
        face(c, y: 14, joy: joy, s: 1.1);
      case 'toaster':
        object(c, 'toast', Offset(0, -45 - joy * 85), 66);
        round(
          c,
          const Rect.fromLTWH(-93, -29, 186, 116),
          const Color(0xFF91BAB6),
          24,
        );
        round(c, const Rect.fromLTWH(-69, -21, 138, 11), townInk, 6);
        face(c, y: 27, joy: joy);
        c.drawCircle(const Offset(76, 29), 9, fill(townCream));
      case 'car' || 'bus' || 'train' || 'elephant':
        for (final side in [-1.0, 1.0]) {
          c.drawCircle(Offset(side * 61, 66), 26, fill(townInk));
          c.drawCircle(Offset(side * 61, 66), 13, fill(townCream));
          line(
            c,
            Offset(side * 61, 66),
            Offset(side * 61 + math.cos(t * 4) * 11, 66 + math.sin(t * 4) * 11),
            townCoral,
            3,
          );
        }
        round(
          c,
          Rect.fromLTWH(
            -94,
            subject == 'bus' ? -75 : -22,
            188,
            88 + (subject == 'bus' ? 53 : 0),
          ),
          subject == 'train' ? townCoral : const Color(0xFF94BEC8),
          21,
        );
        if (subject == 'car') {
          round(
            c,
            const Rect.fromLTWH(-49, -70, 106, 65),
            const Color(0xFF94BEC8),
            28,
          );
          round(c, const Rect.fromLTWH(-35, -58, 77, 37), townCream, 16);
        }
        if (subject == 'bus') {
          for (var i = 0; i < 3; i++) {
            round(c, Rect.fromLTWH(-76 + i * 54, -57, 41, 40), townCream, 9);
          }
        }
        if (subject == 'train') {
          round(c, const Rect.fromLTWH(-79, -78, 75, 75), townCoral, 12);
          round(c, const Rect.fromLTWH(-65, -65, 47, 35), townCream, 7);
          round(c, const Rect.fromLTWH(49, -67, 23, 48), townInk, 6);
        }
        face(c, y: 24, s: .85, joy: joy);
        if (subject == 'elephant') {
          oval(c, const Rect.fromLTWH(-80, -92, 70, 70), townPurple);
          oval(c, const Rect.fromLTWH(9, -92, 70, 70), townPurple);
          oval(c, const Rect.fromLTWH(-54, -91, 108, 95), townPurple);
          face(c, y: -49, s: .6);
          c.drawPath(
            Path()
              ..moveTo(0, -44)
              ..cubicTo(0, 12, 71, -11, 74, -39),
            stroke(townPurple, 22),
          );
        }
      case 'duck':
        object(c, 'duck', Offset.zero, 115);
      case 'pipe':
        object(c, 'pipe', Offset.zero, 110);
        face(c, x: 19, y: 6, s: .7, joy: joy);
      case 'flower':
        c.save();
        c.scale(.55 + progress * .5);
        object(c, 'flower', Offset.zero, 120);
        c.restore();
      case 'snail':
        round(c, const Rect.fromLTWH(-86, 33, 180, 51), townGreen, 24);
        object(c, 'shell', const Offset(-18, 1), 82);
        oval(c, const Rect.fromLTWH(42, -21, 58, 93), townGreen);
        face(c, x: 69, y: 4, s: .49, joy: joy);
        line(c, const Offset(57, -9), const Offset(47, -40), townGreen, 8);
        line(c, const Offset(83, -9), const Offset(98, -40), townGreen, 8);
      case 'caterpillar':
        for (var i = 0; i < 4; i++) {
          final x = -88 + i * 48.0, y = math.sin(t * 3 + i) * 8 + 16;
          oval(
            c,
            Rect.fromCenter(center: Offset(x, y), width: 65, height: 73),
            [
              townGreen,
              const Color(0xFFB8CB87),
              const Color(0xFFD4D58F),
              townGreen,
            ][i],
          );
          object(c, 'sock', Offset(x, y + 46), 21, color: townCoral);
        }
        face(c, x: 62, y: 2, s: .7, joy: joy);
      case 'mushroom':
        object(c, 'mushroom', Offset.zero, 110);
      case 'tree':
        round(
          c,
          const Rect.fromLTWH(-25, -29, 50, 127),
          const Color(0xFFBE9777),
          13,
        );
        line(
          c,
          const Offset(-15, 23),
          const Offset(-69, -20),
          const Color(0xFFBE9777),
          20,
        );
        line(
          c,
          const Offset(13, 14),
          const Offset(66, -30),
          const Color(0xFFBE9777),
          18,
        );
        for (final p in [
          const Offset(-58, -35),
          const Offset(50, -50),
          const Offset(0, -92),
          const Offset(0, -22),
        ]) {
          oval(
            c,
            Rect.fromCircle(center: p, radius: 57),
            townGreen,
            shaded: true,
          );
        }
        face(c, y: -49, joy: joy, s: 1.05, asleep: progress < .1);
      case 'moon':
        c.drawPath(
          Path()
            ..moveTo(41, -94)
            ..cubicTo(-132, -122, -139, 123, 51, 85)
            ..cubicTo(-52, 63, -73, -24, 41, -94)
            ..close(),
          fill(const Color(0xFFF1D89A)),
        );
        face(c, x: -40, y: 9, s: .75, asleep: finished, joy: joy);
      case 'star':
        object(c, 'star', Offset.zero, 123);
        if (finished) {
          oval(
            c,
            const Rect.fromLTWH(-43, -24, 86, 61),
            const Color(0xFFF4CF6A),
          );
          face(c, s: .8, asleep: true);
        }
      case 'balloon':
        c.drawPath(
          Path()
            ..moveTo(0, 54)
            ..cubicTo(48, 96, -26, 109, 9, 152),
          stroke(townInk.withValues(alpha: .5), 2),
        );
        oval(
          c,
          const Rect.fromLTWH(-71, -98, 142, 169),
          townCoral,
          shaded: true,
        );
        face(c, y: -10, s: 1.2, joy: joy);
        oval(
          c,
          const Rect.fromLTWH(-48, -65, 17, 40),
          Colors.white.withValues(alpha: .4),
        );
      case 'carousel':
        round(c, const Rect.fromLTWH(-109, 70, 218, 23), townCoral, 11);
        line(
          c,
          const Offset(0, -71),
          const Offset(0, 73),
          const Color(0xFFD4B466),
          9,
        );
        for (var i = 0; i < 3; i++) {
          final a = t * .7 + i * math.pi * 2 / 3;
          final x = math.sin(a) * 80;
          line(c, Offset(x, -44), Offset(x, 59), const Color(0xFFD4B466), 4);
          object(
            c,
            ['cat', 'duck', 'frog'][i],
            Offset(x, 26 + math.cos(a) * 8),
            34,
          );
        }
        c.drawPath(
          Path()
            ..moveTo(-117, -43)
            ..quadraticBezierTo(-39, -76, 0, -109)
            ..quadraticBezierTo(51, -66, 117, -43)
            ..close(),
          fill(townCoral),
        );
        star(c, const Offset(0, -110), 16, const Color(0xFFF4D06E));
      default:
        monster(c, Offset.zero, 100, t: t, joy: joy);
    }
    c.restore();
  }

  static void landscape(
    Canvas c,
    Size size,
    int district, {
    double t = 0,
    bool room = false,
  }) {
    final area = townDistricts[district];
    c.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [area.sky, townCream],
        ).createShader(Offset.zero & size),
    );
    final w = size.width, h = size.height;
    if (district == 5) {
      for (var i = 0; i < 24; i++) {
        star(
          c,
          Offset((i * .173 % 1) * w, (i * .327 % 1) * h * .7),
          2 + (i % 3) * 1.8,
          townPurple.withValues(alpha: .3),
        );
      }
    }
    cloud(
      c,
      Offset(w * .13 + math.sin(t * .12) * 7, h * .18),
      w * .07,
      color: Colors.white.withValues(alpha: .65),
    );
    cloud(
      c,
      Offset(w * .87 + math.sin(t * .12 + 2) * 7, h * .13),
      w * .09,
      color: Colors.white.withValues(alpha: .60),
    );
    final hill = Path()
      ..moveTo(0, h * .67)
      ..cubicTo(w * .27, h * .47, w * .57, h * .84, w, h * .60)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    c.drawPath(hill, fill(Color.lerp(area.color, townCream, .72)!));
    final hill2 = Path()
      ..moveTo(0, h * .83)
      ..cubicTo(w * .23, h * .72, w * .67, h * .63, w, h * .82)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    c.drawPath(hill2, fill(Color.lerp(area.color, townCream, .55)!));
    // Fine flecks give otherwise flat vector regions the feel of printed paper.
    for (var i = 0; i < 95; i++) {
      final p = Offset((i * .61803398875 % 1) * w, (i * .41421356237 % 1) * h);
      c.drawCircle(
        p,
        i % 3 == 0 ? 1.1 : .65,
        fill(townInk.withValues(alpha: .045)),
      );
    }
    if (district == 1 || district == 2) {
      final tiles = stroke(area.color.withValues(alpha: .13), 1);
      for (double x = 0; x < w; x += 60) {
        c.drawLine(Offset(x, h * .73), Offset(x, h), tiles);
      }
      for (double y = h * .73; y < h; y += 45) {
        c.drawLine(Offset(0, y), Offset(w, y), tiles);
      }
    }
    for (var i = 0; i < 5; i++) {
      final x = i.isEven ? w * (.025 + i * .024) : w * (.94 + i * .005);
      final y = h * (.66 + i * .047);
      object(
        c,
        district == 2
            ? 'bubble'
            : district == 5
            ? 'star'
            : 'flower',
        Offset(x, y),
        14 + i * 2.0,
        color: area.color,
      );
    }
  }
}

class TownScenePainter extends CustomPainter {
  TownScenePainter(this.model) : super(repaint: model);
  final TownModel model;
  @override
  void paint(Canvas canvas, Size size) {
    final m = model, l = TownLayout(size), level = m.level;
    final t = m.reduceMotion ? 0.0 : m.time;
    TownArt.landscape(canvas, size, level.district, t: t);
    final r = l.radius;
    // A pale stage gives the character room to breathe and separates toys.
    TownArt.oval(
      canvas,
      Rect.fromCenter(
        center: l.actor + Offset(0, r * .83),
        width: r * 3.7,
        height: r * .52,
      ),
      townCream.withValues(alpha: .65),
    );
    final hop = m.reduceMotion ? 0.0 : math.sin(m.reaction * math.pi) * r * .18;
    var at = l.actor + Offset(0, -hop + math.sin(t * 2) * r * .018);
    if (m.finished && !m.reduceMotion) {
      if (level.play == TownPlay.inflate || level.subject == 'balloon') {
        at += Offset(
          math.sin(m.finale) * r * .2,
          -math.min(m.finale, 3) * r * .13,
        );
      }
      if ((level.id == 0 || level.id == 2) && m.finale < 1.5) {
        at += Offset(
          math.sin(m.finale * 24) * r * .065,
          -math.sin(m.finale * math.pi / 1.5) * r * .17,
        );
      }
      if (level.play == TownPlay.deliver &&
          ['car', 'train', 'house'].contains(level.subject)) {
        at += Offset(math.sin(m.finale * 1.2) * r * .55, 0);
      }
    }
    TownArt.shadow(
      canvas,
      l.actor + Offset(0, r * 1.04),
      r * (1 - hop / r * .4),
    );
    if (level.play == TownPlay.catchToy && !m.finished) {
      TownArt.monster(
        canvas,
        Offset(size.width * .5, size.height * .76),
        r * .50,
        t: t,
        joy: m.reaction,
        color: townPurple,
      );
      for (var i = 0; i < 6; i++) {
        if (m.used.contains(i)) continue;
        final p = l.toy(i, t, reduce: m.reduceMotion);
        TownArt.shadow(canvas, p + Offset(0, l.hitRadius * .9), l.hitRadius);
        TownArt.object(
          canvas,
          level.props[i % 3],
          p,
          l.hitRadius * .98,
          color: i.isEven ? townCoral : townPurple,
          t: t,
        );
      }
    } else {
      if (level.play == TownPlay.inflate) {
        final bubbleRadius = r * (.2 + m.progress * 1.13);
        if (level.id == 14) {
          TownArt.object(canvas, 'bubble', at, bubbleRadius * 1.6);
        }
      }
      canvas.save();
      canvas.translate(at.dx, at.dy);
      if (!m.reduceMotion &&
          m.finished &&
          (level.id == 0 || level.id == 2) &&
          m.finale < 1.2) {
        final inhale = math.sin(m.finale / 1.2 * math.pi);
        canvas.scale(1 - inhale * .11, 1 + inhale * .11);
      }
      if (!m.reduceMotion) {
        canvas.rotate(
          math.sin(t * 2.8) * (.013 + m.reaction * .045) +
              (m.finished ? math.sin(m.finale * 4) * .055 : 0),
        );
      }
      final gaze = m.gaze == null
          ? Offset.zero
          : (m.gaze! - l.actor) / size.width * 2;
      TownArt.subject(
        canvas,
        level.subject,
        Offset.zero,
        r,
        t: t,
        joy: m.finished ? .8 : m.reaction,
        progress: m.progress,
        finished: m.finished,
        gaze: gaze,
        variant: m.lastVariant,
      );
      if (level.play == TownPlay.feed && m.actionCount > 0) {
        // Each fruit changes the silhouette: an increasingly extravagant hairdo.
        for (var i = 0; i < m.actionCount * 3; i++) {
          final a = -math.pi + (i + 1) * math.pi / (m.actionCount * 3 + 1);
          final p = Offset(
            math.cos(a) * r * .76,
            math.sin(a) * r * .75 - r * .43,
          );
          TownArt.object(canvas, level.props[(i ~/ 3).clamp(0, 2)], p, r * .25);
        }
      }
      if (level.play == TownPlay.inflate && level.id == 11 && m.progress > 0) {
        for (var i = 0; i < (m.progress * 14).ceil(); i++) {
          final p = Offset((i % 5 - 2) * r * .31, r * .36 + i ~/ 5 * r * .22);
          final pop = m.finished
              ? (m.finale * .9 - i * .15).clamp(0.0, 1.0)
              : 0.0;
          if (pop < 1) {
            TownArt.object(
              canvas,
              'bubble',
              p,
              r * (.24 + .05 * math.sin(t + i)) * (1 - pop),
            );
          }
        }
      }
      if (level.play == TownPlay.scrub) {
        if (m.finished) {
          for (var i = 0; i < 5; i++) {
            TownArt.star(
              canvas,
              Offset(-r * .5 + i * r * .24, r * .43),
              r * .10,
              [
                townCoral,
                townPurple,
                townGreen,
                const Color(0xFFF3CA68),
                const Color(0xFF83C7D0),
              ][i],
            );
          }
        }
        for (var i = 0; i < 6; i++) {
          if (!m.cleaned.contains(i)) {
            final p = l.mark(i) - l.actor;
            TownArt.oval(
              canvas,
              Rect.fromCenter(center: p, width: r * .39, height: r * .31),
              const Color(0xFFAB8C74),
            );
            canvas.drawCircle(
              p + Offset(r * .13, -r * .1),
              r * .09,
              TownArt.fill(const Color(0xFFAB8C74)),
            );
          }
        }
      }
      if (m.usesProps && level.play != TownPlay.feed) {
        for (final i in m.used) {
          final p = switch (level.play) {
            TownPlay.tuck => Offset((i - 1) * r * .58, r * .5),
            TownPlay.grow => Offset((i - 1) * r * .6, r * .6),
            _ => Offset(
              (i - 1) * r * .75,
              level.subject == 'car' ? r * .70 : -r * .78,
            ),
          };
          final actual = switch (level.subject) {
            'balloon' =>
              i == 0
                  ? Offset(0, -r * .20)
                  : i == 1
                  ? Offset(0, r * .18)
                  : Offset(0, -r * 1.04),
            'house' =>
              i < 2
                  ? Offset((i == 0 ? -.46 : .46) * r, r * 1.04)
                  : Offset(0, -r * 1.12),
            'caterpillar' => Offset((i - 1) * r * .53, r * .63),
            _ => p,
          };
          TownArt.object(
            canvas,
            level.props[i],
            actual,
            r * (level.subject == 'balloon' ? .54 : .33),
          );
        }
      }
      canvas.restore();
    }
    if (m.finished) {
      _finale(canvas, l, t);
    }
    // Toys are placed on individual porcelain-like pebbles with clear hit areas.
    if ((m.usesProps || level.play == TownPlay.music) && !m.finished) {
      for (var i = 0; i < 3; i++) {
        final p = l.slot(i);
        final used = m.used.contains(i);
        TownArt.oval(
          canvas,
          Rect.fromCenter(
            center: p + const Offset(0, 5),
            width: l.hitRadius * 2.45,
            height: l.hitRadius * 1.8,
          ),
          level.area.color.withValues(alpha: .25),
        );
        TownArt.oval(
          canvas,
          Rect.fromCenter(
            center: p,
            width: l.hitRadius * 2.45,
            height: l.hitRadius * 1.8,
          ),
          townCream,
        );
        if (m.selected == i) {
          canvas.drawOval(
            Rect.fromCenter(
              center: p,
              width: l.hitRadius * 2.55,
              height: l.hitRadius * 2,
            ),
            TownArt.stroke(level.area.dark, 2),
          );
        }
        if (used) {
          canvas.drawCircle(p, 8, TownArt.fill(level.area.color));
        } else if (m.dragging == null || m.selected != i) {
          TownArt.object(
            canvas,
            level.props[i],
            p,
            l.hitRadius * .95,
            color: i == 1 ? townPurple : null,
            t: t,
          );
        }
      }
    }
    if (!m.finished && m.idle > 4.8) {
      final target = m.usesProps
          ? l.slot(
              List.generate(
                3,
                (i) => i,
              ).firstWhere((i) => !m.used.contains(i), orElse: () => 0),
            )
          : level.play == TownPlay.music
          ? l.slot(0)
          : level.play == TownPlay.scrub
          ? l.mark(
              List.generate(
                6,
                (i) => i,
              ).firstWhere((i) => !m.cleaned.contains(i), orElse: () => 0),
            )
          : level.play == TownPlay.catchToy
          ? l.toy(
              List.generate(
                6,
                (i) => i,
              ).firstWhere((i) => !m.used.contains(i), orElse: () => 0),
              t,
              reduce: m.reduceMotion,
            )
          : l.actor;
      final pulse = m.reduceMotion ? 0.5 : (math.sin(t * 3) + 1) / 2;
      canvas.drawCircle(
        target,
        l.hitRadius * (1.1 + pulse * .35),
        TownArt.stroke(
          level.area.dark.withValues(alpha: .25 + .25 * (1 - pulse)),
          3,
        ),
      );
      if (m.usesProps) {
        final path = Path()
          ..moveTo(target.dx, target.dy - l.hitRadius)
          ..quadraticBezierTo(target.dx, l.actor.dy, l.actor.dx, l.actor.dy);
        canvas.drawPath(
          path,
          TownArt.stroke(level.area.dark.withValues(alpha: .22), 3),
        );
      }
    }
    for (final p in m.particles) {
      canvas.save();
      canvas.translate(p.at.dx, p.at.dy);
      canvas.rotate(p.life * 2);
      final color = p.color.withValues(alpha: p.life.clamp(0, 1));
      if (p.kind == 1) {
        canvas.drawCircle(Offset.zero, p.size * 1.3, TownArt.stroke(color, 2));
      } else if (p.kind == 2) {
        TownArt.star(canvas, Offset.zero, p.size * 1.2, color);
      } else {
        TownArt.round(
          canvas,
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * .6,
          ),
          color,
          3,
        );
      }
      canvas.restore();
    }
    if (m.dragging != null && m.selected != null) {
      TownArt.object(
        canvas,
        level.props[m.selected!],
        m.dragging!,
        l.hitRadius * 1.13,
      );
    }
    if (m.usesProps &&
        m.deliveryStart != null &&
        m.time - m.deliveredAt < .48 &&
        !m.reduceMotion) {
      final u = ((m.time - m.deliveredAt) / .48).clamp(0.0, 1.0);
      final destination = l.actor + Offset(0, r * .15);
      final p =
          Offset.lerp(
            m.deliveryStart,
            destination,
            Curves.easeInOut.transform(u),
          )! -
          Offset(0, math.sin(u * math.pi) * r * .45);
      TownArt.object(
        canvas,
        level.props[m.deliveredItem],
        p,
        l.hitRadius * (1 - u * .8),
      );
    }
  }

  void _finale(Canvas c, TownLayout l, double t) {
    final m = model, r = l.radius, w = l.size.width, h = l.size.height;
    final amount = (m.finale / .8).clamp(0.0, 1.0);
    final a = l.actor;
    // Short authored scene beats, followed by a looping playground pose.
    switch (m.level.id) {
      case 0 || 2:
        for (var i = 0; i < 5; i++) {
          final u = ((m.finale - .6 + i * .16) / 2).clamp(0.0, 1.0);
          if (u > 0 && u < 1) {
            TownArt.cloud(
              c,
              a + Offset((i - 2) * r * u * .9, -r * .4 - u * r * 1.8),
              r * .26 * (1 - u * .25),
              color: townCream.withValues(alpha: 1 - u * .55),
              eyes: true,
            );
          }
        }
      case 3:
        for (var i = 0; i < 6; i++) {
          TownArt.object(
            c,
            'sock',
            Offset(
              w * (.15 + i * .14),
              h * .68 - math.sin(t * 7 + i) * r * .12,
            ),
            r * .22,
            color: i.isEven ? townCoral : townPurple,
          );
        }
      case 6:
        for (final side in [-1.0, 1.0]) {
          final p = Path()
            ..moveTo(a.dx, a.dy + r * .58)
            ..cubicTo(
              a.dx + side * r * .8,
              a.dy - r * .2,
              a.dx + side * r * 1.5,
              a.dy + r * .9,
              a.dx + side * r * .9,
              a.dy + r * .18,
            );
          c.drawPath(p, TownArt.stroke(const Color(0xFFECC267), r * .065));
        }
      case 7:
        for (final side in [-1.0, 1.0]) {
          final p =
              a + Offset(side * r * 1.2, -r * (.6 + .25 * math.sin(t * 3)));
          TownArt.oval(
            c,
            Rect.fromCenter(
              center: p + Offset(side * r * .3, 0),
              width: r * .50,
              height: r * .15,
            ),
            townCream,
          );
          TownArt.object(c, 'toast', p, r * .4);
        }
      case 9 || 22:
        for (var i = 0; i < 3; i++) {
          final p = Offset(
            w * (.2 + i * .30),
            h * .71 + math.sin(t * 3 + i) * 3,
          );
          TownArt.round(
            c,
            Rect.fromCenter(center: p, width: r * .57, height: r * .29),
            m.level.area.color,
            8,
          );
          for (final side in [-1.0, 1.0]) {
            c.drawCircle(
              p + Offset(side * r * .18, r * .18),
              r * .07,
              TownArt.fill(townInk),
            );
          }
          TownArt.object(c, m.level.props[i], p - Offset(0, r * .23), r * .30);
        }
        for (var i = 0; i < 4; i++) {
          TownArt.cloud(
            c,
            a +
                Offset(
                  r * .6 - i * r * .21,
                  -r * .8 - i * r * .2 - math.sin(t) * 6,
                ),
            r * .17,
            color: townCream,
          );
        }
      case 12:
        for (var i = 0; i < 6; i++) {
          final angle = i * math.pi / 3 + t * .35;
          TownArt.object(
            c,
            'duck',
            a +
                Offset(
                  math.cos(angle) * r * 1.2,
                  math.sin(angle) * r * .65 + r * .2,
                ),
            r * .29,
          );
        }
      case 13 || 24:
        for (var i = 0; i < 18; i++) {
          final u = (t * .6 + i / 18) % 1;
          final side = i.isEven ? -1.0 : 1.0;
          final p =
              a +
              Offset(
                side * r * u * 1.6,
                -r * math.sin(u * math.pi) * 1.6 + r * .5,
              );
          TownArt.object(c, 'drop', p, r * .085);
        }
      case 16:
        c.save();
        c.translate(a.dx - r * .18, a.dy);
        c.rotate(m.reduceMotion ? 0 : math.sin(t) * .25);
        TownArt.object(c, 'shell', Offset.zero, r * .81);
        c.restore();
      case 18:
        for (var i = 0; i < 5; i++) {
          TownArt.star(
            c,
            a +
                Offset(
                  math.cos(i * 1.5 + t * .7) * r * 1.4,
                  math.sin(i * 1.5 + t * .7) * r * .9,
                ),
            r * .07,
            [townCoral, townPurple, townGreen][i % 3],
          );
        }
      case 19:
        for (var i = 0; i < 5; i++) {
          final p =
              a +
              Offset(
                math.sin(t * .5 + i) * r * 1.6,
                -r * .9 + math.cos(t * .6 + i) * r * .75,
              );
          final spread = m.reduceMotion
              ? 1.0
              : .4 + math.sin(t * 8 + i).abs() * .6;
          TownArt.oval(
            c,
            Rect.fromCenter(
              center: p - Offset(r * .11, 0),
              width: r * .24 * spread,
              height: r * .26,
            ),
            townCoral,
          );
          TownArt.oval(
            c,
            Rect.fromCenter(
              center: p + Offset(r * .11, 0),
              width: r * .24 * spread,
              height: r * .26,
            ),
            townPurple,
          );
          TownArt.line(
            c,
            p - Offset(0, r * .07),
            p + Offset(0, r * .1),
            townInk,
            2,
          );
        }
      case 20:
        for (var i = 0; i < 8; i++) {
          TownArt.object(
            c,
            'drop',
            Offset(
              w * (.13 + i * .10),
              h * .66 + math.sin(t * 2 + i) * r * .08,
            ),
            r * .09,
            color: townCoral,
          );
        }
      case 25:
        TownArt.object(c, 'hat', a - Offset(0, r * 1.12), r * .45);
      case 26:
        final jump = m.reduceMotion ? 0.0 : math.sin(t * 3).abs();
        c.save();
        c.translate(a.dx, a.dy - r * (.65 + jump * .8));
        c.rotate(m.reduceMotion ? 0 : t * .7);
        TownArt.monster(c, Offset.zero, r * .48, joy: .8, t: t);
        c.restore();
      default:
        break;
    }
    if ([0, 2, 13, 20, 24].contains(m.level.id)) {
      c.save();
      c.clipRect(Rect.fromLTWH(0, 0, w, h * .76));
      for (var i = 0; i < 4; i++) {
        final rect = Rect.fromCenter(
          center: l.actor + Offset(0, r * .8),
          width: r * (3.4 - i * .23),
          height: r * (3.3 - i * .23),
        );
        c.drawArc(
          rect,
          math.pi,
          math.pi * amount,
          false,
          TownArt.stroke(
            [
              townCoral,
              const Color(0xFFF1CC6C),
              townGreen,
              townPurple,
            ][i].withValues(alpha: .7),
            r * .10,
          ),
        );
      }
      c.restore();
    }
    // A different physical after-effect for each district: dancing flowers,
    // flying toast, bubbles, butterflies, vehicle steam, sleepy stars.
    for (var i = 0; i < 5; i++) {
      final x = w * (.12 + i * .19);
      final y = h * .72 - (m.reduceMotion ? 0 : math.sin(t * 2 + i) * r * .09);
      final kind = switch (m.level.district) {
        0 => 'flower',
        1 => m.level.id == 7 ? 'toast' : 'cake',
        2 => 'bubble',
        3 => 'leaf',
        4 => 'cloud',
        _ => 'star',
      };
      TownArt.object(
        c,
        kind,
        Offset(x, y),
        r * .24 * amount,
        color: i.isEven ? townCoral : townPurple,
      );
    }
    if (m.level.play == TownPlay.music || m.level.id == 29) {
      for (final side in [-1.0, 1.0]) {
        TownArt.monster(
          c,
          l.actor +
              Offset(
                side * r * 1.8,
                r * .25 - math.sin(t * 4 + side) * r * .13,
              ),
          r * .51,
          color: side < 0 ? townCoral : townPurple,
          t: t,
          joy: .8,
          party: true,
        );
      }
    }
    if (m.level.play == TownPlay.tuck) {
      for (var i = 0; i < 3; i++) {
        TownArt.star(
          c,
          l.actor +
              Offset(r * (.8 + i * .24), -r * (.6 + i * .23) - math.sin(t) * 5),
          r * (.08 + i * .025),
          townPurple.withValues(alpha: .7),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant TownScenePainter oldDelegate) =>
      oldDelegate.model != model;
}

class TownPostcardPainter extends CustomPainter {
  TownPostcardPainter({
    required this.district,
    this.time = 0,
    this.hero = false,
    this.stamps = 0,
  });
  final int district, stamps;
  final double time;
  final bool hero;
  @override
  void paint(Canvas c, Size size) {
    TownArt.landscape(c, size, district, t: time);
    final w = size.width, h = size.height;
    if (hero) {
      final path = Path()
        ..moveTo(w * .37, h * 1.1)
        ..cubicTo(w * .78, h * .64, w * .03, h * .63, w * .43, h * .30);
      c.drawPath(path, TownArt.stroke(const Color(0xFFF9EDD2), h * .12));
      TownArt.subject(c, 'house', Offset(w * .20, h * .37), h * .17, t: time);
      TownArt.subject(c, 'tree', Offset(w * .83, h * .38), h * .16, t: time);
      TownArt.subject(c, 'house', Offset(w * .66, h * .28), h * .11, t: time);
      TownArt.shadow(c, Offset(w * .49, h * .83), h * .21);
      TownArt.monster(c, Offset(w * .49, h * .64), h * .22, t: time, joy: .25);
      TownArt.monster(
        c,
        Offset(w * .27, h * .71),
        h * .13,
        color: townCoral,
        t: time + 2,
        joy: .8,
        party: true,
      );
      TownArt.monster(
        c,
        Offset(w * .72, h * .72),
        h * .14,
        color: townPurple,
        t: time + 1,
        joy: .3,
      );
      TownArt.subject(
        c,
        'sun',
        Offset(w * .86, h * .16),
        h * .06,
        progress: 1,
        joy: .2,
        t: time,
      );
      for (var i = 0; i < math.min(stamps, 6); i++) {
        TownArt.object(
          c,
          'flower',
          Offset(w * (.12 + i * .15), h * .92),
          h * .028,
        );
      }
      for (var i = 0; i < 3; i++) {
        TownArt.object(
          c,
          'bubble',
          Offset(
            w * (.35 + i * .16),
            h * (.2 + math.sin(time * .6 + i) * .055),
          ),
          h * .035,
        );
      }
    } else {
      final subject = [
        'sun',
        'bowl',
        'duck',
        'flower',
        'train',
        'moon',
      ][district];
      TownArt.subject(
        c,
        subject,
        Offset(w * .46, h * .48),
        h * .28,
        t: time,
        progress: 1,
        joy: .3,
      );
      TownArt.monster(
        c,
        Offset(w * .77, h * .73),
        h * .135,
        color: [
          townGreen,
          townCoral,
          townPurple,
          townGreen,
          townCoral,
          townPurple,
        ][district],
        t: time,
        joy: .35,
      );
      TownArt.object(
        c,
        ['flower', 'apple', 'bubble', 'mushroom', 'star', 'star'][district],
        Offset(w * .15, h * .76),
        h * .11,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TownPostcardPainter old) =>
      old.district != district || old.time != time || old.stamps != stamps;
}
