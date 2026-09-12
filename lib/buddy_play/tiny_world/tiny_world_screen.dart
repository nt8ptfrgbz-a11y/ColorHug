import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../buddy_play_catalog.dart';
import '../buddy_play_widgets.dart';
import 'tiny_world_model.dart';

class TinyWorldScreen extends ToyScreen {
  const TinyWorldScreen({
    super.key,
    required super.progress,
    required super.audio,
  });
  @override
  State<TinyWorldScreen> createState() => _WorldState();
}

class _WorldState extends ToyState<TinyWorldScreen, TinyWorldModel> {
  @override
  BuddyPlay get game => BuddyPlay.tinyWorld;
  @override
  TinyWorldModel createModel() => TinyWorldModel();
  @override
  String get invitation => '划小路，摆小家。河上放铅笔桥，朋友就能过去啦！';
  int? lastCell, movingCell;
  Offset? finger;
  void touch(Offset p) {
    final cell = worldCell(p);
    finger = p;
    if (cell != lastCell) {
      lastCell = cell;
      model.touch(cell);
    }
  }

  @override
  Widget scene(BuildContext context) => ToyCanvas(
    key: const ValueKey('world-canvas'),
    painter: _WorldPainter(model, finger),
    onTap: (p) => act(() {
      lastCell = null;
      touch(p);
      finger = null;
      lastCell = null;
    }),
    onDown: (p) => act(() {
      lastCell = null;
      finger = p;
      movingCell =
          model.tool >= 2 &&
              model.tool < 8 &&
              model.objectAt(worldCell(p)) != null
          ? worldCell(p)
          : null;
      if (model.tool < 2 || model.tool == 8) touch(p);
    }, save: false),
    onMove: (p) => act(() {
      if (model.tool < 2 || model.tool == 8) {
        touch(p);
      } else {
        finger = p;
      }
    }, save: false),
    onUp: () => act(() {
      if (finger != null && model.tool >= 2 && model.tool < 8) {
        if (movingCell != null) {
          model.moveObject(movingCell!, worldCell(finger!));
        } else {
          model.touch(worldCell(finger!));
        }
      }
      movingCell = null;
      lastCell = null;
      finger = null;
    }),
    onCancel: () => act(() {
      lastCell = null;
      finger = null;
    }),
  );
  @override
  CustomPainter previewPainter(TinyWorldModel snapshot) =>
      _WorldPainter(snapshot, null);

  @override
  List<Widget> tools() => [
    for (var i = 0; i < 9; i++)
      ToyTool(
        key: ValueKey('world-tool-$i'),
        icon: const ['🛤️', '💧', '🍃', '✏️', '☕', '🍪', '🌸', '🛏️', '🧺'][i],
        label: const [
          '画小路',
          '压池塘',
          '叶子棚',
          '铅笔桥',
          '茶杯屋',
          '饼干',
          '花朵',
          '休息垫',
          '收起来',
        ][i],
        selected: model.tool == i,
        onTap: () => act(() => model.tool = i, save: false),
      ),
    ToyTool(
      key: const ValueKey('world-rain'),
      icon: model.rain ? '🌤️' : '🌧️',
      label: model.rain ? '出太阳' : '下点雨',
      onTap: () => act(model.toggleRain),
    ),
    ToyTool(
      key: const ValueKey('world-next'),
      icon: '🏕️',
      label: '换小世界',
      onTap: () => confirmReset(() => model.preset((model.scene + 1) % 3)),
    ),
  ];
}

class _WorldPainter extends ToyPainter {
  _WorldPainter(this.m, this.finger);
  final TinyWorldModel m;
  final Offset? finger;
  @override
  void paint(Canvas canvas, Size s) {
    start(canvas, s, const Color(0xFFD4E3B6));
    for (var i = 0; i < 80; i++) {
      final x = (i % 10) / 10, y = (i ~/ 10) / 8;
      if (m.ground[i] == 2) {
        box(x, y, .101, .126, const Color(0xFF8DC9D2), radius: 5);
        line(
          Offset(x + .02, y + .055),
          Offset(
            x + .07,
            y + .055 + math.sin(motionTime(m.clock) * 2 + i) * .008,
          ),
          const Color(0xFFAADFE4),
          2,
        );
      } else if (m.ground[i] == 1) {
        box(x + .002, y + .015, .096, .095, const Color(0xFFEBD7B0), radius: 8);
      } else {
        line(
          Offset(x + .075, y + .09),
          Offset(x + .07, y + .075),
          const Color(0xFFACC68D),
          1,
        );
        line(
          Offset(x + .075, y + .09),
          Offset(x + .082, y + .07),
          const Color(0xFFACC68D),
          1,
        );
      }
    }
    for (final o in m.objects) {
      final at = cellCenter(o.cell);
      oval(at.dx, at.dy + .035, .042, .024, const Color(0x20344D55));
      switch (o.kind) {
        case 0:
          line(
            at + const Offset(-.035, .03),
            at + const Offset(0, -.065),
            const Color(0xFF8E9F60),
            4,
          );
          oval(at.dx, at.dy - .04, .065, .045, const Color(0xFF7EAD70));
          line(
            at + const Offset(-.045, -.045),
            at + const Offset(.04, -.025),
            const Color(0xFFB6CF8C),
            2,
          );
        case 1:
          box(
            at.dx - .058,
            at.dy - .024,
            .116,
            .048,
            const Color(0xFFECC75E),
            radius: 4,
          );
          line(
            at + const Offset(-.05, -.012),
            at + const Offset(.045, -.012),
            const Color(0xFFFFE49B),
            3,
          );
          text('✎', at.dx, at.dy, font: 22);
        case 2:
          box(
            at.dx - .046,
            at.dy - .049,
            .09,
            .09,
            const Color(0xFFF6EFE0),
            radius: 12,
          );
          oval(at.dx + .05, at.dy - .012, .025, .029, const Color(0xFFF6EFE0));
          oval(at.dx + .05, at.dy - .012, .013, .016, const Color(0xFFD4E3B6));
          oval(at.dx, at.dy - .049, .044, .015, const Color(0xFFE9C9C1));
          box(
            at.dx - .012,
            at.dy + .008,
            .024,
            .036,
            const Color(0xFF9EB7AF),
            radius: 9,
          );
        case 3:
          oval(at.dx, at.dy, .043, .048, const Color(0xFFD9A66E));
          for (var j = 0; j < 5 - o.bites; j++) {
            oval(
              at.dx + math.cos(j * 1.6) * .025,
              at.dy + math.sin(j * 1.6) * .028,
              .007,
              .008,
              const Color(0xFF8E694D),
            );
          }
          if (o.bites == 5) text('↻', at.dx, at.dy, font: 21);
        case 4:
          text('🌸', at.dx, at.dy - .015, font: 30);
        case 5:
          box(
            at.dx - .045,
            at.dy - .02,
            .09,
            .055,
            const Color(0xFFBCA8D6),
            radius: 12,
          );
          box(
            at.dx - .038,
            at.dy - .012,
            .03,
            .026,
            const Color(0xFFE8DCEB),
            radius: 8,
          );
      }
    }
    for (final a in m.animals) {
      var at = a.position;
      if (a.carrying) text('🍪', at.dx + .025, at.dy, font: 13);
      if (a.using) {
        at += Offset(0, math.sin(motionTime(m.clock) * 4 + a.kind) * .006);
      }
      oval(at.dx, at.dy + .038, .026, .014, const Color(0x22344D55));
      text(const ['🐰', '🐻', '🐥'][a.kind], at.dx, at.dy, font: 26);
      if (a.carrying) text('🍪', at.dx + .025, at.dy, font: 13);
      if (a.using) {
        final object = m.objectAt(a.target ?? -1);
        text(
          object?.kind == 3
              ? '🍪'
              : object?.kind == 5
              ? 'z'
              : m.rain
              ? '♡'
              : '♪',
          at.dx + .025,
          at.dy - .05,
          font: 16,
        );
      }
    }
    if (m.rain) {
      for (var i = 0; i < 40; i++) {
        final x = (i * .137) % 1,
            y = (motionTime(m.clock) * .34 + i * .091) % 1;
        line(
          Offset(x, y),
          Offset(x - .013, y + .034),
          const Color(0x7793AEBE),
          2,
        );
      }
    }
    if (finger != null) {
      final at = cellCenter(worldCell(finger!));
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: p(at.dx, at.dy),
            width: w * .1,
            height: h * .125,
          ),
          const Radius.circular(8),
        ),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }
}
