import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game_audio.dart';
import 'island_progress.dart';

@immutable
class DetectiveOption {
  const DetectiveOption({
    required this.name,
    required this.colorName,
    required this.color,
    required this.emoji,
  });

  final String name;
  final String colorName;
  final Color color;
  final String emoji;
}

@immutable
class DetectiveRound {
  const DetectiveRound({
    required this.clue,
    required this.answer,
    required this.options,
  });

  final String clue;
  final String answer;
  final List<DetectiveOption> options;
}

const detectiveRounds = <DetectiveRound>[
  DetectiveRound(
    clue: '太阳公公想找一个和自己一样明亮的朋友',
    answer: '黄色',
    options: [
      DetectiveOption(
        name: '小草莓',
        colorName: '红色',
        color: Color(0xFFFF4F64),
        emoji: '🍓',
      ),
      DetectiveOption(
        name: '大香蕉',
        colorName: '黄色',
        color: Color(0xFFFFD84A),
        emoji: '🍌',
      ),
      DetectiveOption(
        name: '小树叶',
        colorName: '绿色',
        color: Color(0xFF45CE75),
        emoji: '🍃',
      ),
      DetectiveOption(
        name: '蓝莓果',
        colorName: '蓝色',
        color: Color(0xFF4687FF),
        emoji: '🫐',
      ),
    ],
  ),
  DetectiveRound(
    clue: '小鲸鱼要回到像大海一样的颜色里',
    answer: '蓝色',
    options: [
      DetectiveOption(
        name: '海浪',
        colorName: '蓝色',
        color: Color(0xFF4687FF),
        emoji: '🌊',
      ),
      DetectiveOption(
        name: '橙子',
        colorName: '橙色',
        color: Color(0xFFFF922E),
        emoji: '🍊',
      ),
      DetectiveOption(
        name: '葡萄',
        colorName: '紫色',
        color: Color(0xFF9B67E8),
        emoji: '🍇',
      ),
      DetectiveOption(
        name: '小花',
        colorName: '粉色',
        color: Color(0xFFFF9DB1),
        emoji: '🌸',
      ),
    ],
  ),
  DetectiveRound(
    clue: '消防车出发前，要找到最勇敢的颜色',
    answer: '红色',
    options: [
      DetectiveOption(
        name: '月亮',
        colorName: '白色',
        color: Color(0xFFF8F5EB),
        emoji: '🌙',
      ),
      DetectiveOption(
        name: '消防车',
        colorName: '红色',
        color: Color(0xFFFF4F64),
        emoji: '🚒',
      ),
      DetectiveOption(
        name: '青蛙',
        colorName: '绿色',
        color: Color(0xFF45CE75),
        emoji: '🐸',
      ),
      DetectiveOption(
        name: '雨滴',
        colorName: '青色',
        color: Color(0xFF42D7D0),
        emoji: '💧',
      ),
    ],
  ),
  DetectiveRound(
    clue: '小青蛙想躲进池塘边的叶子里',
    answer: '绿色',
    options: [
      DetectiveOption(
        name: '南瓜',
        colorName: '橙色',
        color: Color(0xFFFF922E),
        emoji: '🎃',
      ),
      DetectiveOption(
        name: '云朵',
        colorName: '白色',
        color: Color(0xFFF8F5EB),
        emoji: '☁️',
      ),
      DetectiveOption(
        name: '叶子',
        colorName: '绿色',
        color: Color(0xFF45CE75),
        emoji: '🌿',
      ),
      DetectiveOption(
        name: '葡萄',
        colorName: '紫色',
        color: Color(0xFF9B67E8),
        emoji: '🍇',
      ),
    ],
  ),
  DetectiveRound(
    clue: '魔法师丢了一颗像葡萄一样神秘的宝石',
    answer: '紫色',
    options: [
      DetectiveOption(
        name: '紫宝石',
        colorName: '紫色',
        color: Color(0xFF9B67E8),
        emoji: '🔮',
      ),
      DetectiveOption(
        name: '太阳',
        colorName: '黄色',
        color: Color(0xFFFFD84A),
        emoji: '☀️',
      ),
      DetectiveOption(
        name: '小熊',
        colorName: '棕色',
        color: Color(0xFF8A654A),
        emoji: '🐻',
      ),
      DetectiveOption(
        name: '雪花',
        colorName: '白色',
        color: Color(0xFFF8F5EB),
        emoji: '❄️',
      ),
    ],
  ),
];

class ColorDetectiveScreen extends StatefulWidget {
  const ColorDetectiveScreen({
    super.key,
    required this.progress,
    required this.audio,
  });

  final IslandProgress progress;
  final GameAudioController audio;

  @override
  State<ColorDetectiveScreen> createState() => _ColorDetectiveScreenState();
}

class _ColorDetectiveScreenState extends State<ColorDetectiveScreen> {
  late int _roundIndex;
  int? _selectedIndex;
  bool _solved = false;
  String _message = '仔细看一看，再做出选择吧！';

  DetectiveRound get _round => detectiveRounds[_roundIndex];

  @override
  void initState() {
    super.initState();
    _roundIndex = widget.progress.detectiveWins % detectiveRounds.length;
  }

  void _choose(int index) {
    if (_solved) return;
    final option = _round.options[index];
    final correct = option.colorName == _round.answer;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedIndex = index;
      _solved = correct;
      _message = correct
          ? '找到了！${option.emoji} ${option.name}就是${_round.answer}的！'
          : '${option.name}是${option.colorName}，再找找看～';
    });
    if (correct) {
      HapticFeedback.mediumImpact();
      widget.progress.recordDetectiveWin(_roundIndex, option.colorName);
    }
    unawaited(
      widget.audio.announce(
        _message,
        sound: correct ? GameSound.correct : GameSound.wrong,
      ),
    );
  }

  void _next() {
    setState(() {
      _roundIndex = (_roundIndex + 1) % detectiveRounds.length;
      _selectedIndex = null;
      _solved = false;
      _message = '新的线索来啦，谁会是正确答案？';
    });
    unawaited(widget.audio.announce('新的线索来啦。${_round.clue}'));
  }

  @override
  Widget build(BuildContext context) {
    final narration = '小侦探，请听线索，然后点击你认为正确的物品。${_round.clue}';
    return NarrateOnMount(
      audio: widget.audio,
      text: narration,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0FFF8),
        body: SafeArea(
          minimum: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Column(
            children: [
              _DetectiveHeader(
                round: _roundIndex + 1,
                stars: widget.progress.stars,
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF28B487), Color(0xFF168B87)],
                  ),
                  borderRadius: BorderRadius.circular(23),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3328B487),
                      blurRadius: 16,
                      offset: Offset(0, 7),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text('🕵️', style: TextStyle(fontSize: 34)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '侦探线索',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _round.clue,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.25,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    RepeatVoiceButton(
                      audio: widget.audio,
                      text: narration,
                      foregroundColor: const Color(0xFF14706B),
                      backgroundColor: Colors.white,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth > 640;
                    return GridView.builder(
                      padding: EdgeInsets.zero,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: wide ? 4 : 2,
                        crossAxisSpacing: 11,
                        mainAxisSpacing: 11,
                        childAspectRatio: wide ? 0.92 : 1.05,
                      ),
                      itemCount: _round.options.length,
                      itemBuilder: (context, index) {
                        final option = _round.options[index];
                        final selected = _selectedIndex == index;
                        final correct = _solved && selected;
                        return _DetectiveCard(
                          key: ValueKey('detective-option-${option.colorName}'),
                          option: option,
                          selected: selected,
                          correct: correct,
                          onTap: () => _choose(index),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: _solved
                      ? const Color(0xFFFFF1A8)
                      : Colors.white.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Row(
                  children: [
                    Text(
                      _solved ? '⭐' : '💡',
                      style: const TextStyle(fontSize: 21),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        _message,
                        style: const TextStyle(
                          color: Color(0xFF3D4B62),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (_solved)
                      FilledButton.icon(
                        key: const ValueKey('detective-next'),
                        onPressed: _next,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('下一题'),
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

class _DetectiveHeader extends StatelessWidget {
  const _DetectiveHeader({required this.round, required this.stars});

  final int round;
  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: '返回彩虹小岛',
        ),
        const SizedBox(width: 9),
        const Expanded(
          child: Text(
            '🔎 色彩侦探',
            style: TextStyle(
              color: Color(0xFF263D47),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          '线索 $round/${detectiveRounds.length}   ⭐ $stars',
          style: const TextStyle(
            color: Color(0xFF3E665E),
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _DetectiveCard extends StatelessWidget {
  const _DetectiveCard({
    super.key,
    required this.option,
    required this.selected,
    required this.correct,
    required this.onTap,
  });

  final DetectiveOption option;
  final bool selected;
  final bool correct;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? option.color.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: correct
                  ? const Color(0xFFFFC928)
                  : selected
                  ? option.color
                  : Colors.white,
              width: selected ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: option.color.withValues(alpha: selected ? 0.26 : 0.12),
                blurRadius: selected ? 18 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(option.emoji, style: const TextStyle(fontSize: 44)),
              const SizedBox(height: 7),
              Text(
                option.name,
                style: const TextStyle(
                  color: Color(0xFF364558),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Container(
                width: 32,
                height: 10,
                decoration: BoxDecoration(
                  color: option.color,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
