import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../buddy_play_catalog.dart';
import '../buddy_play_widgets.dart';
import 'delivery_model.dart';

class DeliveryScreen extends ToyScreen {
  const DeliveryScreen({
    super.key,
    required super.progress,
    required super.audio,
  });
  @override
  State<DeliveryScreen> createState() => _DeliveryState();
}

class _DeliveryState extends ToyState<DeliveryScreen, DeliveryModel> {
  @override
  BuddyPlay get game => BuddyPlay.delivery;
  @override
  DeliveryModel createModel() => DeliveryModel();
  @override
  String get invitation => switch (model.stage) {
    DeliveryStage.loading => '看门牌，把朋友的包裹装上车。',
    DeliveryStage.driving => '按住开车，松手停。路上可以洗车、坐船、看开桥！',
    DeliveryStage.doorstep => '到朋友家啦！把盒子拖给朋友，也可以点送包裹。',
    _ => '礼物留下来啦！点点它，再去看看别的朋友。',
  };
  Offset? finger;
  int? package;
  void down(Offset p) {
    finger = p;
    if (model.stage == DeliveryStage.loading) {
      package = (p.dx * 3).floor().clamp(0, 2);
    }
  }

  void up() {
    if (finger != null) {
      if (model.stage == DeliveryStage.loading &&
          finger!.dy > .4 &&
          package != null) {
        model.load(package!);
      } else if (model.stage == DeliveryStage.doorstep && finger!.dy < .75) {
        model.deliver();
      }
    }
    finger = null;
    package = null;
  }

  @override
  Widget scene(BuildContext context) => ToyCanvas(
    key: const ValueKey('delivery-canvas'),
    painter: _DeliveryPainter(model, finger),
    onDown: (p) => act(() => down(p), save: false),
    onMove: (p) => act(() => finger = p, save: false),
    onUp: () => act(up),
    onCancel: () => act(() {
      finger = null;
      package = null;
    }, save: false),
    onTap: (p) => act(() {
      if (model.stage == DeliveryStage.loading) {
        model.load((p.dx * 3).floor().clamp(0, 2));
      } else if (model.stage == DeliveryStage.doorstep) {
        model.deliver();
      } else if (model.stage == DeliveryStage.home) {
        model.playGift();
      } else if (model.obstacle == 'wash') {
        model.wash();
      } else {
        model.honk();
      }
    }),
  );
  @override
  CustomPainter previewPainter(DeliveryModel snapshot) =>
      _DeliveryPainter(snapshot, null);

  @override
  List<Widget> tools() => [
    if (model.stage == DeliveryStage.loading)
      for (var i = 0; i < 3; i++)
        ToyTool(
          key: ValueKey('delivery-box-$i'),
          icon: const ['🦒', '🐷', '🐧'][i],
          label: '装包裹',
          onTap: () => act(() => model.load(i)),
        ),
    if (model.stage == DeliveryStage.driving) ...[
      Listener(
        onPointerDown: (_) => act(() => model.drive(true), save: false),
        onPointerUp: (_) => act(() => model.drive(false), save: false),
        onPointerCancel: (_) => act(() => model.drive(false), save: false),
        child: ToyTool(
          key: const ValueKey('delivery-hold'),
          icon: '🚚',
          label: '按住开车',
          selected: model.driving,
          onTap: () {},
        ),
      ),
      ToyTool(
        key: const ValueKey('delivery-drive'),
        icon: model.driving ? '⏸️' : '▶️',
        label: model.driving ? '停下来' : '自动开车',
        onTap: () => act(() => model.drive(!model.driving), save: false),
      ),
      ToyTool(
        key: const ValueKey('delivery-wash'),
        icon: '🫧',
        label: '刷刷洗车',
        onTap: model.obstacle == 'wash'
            ? () => act(model.wash, save: false)
            : null,
      ),
      ToyTool(
        key: const ValueKey('delivery-boat'),
        icon: '⛵',
        label: '坐渡船',
        onTap: model.obstacle == 'boat'
            ? () => act(model.sail, save: false)
            : null,
      ),
      ToyTool(
        key: const ValueKey('delivery-bridge'),
        icon: '🌉',
        label: '开合小桥',
        onTap: model.obstacle == 'bridge'
            ? () => act(model.liftBridge, save: false)
            : null,
      ),
      ToyTool(
        key: const ValueKey('delivery-horn'),
        icon: '📯',
        label: '嘀嘀',
        onTap: () => act(model.honk, save: false),
      ),
    ],
    if (model.stage == DeliveryStage.doorstep)
      ToyTool(
        key: const ValueKey('delivery-deliver'),
        icon: '📦',
        label: '送包裹',
        onTap: () => act(model.deliver),
      ),
    if (model.stage == DeliveryStage.home) ...[
      ToyTool(
        key: const ValueKey('delivery-gift'),
        icon: '🎁',
        label: '玩礼物',
        onTap: () => act(model.playGift),
      ),
      ToyTool(
        key: const ValueKey('delivery-next'),
        icon: '🚚',
        label: '下一单',
        onTap: () => act(model.next),
      ),
    ],
    for (var i = 0; i < 3; i++)
      if (model.gifts[i])
        ToyTool(
          key: ValueKey('delivery-visit-$i'),
          icon: const ['🦒', '🐷', '🐧'][i],
          label: '去串门',
          onTap: () => act(() => model.visit(i)),
        ),
    ToyTool(
      icon: '🎨',
      label: '换车色',
      onTap: () => act(() => model.paint = (model.paint + 1) % 4),
    ),
  ];
}

class _DeliveryPainter extends ToyPainter {
  _DeliveryPainter(this.m, this.finger);
  final DeliveryModel m;
  final Offset? finger;
  @override
  void paint(Canvas canvas, Size s) {
    start(canvas, s, const Color(0xFFF6E9D5));
    final atHome =
        m.stage == DeliveryStage.home ||
        m.stage == DeliveryStage.opening ||
        m.stage == DeliveryStage.doorstep;
    if (atHome) {
      box(.09, .13, .82, .69, const Color(0xFFEBCC9C), radius: 30);
      box(.13, .18, .74, .59, const Color(0xFFFFF5E4));
      box(.13, .7, .74, .15, const Color(0xFFD3B990));
      text(const ['🦒', '🐷', '🐧'][m.guest], .5, .48, font: 85);
      text(const ['长颈鹿的小家', '小猪的小家', '企鹅的小家'][m.guest], .5, .09, font: 17);
      if (m.stage == DeliveryStage.doorstep) text('📦 → 🎁', .5, .83, font: 43);
      if (m.stage == DeliveryStage.opening) {
        text('📦', .5, .76, font: 48);
        text('✨', .5, .67 - m.opening * .3, font: 40);
      }
      if (m.stage == DeliveryStage.home) {
        if (m.guest == 0) {
          final path = Path()
            ..moveTo(w * .46, h * .45)
            ..cubicTo(
              w * .8,
              h * .5,
              w * .15,
              h * .7,
              w * .65,
              h * (.79 + math.sin(motionTime(m.clock) * 3) * .03),
            );
          c.drawPath(
            path,
            Paint()
              ..color = const Color(0xFFE88282)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 12
              ..strokeCap = StrokeCap.round,
          );
        }
        if (m.guest == 1) {
          box(
            .27,
            .77 -
                (m.reaction > 0
                    ? math.sin(motionTime(m.clock) * 8).abs() * .15
                    : 0),
            .46,
            .1,
            const Color(0xFFC3AEDC),
            radius: 28,
          );
          text(
            '☁️',
            .5,
            .81 -
                (m.reaction > 0
                    ? math.sin(motionTime(m.clock) * 8).abs() * .15
                    : 0),
            font: 24,
          );
        }
        if (m.guest == 2) {
          box(.63, .68, .18, .15, const Color(0xFF9CBBD0));
          text('❄️', .72, .74, font: 26);
          if (m.reaction > 0) {
            for (var i = 0; i < 18; i++) {
              text(
                '❄',
                .17 + (i * .133 % .65),
                .2 + ((motionTime(m.clock) * .15 + i * .073) % .48),
                font: 15,
                color: Colors.white,
              );
            }
          }
        }
        text(m.reaction > 0 ? 'Thank you!' : '点点礼物，一起玩', .5, .94, font: 19);
      }
    } else {
      box(0, .74, 1, .26, const Color(0xFFCFD8B4));
      box(0, .78, 1, .14, const Color(0xFFB4AAA0));
      for (var i = 0; i < 7; i++) {
        final x = (i * .2 - m.distance * 3) % 1.3 - .1;
        box(x, .85, .1, .015, Colors.white, radius: 2);
        cloud((x + .4) % 1, .12);
      }
      for (var i = 0; i < 4; i++) {
        final x = (i * .34 - m.distance * 1.2) % 1.4 - .2;
        box(x, .4, .18, .3, const Color(0xFFDBB78B));
        box(x + .035, .45, .06, .08, const Color(0xFFF9E7B7));
      }
      if (m.obstacle == 'boat') {
        box(.0, .76, 1, .2, const Color(0xFF81BDCE));
        oval(.46, .88, .32, .07, const Color(0xFFB79169));
        text('⛵', .8 - m.boat * .6, .6, font: 37);
      }
      if (m.obstacle == 'bridge') {
        box(.55, .76, .45, .2, const Color(0xFF81BDCE));
        final lift = math.sin(m.bridge * math.pi) * .25;
        line(
          const Offset(.56, .78),
          Offset(.88, .78 - lift),
          const Color(0xFFC3915B),
          14,
        );
        text('⛵', .95 - m.bridge * .35, .87, font: 31);
      }
      if (m.obstacle == 'wash') {
        box(.2, .36, .57, .1, const Color(0xFFA5C9BE));
        box(.2, .37, .05, .45, const Color(0xFFA5C9BE));
        box(.72, .37, .05, .45, const Color(0xFFA5C9BE));
        text('WASH', .49, .405, font: 16);
      }
      final bob = m.driving && m.obstacle.isEmpty
          ? math.sin(motionTime(m.clock) * 13) * .007
          : 0.0;
      box(
        .28,
        .55 + bob,
        .35,
        .23,
        const [
          Color(0xFFE7A16E),
          Color(0xFF8DBFC7),
          Color(0xFFCCAAD8),
          Color(0xFFAEC47B),
        ][m.paint],
      );
      box(.63, .61 + bob, .14, .17, const Color(0xFFE7A16E));
      box(.65, .62 + bob, .1, .065, const Color(0xFFD5EDF0));
      oval(.36, .8, .06, .06, const Color(0xFF53636A));
      oval(.68, .8, .06, .06, const Color(0xFF53636A));
      oval(.36, .8, .025, .026, const Color(0xFFE7D6B7));
      oval(.68, .8, .025, .026, const Color(0xFFE7D6B7));
      if (m.stage != DeliveryStage.loading) text('📦', .46, .66, font: 30);
      for (var i = 0; i < (m.dirt * 9).ceil(); i++) {
        oval(
          .3 + (i * .053 % .3),
          .6 + (i * .047 % .12),
          .016,
          .015,
          const Color(0xFFA18973),
        );
      }
      if (m.obstacle == 'wash' && m.dirt < 1) {
        for (var i = 0; i < 12; i++) {
          oval(
            .24 + (i * .073 % .5),
            .5 + (i * .031 % .28),
            .02,
            .026,
            Colors.white.withValues(alpha: .65),
          );
        }
      }
      if (m.stage == DeliveryStage.loading) {
        for (var i = 0; i < 3; i++) {
          text('📦', .17 + i * .33, .3, font: 43);
          text(const ['🦒', '🐷', '🐧'][i], .17 + i * .33, .3, font: 20);
        }
        text('这次送给 ${const ['🦒', '🐷', '🐧'][m.guest]}', .5, .08, font: 20);
      } else {
        text(
          switch (m.obstacle) {
            'wash' => '洗车房：点泡泡刷干净',
            'boat' => '渡船：点小船一起过河',
            'bridge' => '让小船先过桥',
            _ => '按住开车 · 松手停',
          },
          .5,
          .98,
          font: 14,
        );
      }
      if (m.reaction > 0) text('🐦 ♪', .8, .27, font: 28);
    }
    if (finger != null) text('📦', finger!.dx, finger!.dy, font: 37);
  }
}
