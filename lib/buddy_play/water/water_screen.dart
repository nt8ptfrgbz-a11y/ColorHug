import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../buddy_play_catalog.dart';
import '../buddy_play_widgets.dart';
import 'water_model.dart';

class WaterScreen extends ToyScreen {
  const WaterScreen({super.key, required super.progress, required super.audio});
  @override
  State<WaterScreen> createState() => _WaterState();
}

class _WaterState extends ToyState<WaterScreen, WaterModel> {
  @override
  BuddyPlay get game => BuddyPlay.water;
  @override
  WaterModel createModel() => WaterModel();
  @override
  String get invitation => '点水管转一转。装满水，再拔塞子送小鸭下滑梯！';
  void touch(Offset p) {
    if (p.dy < .17) {
      model.faucet();
    } else if (p.dy < .43) {
      model.tapPipe(((p.dx - .12) / .27).round().clamp(0, 2));
    } else if (p.dx < .5 && p.dy < .7) {
      model.togglePlug();
    } else if (p.dy > .7) {
      model.releaseDuck();
    }
  }

  @override
  Widget scene(BuildContext context) => ToyCanvas(
    key: const ValueKey('water-canvas'),
    painter: _WaterPainter(model),
    onTap: (p) => act(() => touch(p)),
  );
  @override
  CustomPainter previewPainter(WaterModel snapshot) => _WaterPainter(snapshot);

  @override
  List<Widget> tools() => [
    ToyTool(
      key: const ValueKey('water-tap'),
      icon: '🚰',
      label: model.running ? '关水' : '开水',
      selected: model.running,
      onTap: () => act(model.faucet, save: false),
    ),
    for (var i = 0; i < 3; i++)
      ToyTool(
        key: ValueKey('water-pipe-$i'),
        icon: '🔄',
        label: '水管 ${i + 1}',
        onTap: () => act(() => model.tapPipe(i)),
      ),
    ToyTool(
      key: const ValueKey('water-gate'),
      icon: model.gate ? '🔓' : '🔒',
      label: model.gate ? '关闸门' : '开闸门',
      onTap: () => act(model.toggleGate),
    ),
    ToyTool(
      key: const ValueKey('water-plug'),
      icon: '🛁',
      label: model.plug ? '拔塞子' : '塞起来',
      selected: !model.plug,
      onTap: () => act(model.togglePlug),
    ),
    ToyTool(
      key: const ValueKey('water-duck'),
      icon: '🦆',
      label: '放小鸭',
      onTap: () => act(model.releaseDuck, save: false),
    ),
    ToyTool(
      key: const ValueKey('water-next'),
      icon: '🏞️',
      label: '换水桌',
      onTap: () => confirmReset(() => model.preset((model.scene + 1) % 3)),
    ),
  ];
}

class _WaterPainter extends ToyPainter {
  _WaterPainter(this.m);
  final WaterModel m;
  static const blue = Color(0xFF51B3D5), pipe = Color(0xFF8DB6BD);
  @override
  void paint(Canvas canvas, Size s) {
    start(canvas, s, const Color(0xFFDFF0F2));
    cloud(.8, .08);
    box(.04, .9, .92, .1, const Color(0xFFC0DDC3));
    line(const Offset(.12, 0), const Offset(.12, .15), pipe, 18);
    line(
      const Offset(.12, .15),
      const Offset(.12, .22),
      m.supply ? blue : pipe,
      12,
    );
    text('🚰', .12, .11, font: 35);
    text(m.running ? 'water' : '点点开水', .48, .09, font: 16);
    final target = m.target;
    for (var i = 0; i < 3; i++) {
      final x = .12 + i * .27;
      box(x - .085, .22, .17, .18, Colors.white, radius: 18);
      final rotation = m.pipes[i] - target[i];
      c.save();
      c.translate(x * w, .31 * h);
      c.rotate(rotation * math.pi / 2);
      final path = Path()
        ..moveTo(-w * .07, 0)
        ..lineTo(0, 0)
        ..lineTo(0, h * .07);
      c.drawPath(
        path,
        Paint()
          ..color = pipe
          ..strokeWidth = 18
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
      if (m.supply && m.connected > i) {
        c.drawPath(
          path,
          Paint()
            ..color = blue
            ..strokeWidth = 9
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke,
        );
      }
      c.restore();
      if (i < 2) {
        line(
          Offset(x, .4),
          Offset(x + .27, .31),
          m.supply && m.connected > i ? blue : pipe,
          8,
        );
      }
      text('${i + 1}', x, .2, font: 12);
      if (m.supply && m.connected == i) {
        for (var j = 0; j < 4; j++) {
          oval(
            x + .06,
            .41 + ((motionTime(m.clock) * .3 + j * .04) % .13),
            .009,
            .014,
            blue,
          );
        }
      }
    }
    line(
      const Offset(.66, .4),
      const Offset(.39, .47),
      m.reachesTank ? blue : pipe,
      9,
    );
    box(.07, .45, .4, .23, const Color(0xFF98BEC6));
    box(.09, .46, .36, .2, const Color(0xFFEEF8F7));
    if (m.tank > 0) {
      box(
        .09,
        .66 - .19 * m.tank,
        .36,
        .19 * m.tank,
        blue.withValues(alpha: .75),
        radius: 4,
      );
    }
    text(
      m.tank > .98
          ? 'full'
          : m.tank < .01
          ? 'empty'
          : 'water',
      .27,
      .5,
      font: 15,
    );
    oval(
      .39,
      .66,
      .037,
      .027,
      m.plug ? const Color(0xFFE8A478) : const Color(0xFF4B7A85),
    );
    line(
      const Offset(.39, .69),
      const Offset(.64, .6),
      m.outflow > 0 ? blue : pipe,
      9,
    );
    c.save();
    c.translate(w * .67, h * .59);
    c.rotate(m.wheel);
    for (var i = 0; i < 8; i++) {
      c.rotate(math.pi / 4);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-5, -h * .105, 10, h * .105),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFFD8AF6F),
      );
    }
    c.restore();
    oval(.67, .59, .025, .035, const Color(0xFF997D51));
    line(
      const Offset(.69, .7),
      const Offset(.83, .73),
      m.outflow > 0 ? blue : pipe,
      8,
    );
    c.save();
    c.translate(w * .84, h * .77);
    if (m.tip > 0) c.rotate(.8);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-w * .09, -h * .06, w * .18, h * .12),
        const Radius.circular(10),
      ),
      Paint()..color = const Color(0xFFE7BD79),
    );
    c.drawRect(
      Rect.fromLTWH(
        -w * .07,
        h * (.04 - .08 * m.bucket),
        w * .14,
        h * .08 * m.bucket,
      ),
      Paint()..color = blue,
    );
    c.restore();
    line(
      const Offset(.82, .83),
      const Offset(.35, .91),
      const Color(0xFF83BDD1),
      13,
    );
    oval(.25, .93, .2, .045, blue.withValues(alpha: .55));
    if (m.tip > 0) {
      for (var i = 0; i < 7; i++) {
        oval(
          .7 - i * .05,
          .85 + math.sin(i + motionTime(m.clock) * 7) * .02,
          .012,
          .016,
          blue,
        );
      }
    }
    if (m.duckMoving || m.duck > 0) {
      final q = m.duck < .41
          ? Offset.lerp(
              const Offset(.39, .68),
              const Offset(.82, .77),
              m.duck / .41,
            )!
          : Offset.lerp(
              const Offset(.82, .77),
              const Offset(.22, .91),
              (m.duck - .41) / .59,
            )!;
      text('🦆', q.dx, q.dy - .035, font: 28);
    } else {
      text('🦆 点我', .22, .84, font: 22);
    }
    text(const ['水车与小瀑布', '弯弯水路', '鸭子漂流记'][m.scene], .5, .98, font: 13);
  }
}
