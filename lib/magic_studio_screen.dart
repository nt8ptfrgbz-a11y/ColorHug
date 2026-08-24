import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game_audio.dart';
import 'island_progress.dart';

@immutable
class StudioColor {
  const StudioColor(this.name, this.color);

  final String name;
  final Color color;
}

const studioColors = <StudioColor>[
  StudioColor('红色', Color(0xFFFF4F64)),
  StudioColor('橙色', Color(0xFFFF922E)),
  StudioColor('黄色', Color(0xFFFFD84A)),
  StudioColor('绿色', Color(0xFF45CE75)),
  StudioColor('青色', Color(0xFF42D7D0)),
  StudioColor('蓝色', Color(0xFF4687FF)),
  StudioColor('紫色', Color(0xFF9B67E8)),
  StudioColor('粉色', Color(0xFFFF9DB1)),
  StudioColor('黑色', Color(0xFF30333D)),
];

class PaintStroke {
  PaintStroke({
    required this.colorName,
    required this.color,
    required this.width,
    required this.points,
  });

  final String colorName;
  final Color color;
  final double width;
  final List<Offset> points;
}

class MagicStudioScreen extends StatefulWidget {
  const MagicStudioScreen({
    super.key,
    required this.progress,
    required this.audio,
  });

  final IslandProgress progress;
  final GameAudioController audio;

  @override
  State<MagicStudioScreen> createState() => _MagicStudioScreenState();
}

class _MagicStudioScreenState extends State<MagicStudioScreen> {
  final List<PaintStroke> _strokes = [];
  int _selectedColor = 0;
  double _brushWidth = 12;
  String _message = '选一种颜色，在画布上施展魔法吧！';

  StudioColor get _color => studioColors[_selectedColor];

  void _startStroke(DragStartDetails details) {
    HapticFeedback.selectionClick();
    unawaited(widget.audio.play(GameSound.tap));
    setState(() {
      _strokes.add(
        PaintStroke(
          colorName: _color.name,
          color: _color.color,
          width: _brushWidth,
          points: [details.localPosition],
        ),
      );
      _message = '${_color.name}画笔正在跳舞！';
    });
  }

  void _continueStroke(DragUpdateDetails details) {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.last.points.add(details.localPosition));
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() {
      _strokes.removeLast();
      _message = '刚才的一笔飞走啦！';
    });
    unawaited(widget.audio.announce(_message));
  }

  void _clear() {
    if (_strokes.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _strokes.clear();
      _message = '画布洗干净啦，可以画一幅新的！';
    });
    unawaited(widget.audio.announce(_message));
  }

  Future<void> _hangArtwork() async {
    if (_strokes.isEmpty) {
      setState(() => _message = '画布还是空的，先画几笔吧！');
      unawaited(widget.audio.announce(_message, sound: GameSound.wrong));
      return;
    }
    final usedColors = _strokes.map((stroke) => stroke.colorName).toSet();
    widget.progress.recordArtwork(usedColors);
    HapticFeedback.mediumImpact();
    unawaited(
      widget.audio.announce(
        '作品完成啦！这幅画用了${usedColors.length}种颜色。',
        sound: GameSound.complete,
      ),
    );
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFFBF2),
          icon: const Text('🖼️', style: TextStyle(fontSize: 42)),
          title: const Text(
            '作品完成啦！',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(
            '这幅画用了${usedColors.length}种颜色，是画室记录的第${widget.progress.artworks}幅作品。',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('太好啦'),
            ),
          ],
        );
      },
    );
    if (mounted) {
      setState(() => _message = '还可以继续画，或者创作一幅新作品。');
    }
  }

  @override
  Widget build(BuildContext context) {
    const narration = '欢迎来到魔法画室。先选一种颜色，再用手指在白色画布上画一画。';
    return NarrateOnMount(
      audio: widget.audio,
      text: narration,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7EFFF),
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
                      '🎨 魔法画室',
                      style: TextStyle(
                        color: Color(0xFF4E3D67),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    key: const ValueKey('studio-undo'),
                    onPressed: _strokes.isEmpty ? null : _undo,
                    tooltip: '撤销一笔',
                    icon: const Icon(Icons.undo_rounded),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    key: const ValueKey('studio-clear'),
                    onPressed: _strokes.isEmpty ? null : _clear,
                    tooltip: '清空画布',
                    icon: const Icon(Icons.delete_sweep_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 19)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF675679),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    RepeatVoiceButton(
                      audio: widget.audio,
                      text: '$_message。先选一种颜色，再在白色画布上画一画。',
                    ),
                    const SizedBox(width: 6),
                    FilledButton.icon(
                      key: const ValueKey('studio-save'),
                      onPressed: _hangArtwork,
                      icon: const Icon(Icons.home_rounded, size: 18),
                      label: const Text('完成作品'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFDF7),
                    borderRadius: BorderRadius.circular(27),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x239B67E8),
                        blurRadius: 18,
                        offset: Offset(0, 7),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: GestureDetector(
                    key: const ValueKey('studio-canvas'),
                    behavior: HitTestBehavior.opaque,
                    onPanStart: _startStroke,
                    onPanUpdate: _continueStroke,
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: MagicCanvasPainter(strokes: _strokes),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 72,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(23),
                ),
                child: Row(
                  children: [
                    PopupMenuButton<double>(
                      tooltip: '画笔粗细',
                      initialValue: _brushWidth,
                      onSelected: (value) =>
                          setState(() => _brushWidth = value),
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 7, child: Text('细画笔')),
                        PopupMenuItem(value: 12, child: Text('中画笔')),
                        PopupMenuItem(value: 21, child: Text('粗画笔')),
                      ],
                      child: Container(
                        width: 50,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.brush_rounded,
                          color: _color.color,
                          size: 22 + _brushWidth * 0.25,
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 38,
                      color: const Color(0x22705D82),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: studioColors.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final item = studioColors[index];
                          final selected = _selectedColor == index;
                          return Semantics(
                            button: true,
                            selected: selected,
                            label: '${item.name}画笔',
                            child: InkWell(
                              key: ValueKey('studio-color-${item.name}'),
                              onTap: () {
                                setState(() {
                                  _selectedColor = index;
                                  _message = '${item.name}画笔准备好啦！';
                                });
                                unawaited(
                                  widget.audio.announce(
                                    _message,
                                    sound: GameSound.tap,
                                  ),
                                );
                              },
                              customBorder: const CircleBorder(),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: item.color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFF433458)
                                        : Colors.white,
                                    width: selected ? 4 : 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: item.color.withValues(alpha: 0.34),
                                      blurRadius: selected ? 11 : 5,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MagicCanvasPainter extends CustomPainter {
  MagicCanvasPainter({required this.strokes});

  final List<PaintStroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()..color = const Color(0x0D7B6A88);
    for (var x = 20.0; x < size.width; x += 34) {
      for (var y = 20.0; y < size.height; y += 34) {
        canvas.drawCircle(Offset(x, y), 1.4, dotPaint);
      }
    }

    if (strokes.isEmpty) {
      final painter = TextPainter(
        text: const TextSpan(
          text: '在这里画一画吧  ✨',
          style: TextStyle(
            color: Color(0x55705D82),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(
          (size.width - painter.width) / 2,
          (size.height - painter.height) / 2,
        ),
      );
    }

    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      if (stroke.points.length == 1) {
        canvas.drawCircle(
          stroke.points.single,
          stroke.width / 2,
          paint..style = PaintingStyle.fill,
        );
        continue;
      }
      final path = Path()
        ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (var index = 1; index < stroke.points.length; index++) {
        final previous = stroke.points[index - 1];
        final current = stroke.points[index];
        final middle = Offset(
          (previous.dx + current.dx) / 2,
          (previous.dy + current.dy) / 2,
        );
        path.quadraticBezierTo(previous.dx, previous.dy, middle.dx, middle.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant MagicCanvasPainter oldDelegate) => true;
}
