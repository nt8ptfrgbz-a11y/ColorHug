import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game_audio.dart';
import 'island_progress.dart';

@immutable
class RepairTask {
  const RepairTask({
    required this.title,
    required this.prompt,
    required this.colorName,
    required this.emoji,
  });

  final String title;
  final String prompt;
  final String colorName;
  final String emoji;
}

const repairTasks = <RepairTask>[
  RepairTask(
    title: '叫醒太阳',
    prompt: '太阳公公需要一种明亮又温暖的颜色',
    colorName: '黄色',
    emoji: '☀️',
  ),
  RepairTask(
    title: '唤醒小河',
    prompt: '给小河穿上像天空一样的颜色',
    colorName: '蓝色',
    emoji: '💧',
  ),
  RepairTask(
    title: '种出草地',
    prompt: '小芽喜欢森林和叶子的颜色',
    colorName: '绿色',
    emoji: '🌱',
  ),
  RepairTask(
    title: '点亮花朵',
    prompt: '最后用热情的颜色叫醒小花吧',
    colorName: '红色',
    emoji: '🌷',
  ),
];

const _repairColors = <({String name, Color color})>[
  (name: '红色', color: Color(0xFFFF4F64)),
  (name: '黄色', color: Color(0xFFFFD84A)),
  (name: '蓝色', color: Color(0xFF4687FF)),
  (name: '绿色', color: Color(0xFF45CE75)),
  (name: '青色', color: Color(0xFF42D7D0)),
  (name: '紫色', color: Color(0xFF9B67E8)),
];

class RainbowRepairScreen extends StatefulWidget {
  const RainbowRepairScreen({
    super.key,
    required this.progress,
    required this.audio,
  });

  final IslandProgress progress;
  final GameAudioController audio;

  @override
  State<RainbowRepairScreen> createState() => _RainbowRepairScreenState();
}

class _RainbowRepairScreenState extends State<RainbowRepairScreen>
    with SingleTickerProviderStateMixin {
  late int _step;
  late final AnimationController _sparkleController;
  String _message = '选出正确的颜色，把它送进花园吧！';
  String? _wrongColor;

  bool get _completed => _step >= repairTasks.length;
  RepairTask? get _task => _completed ? null : repairTasks[_step];

  @override
  void initState() {
    super.initState();
    _step = widget.progress.repairedParts.clamp(0, repairTasks.length);
    if (_completed) {
      _message = '太棒啦！整座花园都恢复颜色了！';
    }
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    super.dispose();
  }

  void _chooseColor(String name) {
    final task = _task;
    if (task == null) return;
    HapticFeedback.selectionClick();
    if (name != task.colorName) {
      setState(() {
        _wrongColor = name;
        _message = '$name也很漂亮，不过${task.emoji}想要${task.colorName}哦！';
      });
      unawaited(widget.audio.announce(_message, sound: GameSound.wrong));
      return;
    }

    final nextStep = _step + 1;
    widget.progress.repairPart(nextStep, name);
    HapticFeedback.mediumImpact();
    setState(() {
      _step = nextStep;
      _wrongColor = null;
      _message = _completed
          ? '太棒啦！整座花园都恢复颜色了！'
          : '${task.emoji} ${task.title}成功！下一处也在等你。';
    });
    _sparkleController.forward(from: 0);
    final narration = _completed ? _message : '$_message ${_task!.prompt}';
    unawaited(
      widget.audio.announce(
        narration,
        sound: _completed ? GameSound.complete : GameSound.correct,
      ),
    );
  }

  void _replay() {
    setState(() {
      _step = 0;
      _message = '再施展一次颜色魔法吧！';
      _wrongColor = null;
    });
    unawaited(widget.audio.announce('再施展一次颜色魔法吧！${repairTasks.first.prompt}'));
  }

  @override
  Widget build(BuildContext context) {
    final narration = _completed
        ? _message
        : '请听一听花园需要什么，再点击下方正确的颜色。${_task!.prompt}';
    return NarrateOnMount(
      audio: widget.audio,
      text: narration,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF7E6),
        body: SafeArea(
          minimum: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: '返回彩虹小岛',
                  ),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text(
                      '🌈 彩虹修复师',
                      style: TextStyle(
                        color: Color(0xFF523D47),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '修复 $_step/${repairTasks.length}   ⭐ ${widget.progress.stars}',
                    style: const TextStyle(
                      color: Color(0xFF755866),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: AnimatedBuilder(
                    animation: _sparkleController,
                    builder: (context, _) {
                      return CustomPaint(
                        key: const ValueKey('repair-garden'),
                        size: Size.infinite,
                        painter: GardenRepairPainter(
                          step: _step,
                          sparkle: _sparkleController.value,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (_completed)
                _CompletedRepairCard(
                  key: const ValueKey('repair-completed'),
                  message: _message,
                  onReplay: _replay,
                  audio: widget.audio,
                )
              else
                _RepairControls(
                  key: ValueKey('repair-step-$_step'),
                  task: _task!,
                  message: _message,
                  wrongColor: _wrongColor,
                  onChoose: _chooseColor,
                  audio: widget.audio,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RepairControls extends StatelessWidget {
  const _RepairControls({
    super.key,
    required this.task,
    required this.message,
    required this.wrongColor,
    required this.onChoose,
    required this.audio,
  });

  final RepairTask task;
  final String message;
  final String? wrongColor;
  final ValueChanged<String> onChoose;
  final GameAudioController audio;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(23),
        boxShadow: const [BoxShadow(color: Color(0x180B4778), blurRadius: 14)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(task.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        color: Color(0xFF503F47),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      task.prompt,
                      style: const TextStyle(
                        color: Color(0xFF7B6871),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Text(
                  message,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: wrongColor == null
                        ? const Color(0xFF7B6871)
                        : const Color(0xFFE35D71),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              RepeatVoiceButton(
                audio: audio,
                text: '${task.title}。${task.prompt}',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: _repairColors.map((item) {
              final ink = item.color.computeLuminance() > 0.55
                  ? const Color(0xFF36323B)
                  : Colors.white;
              return Semantics(
                button: true,
                label: '选择${item.name}',
                child: InkWell(
                  key: ValueKey('repair-color-${item.name}'),
                  onTap: () => onChoose(item.name),
                  customBorder: const CircleBorder(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: item.color.withValues(alpha: 0.38),
                          blurRadius: 9,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      item.name.substring(0, 1),
                      style: TextStyle(
                        color: ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _CompletedRepairCard extends StatelessWidget {
  const _CompletedRepairCard({
    super.key,
    required this.message,
    required this.onReplay,
    required this.audio,
  });

  final String message;
  final VoidCallback onReplay;
  final GameAudioController audio;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE77A), Color(0xFFFFB9C5)],
        ),
        borderRadius: BorderRadius.circular(23),
      ),
      child: Row(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 31)),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF5B3D48),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          RepeatVoiceButton(audio: audio, text: message),
          const SizedBox(width: 6),
          FilledButton.tonalIcon(
            onPressed: onReplay,
            icon: const Icon(Icons.replay_rounded),
            label: const Text('再玩一次'),
          ),
        ],
      ),
    );
  }
}

class GardenRepairPainter extends CustomPainter {
  GardenRepairPainter({required this.step, required this.sparkle});

  final int step;
  final double sparkle;

  Color _active(int threshold, Color color) {
    return step >= threshold ? color : const Color(0xFFB6BBC2);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _active(2, const Color(0xFFBDEBFF)),
          _active(3, const Color(0xFFF3FDFF)),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    final sunCenter = Offset(size.width * 0.80, size.height * 0.20);
    final sunColor = _active(1, const Color(0xFFFFD84A));
    final sunPaint = Paint()
      ..color = sunColor
      ..maskFilter = step >= 1
          ? const MaskFilter.blur(BlurStyle.normal, 9)
          : null;
    canvas.drawCircle(
      sunCenter,
      math.min(size.width, size.height) * 0.085,
      sunPaint,
    );
    canvas.drawCircle(
      sunCenter,
      math.min(size.width, size.height) * 0.072,
      Paint()..color = sunColor,
    );

    final hillPaint = Paint()..color = _active(3, const Color(0xFF75D780));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.22, size.height * 0.79),
        width: size.width * 0.75,
        height: size.height * 0.50,
      ),
      hillPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.78, size.height * 0.80),
        width: size.width * 0.78,
        height: size.height * 0.55,
      ),
      Paint()..color = _active(3, const Color(0xFF53C672)),
    );

    final riverPath = Path()
      ..moveTo(size.width * 0.43, size.height * 0.50)
      ..cubicTo(
        size.width * 0.31,
        size.height * 0.68,
        size.width * 0.70,
        size.height * 0.75,
        size.width * 0.56,
        size.height,
      )
      ..lineTo(size.width * 0.88, size.height)
      ..cubicTo(
        size.width * 0.82,
        size.height * 0.78,
        size.width * 0.52,
        size.height * 0.67,
        size.width * 0.57,
        size.height * 0.51,
      )
      ..close();
    canvas.drawPath(
      riverPath,
      Paint()..color = _active(2, const Color(0xFF54BCEB)),
    );

    _paintTree(canvas, Offset(size.width * 0.17, size.height * 0.57), size);
    _paintTree(canvas, Offset(size.width * 0.72, size.height * 0.55), size);

    final flowerColors = step >= 4
        ? const [
            Color(0xFFFF4F64),
            Color(0xFFFFD84A),
            Color(0xFF9B67E8),
            Color(0xFFFF82B2),
          ]
        : const [Color(0xFFAEB2B8)];
    for (var index = 0; index < 12; index++) {
      final x = size.width * (0.08 + (index % 6) * 0.16);
      final y = size.height * (0.78 + (index ~/ 6) * 0.11);
      final color = flowerColors[index % flowerColors.length];
      canvas.drawLine(
        Offset(x, y),
        Offset(x, y + 16),
        Paint()
          ..color = _active(3, const Color(0xFF357F4B))
          ..strokeWidth = 3,
      );
      for (var petal = 0; petal < 5; petal++) {
        final angle = petal * math.pi * 2 / 5;
        canvas.drawCircle(
          Offset(x + math.cos(angle) * 6, y + math.sin(angle) * 6),
          4.5,
          Paint()..color = color,
        );
      }
      canvas.drawCircle(
        Offset(x, y),
        3.5,
        Paint()..color = _active(1, const Color(0xFFFFD84A)),
      );
    }

    if (sparkle > 0 && sparkle < 1) {
      final sparklePaint = Paint()
        ..color = Colors.white.withValues(alpha: 1 - sparkle)
        ..strokeWidth = 2.5;
      for (var index = 0; index < 18; index++) {
        final angle = index * math.pi * 2 / 18;
        final distance = 25 + sparkle * 90;
        final center = Offset(
          size.width * 0.5 + math.cos(angle) * distance,
          size.height * 0.5 + math.sin(angle) * distance,
        );
        canvas.drawCircle(center, 2.5 + (index % 3), sparklePaint);
      }
    }
  }

  void _paintTree(Canvas canvas, Offset center, Size size) {
    final scale = math.min(size.width, size.height) / 430;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center + Offset(0, 40 * scale),
          width: 18 * scale,
          height: 76 * scale,
        ),
        Radius.circular(7 * scale),
      ),
      Paint()..color = _active(3, const Color(0xFF8A654A)),
    );
    final leaves = Paint()..color = _active(3, const Color(0xFF31A960));
    canvas.drawCircle(center, 34 * scale, leaves);
    canvas.drawCircle(
      center + Offset(-24 * scale, 12 * scale),
      25 * scale,
      leaves,
    );
    canvas.drawCircle(
      center + Offset(25 * scale, 11 * scale),
      27 * scale,
      leaves,
    );
  }

  @override
  bool shouldRepaint(covariant GardenRepairPainter oldDelegate) {
    return oldDelegate.step != step || oldDelegate.sparkle != sparkle;
  }
}
