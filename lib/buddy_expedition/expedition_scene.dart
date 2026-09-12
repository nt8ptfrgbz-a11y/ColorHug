import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'expedition_assets.dart';
import 'expedition_controller.dart';
import 'expedition_models.dart';
import 'expedition_world.dart';
import 'chapters/bay_controller.dart';
part 'chapters/island_scenes.dart';

class ValleyView {
  ValleyView(this.size, this.camera, {this.region = IslandRegion.valley});
  final IslandRegion region;
  final Size size;
  final double camera;
  double get scale {
    if (size.width >= 600) return (size.height / 610).clamp(.60, 1.3);
    if (region != IslandRegion.valley) return size.width / 650;
    final enter = ((camera - 800) / 260).clamp(0.0, 1.0);
    final exit = ((1850 - camera) / 230).clamp(0.0, 1.0);
    final blend = Curves.easeInOut.transform(math.min(enter, exit));
    return size.width / (515 + 145 * blend);
  }

  double get horizon => size.height * (size.width < 600 ? .64 : .74);
  Offset toScreen(Offset world) => Offset(
    size.width / 2 + (world.dx - camera) * scale,
    horizon + world.dy * scale,
  );
  Offset toWorld(Offset screen) => Offset(
    (screen.dx - size.width / 2) / scale + camera,
    (screen.dy - horizon) / scale,
  );
  Rect rectToScreen(Rect world) =>
      Rect.fromPoints(toScreen(world.topLeft), toScreen(world.bottomRight));
}

class ExpeditionScene extends CustomPainter {
  ExpeditionScene(
    this.model,
    this.assets, {
    required this.reducedMotion,
    this.focus,
    this.touch,
  }) : super(repaint: model);
  final ExpeditionController model;
  final ExpeditionAssets assets;
  final bool reducedMotion;
  final ExpeditionInput? focus;
  final Offset? touch;
  late Canvas c;
  late Size size;
  late ValleyView view;
  bool get _campResting =>
      model.region == IslandRegion.valley &&
      model.home &&
      model.dino == DinoAction.home;
  double get t => reducedMotion ? 0 : model.time;
  final Paint _imagePaint = Paint()..filterQuality = FilterQuality.medium;
  void image(String name, Rect target, {double opacity = 1}) {
    final src = assets.images[name];
    if (src == null) return;
    _imagePaint.color = Colors.white.withValues(alpha: opacity);
    c.drawImageRect(
      src,
      Rect.fromLTWH(0, 0, src.width.toDouble(), src.height.toDouble()),
      target,
      _imagePaint,
    );
  }

  void sprite(
    String name,
    double x,
    double y,
    double w,
    double h, {
    double angle = 0,
    double opacity = 1,
    Alignment pivot = Alignment.bottomCenter,
  }) {
    c.save();
    c.translate(x, y);
    c.rotate(angle);
    image(
      name,
      Rect.fromLTWH(-w * (pivot.x + 1) / 2, -h * (pivot.y + 1) / 2, w, h),
      opacity: opacity,
    );
    c.restore();
  }

  void line(Offset a, Offset b, Color color, double width) {
    c.drawLine(
      a,
      b,
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  void ellipse(Offset at, double rx, double ry, Color color) => c.drawOval(
    Rect.fromCenter(center: at, width: rx * 2, height: ry * 2),
    Paint()..color = color,
  );
  void text(
    String value,
    Offset at, {
    double font = 18,
    Color color = expeditionInk,
  }) {
    final text = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontFamily: 'Hiragino Sans GB',
          fontFamilyFallback: const ['PingFang SC'],
          fontSize: font,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 300);
    text.paint(c, at - Offset(text.width / 2, text.height / 2));
  }

  @override
  void paint(Canvas canvas, Size s) {
    c = canvas;
    size = s;
    view = ValleyView(s, model.cameraX, region: model.region);
    final sky = Paint()
      ..shader = ui.Gradient.linear(Offset.zero, Offset(0, s.height), const [
        Color(0xFFE2EEDD),
        Color(0xFFF7E9C9),
      ]);
    c.drawRect(Offset.zero & s, sky);
    if (model.region == IslandRegion.valley) {
      _sky();
    } else {
      _islandSky();
    }
    c.save();
    c.translate(size.width / 2 - model.cameraX * view.scale, view.horizon);
    c.scale(view.scale);
    _world();
    c.restore();
    _guidance();
  }

  void _sky() {
    final x = size.width * .79 - model.cameraX * .012;
    ellipse(Offset(x, size.height * .19), 55, 55, const Color(0x15FFFDF0));
    ellipse(Offset(x, size.height * .19), 37, 37, const Color(0x33FFFADE));
    ellipse(Offset(x, size.height * .19), 23, 23, const Color(0xFFFDF0C8));
    for (var i = 0; i < 5; i++) {
      final cx = (i * 260.0 - model.cameraX * .035) % (size.width + 250) - 80;
      final cy = size.height * (.17 + (i % 3) * .053);
      ellipse(Offset(cx, cy), 55, 9, const Color(0x60FFFFFF));
      ellipse(Offset(cx - 10, cy - 5), 31, 12, const Color(0x50FFFFFF));
    }
    final mountainsWidth = math.max(size.width * 1.5, 1100.0);
    image(
      'mountains',
      Rect.fromLTWH(
        -model.cameraX * .075,
        view.horizon - 400 * view.scale,
        mountainsWidth,
        370 * view.scale,
      ),
      opacity: .75,
    );
    // Wispy birds in the distance, not a competing foreground animation.
    for (var i = 0; i < 3; i++) {
      final bx = size.width * .45 + i * 18 + math.sin(t * .4) * 8,
          by = size.height * .23 + i * 6;
      final p = Path()
        ..moveTo(bx - 5, by)
        ..quadraticBezierTo(bx - 2, by - 3, bx, by)
        ..quadraticBezierTo(bx + 3, by - 4, bx + 6, by - 1);
      c.drawPath(
        p,
        Paint()
          ..color = const Color(0x7790A897)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  void _world() {
    if (model.region != IslandRegion.valley) {
      _islandWorld();
      return;
    }
    final left = model.cameraX - size.width / 2 / view.scale - 350,
        right = model.cameraX + size.width / 2 / view.scale + 350;
    // Distant woodland is offset by parallax; foreground geometry uses world coordinates.
    for (var i = 0; i < 20; i++) {
      final x = i * 178.0 - 120;
      if (x < left - 180 || x > right + 180) continue;
      sprite(
        i % 3 == 0 ? 'tree_gold' : 'tree',
        x,
        -60,
        170 + i % 3 * 27,
        275 + i % 3 * 31,
        opacity: .36,
      );
    }
    final ground = Path()..moveTo(left, model.terrain(left) - 17);
    for (var x = left; x < right; x += 12) {
      ground.lineTo(x, model.terrain(x) - 17);
    }
    ground
      ..lineTo(right, 700)
      ..lineTo(left, 700)
      ..close();
    c.drawPath(
      ground,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, -30),
          const Offset(0, 370),
          const [Color(0xFFCCD6A6), Color(0xFFABC195), Color(0xFF7EA485)],
          [0, .5, 1],
        ),
    );
    for (var i = 0; i < 20; i++) {
      final x = i * 135.0;
      if (x < left || x > right) continue;
      final y = 30 + (i % 4) * 24.0;
      c.drawPath(
        Path()
          ..moveTo(x, y)
          ..quadraticBezierTo(x + 37, y - 14, x + 97, y + 4),
        Paint()
          ..color = const Color(0x20F6EBC0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9,
      );
    }
    _road(left, right);
    _river();
    // Camp, with a persistent place for the new companion.
    sprite('tent', 250, -32, 245, 190);
    sprite('rock', 138, -8, 70, 46);
    sprite('fern', 98, 30, 130, 100);
    sprite('nest', 205, 24, 180, 94);
    _sign(421, -19, '河谷', true);
    _sign(2040, -8, '果林', true);
    // The echo cave is part of the landscape, not a modal mini-game.
    sprite('rock', 974, -36, 212, 139);
    ellipse(const Offset(979, -65), 32, 33, const Color(0xFF638375));
    ellipse(const Offset(979, -65), 24, 27, const Color(0xFF41665E));
    sprite('fern', 908, 13, 120, 89);
    // Tall trees are placed beside, not on, the interactive route.
    for (final tree in [
      (80.0, 380.0),
      (640.0, 320.0),
      (1720.0, 420.0),
      (2150.0, 380.0),
    ]) {
      if (tree.$1 < left - 180 || tree.$1 > right + 180) continue;
      sprite(
        tree.$1 == 640 ? 'tree_gold' : 'tree',
        tree.$1,
        -28,
        tree.$2 * .64,
        tree.$2,
      );
    }
    _puddle();
    if (model.logPlace != LogPlace.hook) _log();
    if (model.dino != DinoAction.riding &&
        model.dino != DinoAction.boarding &&
        model.dino != DinoAction.alighting) {
      _dino(
        model.dinoX,
        model.terrain(model.dinoX) + 4,
        1,
        model.dinoX > model.carX ? -1 : 1,
      );
    }
    if (!model.fruitCarried && !model.fed) {
      sprite(
        'fruit',
        model.fruitX,
        model.fruitY + 27,
        57,
        57,
        angle: model.fruitRotation,
        pivot: Alignment.center,
      );
    }
    _car();
    if (model.story.flyerRescued && !_campResting) {
      _flyer(model.carX + 22, model.terrain(model.carX) - 128, .55);
    }
    if (model.logPlace == LogPlace.hook) _log();
    for (final p in model.particles) {
      if (reducedMotion && p.radius < 4) continue;
      ellipse(
        p.position,
        p.radius,
        p.radius * .65,
        p.color.withValues(alpha: (p.life / .4).clamp(0.0, .85)),
      );
    }
    if (_campResting) {
      if (model.story.picnicReady) sprite('basket', 310, 12, 80, 68);
      if (model.story.lampFound) {
        if (model.campLampOn) {
          ellipse(const Offset(320, -156), 60, 60, const Color(0x33FFEBC0));
        }
        sprite(
          'lantern',
          320,
          -125,
          55,
          66,
          opacity: model.campLampOn ? 1 : .45,
        );
      }
      if (model.story.flyerRescued) _flyer(365, -75, .62);
      sprite('fern', 332, 37, 145, 100);
      if (model.fed) sprite('fruit', 221, 9, 30, 30);
    }
    // Foreground paper-cut ferns frame the scene without hiding the road.
    for (final x in [35.0, 810.0, 1580.0, 2090.0]) {
      if (x > left && x < right) {
        sprite('fern', x, 120, 180, 132, angle: math.sin(t * .45 + x) * .016);
      }
    }
  }

  void _road(double left, double right) {
    final p = Path()..moveTo(left, model.terrain(left) + 13);
    for (var x = left; x < right; x += 8) {
      p.lineTo(x, model.terrain(x) + 13);
    }
    c.drawPath(
      p,
      Paint()
        ..color = const Color(0xFFB9B68C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 65
        ..strokeCap = StrokeCap.round,
    );
    c.drawPath(
      p,
      Paint()
        ..color = const Color(0xFFE4D1A7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 53
        ..strokeCap = StrokeCap.round,
    );
    c.drawPath(
      p,
      Paint()
        ..color = const Color(0x55FAE7BD)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 25
        ..strokeCap = StrokeCap.round,
    );
    for (var i = 0; i < 125; i++) {
      final x = i * 20.0;
      if (x < left || x > right || x > riverLeft && x < riverRight) continue;
      final y = model.terrain(x) + 16 + math.sin(i * 9.3) * 15;
      ellipse(Offset(x, y), 1.7 + i % 3, 1.1, const Color(0xFFCCB894));
    }
  }

  void _river() {
    final river = Path()
      ..moveTo(1322, -110)
      ..cubicTo(1335, -30, 1250, 77, 1282, 260)
      ..lineTo(1510, 600)
      ..lineTo(1660, 600)
      ..cubicTo(1420, 196, 1550, 87, 1440, -90)
      ..close();
    c.drawPath(
      river,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(1280, -90),
          const Offset(1510, 500),
          const [Color(0xFFADCFBD), Color(0xFF76B8AF), Color(0xFF60A4A2)],
          [0, .45, 1],
        ),
    );
    for (var i = 0; i < 24; i++) {
      final y = -63 + (i * 24 + t * 14) % 560;
      final x = 1335 + (y * .24) + math.sin(i * 2.3) * 24;
      line(
        Offset(x, y),
        Offset(x + 16 + i % 3 * 9, y - 1),
        const Color(0x66D9EBCA),
        2,
      );
    }
    sprite('rock', riverLeft - 7, 40, 106, 70);
    sprite('rock', riverRight + 4, 45, 106, 70);
    sprite('fern', riverLeft - 83, 65, 120, 92);
    sprite('fern', riverRight + 99, 82, 120, 92);
    if (!model.bridge) {
      final opacity = model.snapReady ? .55 : .17;
      final rect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(
          riverLeft - 15,
          -39,
          riverRight - riverLeft + 30,
          39,
        ),
        const Radius.circular(18),
      );
      c.drawRRect(
        rect,
        Paint()
          ..color = const Color(0xFFFFF3BD).withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = model.snapReady ? 4 : 2,
      );
      for (var i = 0; i < 6; i++) {
        ellipse(
          Offset(riverLeft + 10 + i * 32, -19),
          2.5,
          2.5,
          const Color(0x80FFF2C0),
        );
      }
    }
  }

  void _puddle() {
    ellipse(const Offset(535, 19), 83, 23, const Color(0xFFB6A887));
    ellipse(const Offset(534, 17), 72, 18, const Color(0xFFA6B7A0));
    for (var i = 0; i < 3; i++) {
      final r = 12 + (t * 11 + i * 20) % 58;
      c.drawOval(
        Rect.fromCenter(
          center: const Offset(540, 15),
          width: r * 2,
          height: r * .32,
        ),
        Paint()
          ..color = const Color(0x66DFDDAD)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3,
      );
    }
    sprite(
      'fern',
      529 + math.sin(t) * 8,
      14,
      27,
      22,
      angle: .3 + math.sin(t * .7) * .12,
    );
    ellipse(const Offset(384, 21), 31, 13, const Color(0xFFAACDC0));
    line(
      const Offset(368, 18),
      const Offset(390, 17),
      const Color(0xFFDBEBD4),
      2,
    );
  }

  void _sign(double x, double y, String label, bool right) {
    line(Offset(x, y), Offset(x, y - 78), const Color(0xFF9C9066), 7);
    c.save();
    c.translate(x, y - 62);
    c.rotate(right ? .035 : -.035);
    final p = Path()
      ..moveTo(-40, -18)
      ..lineTo(31, -18)
      ..lineTo(45, 0)
      ..lineTo(31, 18)
      ..lineTo(-40, 18)
      ..close();
    if (!right) c.scale(-1, 1);
    c.drawPath(p, Paint()..color = const Color(0xFFD2B889));
    if (!right) c.scale(-1, 1);
    text(label, const Offset(0, 0), font: 17, color: const Color(0xFF677858));
    c.restore();
  }

  void _log() {
    final bounce = reducedMotion
        ? 0
        : math.sin(model.landingBounce * math.pi) * 4;
    if (model.logPlace != LogPlace.hook) {
      ellipse(
        Offset(model.logX, model.terrain(model.logX) + 5),
        118,
        9,
        const Color(0x224D6352),
      );
    }
    sprite(
      'log',
      model.logX,
      model.logY - bounce,
      bridgeLength,
      87,
      angle: model.logAngle,
      pivot: Alignment.center,
    );
    if (model.logPlace == LogPlace.bank &&
        model.riverWork &&
        model.idleTime > 2) {
      c.drawOval(
        Rect.fromCenter(
          center: Offset(model.logX, model.logY),
          width: 280,
          height: 75,
        ),
        Paint()
          ..color = const Color(0x60FFF6C8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  void _car() {
    final m = model;
    final ground = model.terrain(m.carX);
    ellipse(Offset(m.carX, ground + 22), 108, 12, const Color(0x27405D4C));
    c.save();
    c.translate(m.carX, ground);
    c.rotate(m.carTilt);
    c.save();
    c.translate(0, reducedMotion ? 0 : m.suspension);
    sprite('car', 0, 18, 224, 126);
    if (m.mud > 0) {
      for (var i = 0; i < (m.mud * 15).ceil(); i++) {
        ellipse(
          Offset(-82 + (i * 37) % 168, -17 - (i * 17) % 30),
          3 + i % 4,
          2 + i % 3,
          const Color(0xAA9D926D),
        );
      }
    }
    if (!_campResting &&
        m.story.picnicReady &&
        (m.region != IslandRegion.orchard || m.orchard.basketLift >= 1)) {
      sprite('basket', -55, -70, 45, 38);
    }
    if (!_campResting && m.story.lampFound) sprite('lantern', 65, -87, 27, 33);
    if (m.fruitCarried && !m.fed) sprite('fruit', -57, -74, 45, 45);
    if (m.dino == DinoAction.riding &&
        !(m.region == IslandRegion.orchard &&
            (m.orchard.helper > .5 || m.orchard.cleared && !m.orchard.fed))) {
      _dino(-50, -62, .57, 1, local: true);
    }
    if (m.dino == DinoAction.boarding || m.dino == DinoAction.alighting) {
      final progress = Curves.easeInOut.transform(m.boarding.clamp(0.0, 1.0));
      final f = m.dino == DinoAction.alighting ? 1 - progress : progress;
      final start = m.dinoX - m.carX;
      final x = start + (-50 - start) * f,
          y = -62 * f - math.sin(f * math.pi) * 80;
      _dino(x, y, .9 - .33 * f, 1, local: true);
    }
    // Painted door lamp, not a toolbar horn.
    if (m.hornReaction > 0) {
      for (var i = 0; i < 3; i++) {
        c.drawArc(
          Rect.fromCenter(
            center: const Offset(100, -50),
            width: 20 + i * 18,
            height: 20 + i * 18,
          ),
          -.6,
          1.2,
          false,
          Paint()
            ..color = const Color(0xB8E0BD78)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
    c.restore();
    for (final x in [-65.0, 50.0]) {
      sprite(
        'wheel',
        x,
        0,
        57,
        57,
        angle: m.wheelAngle,
        pivot: Alignment.center,
      );
    }
    c.restore();
    if (model.region == IslandRegion.valley) _crane();
  }

  void _crane() {
    final base = model.craneBase;
    final wrist = model.hook - const Offset(0, 47);
    final v = wrist - base;
    final length = v.distance.clamp(35.0, 319.0);
    const upper = 170.0, lower = 150.0;
    final direction = math.atan2(v.dy, v.dx);
    final cosine =
        ((upper * upper + length * length - lower * lower) /
                (2 * upper * length))
            .clamp(-1.0, 1.0);
    final angle = direction - math.acos(cosine);
    final elbow =
        base + Offset(math.cos(angle) * upper, math.sin(angle) * upper);
    _arm(base, elbow);
    _arm(elbow, wrist);
    line(wrist, model.hook, const Color(0xFF687F6E), 3);
    ellipse(model.hook, 7, 7, const Color(0xFF829785));
    final gripping = model.logPlace == LogPlace.hook;
    final claw = Path()
      ..moveTo(model.hook.dx - 5, model.hook.dy + 3)
      ..quadraticBezierTo(
        model.hook.dx - (gripping ? 16 : 24),
        model.hook.dy + 27,
        model.hook.dx - (gripping ? 3 : 17),
        model.hook.dy + 32,
      );
    c.drawPath(
      claw,
      Paint()
        ..color = const Color(0xFF6A8273)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    final claw2 = Path()
      ..moveTo(model.hook.dx + 5, model.hook.dy + 3)
      ..quadraticBezierTo(
        model.hook.dx + (gripping ? 16 : 24),
        model.hook.dy + 27,
        model.hook.dx + (gripping ? 3 : 17),
        model.hook.dy + 32,
      );
    c.drawPath(
      claw2,
      Paint()
        ..color = const Color(0xFF6A8273)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
  }

  void _arm(Offset a, Offset b) {
    c.save();
    c.translate(a.dx, a.dy);
    c.rotate(math.atan2(b.dy - a.dy, b.dx - a.dx));
    image('arm', Rect.fromLTWH(-20, -27, (b - a).distance + 43, 58));
    c.restore();
  }

  void _dino(
    double x,
    double y,
    double scale,
    int direction, {
    bool local = false,
  }) {
    c.save();
    c.translate(x, y);
    c.scale(scale * direction, scale);
    if (!local) ellipse(const Offset(0, 9), 76, 11, const Color(0x26435E4E));
    final walking =
        model.dino == DinoAction.crossing || model.dino == DinoAction.following;
    final gait = walking ? model.dinoWalk : 0.0;
    final bob = reducedMotion
        ? 0.0
        : walking
        ? math.sin(gait * 2).abs() * 3
        : math.sin(t * 1.8) * 1.5;
    c.translate(0, -bob);
    sprite(
      'dino_tail',
      -22,
      -38,
      113,
      88,
      angle: math.sin(t * 2) * .05,
      pivot: Alignment.centerRight,
    );
    sprite('dino_leg', 22, 1, 36, 47, angle: walking ? math.sin(gait) * .3 : 0);
    sprite(
      'dino_leg',
      -32,
      0,
      37,
      47,
      angle: walking ? -math.sin(gait) * .3 : 0,
    );
    sprite('dino_body', -4, -7, 132, 118);
    sprite(
      'dino_leg',
      -40,
      3,
      40,
      50,
      angle: walking ? math.sin(gait) * .3 : 0,
    );
    sprite(
      'dino_leg',
      22,
      3,
      40,
      50,
      angle: walking ? -math.sin(gait) * .3 : 0,
    );
    final tilt = model.dinoMood > 0
        ? math.sin(t * 3) * .065
        : math.sin(t * .7) * .025;
    c.save();
    c.translate(49, -104);
    c.rotate(tilt);
    sprite('dino_head', 0, 0, 115, 85, pivot: Alignment.center);
    final blink = (t % 4.7) > 4.5;
    ellipse(const Offset(-3, -7), 5, blink ? 1.2 : 7, const Color(0xFF365C53));
    ellipse(
      const Offset(-4, -9),
      1.7,
      blink ? 0 : 1.8,
      const Color(0xFFF3F4DA),
    );
    final mouth = Path()
      ..moveTo(23, 13)
      ..quadraticBezierTo(33, 20 + (model.dinoMood > 0 ? 4 : 0), 43, 10);
    c.drawPath(
      mouth,
      Paint()
        ..color = const Color(0xFF44705F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
    c.restore();
    if (model.dinoMood > 0) {
      for (var i = 0; i < 3; i++) {
        ellipse(
          Offset(57 + i * 13, -163 - math.sin(t * 4 + i) * 5),
          2.5,
          2.5,
          const Color(0xFFE9C383),
        );
      }
    }
    c.restore();
  }

  void _guidance() {
    if (model.driveTarget != null) {
      final at = view.toScreen(onRoad(model.driveTarget!));
      c.drawOval(
        Rect.fromCenter(
          center: at + const Offset(0, 12),
          width: 46,
          height: 15,
        ),
        Paint()
          ..color = const Color(0x70FFF9D5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    if (touch != null) {
      c.drawCircle(
        touch!,
        22,
        Paint()
          ..color = const Color(0x44FFF9D8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ExpeditionScene old) =>
      old.assets != assets ||
      old.reducedMotion != reducedMotion ||
      old.touch != touch;
}
