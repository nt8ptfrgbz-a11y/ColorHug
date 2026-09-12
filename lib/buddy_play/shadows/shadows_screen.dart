import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../buddy_play_catalog.dart';
import '../buddy_play_widgets.dart';
import 'shadows_model.dart';

class ShadowsScreen extends ToyScreen {
  const ShadowsScreen({
    super.key,
    required super.progress,
    required super.audio,
  });
  @override
  State<ShadowsScreen> createState() => _ShadowsState();
}

class _ShadowsState extends ToyState<ShadowsScreen, ShadowsModel> {
  @override
  BuddyPlay get game => BuddyPlay.shadows;
  @override
  ShadowsModel createModel() => ShadowsModel();
  @override
  String get invitation => '拖手电，拖玩具。让兔子的影子去碰月亮吧！';
  @override
  Widget scene(BuildContext context) => ToyCanvas(
    key: const ValueKey('shadows-canvas'),
    painter: _ShadowsPainter(model),
    onDown: (p) => act(() => model.down(p), save: false),
    onMove: (p) => act(() => model.move(p), save: false),
    onUp: () => act(model.up),
    onCancel: () => act(model.up),
    onTap: (p) => act(() {
      if (p.dy > .8) {
        model.down(p);
        model.up();
      } else if (p.dy > .5) {
        model.toys.last.at = Offset(p.dx.clamp(.18, .82), p.dy.clamp(.53, .77));
        model.held = model.toys.length - 1;
        model.up();
      } else {
        model.peek();
      }
    }),
  );
  @override
  CustomPainter previewPainter(ShadowsModel snapshot) =>
      _ShadowsPainter(snapshot);

  @override
  List<Widget> tools() => [
    for (var i = 0; i < 4; i++)
      ToyTool(
        key: ValueKey('shadows-toy-$i'),
        icon: const ['🐰', '🐻', '🍌', '🎩'][i],
        label: const ['小兔', '小熊', '香蕉', '帽子'][i],
        selected: model.selected == i,
        onTap: () => act(() => model.select(i), save: false),
      ),
    ToyTool(
      key: const ValueKey('shadows-add'),
      icon: '➕',
      label: '放玩具',
      onTap: model.toys.length < 4 ? () => act(model.add) : null,
    ),
    ToyTool(
      key: const ValueKey('shadows-remove'),
      icon: '🧺',
      label: '收一个',
      onTap: model.toys.length > 1
          ? () => act(() => model.toys.removeLast())
          : null,
    ),
    ToyTool(
      key: const ValueKey('shadows-hat'),
      icon: '🎀',
      label: '戴帽子',
      onTap: () => act(model.hat),
    ),
    ToyTool(
      key: const ValueKey('shadows-peek'),
      icon: '💡',
      label: model.reveal ? '看影子' : '看真相',
      onTap: () => act(model.peek, save: false),
    ),
    ToyTool(
      key: const ValueKey('shadows-near'),
      icon: '🐘',
      label: '影子变大',
      onTap: () => act(() {
        final t = model.toys.last;
        t.at = Offset(t.at.dx, (t.at.dy + .045).clamp(.53, .77));
        model.held = model.toys.length - 1;
        model.up();
      }),
    ),
    ToyTool(
      key: const ValueKey('shadows-far'),
      icon: '🐭',
      label: '影子变小',
      onTap: () => act(() {
        final t = model.toys.last;
        t.at = Offset(t.at.dx, (t.at.dy - .045).clamp(.53, .77));
        model.held = model.toys.length - 1;
        model.up();
      }),
    ),
    ToyTool(
      key: const ValueKey('shadows-next'),
      icon: '⛺',
      label: '换帐篷',
      onTap: () => confirmReset(model.preset),
    ),
  ];
}

class _ShadowsPainter extends ToyPainter {
  _ShadowsPainter(this.m);
  final ShadowsModel m;
  @override
  void paint(Canvas canvas, Size s) {
    start(
      canvas,
      s,
      m.reveal ? const Color(0xFFBDB1CB) : const Color(0xFF45405C),
    );
    final tent = Path()
      ..moveTo(w * .02, h * .95)
      ..lineTo(w * .5, -h * .12)
      ..lineTo(w * .98, h * .95)
      ..close();
    c.drawPath(
      tent,
      Paint()
        ..color = m.reveal ? const Color(0xFFE9D6B9) : const Color(0xFF8D7898),
    );
    box(
      .06,
      .04,
      .88,
      .48,
      m.reveal ? const Color(0xFFFFEDCE) : const Color(0xFFE5CBA7),
      radius: 35,
    );
    for (var i = 0; i < 9; i++) {
      oval(
        .09 + i * .103,
        .045 + math.sin(i * .65) * .035,
        .012,
        .016,
        const Color(0xFFFFE9AD),
      );
    }
    final moonAt = p(.73, .16);
    final radius = math.min(w, h) * .055;
    final moon = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: moonAt, radius: radius)),
      Path()..addOval(
        Rect.fromCircle(
          center: moonAt + Offset(radius * .48, -radius * .22),
          radius: radius * .88,
        ),
      ),
    );
    c.drawPath(moon, Paint()..color = const Color(0xFFFFF5D1));
    if (m.scene == 1) {
      sparkle(.25, .18, Colors.white);
    }
    if (m.scene == 2) {
      cloud(.2, .3);
    }
    box(.03, .53, .94, .47, const Color(0xFF9D869D), radius: 22);
    for (var i = 0; i < 8; i++) {
      line(
        Offset(.04, .58 + i * .06),
        Offset(.96, .58 + i * .06),
        const Color(0x22FFFFFF),
        2,
      );
    }
    final beam = Path()
      ..moveTo(w * m.light.dx, h * m.light.dy)
      ..lineTo(w * .1, h * .12)
      ..lineTo(w * .9, h * .12)
      ..close();
    c.drawPath(beam, Paint()..color = const Color(0x18FFF0AD));
    for (final toy in m.toys) {
      final projection = projectShadow(m.light, toy.at);
      drawToy(
        toy,
        Offset(projection.x, .405),
        projection.scale * .42,
        const Color(0xB33E3651),
        true,
      );
    }
    for (final toy in m.toys) {
      drawToy(
        toy,
        toy.at,
        .7,
        const [
          Color(0xFFF0D5BA),
          Color(0xFFC89574),
          Color(0xFFF2CF77),
          Color(0xFF748698),
        ][toy.kind],
        false,
      );
    }
    oval(m.light.dx, m.light.dy - .015, .065, .026, const Color(0xFFFFE9AA));
    box(
      m.light.dx - .035,
      m.light.dy - .01,
      .07,
      .1,
      const Color(0xFFB6C9B7),
      radius: 10,
    );
    text('↔', m.light.dx, m.light.dy + .012, font: 19);
    text(
      m.reveal ? '只是小玩具呀，一点也不可怕' : '手电在哪里，影子就跟着变',
      .5,
      .985,
      font: 12,
      color: Colors.white,
    );
  }

  void drawToy(
    ShadowToy toy,
    Offset at,
    double scale,
    Color color,
    bool shadow,
  ) {
    c.save();
    c.translate(at.dx * w, at.dy * h);
    c.scale(scale);
    final paint = Paint()..color = color;
    void ellipse(double x, double y, double rx, double ry) => c.drawOval(
      Rect.fromCenter(
        center: Offset(x * w, y * h),
        width: rx * w * 2,
        height: ry * h * 2,
      ),
      paint,
    );
    if (toy.kind == 2) {
      final path = Path()
        ..moveTo(-w * .08, -h * .07)
        ..quadraticBezierTo(w * .07, h * .08, w * .1, -h * .13)
        ..quadraticBezierTo(w * .02, -h * .015, -w * .08, -h * .07)
        ..close();
      c.drawPath(path, paint);
    } else if (toy.kind == 3) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-w * .07, -h * .14, w * .14, h * .13),
          const Radius.circular(6),
        ),
        paint,
      );
      c.drawOval(
        Rect.fromCenter(center: Offset.zero, width: w * .23, height: h * .035),
        paint,
      );
    } else {
      ellipse(0, -.045, .075, .09);
      ellipse(0, -.13, .074, .065);
      if (toy.kind == 0) {
        ellipse(-.041, -.21, .023, .075);
        ellipse(.041, -.21, .023, .075);
      } else {
        ellipse(-.065, -.177, .032, .034);
        ellipse(.065, -.177, .032, .034);
      }
      ellipse(-.06, .026, .04, .022);
      ellipse(.06, .026, .04, .022);
      if (!shadow) {
        for (final x in [-.025, .025]) {
          c.drawCircle(
            Offset(w * x, -h * .135),
            3,
            Paint()..color = const Color(0xFF414B52),
          );
        }
        c.drawCircle(
          Offset(0, -h * .11),
          2,
          Paint()..color = const Color(0xFF414B52),
        );
      }
    }
    if (toy.hat > 0) {
      final y = toy.kind == 0 ? -.29 : -.21;
      c.drawRect(Rect.fromLTWH(-w * .062, h * y, w * .124, h * .04), paint);
      if (toy.hat == 1) {
        final crown = Path()
          ..moveTo(-w * .06, h * y)
          ..lineTo(-w * .06, h * (y - .045))
          ..lineTo(0, h * (y - .02))
          ..lineTo(w * .06, h * (y - .045))
          ..lineTo(w * .06, h * y)
          ..close();
        c.drawPath(crown, paint);
      } else {
        c.drawCircle(Offset(w * .02, h * (y - .025)), w * .035, paint);
      }
    }
    c.restore();
  }
}
