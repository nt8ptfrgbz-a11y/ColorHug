import 'dart:async';

import 'package:flutter/material.dart';

import 'game_audio.dart';
import 'island_progress.dart';

class ColorGalleryScreen extends StatelessWidget {
  const ColorGalleryScreen({
    super.key,
    required this.progress,
    required this.audio,
  });

  final IslandProgress progress;
  final GameAudioController audio;

  void _showDiscovery(BuildContext context, ColorDiscovery discovery) {
    final unlocked = progress.hasDiscovered(discovery.name);
    final narration = unlocked
        ? '这是${discovery.name}。${discovery.fact}'
        : '这个颜色还没有发现。去小岛玩游戏，就有机会找到它！';
    unawaited(
      audio.announce(
        narration,
        sound: unlocked ? GameSound.discover : GameSound.wrong,
      ),
    );
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          decoration: const BoxDecoration(
            color: Color(0xFFFFFBF2),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8CFCA),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 17),
                Container(
                  width: 88,
                  height: 88,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: unlocked ? discovery.color : const Color(0xFFB7BAC1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (unlocked
                                    ? discovery.color
                                    : const Color(0xFFB7BAC1))
                                .withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text(
                    unlocked ? discovery.emoji : '❓',
                    style: const TextStyle(fontSize: 45),
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  unlocked ? discovery.name : '神秘颜色',
                  style: const TextStyle(
                    color: Color(0xFF4A3E49),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  unlocked ? discovery.fact : '去小岛玩游戏，就有机会发现它！',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF786B75),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                RepeatVoiceButton(audio: audio, text: narration),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const narration = '欢迎来到色彩图鉴。点击亮起来的颜色卡片，就能听到颜色的小秘密。';
    return NarrateOnMount(
      audio: audio,
      text: narration,
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFFFF4E8),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '📖 色彩图鉴',
                              style: TextStyle(
                                color: Color(0xFF514047),
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '每发现一种颜色，就会点亮一张卡片',
                              style: TextStyle(
                                color: Color(0xFF8B7179),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          '🎨 ${progress.discoveredCount}/${progress.discoveryTotal}',
                          key: const ValueKey('gallery-progress'),
                          style: const TextStyle(
                            color: Color(0xFF66525A),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 760
                            ? 5
                            : constraints.maxWidth >= 520
                            ? 4
                            : 3;
                        return GridView.builder(
                          padding: const EdgeInsets.only(bottom: 10),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 11,
                                mainAxisSpacing: 11,
                                childAspectRatio: 0.84,
                              ),
                          itemCount: colorDiscoveryCatalog.length,
                          itemBuilder: (context, index) {
                            final discovery = colorDiscoveryCatalog[index];
                            return _DiscoveryCard(
                              key: ValueKey('gallery-color-${discovery.name}'),
                              discovery: discovery,
                              unlocked: progress.hasDiscovered(discovery.name),
                              onTap: () => _showDiscovery(context, discovery),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DiscoveryCard extends StatelessWidget {
  const _DiscoveryCard({
    super.key,
    required this.discovery,
    required this.unlocked,
    required this.onTap,
  });

  final ColorDiscovery discovery;
  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayColor = unlocked ? discovery.color : const Color(0xFFB9BCC2);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(23),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: unlocked ? 0.92 : 0.60),
            borderRadius: BorderRadius.circular(23),
            border: Border.all(
              color: unlocked
                  ? displayColor.withValues(alpha: 0.35)
                  : Colors.white,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: displayColor.withValues(alpha: unlocked ? 0.20 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: displayColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: displayColor.withValues(alpha: 0.35),
                      blurRadius: 11,
                    ),
                  ],
                ),
                child: Text(
                  unlocked ? discovery.emoji : '?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: unlocked ? 28 : 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Text(
                unlocked ? discovery.name : '等待发现',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: unlocked
                      ? const Color(0xFF4F4349)
                      : const Color(0xFF969399),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                unlocked ? '点击看秘密' : '去小岛寻找',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF9B8C91),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
