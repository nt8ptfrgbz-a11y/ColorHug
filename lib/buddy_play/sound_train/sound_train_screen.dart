import 'package:flutter/material.dart';
import '../buddy_play_catalog.dart';
import '../buddy_play_widgets.dart';
import 'sound_train_model.dart';

class SoundTrainScreen extends ToyScreen {
  const SoundTrainScreen({
    super.key,
    required super.progress,
    required super.audio,
  });
  @override
  State<SoundTrainScreen> createState() => _TrainState();
}

class _TrainState extends ToyState<SoundTrainScreen, SoundTrainModel> {
  @override
  BuddyPlay get game => BuddyPlay.soundTrain;
  @override
  SoundTrainModel createModel() => SoundTrainModel();
  int? from;
  Offset? finger;
  int? exchange;
  @override
  String get invitation => '选声音，点车厢装进去。拖动车厢换顺序，再发车！';
  int carAt(Offset p) =>
      (p.dx * model.cars.length).floor().clamp(0, model.cars.length - 1);
  void stopAudio() {
    widget.audio.stopEffects();
  }

  @override
  Widget scene(BuildContext context) => ToyCanvas(
    key: const ValueKey('train-canvas'),
    painter: _TrainPainter(model, finger, from, exchange),
    onTap: (p) => act(() {
      if (model.playing) return;
      final i = carAt(p);
      if (exchange != null) {
        model.swap(exchange!, i);
        exchange = null;
      } else {
        model.setCar(i);
      }
      stopAudio();
    }),
    onDown: (p) => act(() {
      if (model.playing) return;
      from = carAt(p);
      finger = p;
    }, save: false),
    onMove: (p) => act(() => finger = p, save: false),
    onUp: () => act(() {
      if (from != null && finger != null) {
        model.swap(from!, carAt(finger!));
        stopAudio();
      }
      from = null;
      finger = null;
    }),
    onCancel: () => act(() {
      from = null;
      finger = null;
    }, save: false),
  );
  @override
  CustomPainter previewPainter(SoundTrainModel snapshot) =>
      _TrainPainter(snapshot, null, null, null);

  @override
  List<Widget> tools() => [
    for (var i = 0; i < 4; i++)
      ToyTool(
        key: ValueKey('train-sound-$i'),
        icon: const ['🐸', '🥁', '🐱', '🔔'][i],
        label: const ['呱呱', '咚咚', '喵喵', '叮叮'][i],
        selected: model.selected == i,
        onTap: () => act(() {
          model.stop();
          model.choose(i);
        }, save: false),
      ),
    ToyTool(
      key: const ValueKey('train-add'),
      icon: '➕',
      label: '加车厢',
      onTap: model.cars.length < 6
          ? () => act(() {
              stopAudio();
              model.add();
            })
          : null,
    ),
    ToyTool(
      key: const ValueKey('train-remove'),
      icon: '➖',
      label: '减车厢',
      onTap: model.cars.length > 2
          ? () => act(() {
              stopAudio();
              model.remove();
            })
          : null,
    ),
    ToyTool(
      key: const ValueKey('train-start'),
      icon: model.playing ? '⏹️' : '🚂',
      label: model.playing ? '停下来' : '发车',
      selected: model.playing,
      onTap: () => act(() {
        if (model.playing) {
          model.stop();
          stopAudio();
        } else {
          model.start();
        }
      }, save: false),
    ),
    ToyTool(
      key: const ValueKey('train-speed'),
      icon: const ['🐢', '🚂', '🐇'][model.speed],
      label: const ['慢慢开', '轻快开', '快快开'][model.speed],
      onTap: () => act(() {
        stopAudio();
        model.changeSpeed();
      }),
    ),
    ToyTool(
      key: const ValueKey('train-next'),
      icon: const ['🌳', '⛰️', '🌙'][model.scene],
      label: '换风景',
      onTap: () => confirmReset(model.preset),
    ),
    for (var i = 0; i < model.cars.length; i++)
      ToyTool(
        key: ValueKey('train-swap-$i'),
        icon: '${i + 1}',
        label: exchange == i ? '选另一节' : '交换车厢',
        selected: exchange == i,
        onTap: () => act(() {
          model.stop();
          stopAudio();
          if (exchange == null) {
            exchange = i;
          } else {
            model.swap(exchange!, i);
            exchange = null;
          }
        }),
      ),
  ];
}

class _TrainPainter extends ToyPainter {
  _TrainPainter(this.m, this.finger, this.from, this.exchange);
  final SoundTrainModel m;
  final Offset? finger;
  final int? from, exchange;
  @override
  void paint(Canvas canvas, Size s) {
    final night = m.scene == 2;
    start(canvas, s, night ? const Color(0xFF333C5F) : const Color(0xFFE8E5F3));
    if (night) {
      text('🌙', .8, .13, font: 38);
      for (var i = 0; i < 14; i++) {
        sparkle((i * .177) % 1, .05 + (i * .071 % .3), const Color(0xFFF4DDA4));
      }
    } else {
      cloud(.18, .17);
      cloud(.83, .11);
    }
    box(
      0,
      .79,
      1,
      .21,
      night ? const Color(0xFF535979) : const Color(0xFFB8CAA6),
    );
    line(const Offset(0, .8), const Offset(1, .8), const Color(0xFF9B8A80), 7);
    line(
      const Offset(0, .87),
      const Offset(1, .87),
      const Color(0xFF9B8A80),
      5,
    );
    for (var i = 0; i < 15; i++) {
      line(
        Offset(i * .08, .79),
        Offset(i * .08 - .025, .89),
        const Color(0xFF9B8A80),
        5,
      );
    }
    if (m.scene == 1) {
      box(.35, .27, .3, .56, const Color(0xFFA69CAC), radius: 60);
      box(.43, .39, .16, .43, const Color(0xFF686776), radius: 40);
    } else {
      box(
        .45,
        .26,
        .025,
        .55,
        night ? const Color(0xFFBAABD6) : const Color(0xFFAB94CA),
      );
      box(
        .65,
        .26,
        .025,
        .55,
        night ? const Color(0xFFBAABD6) : const Color(0xFFAB94CA),
      );
      box(.45, .26, .225, .08, const Color(0xFFBDA5D3));
      text('♫', .56, .3, font: 26, color: Colors.white);
    }
    if (m.playing) {
      final locomotive = m.carX(-1);
      drawCar(locomotive, .67, '🚂', const Color(0xFFE8B16C), false);
      for (var i = 0; i < m.cars.length; i++) {
        drawCar(
          m.carX(i),
          .67,
          const ['🐸', '🥁', '🐱', '🔔'][m.cars[i]],
          const Color(0xFFBBA1D5),
          m.active == i && m.flash > 0,
        );
      }
    } else {
      for (var i = 0; i < m.cars.length; i++) {
        final x = (i + .5) / m.cars.length;
        final width = .85 / m.cars.length;
        box(
          x - width / 2,
          .51,
          width,
          .24,
          exchange == i ? const Color(0xFFE7C56D) : const Color(0xFFBBA1D5),
          radius: 12,
        );
        text(
          const ['🐸', '🥁', '🐱', '🔔'][m.cars[i]],
          x,
          .62,
          font: m.cars.length > 4 ? 27 : 38,
        );
        oval(x - width * .27, .78, .017, .03, const Color(0xFF657083));
        oval(x + width * .27, .78, .017, .03, const Color(0xFF657083));
        text(
          '${i + 1}',
          x,
          .45,
          font: 13,
          color: night ? Colors.white : const Color(0xFF52626D),
        );
      }
    }
    if (m.flash > 0) {
      text('♪ ♫', .55, .18, font: 33, color: const Color(0xFFE4B94E));
    }
    text(
      m.playing ? '听：车厢经过音乐门才发声' : '拖一拖，排一首自己的歌',
      .5,
      .95,
      font: 14,
      color: night ? Colors.white : const Color(0xFF52626D),
    );
    if (finger != null && from != null) {
      text(
        const ['🐸', '🥁', '🐱', '🔔'][m.cars[from!]],
        finger!.dx,
        finger!.dy,
        font: 39,
      );
    }
  }

  void drawCar(double x, double y, String icon, Color color, bool active) {
    if (x < -.2 || x > 1.2) return;
    box(
      x - .075,
      y - .1,
      .15,
      .19,
      active ? const Color(0xFFF2CE75) : color,
      radius: 12,
    );
    text(icon, x, y - .012, font: 28);
    oval(x - .042, y + .11, .023, .031, const Color(0xFF596575));
    oval(x + .042, y + .11, .023, .031, const Color(0xFF596575));
  }
}
