import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../buddy_models.dart';
import '../buddy_play_catalog.dart';
import '../buddy_play_widgets.dart';
import 'salon_model.dart';

class SalonScreen extends ToyScreen {
  const SalonScreen({super.key, required super.progress, required super.audio});
  @override
  State<SalonScreen> createState() => _SalonState();
}

class _SalonState extends ToyState<SalonScreen, SalonModel> {
  @override
  BuddyPlay get game => BuddyPlay.salon;
  @override
  SalonModel createModel() => SalonModel();
  @override
  String get invitation => '选工具，轻轻划过头发。剪短了也能长回来！';
  void touch(Offset p) => act(() => model.touch(p, previous: model.finger));
  @override
  Widget scene(BuildContext context) => ToyCanvas(
    key: const ValueKey('salon-canvas'),
    painter: _SalonPainter(model),
    onTap: touch,
    onDown: touch,
    onMove: touch,
    onUp: () => act(() => model.finger = null),
    onCancel: () => act(() => model.finger = null),
  );
  @override
  CustomPainter previewPainter(SalonModel snapshot) => _SalonPainter(snapshot);

  @override
  List<Widget> tools() => [
    for (var i = 0; i < 4; i++)
      ToyTool(
        key: ValueKey('salon-tool-$i'),
        icon: const ['✂️', '🪮', '💨', '🫧'][i],
        label: const ['剪一剪', '梳一梳', '吹一吹', '长回来'][i],
        selected: model.tool == i,
        onTap: () => act(() => model.tool = i, save: false),
      ),
    ToyTool(
      key: const ValueKey('salon-color'),
      icon: '🎨',
      label: '染头发',
      onTap: () => act(() => model.look.color = (model.look.color + 1) % 4),
    ),
    ToyTool(
      key: const ValueKey('salon-decor'),
      icon: '🎀',
      label: '加装饰',
      onTap: () => act(model.decorate),
    ),
    ToyTool(
      key: const ValueKey('salon-mirror'),
      icon: '🪞',
      label: '照镜子',
      onTap: () => act(model.finish),
    ),
    ToyTool(
      key: const ValueKey('salon-next'),
      icon: '👋',
      label: '下一位',
      onTap: () => act(model.next),
    ),
  ];
}

class _SalonPainter extends ToyPainter {
  _SalonPainter(this.m);
  final SalonModel m;
  static const hairColors = [
    Color(0xFF745782),
    Color(0xFFE9906C),
    Color(0xFF6DA8A6),
    Color(0xFFDFC258),
  ];
  @override
  void paint(Canvas canvas, Size s) {
    start(canvas, s, const Color(0xFFF7E2E8));
    box(.1, .06, .8, .79, const Color(0xFFD9AEBE), radius: 40);
    box(.13, .085, .74, .73, const Color(0xFFECF1E8), radius: 36);
    line(const Offset(.18, .15), const Offset(.3, .12), Colors.white, 5);
    line(const Offset(.18, .19), const Offset(.4, .13), Colors.white, 3);
    box(.16, .77, .68, .15, const Color(0xFFCA8DA3), radius: 28);
    line(
      const Offset(.5, .85),
      const Offset(.5, 1),
      const Color(0xFF8F8B8E),
      12,
    );
    final body = buddyColors[m.guest];
    oval(.5, .66, .23, .23, body);
    oval(.5, .53, .235, .2, body);
    oval(.26, .48, .052, .065, body);
    oval(.74, .48, .052, .065, body);
    final cape = Path()
      ..moveTo(w * .29, h * .66)
      ..quadraticBezierTo(w * .5, h * .73, w * .71, h * .66)
      ..lineTo(w * .79, h * .92)
      ..quadraticBezierTo(w * .5, h * .98, w * .21, h * .92)
      ..close();
    c.drawPath(cape, Paint()..color = const Color(0xFFEDC573));
    for (var i = 0; i < 11; i++) {
      final a = m.root(i), b = m.tip(i);
      final path = Path()
        ..moveTo(a.dx * w, a.dy * h)
        ..quadraticBezierTo(
          (a.dx + m.look.leans[i] * .3) * w,
          (a.dy - m.look.lengths[i] * .5) * h,
          b.dx * w,
          b.dy * h,
        );
      c.drawPath(
        path,
        Paint()
          ..color = hairColors[m.look.color]
          ..strokeWidth = w * .032
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }
    final blink = (motionTime(m.clock) % 4) > 3.8;
    eyes(.5, .51, happy: m.joy > 0 || blink);
    oval(.365, .57, .035, .024, const Color(0x88E99CA5));
    oval(.635, .57, .035, .024, const Color(0x88E99CA5));
    if (m.look.decor > 0) {
      text(const ['', '🎀', '🌸', '🐦'][m.look.decor], .58, .32, font: 39);
    }
    for (final v in m.clippings) {
      line(
        v.at,
        v.at + const Offset(.02, .03),
        hairColors[v.color].withValues(
          alpha: (1 - v.age / 1.6).clamp(0.0, 1.0),
        ),
        5,
      );
    }
    if (m.wind > 0) {
      for (var i = 0; i < 3; i++) {
        line(
          Offset(.08, .32 + i * .06),
          Offset(.22, .29 + i * .06),
          Colors.white,
          4,
        );
      }
    }
    text(
      const ['蓬蓬 · 想试试短发', '卷卷 · 想要歪歪头', '软软 · 喜欢小鸟'][m.guest],
      .5,
      .975,
      font: 13,
    );
    if (m.mirror) {
      box(.2, .04, .6, .09, const Color(0xFFFFF5D9));
      text('I love my hair! ♡', .5, .085, font: 18);
      for (var i = 0; i < 6; i++) {
        sparkle(
          .12 + i * .15,
          .17 + .025 * math.sin(motionTime(m.clock) + i),
          const Color(0xFFD5B54F),
        );
      }
    }
    if (m.finger != null) {
      text(
        const ['✂️', '🪮', '💨', '🫧'][m.tool],
        m.finger!.dx,
        m.finger!.dy,
        font: 38,
      );
    }
  }
}
