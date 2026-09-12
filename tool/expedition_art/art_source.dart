// Original layered storybook illustration. Coordinates are editable source art,
// baked once to transparent PNGs; no image service or third-party artwork.
import 'dart:math' as math;
import 'dart:ui';

class ExpeditionArt {
  ExpeditionArt(this.c);
  final Canvas c;
  static const ink = Color(0xFF385851);
  void path(Path p, Color fill, {Color? stroke, double width = 2}) {
    c.drawPath(p, Paint()..color = fill);
    if (stroke != null) {
      c.drawPath(
        p,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void oval(double x, double y, double rx, double ry, Color color) =>
      c.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: rx * 2, height: ry * 2),
        Paint()..color = color,
      );
  void stroke(Path p, Color color, double width) => c.drawPath(
    p,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );
  void line(
    double x,
    double y,
    double x2,
    double y2,
    Color color,
    double width,
  ) => stroke(
    Path()
      ..moveTo(x, y)
      ..lineTo(x2, y2),
    color,
    width,
  );
  void rr(double x, double y, double w, double h, Color color, double r) =>
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)),
        Paint()..color = color,
      );
  void gradient(Path p, List<Color> colors, Rect rect) => c.drawPath(
    p,
    Paint()
      ..shader = Gradient.linear(rect.topLeft, rect.bottomRight, colors, [
        for (var i = 0; i < colors.length; i++) i / (colors.length - 1),
      ]),
  );
  void grain(
    Path clip,
    Rect bounds,
    int seed, {
    int count = 1000,
    double alpha = .045,
  }) {
    final rng = math.Random(seed);
    c.save();
    c.clipPath(clip);
    for (var i = 0; i < count; i++) {
      final x = bounds.left + rng.nextDouble() * bounds.width,
          y = bounds.top + rng.nextDouble() * bounds.height;
      oval(
        x,
        y,
        .4 + rng.nextDouble() * 1.6,
        .3 + rng.nextDouble() * .7,
        (i % 3 == 0 ? const Color(0xFFFFFFFF) : const Color(0xFF475B45))
            .withValues(alpha: alpha),
      );
    }
    c.restore();
  }

  void leaf(double x, double y, double scale, double angle, Color color) {
    c.save();
    c.translate(x, y);
    c.rotate(angle);
    c.scale(scale);
    final p = Path()
      ..moveTo(0, 0)
      ..cubicTo(-24, -15, -26, -48, 0, -70)
      ..cubicTo(25, -48, 23, -15, 0, 0)
      ..close();
    path(p, color);
    stroke(
      Path()
        ..moveTo(0, -4)
        ..quadraticBezierTo(4, -37, 0, -61),
      const Color(0x66F5F1BC),
      1.8,
    );
    for (var i = 0; i < 3; i++) {
      line(1, -17 - i * 12, -10, -25 - i * 11, const Color(0x45F5F1BC), 1.2);
    }
    c.restore();
  }

  void car() {
    // Rear bed, cab and nose face right. Wheel sockets centered at (65,150)/(224,150).
    final chassis = Path()
      ..moveTo(25, 110)
      ..lineTo(275, 110)
      ..quadraticBezierTo(294, 116, 286, 139)
      ..lineTo(22, 139)
      ..close();
    path(chassis, const Color(0xFF657B68), stroke: ink, width: 3);
    rr(19, 125, 275, 16, const Color(0xFF405954), 6);
    rr(26, 77, 117, 52, const Color(0xFFC79050), 10);
    final bed = Path()
      ..moveTo(26, 79)
      ..lineTo(145, 79)
      ..lineTo(141, 125)
      ..lineTo(30, 125)
      ..close();
    gradient(bed, [
      const Color(0xFFF2D99C),
      const Color(0xFFCBA469),
    ], const Rect.fromLTWH(20, 75, 135, 60));
    line(28, 88, 142, 88, const Color(0xFFFFEBC0), 4);
    line(31, 121, 141, 121, const Color(0xFFAB865B), 3);
    for (var i = 0; i < 5; i++) {
      line(43 + i * 21, 89, 43 + i * 21, 116, const Color(0xFFDBB57C), 2);
      oval(43 + i * 21, 94, 1.7, 1.7, const Color(0xFF967D52));
    }
    final cabin = Path()
      ..moveTo(143, 125)
      ..lineTo(143, 41)
      ..quadraticBezierTo(143, 23, 162, 23)
      ..lineTo(209, 23)
      ..quadraticBezierTo(223, 25, 229, 40)
      ..lineTo(247, 81)
      ..lineTo(271, 88)
      ..quadraticBezierTo(281, 93, 281, 112)
      ..lineTo(277, 126)
      ..close();
    gradient(cabin, [
      const Color(0xFFFFE9AB),
      const Color(0xFFE8BC62),
      const Color(0xFFD59C4B),
    ], const Rect.fromLTWH(140, 20, 145, 120));
    stroke(cabin, const Color(0xFFA9824B), 2);
    grain(cabin, const Rect.fromLTWH(140, 20, 145, 120), 11, count: 850);
    rr(137, 20, 91, 12, const Color(0xFF597C69), 6);
    rr(153, 12, 57, 9, const Color(0xFF7E9780), 4);
    final glass = Path()
      ..moveTo(157, 40)
      ..lineTo(211, 40)
      ..lineTo(228, 76)
      ..lineTo(157, 76)
      ..close();
    gradient(glass, [
      const Color(0xFFDCF1DD),
      const Color(0xFF8CB8AF),
    ], const Rect.fromLTWH(150, 40, 80, 40));
    stroke(glass, const Color(0xFF729489), 3);
    stroke(
      Path()
        ..moveTo(162, 44)
        ..lineTo(176, 44)
        ..lineTo(164, 66),
      const Color(0xB8F7FFEE),
      3,
    );
    rr(149, 82, 69, 40, const Color(0xFFF0CA79), 8);
    line(156, 85, 204, 85, const Color(0xFFFFE0A0), 2);
    rr(199, 87, 13, 4, const Color(0xFF8D784A), 2);
    oval(178, 104, 11, 11, const Color(0xFFD59D53));
    leaf(178, 111, .22, .4, const Color(0xFFFFE8AD));
    rr(236, 86, 45, 11, const Color(0xFFF7D48A), 4);
    rr(269, 100, 17, 12, const Color(0xFFFFF5CC), 5);
    rr(277, 118, 15, 14, const Color(0xFF677F6C), 4);
    rr(18, 115, 9, 10, const Color(0xFFD28567), 3);
    rr(255, 109, 10, 4, const Color(0xFFAD8249), 2);
    oval(65, 144, 34, 28, const Color(0xFF455D52));
    oval(224, 144, 34, 28, const Color(0xFF455D52));
    // Passenger, drawn behind the window frame but above tinted glass.
    oval(184, 67, 15, 12, const Color(0xFF9EC9A2));
    oval(182, 52, 15, 13, const Color(0xFFAAD5AD));
    oval(170, 47, 4, 5, const Color(0xFFAAD5AD));
    oval(194, 47, 4, 5, const Color(0xFFAAD5AD));
    oval(177, 53, 1.5, 2, ink);
    oval(187, 53, 1.5, 2, ink);
    stroke(
      Path()
        ..moveTo(180, 59)
        ..quadraticBezierTo(183, 62, 187, 58),
      ink,
      1.4,
    );
    rr(170, 36, 28, 5, const Color(0xFFC18E58), 2);
    rr(176, 28, 18, 11, const Color(0xFFE9C18A), 4);
    line(177, 37, 193, 37, const Color(0xFF88774B), 2);
  }

  void wheel() {
    oval(50, 50, 45, 45, const Color(0xFF405B56));
    oval(48, 47, 37, 37, const Color(0xFF506D64));
    for (var i = 0; i < 14; i++) {
      c.save();
      c.translate(50, 50);
      c.rotate(i * math.pi / 7);
      line(-5, -39, 5, -39, const Color(0xFF263F3E), 3);
      c.restore();
    }
    oval(50, 50, 25, 25, const Color(0xFFD4BE89));
    oval(49, 48, 19, 19, const Color(0xFFF5E2B0));
    oval(50, 50, 8, 8, const Color(0xFF8E9271));
    oval(48, 48, 3, 3, const Color(0xFFD9DDAC));
    for (var i = 0; i < 5; i++) {
      final a = i * math.pi * 2 / 5;
      oval(
        50 + math.cos(a) * 14,
        50 + math.sin(a) * 14,
        2.6,
        2.6,
        const Color(0xFF9C9D78),
      );
    }
  }

  void log() {
    final body = Path()
      ..moveTo(23, 23)
      ..cubicTo(78, 13, 153, 23, 220, 17)
      ..lineTo(224, 58)
      ..cubicTo(168, 64, 76, 60, 23, 65)
      ..close();
    gradient(body, [
      const Color(0xFFCC9C64),
      const Color(0xFF9E754B),
    ], const Rect.fromLTWH(20, 20, 210, 45));
    stroke(
      Path()
        ..moveTo(30, 26)
        ..cubicTo(91, 20, 154, 32, 211, 23),
      const Color(0xFFE7BD82),
      4,
    );
    for (var i = 0; i < 6; i++) {
      final p = Path()
        ..moveTo(35, 30 + i * 5)
        ..cubicTo(80, 24 + i * 6, 120, 42 + i * 3, 205, 27 + i * 5);
      stroke(
        p,
        i.isEven ? const Color(0xFF997448) : const Color(0xFFB98D59),
        1.4,
      );
    }
    oval(23, 44, 20, 24, const Color(0xFFDFC18A));
    oval(23, 44, 14, 18, const Color(0xFFA98555));
    oval(23, 44, 11.7, 15.6, const Color(0xFFE6CA98));
    oval(23, 44, 7, 9, const Color(0xFFB59160));
    oval(23, 44, 4.8, 6.5, const Color(0xFFE7CDA0));
    oval(222, 38, 12, 20, const Color(0xFFD8B780));
    oval(222, 38, 7, 13, const Color(0xFFB18855));
    oval(222, 38, 4.5, 9, const Color(0xFFE9CB98));
    path(
      Path()
        ..moveTo(154, 22)
        ..lineTo(168, 8)
        ..lineTo(180, 14)
        ..lineTo(174, 25)
        ..close(),
      const Color(0xFFAB7C4A),
    );
    leaf(174, 14, .27, .9, const Color(0xFF739660));
    grain(
      body,
      const Rect.fromLTWH(22, 18, 205, 46),
      12,
      count: 550,
      alpha: .1,
    );
  }

  void dinoBody() {
    final p = Path()
      ..moveTo(32, 118)
      ..cubicTo(8, 110, 8, 95, 32, 79)
      ..cubicTo(47, 57, 70, 35, 94, 40)
      ..cubicTo(122, 36, 157, 48, 165, 79)
      ..cubicTo(175, 111, 143, 141, 107, 147)
      ..cubicTo(67, 153, 49, 140, 32, 118)
      ..close();
    gradient(p, [
      const Color(0xFFB8DCAF),
      const Color(0xFF78B49B),
      const Color(0xFF559384),
    ], const Rect.fromLTWH(25, 40, 140, 110));
    stroke(p, const Color(0xFF588F7C), 1.8);
    grain(p, const Rect.fromLTWH(20, 40, 150, 110), 42, count: 650);
    oval(126, 112, 28, 28, const Color(0xFFBED7AE));
    for (var i = 0; i < 5; i++) {
      oval(
        45 + i * 15,
        80 - math.sin(i * .8) * 12,
        4 + i % 2,
        3.5,
        const Color(0xFF77A78C),
      );
    }
    for (var i = 0; i < 4; i++) {
      final x = 45.0 + i * 19, y = 58.0 - math.sin(i * .7) * 15;
      path(
        Path()
          ..moveTo(x, y + 7)
          ..quadraticBezierTo(x + 2, y - 13, x + 13, y - 6)
          ..lineTo(x + 16, y + 8)
          ..close(),
        const Color(0xFFC5D3A0),
      );
    }
  }

  void dinoHead() {
    final p = Path()
      ..moveTo(22, 91)
      ..cubicTo(4, 60, 22, 21, 66, 18)
      ..cubicTo(106, 11, 126, 35, 123, 58)
      ..cubicTo(154, 56, 167, 69, 158, 89)
      ..cubicTo(145, 112, 82, 121, 46, 110)
      ..close();
    gradient(p, [
      const Color(0xFFC5E2B8),
      const Color(0xFF8AC4A4),
      const Color(0xFF6BAB97),
    ], const Rect.fromLTWH(20, 15, 130, 100));
    stroke(p, const Color(0xFF629A84), 1.8);
    grain(p, const Rect.fromLTWH(20, 15, 140, 100), 13, count: 500);
    oval(114, 97, 31, 11, const Color(0xFFC4DDB2));
    oval(143, 71, 2.8, 2.1, const Color(0xFF659383));
    oval(130, 69, 2, 1.5, const Color(0xFF659383));
    oval(49, 40, 8, 4, const Color(0x55FFFFFF));
    oval(122, 91, 8, 4.5, const Color(0x88EBAF99));
  }

  void dinoLeg() {
    final p = Path()
      ..moveTo(20, 5)
      ..cubicTo(42, 0, 47, 26, 42, 43)
      ..cubicTo(53, 45, 60, 52, 53, 61)
      ..lineTo(18, 63)
      ..cubicTo(7, 59, 12, 46, 15, 36)
      ..close();
    gradient(p, [
      const Color(0xFF90BDA0),
      const Color(0xFF629B86),
    ], const Rect.fromLTWH(10, 0, 48, 64));
    for (var i = 0; i < 3; i++) {
      oval(26 + i * 10, 57, 4, 4.5, const Color(0xFFDDE0B4));
    }
  }

  void dinoTail() {
    final p = Path()
      ..moveTo(147, 43)
      ..cubicTo(85, 73, 48, 20, 12, 17)
      ..cubicTo(47, 89, 89, 118, 151, 98)
      ..close();
    gradient(p, [
      const Color(0xFFAACDA4),
      const Color(0xFF68A98F),
    ], const Rect.fromLTWH(10, 15, 150, 92));
    for (var i = 0; i < 4; i++) {
      final x = 53.0 + i * 21;
      path(
        Path()
          ..moveTo(x, 50 + i * 7)
          ..lineTo(x - 4, 28 + i * 9)
          ..quadraticBezierTo(x + 11, 29 + i * 9, x + 13, 54 + i * 7)
          ..close(),
        const Color(0xFFB4C98E),
      );
    }
  }

  void tree(int variant) {
    final rng = math.Random(20 + variant);
    final trunk = Path()
      ..moveTo(134, 458)
      ..cubicTo(146, 370, 141, 295, 123, 203)
      ..lineTo(162, 202)
      ..cubicTo(157, 282, 154, 375, 177, 462)
      ..close();
    gradient(trunk, [
      const Color(0xFFB8A47C),
      const Color(0xFF7F8865),
    ], const Rect.fromLTWH(123, 200, 54, 262));
    line(150, 330, 82, 210, const Color(0xFF9C9773), 13);
    line(151, 310, 221, 187, const Color(0xFF9C9773), 12);
    stroke(
      Path()
        ..moveTo(158, 443)
        ..cubicTo(153, 385, 153, 350, 158, 289),
      const Color(0x55D7C49A),
      3,
    );
    final colors = variant == 0
        ? [
            const Color(0xFF9CB58A),
            const Color(0xFF6E9B79),
            const Color(0xFF477D68),
          ]
        : [
            const Color(0xFFCDD099),
            const Color(0xFFA4BA7E),
            const Color(0xFF709565),
          ];
    final canopy = Path()..addOval(const Rect.fromLTWH(72, 72, 170, 220));
    for (var i = 0; i < 18; i++) {
      final a = i * math.pi * 2 / 18;
      final x = 151 + math.cos(a) * (64 + rng.nextDouble() * 39),
          y = 171 + math.sin(a) * (78 + rng.nextDouble() * 35);
      canopy.addOval(
        Rect.fromCenter(center: Offset(x, y), width: 100, height: 113),
      );
    }
    gradient(canopy, colors, const Rect.fromLTWH(10, 20, 288, 300));
    grain(
      canopy,
      const Rect.fromLTWH(0, 0, 300, 330),
      variant + 6,
      count: 2200,
      alpha: .07,
    );
    for (var i = 0; i < 42; i++) {
      final x = 47 + rng.nextDouble() * 205, y = 50 + rng.nextDouble() * 226;
      leaf(
        x,
        y,
        .14 + rng.nextDouble() * .2,
        rng.nextDouble() * 3 - 1.5,
        colors[i % 3].withValues(alpha: .55),
      );
    }
    for (var i = 0; i < 6; i++) {
      oval(
        70 + rng.nextDouble() * 160,
        110 + rng.nextDouble() * 130,
        3,
        4,
        const Color(0xFFDDD6A0),
      );
    }
  }

  void fern() {
    for (var i = 0; i < 9; i++) {
      final angle = -1.4 + i * .34;
      leaf(
        110,
        132,
        .7 + (i % 3) * .13,
        angle,
        const [Color(0xFF527F61), Color(0xFF6F9E6B), Color(0xFF96B780)][i % 3],
      );
    }
    for (var i = 0; i < 5; i++) {
      line(110, 130, 83 + i * 12, 147, const Color(0xFF63875E), 2);
    }
  }

  void rock() {
    final p = Path()
      ..moveTo(15, 85)
      ..lineTo(34, 37)
      ..lineTo(78, 15)
      ..lineTo(137, 25)
      ..lineTo(169, 62)
      ..lineTo(164, 96)
      ..lineTo(93, 110)
      ..lineTo(30, 105)
      ..close();
    gradient(p, [
      const Color(0xFFC5CBB0),
      const Color(0xFF8BA899),
      const Color(0xFF728E83),
    ], const Rect.fromLTWH(10, 15, 160, 95));
    path(
      Path()
        ..moveTo(34, 37)
        ..lineTo(78, 15)
        ..lineTo(137, 25)
        ..lineTo(110, 52)
        ..lineTo(48, 57)
        ..close(),
      const Color(0xFFCED0B5),
    );
    grain(p, const Rect.fromLTWH(15, 15, 150, 100), 30, count: 700);
    for (var i = 0; i < 4; i++) {
      oval(34 + i * 25, 88 + math.sin(i) * 8, 13, 5, const Color(0xFF809F6F));
    }
  }

  void tent() {
    final body = Path()
      ..moveTo(15, 204)
      ..quadraticBezierTo(41, 115, 130, 27)
      ..lineTo(265, 199)
      ..quadraticBezierTo(156, 222, 15, 204)
      ..close();
    gradient(body, [
      const Color(0xFFF7D7A0),
      const Color(0xFFD5A271),
    ], const Rect.fromLTWH(30, 25, 230, 190));
    path(
      Path()
        ..moveTo(130, 27)
        ..lineTo(151, 203)
        ..lineTo(265, 199)
        ..close(),
      const Color(0xFFC2946A),
    );
    path(
      Path()
        ..moveTo(130, 61)
        ..lineTo(72, 202)
        ..lineTo(157, 206)
        ..close(),
      const Color(0xFF66877A),
    );
    path(
      Path()
        ..moveTo(130, 61)
        ..lineTo(111, 192)
        ..lineTo(72, 202)
        ..close(),
      const Color(0xFFECBD82),
    );
    stroke(
      Path()
        ..moveTo(16, 204)
        ..quadraticBezierTo(41, 115, 130, 27)
        ..lineTo(265, 199),
      const Color(0xFFFBE2B0),
      4,
    );
    line(130, 27, 130, 5, const Color(0xFF8F7952), 4);
    path(
      Path()
        ..moveTo(132, 6)
        ..lineTo(165, 12)
        ..lineTo(132, 22)
        ..close(),
      const Color(0xFF75A99A),
    );
    line(17, 200, 1, 220, const Color(0xFFC3B185), 2);
    line(265, 198, 283, 218, const Color(0xFFC3B185), 2);
    grain(
      body,
      const Rect.fromLTWH(15, 25, 250, 188),
      34,
      count: 1500,
      alpha: .055,
    );
    oval(115, 202, 32, 7, const Color(0xFFC1B384));
  }

  void fruit() {
    final p = Path()
      ..moveTo(53, 29)
      ..cubicTo(20, 5, 0, 37, 7, 65)
      ..cubicTo(17, 99, 40, 111, 54, 97)
      ..cubicTo(79, 110, 101, 81, 104, 56)
      ..cubicTo(109, 20, 78, 9, 53, 29)
      ..close();
    gradient(p, [
      const Color(0xFFF2BD83),
      const Color(0xFFE28E66),
      const Color(0xFFC77654),
    ], const Rect.fromLTWH(5, 12, 98, 90));
    stroke(
      Path()
        ..moveTo(24, 34)
        ..quadraticBezierTo(13, 50, 20, 62),
      const Color(0x99FFE4B4),
      6,
    );
    line(54, 29, 60, 5, const Color(0xFF8D7950), 6);
    leaf(59, 17, .35, 1, const Color(0xFF739B68));
    grain(p, const Rect.fromLTWH(5, 15, 100, 92), 21, count: 240);
  }

  void mountains() {
    final back = Path()
      ..moveTo(0, 420)
      ..lineTo(0, 223)
      ..cubicTo(120, 230, 133, 114, 218, 120)
      ..cubicTo(335, 124, 324, 6, 439, 48)
      ..cubicTo(560, 61, 627, 223, 758, 185)
      ..cubicTo(881, 88, 948, 13, 1085, 118)
      ..cubicTo(1148, 153, 1187, 203, 1280, 188)
      ..lineTo(1280, 420)
      ..close();
    gradient(back, [
      const Color(0xFFBDCEC1),
      const Color(0xFF99B7AB),
    ], const Rect.fromLTWH(0, 0, 1280, 420));
    final front = Path()
      ..moveTo(0, 420)
      ..lineTo(0, 320)
      ..cubicTo(170, 204, 240, 341, 370, 248)
      ..cubicTo(466, 189, 520, 280, 622, 297)
      ..cubicTo(812, 294, 858, 167, 956, 244)
      ..cubicTo(1115, 301, 1212, 243, 1280, 280)
      ..lineTo(1280, 420)
      ..close();
    gradient(front, [
      const Color(0xFFA6C0A6),
      const Color(0xFF82AB94),
    ], const Rect.fromLTWH(0, 160, 1280, 260));
    grain(
      front,
      const Rect.fromLTWH(0, 170, 1280, 250),
      5,
      count: 4000,
      alpha: .03,
    );
  }

  void arm() {
    rr(7, 19, 182, 28, const Color(0xFFAA814C), 14);
    rr(8, 13, 178, 27, const Color(0xFFE9BF72), 13);
    line(25, 19, 163, 19, const Color(0xFFF9DA95), 4);
    rr(55, 37, 109, 8, const Color(0xFF7C8E7F), 4);
    oval(21, 28, 19, 19, const Color(0xFF8D916E));
    oval(21, 28, 12, 12, const Color(0xFFD8CCA0));
    oval(21, 28, 5, 5, const Color(0xFF718474));
    oval(177, 28, 13, 13, const Color(0xFF8D916E));
    oval(177, 28, 7, 7, const Color(0xFFDDD3A7));
  }

  void nest() {
    oval(135, 92, 119, 39, const Color(0xFFB19D6E));
    oval(135, 83, 108, 31, const Color(0xFFD1BD86));
    oval(135, 83, 83, 23, const Color(0xFFA9966B));
    for (var i = 0; i < 15; i++) {
      final a = i * math.pi * 2 / 15;
      line(
        135 + math.cos(a) * 102,
        87 + math.sin(a) * 29,
        135 + math.cos(a + .24) * 108,
        87 + math.sin(a + .24) * 33,
        const Color(0xFFE4CD94),
        3,
      );
    }
    for (var i = 0; i < 5; i++) {
      leaf(
        70 + i * 30,
        100,
        .55,
        -.8 + i * .34,
        const [Color(0xFF8DAC79), Color(0xFFA7BC85)][i % 2],
      );
    }
  }
}
