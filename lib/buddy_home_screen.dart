import 'dart:async';

import 'package:flutter/material.dart';

import 'buddy_bath_screen.dart';
import 'buddy_adventure_screen.dart';
import 'buddy_adventure_models.dart';
import 'buddy_hide_screen.dart';
import 'buddy_juice_screen.dart';
import 'buddy_models.dart';
import 'buddy_widgets.dart';
import 'game_audio.dart';
import 'island_progress.dart';

class BuddyHomeScreen extends StatefulWidget {
  const BuddyHomeScreen({
    super.key,
    required this.progress,
    required this.audio,
  });
  final IslandProgress progress;
  final GameAudioController audio;
  @override
  State<BuddyHomeScreen> createState() => _BuddyHomeScreenState();
}

class _BuddyHomeScreenState extends State<BuddyHomeScreen> {
  static const _welcome =
      '欢迎来抱抱的小家！九个小世界等着你，有果汁屋、恐龙蛋、天气工厂、软糖桥和小剧场。点喜欢的图片，我们一起出发！';
  bool _greeting = false;
  Timer? _greetingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(widget.audio.speak(_welcome));
    });
  }

  Future<void> _open(Widget screen) async {
    unawaited(widget.audio.stopSpeech());
    unawaited(widget.audio.play(GameSound.tap));
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) unawaited(widget.audio.speak('回到抱抱的小家啦！今天还想一起玩什么？'));
  }

  void _greet() {
    _greetingTimer?.cancel();
    setState(() => _greeting = true);
    unawaited(widget.audio.speakLesson('你好呀！抱抱见到你真开心。', 'Hello, my friend!'));
    _greetingTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _greeting = false);
    });
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.progress,
    builder: (context, _) {
      final progress = widget.progress;
      return BuddyGameShell(
        title: '小伙伴乐园',
        sceneHeight: 280,
        subtitle: 'BAOBAO & FRIENDS · 每次都有小故事',
        guide: '你好，我是抱抱！今天我们一起玩什么？',
        audio: widget.audio,
        progress: progress,
        onRepeat: () => widget.audio.speak(_welcome),
        backLabel: '返回彩虹小岛',
        scene: BuddyRoom(
          color: const Color(0xFFE4EDDD),
          floor: const Color(0xFFCCD4AB),
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                Positioned(
                  left: 22,
                  top: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '抱抱的小家',
                        style: TextStyle(
                          color: buddyInk,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _greeting ? 'Hello, my friend! ♡' : '点点我，打个招呼',
                        style: const TextStyle(
                          color: Color(0xFF72876B),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: const Alignment(0, .6),
                  child: SizedBox(
                    width: 240,
                    height: 260,
                    child: GestureDetector(
                      key: const ValueKey('buddy-greet'),
                      onTap: _greet,
                      child: BuddyCharacter(
                        color: buddyColors[progress.buddyColor],
                        outfit: progress.buddyOutfit,
                        joyful: _greeting,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 22,
                  bottom: 19,
                  child: Text(
                    '🌷 ${progress.juiceRecipes.length} 杯小创作',
                    style: const TextStyle(
                      color: buddyInk,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        controls: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 8,
              children: [
                for (var i = 0; i < buddyColors.length; i++)
                  Semantics(
                    button: true,
                    label: '选择${const ['薄荷', '葡萄', '蜜桃', '奶油'][i]}色抱抱',
                    selected: progress.buddyColor == i,
                    child: InkWell(
                      key: ValueKey('buddy-color-$i'),
                      onTap: () {
                        progress.dressBuddy(color: i);
                        unawaited(widget.audio.play(GameSound.tap));
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: buddyColors[i],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: progress.buddyColor == i
                                ? buddyInk
                                : Colors.white,
                            width: 3,
                          ),
                        ),
                        child: progress.buddyColor == i
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                  ),
                for (var i = 0; i < buddyOutfits.length; i++)
                  ActionChip(
                    key: ValueKey('buddy-outfit-${buddyOutfits[i]}'),
                    label: Text(
                      buddyOutfitEmojis[i],
                      style: const TextStyle(fontSize: 25),
                    ),
                    onPressed: () {
                      progress.dressBuddy(outfit: buddyOutfits[i]);
                      unawaited(widget.audio.play(GameSound.discover));
                    },
                  ),
              ],
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 700 ? 3 : 2;
                final width =
                    (constraints.maxWidth - (columns - 1) * 12) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _PlayCard(
                      key: const ValueKey('buddy-game-juice'),
                      width: width,
                      icon: '🍹',
                      title: '怪兽果汁屋',
                      subtitle: '切一切 · 搅一搅 · 喂抱抱',
                      note: '${progress.juiceRecipes.length} 杯配方收藏',
                      color: const Color(0xFFF2D8AF),
                      onTap: () => _open(
                        BuddyJuiceScreen(
                          progress: progress,
                          audio: widget.audio,
                        ),
                      ),
                    ),
                    _PlayCard(
                      key: const ValueKey('buddy-game-bath'),
                      width: width,
                      icon: '🫧',
                      title: '小怪兽洗澡澡',
                      subtitle: '搓泡泡 · 冲水 · 擦干换装',
                      note: '${progress.buddyBaths} 次温柔照顾',
                      color: const Color(0xFFCFE7E3),
                      onTap: () => _open(
                        BuddyBathScreen(
                          progress: progress,
                          audio: widget.audio,
                        ),
                      ),
                    ),
                    _PlayCard(
                      key: const ValueKey('buddy-game-hide'),
                      width: width,
                      icon: '🙈',
                      title: '英语躲猫猫',
                      subtitle: '听一听 · 找朋友 · 换你来藏',
                      note: '${progress.buddyHideRounds} 次找到朋友',
                      color: const Color(0xFFE2DCF0),
                      onTap: () => _open(
                        BuddyHideScreen(
                          progress: progress,
                          audio: widget.audio,
                        ),
                      ),
                    ),
                    for (final game in BuddyAdventure.values)
                      _PlayCard(
                        key: ValueKey('buddy-game-${game.name}'),
                        width: width,
                        icon: const [
                          '☁️',
                          '🦕',
                          '🍮',
                          '🤪',
                          '🎭',
                          '🎆',
                        ][game.index],
                        title: buddyAdventureTitles[game.index],
                        subtitle: const [
                          '变天气 · 帮朋友',
                          '刷沙土 · 孵蛋 · 照顾',
                          '搭软糖 · 过小桥',
                          '你来教 · 抱抱学',
                          '编动作 · 演故事',
                          '画星光 · 放烟花',
                        ][game.index],
                        note: '${progress.buddyAdventureWins(game)} 个小发现',
                        color: const [
                          Color(0xFFD7EAF0),
                          Color(0xFFE1E9C5),
                          Color(0xFFEED7EA),
                          Color(0xFFF2DDD2),
                          Color(0xFFDBDEF2),
                          Color(0xFFDAD1EA),
                        ][game.index],
                        onTap: () => _open(
                          BuddyAdventureScreen(
                            adventure: game,
                            progress: progress,
                            audio: widget.audio,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 26),
            const Text(
              '🍹 我的配方架',
              style: TextStyle(
                color: buddyInk,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            if (progress.juiceRecipes.isEmpty)
              const Text(
                '做好的果汁会放在这里，点一下就能再调一杯。',
                style: TextStyle(color: Color(0xFF738580), height: 1.6),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final recipe in progress.juiceRecipes)
                    ActionChip(
                      key: ValueKey('buddy-recipe-${recipe.id}'),
                      backgroundColor: recipe.color.withValues(alpha: .22),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Text(
                          recipe.label,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      tooltip:
                          '再做一杯${recipe.ingredients.map((fruit) => fruit.name).join('、')}果汁',
                      onPressed: () => _open(
                        BuddyJuiceScreen(
                          progress: progress,
                          audio: widget.audio,
                          recipe: recipe,
                        ),
                      ),
                    ),
                ],
              ),
            if (progress.buddyWords.isNotEmpty) ...[
              const SizedBox(height: 26),
              const Text(
                '👂 一起听过的词语',
                style: TextStyle(
                  color: buddyInk,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final word in progress.buddyWords.toList()..sort())
                    ActionChip(
                      avatar: const Icon(Icons.volume_up_rounded, size: 17),
                      label: Text(word),
                      onPressed: () => widget.audio.speakEnglish(word),
                    ),
                ],
              ),
            ],
          ],
        ),
      );
    },
  );
}

class _PlayCard extends StatelessWidget {
  const _PlayCard({
    super.key,
    required this.width,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.note,
    required this.color,
    required this.onTap,
  });
  final double width;
  final String icon, title, subtitle, note;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Material(
      color: color,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: EdgeInsets.all(width < 240 ? 12 : 20),
          child: width < 240
              ? SizedBox(
                  height: 152,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(icon, style: const TextStyle(fontSize: 35)),
                          const Spacer(),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 19,
                            color: buddyInk,
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Text(
                        title,
                        style: const TextStyle(
                          color: buddyInk,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: buddyInk,
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        note,
                        style: TextStyle(
                          color: buddyInk.withValues(alpha: .65),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                )
              : Row(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 43)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: buddyInk,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: buddyInk,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            note,
                            style: TextStyle(
                              color: buddyInk.withValues(alpha: .65),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: buddyInk),
                  ],
                ),
        ),
      ),
    ),
  );
}
