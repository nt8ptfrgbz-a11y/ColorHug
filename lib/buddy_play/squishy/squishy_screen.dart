import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../buddy_models.dart';
import '../../buddy_widgets.dart';
import '../buddy_play_catalog.dart';
import '../buddy_play_widgets.dart';
import 'squishy_model.dart';

class SquishyScreen extends ToyScreen {
  const SquishyScreen({
    super.key,
    required super.progress,
    required super.audio,
  });
  @override
  State<SquishyScreen> createState() => _SquishyState();
}

class _SquishyState extends ToyState<SquishyScreen, SquishyModel> {
  @override
  BuddyPlay get game => BuddyPlay.squishy;
  @override
  SquishyModel createModel() => SquishyModel();
  @override
  String get invitation => '拉拉边缘，按按肚子。松开手，看它弹回来！';
  @override
  Widget scene(BuildContext context) => ToyCanvas(
    key: const ValueKey('squishy-canvas'),
    painter: _SquishyPainter(model),
    onDown: (p) => act(() => model.down(p), save: false),
    onMove: (p) => act(() => model.move(p), save: false),
    onUp: () => act(model.release),
    onTap: (p) => act(() {
      model.down(p);
      model.release();
    }),
    onCancel: () => act(model.release),
  );
  @override
  CustomPainter previewPainter(SquishyModel snapshot) =>
      _SquishyPainter(snapshot);

  @override
  List<Widget> tools() => [
    for (var i = 0; i < 5; i++)
      ToyTool(
        key: ValueKey('squishy-tool-$i'),
        icon: const ['🤏', '🪶', '🪭', '🌀', '👀'][i],
        label: const ['拉和捏', '挠痒痒', '小扇子', '弹簧垫', '摆五官'][i],
        selected: model.tool == i,
        onTap: () => act(() {
          model.release();
          model.tool = i;
        }, save: false),
      ),
    ToyTool(
      key: const ValueKey('squishy-stamp'),
      icon: '😊',
      label: '表情印章',
      onTap: () => act(model.stamp),
    ),
    ToyTool(
      key: const ValueKey('squishy-color'),
      icon: '🎨',
      label: '换果冻色',
      onTap: () => act(() => model.color = (model.color + 1) % 4),
    ),
    ToyTool(
      key: const ValueKey('squishy-reset'),
      icon: '🍮',
      label: '圆滚滚',
      onTap: () => confirmReset(
        () => model.restore({
          'v': 1,
          'color': model.color,
          'mood': 0,
          'face': [
            [.42, .49],
            [.58, .49],
            [.5, .61],
          ],
        }),
      ),
    ),
  ];
}

class _SquishyPainter extends ToyPainter {
  _SquishyPainter(this.m);
  final SquishyModel m;
  @override
  void paint(Canvas canvas, Size s) {
    start(canvas, s, const Color(0xFFE9F0DF));
    cloud(.16, .15);
    cloud(.83, .12);
    oval(.5, .9, .34, .055, const Color(0xFFCCD9B9));
    final bounce = m.jump > 0
        ? math.sin(motionTime(m.clock) * 10).abs() * m.jump * .025
        : 0.0;
    c.save();
    c.translate(0, -bounce * h);
    final pts = m.points;
    final path = Path();
    final first = (pts.last + pts.first) * .5;
    path.moveTo(first.dx * w, first.dy * h);
    for (var i = 0; i < pts.length; i++) {
      final next = (pts[i] + pts[(i + 1) % pts.length]) * .5;
      path.quadraticBezierTo(
        pts[i].dx * w,
        pts[i].dy * h,
        next.dx * w,
        next.dy * h,
      );
    }
    path.close();
    c.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(buddyColors[m.color], Colors.white, .35)!,
            buddyColors[m.color],
          ],
        ).createShader(Offset.zero & s),
    );
    c.drawPath(
      path,
      Paint()
        ..color = buddyColors[m.color].withValues(alpha: .55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    oval(.37, .33, .046, .026, Colors.white.withValues(alpha: .65));
    for (var i = 0; i < 2; i++) {
      final at = m.face[i];
      oval(at.dx, at.dy, .046, .057, Colors.white);
      oval(at.dx, at.dy + .005, .019, m.mood == 1 ? .006 : .03, buddyInk);
    }
    final mouth = m.face[2];
    oval(
      mouth.dx,
      mouth.dy,
      .052,
      m.mood == 1
          ? .013
          : m.mood == 2
          ? .043
          : .033,
      buddyInk,
    );
    if (m.mood == 0) {
      oval(mouth.dx, mouth.dy + .016, .026, .013, const Color(0xFFF0A6B4));
    }
    if (m.laugh > 0) {
      text('ha ha!', .5, .16, font: 24);
      oval(.33, .59, .034, .02, const Color(0xFFEFB3B3));
      oval(.67, .59, .034, .02, const Color(0xFFEFB3B3));
    }
    if (m.mood == 1) {
      text('z z Z', .77, .3, font: 22, color: const Color(0xFF7F9194));
    }
    c.restore();
    if (m.tool == 3) {
      for (var i = 0; i < 4; i++) {
        line(
          Offset(.35 + i * .09, .92),
          Offset(.39 + i * .09, .95),
          const Color(0xFFB297C9),
          4,
        );
      }
      box(.27, .89, .46, .035, const Color(0xFFB297C9));
    }
    if (m.tool == 4) {
      for (final f in m.face) {
        c.drawCircle(
          p(f.dx, f.dy),
          w * .055,
          Paint()
            ..color = Colors.white.withValues(alpha: .7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
    if (m.finger != null) {
      text(
        const ['🤏', '🪶', '🪭', '🌀', '👀'][m.tool],
        m.finger!.dx,
        m.finger!.dy,
        font: 31,
      );
    }
    text(m.tool == 4 ? '眼睛和嘴巴可以拖动哦' : '软软的，怎么捏都可以', .5, .97, font: 14);
  }
}
