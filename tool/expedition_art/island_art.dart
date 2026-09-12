import 'dart:math' as math;
import 'dart:ui';
import 'art_source.dart';

extension IslandArt on ExpeditionArt {
  void door() {
    final shape = Path()
      ..moveTo(18, 410)
      ..lineTo(8, 76)
      ..quadraticBezierTo(135, -20, 260, 65)
      ..lineTo(270, 410)
      ..close();
    gradient(shape, [
      const Color(0xFF9DAEAC),
      const Color(0xFF788F9A),
      const Color(0xFF586F80),
    ], const Rect.fromLTWH(8, 10, 262, 400));
    stroke(
      Path()
        ..moveTo(23, 400)
        ..lineTo(22, 80)
        ..quadraticBezierTo(140, 1, 244, 74),
      const Color(0x88C7CCC0),
      5,
    );
    line(40, 143, 243, 142, const Color(0xFF657E8A), 3);
    line(27, 269, 255, 267, const Color(0xFF657E8A), 3);
    line(161, 144, 153, 266, const Color(0xFF657E8A), 3);
    line(110, 273, 117, 400, const Color(0xFF657E8A), 3);
    oval(130, 211, 25, 25, const Color(0xFFBAD1B9));
    oval(130, 211, 13, 13, const Color(0xFF839F9E));
    grain(
      shape,
      const Rect.fromLTWH(8, 25, 260, 380),
      101,
      count: 1800,
      alpha: .07,
    );
  }

  void basket() {
    final p = Path()
      ..moveTo(20, 62)
      ..lineTo(160, 62)
      ..lineTo(148, 127)
      ..quadraticBezierTo(87, 144, 32, 127)
      ..close();
    gradient(p, [
      const Color(0xFFE8C893),
      const Color(0xFFB88B5D),
    ], const Rect.fromLTWH(20, 60, 145, 80));
    stroke(
      Path()
        ..moveTo(35, 64)
        ..cubicTo(39, -7, 141, -7, 149, 64),
      const Color(0xFFB39462),
      8,
    );
    stroke(
      Path()
        ..moveTo(38, 60)
        ..cubicTo(44, 7, 136, 7, 145, 60),
      const Color(0xFFF4D8A4),
      3,
    );
    for (var i = 0; i < 6; i++) {
      line(32 + i * 22, 66, 40 + i * 19, 126, const Color(0xFF9E7950), 2);
    }
    for (var i = 0; i < 5; i++) {
      stroke(
        Path()
          ..moveTo(24 + i * 2, 72 + i * 11)
          ..quadraticBezierTo(90, 85 + i * 10, 157 - i * 2, 72 + i * 11),
        const Color(0xFFDAB785),
        4,
      );
    }
    rr(15, 58, 151, 12, const Color(0xFFEED39E), 6);
    grain(p, const Rect.fromLTWH(20, 60, 145, 80), 91, count: 600);
  }

  void mushroom() {
    rr(55, 72, 30, 76, const Color(0xFFAABAB7), 15);
    line(67, 91, 66, 135, const Color(0xFFDDEBD4), 3);
    final cap = Path()
      ..moveTo(8, 87)
      ..cubicTo(14, 26, 113, -19, 142, 87)
      ..quadraticBezierTo(69, 108, 8, 87)
      ..close();
    gradient(cap, [
      const Color(0xFFAADAC8),
      const Color(0xFF70A1A5),
      const Color(0xFF527A8F),
    ], const Rect.fromLTWH(0, 20, 145, 90));
    for (var i = 0; i < 7; i++) {
      oval(
        29 + i * 14,
        65 - math.sin(i * .5) * 28,
        5,
        3,
        const Color(0xFFECF2B8),
      );
    }
    line(25, 88, 126, 87, const Color(0x88E1ECC4), 2);
  }

  void lantern() {
    stroke(
      Path()
        ..moveTo(33, 38)
        ..cubicTo(8, -2, 108, -2, 88, 38),
      const Color(0xFF92A283),
      7,
    );
    rr(22, 34, 79, 103, const Color(0xFF77978C), 15);
    rr(30, 45, 63, 80, const Color(0xFFF2D595), 10);
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final angle = i * math.pi / 5 - math.pi / 2, r = i.isEven ? 26.0 : 12.0;
      final x = 61 + math.cos(angle) * r, y = 83 + math.sin(angle) * r;
      if (i == 0) {
        star.moveTo(x, y);
      } else {
        star.lineTo(x, y);
      }
    }
    star.close();
    path(star, const Color(0xFFFFF4C1));
    rr(19, 32, 86, 11, const Color(0xFFB2C2A0), 5);
    rr(18, 130, 88, 10, const Color(0xFF819E8C), 5);
  }

  void caveArch() {
    final p = Path()
      ..moveTo(0, 320)
      ..lineTo(16, 146)
      ..lineTo(70, 63)
      ..lineTo(162, 16)
      ..lineTo(257, 4)
      ..lineTo(357, 52)
      ..lineTo(412, 122)
      ..lineTo(450, 320)
      ..close();
    gradient(p, [
      const Color(0xFF9AA4A5),
      const Color(0xFF526F81),
      const Color(0xFF3D5269),
    ], const Rect.fromLTWH(0, 0, 450, 330));
    path(
      Path()
        ..moveTo(89, 320)
        ..lineTo(109, 167)
        ..quadraticBezierTo(233, 11, 340, 171)
        ..lineTo(364, 320)
        ..close(),
      const Color(0xFF35435C),
    );
    for (var i = 0; i < 5; i++) {
      line(
        37 + i * 79,
        103 - i % 2 * 35,
        64 + i * 79,
        146 - i % 2 * 15,
        const Color(0x44778996),
        3,
      );
    }
    grain(p, const Rect.fromLTWH(0, 0, 450, 320), 92, count: 2600, alpha: .09);
  }

  void boat() {
    final hull = Path()
      ..moveTo(15, 122)
      ..lineTo(389, 122)
      ..quadraticBezierTo(362, 204, 283, 212)
      ..lineTo(97, 212)
      ..quadraticBezierTo(28, 195, 15, 122)
      ..close();
    gradient(hull, [
      const Color(0xFFE2C190),
      const Color(0xFFB4936B),
      const Color(0xFF877E66),
    ], const Rect.fromLTWH(10, 120, 390, 100));
    for (var i = 0; i < 5; i++) {
      stroke(
        Path()
          ..moveTo(30 + i * 5, 139 + i * 13)
          ..quadraticBezierTo(195, 152 + i * 13, 375 - i * 9, 139 + i * 13),
        const Color(0xFFC8AC7E),
        3,
      );
    }
    rr(8, 112, 390, 16, const Color(0xFFF0D7A9), 7);
    rr(310, 36, 65, 78, const Color(0xFF83A9A0), 12);
    rr(320, 48, 45, 31, const Color(0xFFC4E0D2), 6);
    rr(304, 27, 77, 12, const Color(0xFFECC998), 5);
    line(70, 111, 70, 57, const Color(0xFF8F9B81), 6);
    line(240, 111, 240, 57, const Color(0xFF8F9B81), 6);
    line(70, 59, 240, 59, const Color(0xFFD5C39F), 3);
    oval(46, 146, 14, 14, const Color(0xFF69867C));
    oval(46, 146, 7, 7, const Color(0xFFE4CE9C));
    grain(hull, const Rect.fromLTWH(15, 120, 374, 92), 93, count: 1400);
  }

  void flyer() {
    final body = Path()
      ..moveTo(52, 114)
      ..cubicTo(16, 97, 17, 44, 63, 45)
      ..cubicTo(93, 6, 136, 32, 129, 67)
      ..lineTo(170, 86)
      ..lineTo(128, 98)
      ..cubicTo(111, 128, 77, 142, 52, 114)
      ..close();
    gradient(body, [
      const Color(0xFFF2C49B),
      const Color(0xFFDCA283),
      const Color(0xFFB98278),
    ], const Rect.fromLTWH(15, 20, 156, 122));
    oval(102, 64, 5, 7, const Color(0xFF4A6060));
    oval(101, 62, 1.7, 2, const Color(0xFFFFF0D0));
    oval(111, 84, 9, 4, const Color(0xFFE8B394));
    path(
      Path()
        ..moveTo(72, 41)
        ..lineTo(73, 14)
        ..lineTo(99, 35)
        ..close(),
      const Color(0xFFD9AC8B),
    );
    line(65, 118, 55, 136, const Color(0xFFB3886F), 4);
    line(86, 120, 89, 137, const Color(0xFFB3886F), 4);
    grain(body, const Rect.fromLTWH(20, 40, 110, 95), 94, count: 500);
  }

  void wing() {
    final p = Path()
      ..moveTo(8, 91)
      ..cubicTo(30, 11, 88, 3, 157, 15)
      ..lineTo(138, 65)
      ..quadraticBezierTo(105, 43, 91, 84)
      ..quadraticBezierTo(54, 60, 43, 102)
      ..close();
    gradient(p, [
      const Color(0xFFF2D8AD),
      const Color(0xFFE6B792),
      const Color(0xFFBD897C),
    ], const Rect.fromLTWH(8, 5, 155, 100));
    line(13, 89, 143, 20, const Color(0xFFBB927D), 3);
    line(48, 74, 89, 83, const Color(0xFFCA9D85), 2);
    line(81, 53, 138, 65, const Color(0xFFCA9D85), 2);
  }
}
