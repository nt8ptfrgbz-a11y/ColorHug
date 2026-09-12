part of '../expedition_scene.dart';

extension IslandScenes on ExpeditionScene {
  void _islandSky() {
    final info = islandRegions[model.region]!;
    c.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height), [
          info.sky,
          info.ground,
        ]),
    );
    if (model.region == IslandRegion.cave) {
      for (var i = 0; i < 28; i++) {
        final x = (i * 123.7 - model.cameraX * .12) % (size.width + 80),
            y = 70 + (i * 61.1) % (size.height * .5);
        ellipse(Offset(x, y), 2 + i % 3, 2 + i % 3, const Color(0x77D4DCB9));
      }
    } else {
      ellipse(
        Offset(size.width * .78, size.height * .18),
        28,
        28,
        const Color(0xAAFFF5D1),
      );
      for (var i = 0; i < 5; i++) {
        ellipse(
          Offset(
            (i * 230 - model.cameraX * .08) % (size.width + 170),
            size.height * (.2 + i % 2 * .07),
          ),
          65,
          12,
          const Color(0x77FFFFFF),
        );
      }
    }
  }

  void _islandWorld() {
    final left = model.cameraX - size.width / (2 * view.scale) - 250,
        right = model.cameraX + size.width / (2 * view.scale) + 250;
    final info = islandRegions[model.region]!;
    c.drawRect(
      Rect.fromLTRB(left, 0, right, 650),
      Paint()..color = info.ground,
    );
    switch (model.region) {
      case IslandRegion.orchard:
        _orchard(left, right);
      case IslandRegion.cave:
        _cave(left, right);
      case IslandRegion.bay:
        _bay(left, right);
      case IslandRegion.valley:
        break;
    }
    if (model.region != IslandRegion.bay || !model.onBoat) {
      _car();
      if (model.story.flyerRescued) {
        _flyer(model.carX + 25, model.terrain(model.carX) - 142, .55);
      }
    }
    _sign(165, 0, '回去', false);
    if (model.region != IslandRegion.bay) {
      _sign(
        model.worldEnd - 120,
        0,
        model.region == IslandRegion.orchard ? '山洞' : '海湾',
        true,
      );
    }
    if (model.transition > 0) {
      c.drawRect(
        Rect.fromLTRB(left, -1400, right, 650),
        Paint()
          ..color = info.sky.withValues(
            alpha: (model.transition / .65).clamp(0.0, .8),
          ),
      );
    }
  }

  void _orchard(double left, double right) {
    for (var i = 0; i < 10; i++) {
      final x = 120 + i * 210.0;
      if (x < left - 180 || x > right + 180) continue;
      sprite('tree_gold', x, -35, 235, 365, opacity: i % 2 == 0 ? .65 : .9);
    }
    _road(left, right);
    for (var i = 0; i < 18; i++) {
      final x = i * 107.0;
      if (x > left && x < right) {
        sprite('fern', x, 105, 80, 60, opacity: .55);
        ellipse(Offset(x + 25, 75), 3, 4, const Color(0xFFE4A28D));
      }
    }
    final o = model.orchard;
    sprite(
      'rock',
      o.stoneX,
      o.cleared ? 30 : 5,
      125,
      84,
      angle: (o.stoneX - 690) / 70,
    );
    if (o.push > 0 || o.helper > .5 || o.cleared && !o.fed) {
      _dino(o.helperX, model.terrain(o.helperX), .78, 1);
    }
    sprite(
      'tree_gold',
      1150,
      -15,
      325,
      420,
      angle: math.sin(t * 16) * o.shake * .04,
    );
    if (o.basketLoaded && o.basketLift < 1) {
      final at = Offset.lerp(
        const Offset(1275, 6),
        Offset(model.carX - 55, -70),
        Curves.easeInOut.transform(o.basketLift),
      )!;
      sprite(
        'basket',
        at.dx,
        at.dy,
        112 - 67 * o.basketLift,
        94 - 56 * o.basketLift,
      );
    }
    if (!o.basketLoaded) {
      sprite('basket', o.basketAt.dx, o.basketAt.dy + 26, 112, 94);
      for (var i = 0; i < o.count; i++) {
        sprite(
          'fruit',
          o.basketAt.dx - 27 + i * 23,
          o.basketAt.dy - 23,
          33,
          33,
        );
      }
    }
    for (final a in o.apples) {
      if (!a.stored && !a.eaten && !o.basketLoaded) {
        sprite(
          'fruit',
          a.position.dx,
          a.position.dy,
          40,
          40,
          pivot: Alignment.center,
        );
      }
    }
    if (o.cleared && !o.fed) {
      text(
        '♡',
        const Offset(1355, -150),
        font: 24,
        color: const Color(0xFFB47E6C),
      );
    }
    if (!o.cleared) text('一起推 →', Offset(o.stoneX, -112), font: 17);
  }

  void _cave(double left, double right) {
    c.drawRect(
      Rect.fromLTRB(left, -900, right, 0),
      Paint()..color = const Color(0xFF43536A),
    );
    for (var i = 0; i < 12; i++) {
      final x = i * 165.0;
      if (x < left - 180 || x > right + 180) continue;
      sprite('cave_arch', x, -15, 330, 325, opacity: .36);
      sprite('mushroom', x + 50, 45, 65 + i % 3 * 18, 70 + i % 3 * 18);
    }
    _road(left, right);
    final cave = model.cave,
        source = Offset(model.carX + 70, -90),
        aim = cave.light;
    final angle = math.atan2(aim.dy - source.dy, aim.dx - source.dx);
    final beam = Path()
      ..moveTo(source.dx, source.dy)
      ..lineTo(
        source.dx + math.cos(angle - .21) * 650,
        source.dy + math.sin(angle - .21) * 650,
      )
      ..lineTo(
        source.dx + math.cos(angle + .21) * 650,
        source.dy + math.sin(angle + .21) * 650,
      )
      ..close();
    c.drawPath(
      beam,
      Paint()
        ..shader = ui.Gradient.radial(source, 650, const [
          Color(0x55FFF0AA),
          Color(0x00FFF0AA),
        ]),
    );
    final alpha = (.16 + .84 * cave.revealed).clamp(0.0, 1.0);
    c.save();
    c.translate(920, -118);
    for (var i = 0; i < 5; i++) {
      final a = i * math.pi * 2 / 5;
      line(
        Offset(math.cos(a) * 20, math.sin(a) * 20),
        Offset(math.cos(a) * 45, math.sin(a) * 45),
        Color(0xFFF4D6A3).withValues(alpha: alpha),
        4,
      );
    }
    ellipse(
      Offset.zero,
      16,
      16,
      const Color(0xFFFFE7B4).withValues(alpha: alpha),
    );
    c.restore();
    for (var i = 0; i < 9; i++) {
      final x = 870 + i * 18 + math.sin(t * 2 + i) * 8,
          y = -165 + math.cos(t + i) * 22;
      ellipse(
        Offset(x, y),
        3,
        3,
        const Color(0xFFEEEDBC).withValues(alpha: alpha),
      );
    }
    sprite('door', 1180, -cave.door * 210, 145, 215);
    if (cave.revealed >= .7) {
      line(
        const Offset(1125, -20),
        Offset(1125 + cave.lever * 27, -88 + cave.lever * 55),
        const Color(0xFFB6C5AA),
        8,
      );
      ellipse(
        Offset(1125 + cave.lever * 27, -88 + cave.lever * 55),
        13,
        13,
        const Color(0xFFEBCDA0),
      );
    }
    if (!cave.lamp && cave.door > .95) sprite('lantern', 1230, -20, 62, 75);
    if (cave.lamp) {
      ellipse(const Offset(1280, -95), 35, 35, const Color(0x33FFF2B6));
      text(
        '海湾 →',
        const Offset(1400, -100),
        font: 20,
        color: const Color(0xFFE7E5CB),
      );
    }
  }

  void _bay(double left, double right) {
    c.drawRect(
      Rect.fromLTRB(left, -145, right, -5),
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, -145),
          const Offset(0, 5),
          const [Color(0xFF9FD0C8), Color(0xFF73B5B1)],
        ),
    );
    for (var i = 0; i < 35; i++) {
      final x = i * 75.0 + math.sin(t * .5) * 10, y = -125 + i % 4 * 27.0;
      line(Offset(x, y), Offset(x + 30, y), const Color(0x66E4F0D2), 2);
    }
    c.drawRect(
      Rect.fromLTRB(1530, -145, right, 650),
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, -145),
          const Offset(0, 600),
          const [Color(0xFF9FD0C8), Color(0xFF66ADAD)],
        ),
    );
    if (!model.onBoat) _road(left, 1510);
    for (var i = 0; i < 15; i++) {
      final x = i * 135.0;
      if (x < left || x > right) continue;
      ellipse(Offset(x, 65), 10, 5, const Color(0xFFECC9B5));
      for (var j = 0; j < 3; j++) {
        line(
          Offset(x - 4 + j * 4, 64),
          Offset(x - 5 + j * 5, 60),
          const Color(0xFFCFAF98),
          1,
        );
      }
    }
    sprite('rock', 860, -80, 165, 180);
    sprite('fern', 595, 65, 110, 83);
    final b = model.bay;
    if (!b.rescued && !b.babyInBasket) _flyer(860, -164, .62);
    if (!b.rescued) {
      sprite('basket', b.basket.dx, b.basket.dy + 26, 110, 92);
      if (b.holding) {
        final base = Offset(model.carX - 40, -115);
        final wrist = b.basket - const Offset(0, 65);
        final elbow = Offset(
          (base.dx + wrist.dx) / 2,
          math.min(base.dy, wrist.dy) - 100,
        );
        _arm(base, elbow);
        _arm(elbow, wrist);
        line(
          b.basket - const Offset(0, 65),
          b.basket,
          const Color(0xFF9CA585),
          3,
        );
      }
      if (b.babyInBasket) _flyer(b.basket.dx, b.basket.dy - 17, .4);
    }
    for (var i = 0; i < 7; i++) {
      final x = 1350 + i * 32.0;
      line(Offset(x, 0), Offset(x, 80), const Color(0xFFAE9875), 8);
    }
    line(
      const Offset(1320, -3),
      const Offset(1550, -3),
      const Color(0xFFE8CEA2),
      15,
    );
    if (b.ferry == FerryPhase.docked || model.onBoat) {
      line(
        const Offset(1500, -3),
        const Offset(1600, 9),
        const Color(0xFFD5B98A),
        16,
      );
    }
    final bx = b.boatX, by = 30 + math.sin(t * 1.4) * 4;
    sprite('boat', bx, by + 100, 370, 198);
    if (model.onBoat) {
      c.save();
      c.translate(bx - model.carX, -12 + math.sin(t * 1.4) * 4);
      _car();
      _flyer(model.carX + 22, -142, .55);
      c.restore();
    }
    line(
      const Offset(1430, -15),
      const Offset(1450, -72),
      const Color(0xFF9A9979),
      7,
    );
    ellipse(const Offset(1450, -65), 15, 15, const Color(0xFFDACC9E));
    if (b.ferry == FerryPhase.sailing) {
      text('回家啦 · Home', Offset(bx, -205), font: 21);
      for (var i = 0; i < 5; i++) {
        final x = bx - 190 + i * 90.0, y = 130 + math.sin(t * 2 + i) * 12;
        ellipse(Offset(x, y), 13, 5, const Color(0xFF84AAA3));
      }
    }
  }

  void _flyer(double x, double y, double scale) {
    c.save();
    c.translate(x, y);
    c.scale(scale);
    sprite(
      'wing',
      -5,
      -50,
      110,
      74,
      angle: math.sin(t * 4) * .15,
      pivot: Alignment.centerRight,
    );
    sprite('flyer', 0, 0, 115, 93);
    sprite(
      'wing',
      -10,
      -46,
      105,
      70,
      angle: math.sin(t * 4 + .4) * .12,
      pivot: Alignment.centerRight,
    );
    c.restore();
  }
}
