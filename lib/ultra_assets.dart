import 'package:flutter/material.dart';

abstract final class UltraAssets {
  static const hero = 'assets/ultra/ultraman-hero.png';
  static const kaijuSheet = 'assets/ultra/kaiju-sheet.png';
  static const trainingBase = 'assets/ultra/training-base.png';
  static const rescueScenes = 'assets/ultra/rescue-scenes.png';
  static const heroSelectionSheet = 'assets/ultra/hero-selection-sheet.png';
  static const fighterImages = <String>[
    'assets/ultra/hero-spark.png',
    'assets/ultra/hero-gale.png',
    'assets/ultra/hero-nova.png',
  ];
  static const monsterPlanet = 'assets/ultra/monster-planet.png';
  static const battleVfxSheet = 'assets/ultra/battle-vfx-sheet.png';
}

class UltraFighterImage extends StatelessWidget {
  const UltraFighterImage({
    super.key,
    required this.index,
    this.fit = BoxFit.contain,
  });

  final int index;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      UltraAssets.fighterImages[index % UltraAssets.fighterImages.length],
      fit: fit,
      filterQuality: FilterQuality.high,
      semanticLabel: '可选择的奥特曼战士',
    );
  }
}

class UltraHeroImage extends StatelessWidget {
  const UltraHeroImage({super.key, this.fit = BoxFit.contain});

  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      UltraAssets.hero,
      fit: fit,
      filterQuality: FilterQuality.high,
      semanticLabel: '奥特曼',
    );
  }
}

class KaijuSprite extends StatelessWidget {
  const KaijuSprite({super.key, required this.index});

  final int index;

  static const _alignments = <Alignment>[
    Alignment.topLeft,
    Alignment.topRight,
    Alignment.bottomLeft,
    Alignment.bottomRight,
  ];

  @override
  Widget build(BuildContext context) {
    final alignment = _alignments[index % _alignments.length];
    return ClipRect(
      child: Transform.scale(
        scale: 2,
        alignment: alignment,
        child: Image.asset(
          UltraAssets.kaijuSheet,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          semanticLabel: '可爱怪兽',
        ),
      ),
    );
  }
}

class RescueSceneImage extends StatelessWidget {
  const RescueSceneImage({super.key, required this.index});

  final int index;

  static const _alignments = <Alignment>[
    Alignment.topLeft,
    Alignment.topRight,
    Alignment.bottomLeft,
    Alignment.bottomRight,
  ];

  @override
  Widget build(BuildContext context) {
    final alignment = _alignments[index % _alignments.length];
    return ClipRect(
      child: Transform.scale(
        scale: 2,
        alignment: alignment,
        child: Image.asset(
          UltraAssets.rescueScenes,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          semanticLabel: '宇宙救援场景',
        ),
      ),
    );
  }
}
