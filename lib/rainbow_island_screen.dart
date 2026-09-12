import 'dart:async';

import 'package:flutter/material.dart';

import 'buddy_home_screen.dart';
import 'color_challenges.dart';
import 'color_detective_screen.dart';
import 'color_gallery_screen.dart';
import 'game_audio.dart';
import 'island_progress.dart';
import 'magic_studio_screen.dart';
import 'rainbow_repair_screen.dart';
import 'rainbow_repair_levels.dart';
import 'ultraman_training_camp_screen.dart';

class RainbowIslandScreen extends StatelessWidget {
  const RainbowIslandScreen({
    super.key,
    required this.progress,
    required this.audio,
    required this.onOpenLab,
  });

  final IslandProgress progress;
  final GameAudioController audio;
  final VoidCallback onOpenLab;

  static const _welcome = '风把小岛的颜色吹散啦！去不同的地方玩颜色游戏，一起把彩虹带回来吧。';

  void _open(BuildContext context, Widget screen) {
    unawaited(audio.play(GameSound.tap));
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return NarrateOnMount(
      audio: audio,
      text: _welcome,
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF3F7FF),
            body: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFBDE8FF), Color(0xFFF4EEFF)],
                ),
              ),
              child: SafeArea(
                minimum: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                child: Column(
                  children: [
                    _IslandHeader(progress: progress, audio: audio),
                    const SizedBox(height: 12),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 620;
                          final cardWidth = compact
                              ? constraints.maxWidth
                              : (constraints.maxWidth - 14) / 2;
                          return SingleChildScrollView(
                            child: Column(
                              children: [
                                _StoryBanner(audio: audio, narration: _welcome),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 14,
                                  runSpacing: 14,
                                  children: [
                                    _ActivityCard(
                                      key: const ValueKey('activity-buddy'),
                                      width: cardWidth,
                                      icon: '🌷',
                                      title: '小伙伴乐园',
                                      subtitle: '恐龙岛完整冒险与 17 个小世界 · 玩着听英语',
                                      badge: '3–5岁 · 一起玩，一起成长',
                                      colors: const [
                                        Color(0xFF63AA90),
                                        Color(0xFF397F77),
                                      ],
                                      onTap: () => _open(
                                        context,
                                        BuddyHomeScreen(
                                          progress: progress,
                                          audio: audio,
                                        ),
                                      ),
                                    ),
                                    _ActivityCard(
                                      key: const ValueKey('activity-lab'),
                                      width: cardWidth,
                                      icon: '🧪',
                                      title: '颜色实验室',
                                      subtitle: '让颜色精灵抱一抱，发现新的颜色',
                                      badge:
                                          '${progress.completedColorChallenges}/$colorChallengeTotal 关',
                                      colors: const [
                                        Color(0xFF3A2A78),
                                        Color(0xFF1B4F80),
                                      ],
                                      onTap: () {
                                        unawaited(audio.play(GameSound.tap));
                                        onOpenLab();
                                      },
                                    ),
                                    _ActivityCard(
                                      key: const ValueKey('activity-detective'),
                                      width: cardWidth,
                                      icon: '🔎',
                                      title: '色彩侦探',
                                      subtitle: '观察线索，在物品中找到正确颜色',
                                      badge: '${progress.detectiveWins}/5 线索',
                                      colors: const [
                                        Color(0xFF28B487),
                                        Color(0xFF158B86),
                                      ],
                                      onTap: () => _open(
                                        context,
                                        ColorDetectiveScreen(
                                          progress: progress,
                                          audio: audio,
                                        ),
                                      ),
                                    ),
                                    _ActivityCard(
                                      key: const ValueKey('activity-repair'),
                                      width: cardWidth,
                                      icon: '🌈',
                                      title: '彩虹修复师',
                                      subtitle: '探索20张地图，完成100个颜色修复任务',
                                      badge:
                                          '${progress.repairedParts.clamp(0, repairLevelTotal)}/$repairLevelTotal 关',
                                      colors: const [
                                        Color(0xFFFFB34D),
                                        Color(0xFFFF718C),
                                      ],
                                      onTap: () => _open(
                                        context,
                                        RainbowRepairScreen(
                                          progress: progress,
                                          audio: audio,
                                        ),
                                      ),
                                    ),
                                    _ActivityCard(
                                      key: const ValueKey('activity-studio'),
                                      width: cardWidth,
                                      icon: '🎨',
                                      title: '魔法画室',
                                      subtitle: '用彩虹画笔创作独一无二的作品',
                                      badge: '${progress.artworks} 幅作品',
                                      colors: const [
                                        Color(0xFF9B67E8),
                                        Color(0xFFE66FC1),
                                      ],
                                      onTap: () => _open(
                                        context,
                                        MagicStudioScreen(
                                          progress: progress,
                                          audio: audio,
                                        ),
                                      ),
                                    ),
                                    _ActivityCard(
                                      key: const ValueKey('activity-gallery'),
                                      width: cardWidth,
                                      icon: '📖',
                                      title: '色彩图鉴',
                                      subtitle: '收藏发现过的颜色和它们的小秘密',
                                      badge:
                                          '${progress.discoveredCount}/${progress.discoveryTotal} 颜色',
                                      colors: const [
                                        Color(0xFF4C82E6),
                                        Color(0xFF765CD5),
                                      ],
                                      onTap: () => _open(
                                        context,
                                        ColorGalleryScreen(
                                          progress: progress,
                                          audio: audio,
                                        ),
                                      ),
                                    ),
                                    _ActivityCard(
                                      key: const ValueKey('activity-guardian'),
                                      width: cardWidth,
                                      icon: '🦸',
                                      title: '奥特曼训练营',
                                      subtitle: '切水果、怪兽雷达、光线发射等五种趣味玩法',
                                      badge:
                                          '${progress.fruitSliceWins + progress.monsterRadarWins + progress.beamTrainingWins + progress.spaceRescueWins + progress.guardianWins}/58 任务',
                                      colors: const [
                                        Color(0xFF3446A8),
                                        Color(0xFFE54E8B),
                                      ],
                                      onTap: () => _open(
                                        context,
                                        UltramanTrainingCampScreen(
                                          progress: progress,
                                          audio: audio,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _IslandHeader extends StatelessWidget {
  const _IslandHeader({required this.progress, required this.audio});

  final IslandProgress progress;
  final GameAudioController audio;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          key: const ValueKey('island-back'),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: '返回颜色实验室',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 9),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🏝️ 彩虹小岛',
                style: TextStyle(
                  color: Color(0xFF263253),
                  fontSize: 25,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 5),
              Text(
                '今天想去哪里玩？',
                style: TextStyle(
                  color: Color(0xFF64708F),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        _ProgressPill(
          icon: '🎨',
          value: '${progress.discoveredCount}/${progress.discoveryTotal}',
        ),
        const SizedBox(width: 7),
        _ProgressPill(icon: '⭐', value: '${progress.stars}'),
        const SizedBox(width: 7),
        AudioToggleButton(audio: audio),
      ],
    );
  }
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({required this.icon, required this.value});

  final String icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x140E335A), blurRadius: 12)],
      ),
      child: Text(
        '$icon $value',
        style: const TextStyle(
          color: Color(0xFF34405F),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StoryBanner extends StatelessWidget {
  const _StoryBanner({required this.audio, required this.narration});

  final GameAudioController audio;
  final String narration;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white),
        boxShadow: const [
          BoxShadow(
            color: Color(0x180B4778),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🌬️', style: TextStyle(fontSize: 34)),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '风把小岛的颜色吹散啦！',
                  style: TextStyle(
                    color: Color(0xFF35415F),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  '去不同的地方玩颜色游戏，一起把彩虹带回来吧。',
                  style: TextStyle(
                    color: Color(0xFF69738E),
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          RepeatVoiceButton(audio: audio, text: narration),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    super.key,
    required this.width,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.colors,
    required this.onTap,
  });

  final double width;
  final String icon;
  final String title;
  final String subtitle;
  final String badge;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 142,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(26),
          child: Ink(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: colors.last.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Text(icon, style: const TextStyle(fontSize: 34)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 12,
                          height: 1.28,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white70,
                  size: 17,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
