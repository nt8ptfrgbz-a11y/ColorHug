import 'package:flutter/material.dart';
import '../buddy_play_catalog.dart';
import '../buddy_play_widgets.dart';
import 'rolling_model.dart';

class RollingScreen extends ToyScreen {
  const RollingScreen({
    super.key,
    required super.progress,
    required super.audio,
  });
  @override
  State<RollingScreen> createState() => _RollingState();
}

class _RollingState extends ToyState<RollingScreen, RollingModel> {
  @override
  BuddyPlay get game => BuddyPlay.rolling;
  @override
  RollingModel createModel() => RollingModel();
  int selected = 0;
  Offset? finger;
  @override
  String get invitation => '选个机关，点轨道上的大圆圈。再放一颗球！';
  void place(Offset p) {
    final pts = rollingPoints(model.scene, model.right);
    var nearest = 0;
    var dist = 2.0;
    for (var i = 0; i < 3; i++) {
      final d = (pts[i + 1] - p).distance;
      if (d < dist) {
        dist = d;
        nearest = i;
      }
    }
    if (dist < .18) {
      model.setPart(nearest, selected);
    } else if (p.dy > .69) {
      model.rescue();
    } else if (p.dy < .2) {
      model.launch();
    }
  }

  @override
  Widget scene(BuildContext context) => ToyCanvas(
    key: const ValueKey('rolling-canvas'),
    painter: _RollingPainter(model, finger, selected),
    onTap: (p) => act(() => place(p)),
    onDown: (p) => act(() => finger = p, save: false),
    onMove: (p) => act(() => finger = p, save: false),
    onUp: () => act(() {
      if (finger != null) place(finger!);
      finger = null;
    }),
    onCancel: () => act(() => finger = null, save: false),
  );
  @override
  CustomPainter previewPainter(RollingModel snapshot) =>
      _RollingPainter(snapshot, null, 0);

  @override
  List<Widget> tools() => [
    for (var i = 0; i < 5; i++)
      ToyTool(
        key: ValueKey('rolling-part-$i'),
        icon: const ['🪇', '🐘', '🦆', '↔️', '🔔'][i],
        label: const ['跳床', '变大洞', '鸭子洞', '岔路', '铃铛'][i],
        selected: selected == i,
        onTap: () => act(() => selected = i, save: false),
      ),
    ToyTool(
      key: const ValueKey('rolling-launch'),
      icon: '🔴',
      label: '放小球',
      onTap: () => act(model.launch, save: false),
    ),
    ToyTool(
      key: const ValueKey('rolling-fork'),
      icon: model.right ? '➡️' : '⬅️',
      label: '换方向',
      onTap: () => act(() => model.right = !model.right),
    ),
    ToyTool(
      key: const ValueKey('rolling-rescue'),
      icon: '🤧',
      label: '打喷嚏',
      onTap: () => act(model.rescue, save: false),
    ),
    ToyTool(
      key: const ValueKey('rolling-pause'),
      icon: model.paused ? '▶️' : '⏸️',
      label: model.paused ? '继续滚' : '停一下',
      onTap: () => act(() {
        model.paused = !model.paused;
        model.event(
          model.paused ? 'stop' : 'go',
          model.paused ? '小球休息一下' : '继续出发',
        );
      }, save: false),
    ),
    ToyTool(
      icon: const ['🔴', '🔵', '🟡'][model.ballStyle],
      label: '换小球',
      onTap: () => act(() => model.ballStyle = (model.ballStyle + 1) % 3),
    ),
    ToyTool(
      key: const ValueKey('rolling-next'),
      icon: '🎢',
      label: '换滑道',
      onTap: () => confirmReset(() => model.preset((model.scene + 1) % 3)),
    ),
  ];
}

class _RollingPainter extends ToyPainter {
  _RollingPainter(this.m, this.finger, this.selected);
  final RollingModel m;
  final Offset? finger;
  final int selected;
  static const colors = [
    Color(0xFFE98976),
    Color(0xFF70B5D2),
    Color(0xFFEFC464),
  ];
  @override
  void paint(Canvas canvas, Size s) {
    start(canvas, s, const Color(0xFFFBEDD3));
    cloud(.2, .07);
    cloud(.85, .1);
    box(.03, .92, .94, .08, const Color(0xFFD8C5A4));
    for (final right in [true, false]) {
      final pts = rollingPoints(m.scene, right);
      for (var i = 0; i < 4; i++) {
        line(
          pts[i] + const Offset(0, .03),
          pts[i + 1] + const Offset(0, .03),
          const Color(0xFFB59D77),
          14,
        );
        line(pts[i], pts[i + 1], const Color(0xFFEFCA80), 11);
        line(
          Offset(pts[i + 1].dx, pts[i + 1].dy + .06),
          Offset(pts[i + 1].dx, .93),
          const Color(0xFFD8C5A4),
          7,
        );
      }
      final end = pts.last;
      box(
        end.dx - .1,
        .87,
        .2,
        .1,
        right ? const Color(0xFF9FC6B2) : const Color(0xFFD5ADD0),
      );
      text(right ? '⭐' : '♡', end.dx, .92, font: 24);
    }
    final pts = rollingPoints(m.scene, m.right);
    for (var i = 0; i < 3; i++) {
      final at = pts[i + 1];
      oval(at.dx, at.dy, .1, .095, Colors.white.withValues(alpha: .9));
      oval(at.dx, at.dy, .082, .075, const Color(0xFFF0DDB5));
      text(
        const ['↟', 'BIG', '🦆', '↔', '🔔'][m.parts[i]],
        at.dx,
        at.dy,
        font: m.parts[i] == 1 ? 16 : 30,
      );
    }
    text('放球 ↓', pts.first.dx, .06, font: 14);
    for (final b in m.balls) {
      final at = b.position;
      final r = b.big ? .064 : .038;
      oval(at.dx, at.dy + .045, r, .018, const Color(0x22344D55));
      oval(at.dx, at.dy, r, r * w / h, colors[b.style]);
      oval(
        at.dx - .012,
        at.dy - .015,
        .01,
        .012,
        Colors.white.withValues(alpha: .7),
      );
      if (b.duck) text('🦆', at.dx, at.dy, font: 26);
      if (b.stuck) text('🤧 点我', at.dx, at.dy - .1, font: 16);
    }
    if (m.balls.isEmpty) {
      text(m.landed > 0 ? '到家啦！换个机关再试试' : '小球准备好啦', .5, .79, font: 15);
    }
    if (finger != null) {
      text(
        const ['🪇', '🐘', '🦆', '↔️', '🔔'][selected],
        finger!.dx,
        finger!.dy,
        font: 38,
      );
    }
  }
}
