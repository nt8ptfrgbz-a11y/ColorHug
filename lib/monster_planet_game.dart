import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/text.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game_audio.dart';
import 'island_progress.dart';
import 'ultra_assets.dart';

@immutable
class UltraFighter {
  const UltraFighter({
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.imageIndex,
    required this.color,
    required this.speed,
    required this.maxHealth,
    required this.attack,
    required this.skill,
  });

  final String id;
  final String name;
  final String title;
  final String description;
  final int imageIndex;
  final Color color;
  final double speed;
  final int maxHealth;
  final double attack;
  final double skill;
}

const ultraFighters = <UltraFighter>[
  UltraFighter(
    id: 'spark',
    name: '光辉战士',
    title: '均衡型',
    description: '移动、生命和力量都很可靠，第一次出发就选他。',
    imageIndex: 0,
    color: Color(0xFFE94E62),
    speed: 300,
    maxHealth: 110,
    attack: 1,
    skill: 1,
  ),
  UltraFighter(
    id: 'gale',
    name: '疾风战士',
    title: '速度型',
    description: '跑得最快、跳得轻巧，适合灵活躲开怪兽。',
    imageIndex: 1,
    color: Color(0xFF2E91E5),
    speed: 380,
    maxHealth: 92,
    attack: 0.92,
    skill: 1.08,
  ),
  UltraFighter(
    id: 'nova',
    name: '星耀战士',
    title: '力量型',
    description: '拳击和星光必杀威力最大，不过移动会慢一点。',
    imageIndex: 2,
    color: Color(0xFF9C62D7),
    speed: 260,
    maxHealth: 125,
    attack: 1.18,
    skill: 1.25,
  ),
];

abstract final class MonsterBattleRules {
  static int punchDamage(UltraFighter fighter) => (14 * fighter.attack).round();

  static int specialDamage(UltraFighter fighter) =>
      (48 * fighter.skill).round();

  static double energyAfterHit(double current) =>
      (current + 25).clamp(0, 100).toDouble();
}

class MonsterPlanetSelectScreen extends StatefulWidget {
  const MonsterPlanetSelectScreen({
    super.key,
    required this.progress,
    required this.audio,
  });

  final IslandProgress progress;
  final GameAudioController audio;

  @override
  State<MonsterPlanetSelectScreen> createState() =>
      _MonsterPlanetSelectScreenState();
}

class _MonsterPlanetSelectScreenState extends State<MonsterPlanetSelectScreen> {
  int _selectedIndex = 0;

  UltraFighter get _selected => ultraFighters[_selectedIndex];

  void _select(int index) {
    setState(() => _selectedIndex = index);
    final fighter = ultraFighters[index];
    unawaited(
      widget.audio.announce(
        '${fighter.name}，${fighter.title}。${fighter.description}',
        sound: GameSound.tap,
      ),
    );
  }

  void _start() {
    unawaited(widget.audio.play(GameSound.correct));
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MonsterPlanetBattleScreen(
          progress: widget.progress,
          audio: widget.audio,
          fighter: _selected,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NarrateOnMount(
      audio: widget.audio,
      text: '请选择一位奥特战士。红色能力均衡，蓝色速度最快，金紫色力量最强。点击角色就能听介绍。',
      child: Scaffold(
        backgroundColor: const Color(0xFF07132E),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(UltraAssets.monsterPlanet, fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xBB06122E), Color(0xE6071026)],
                ),
              ),
            ),
            SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton.filledTonal(
                        key: const ValueKey('monster-select-back'),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: '返回奥特曼训练营',
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🪐 怪兽星球',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '选择你的奥特战士，准备迎战！',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      RepeatVoiceButton(
                        audio: widget.audio,
                        text: '请选择一位奥特战士。红色能力均衡，蓝色速度最快，金紫色力量最强。',
                        foregroundColor: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final horizontal = constraints.maxWidth >= 680;
                        return GridView.builder(
                          key: const ValueKey('monster-fighter-grid'),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: horizontal ? 3 : 1,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: horizontal ? 0.78 : 2.35,
                              ),
                          itemCount: ultraFighters.length,
                          itemBuilder: (context, index) {
                            final fighter = ultraFighters[index];
                            return _FighterCard(
                              key: ValueKey('fighter-${fighter.id}'),
                              fighter: fighter,
                              selected: index == _selectedIndex,
                              horizontal: horizontal,
                              completed: widget.progress.hasMonsterPlanetWin(
                                fighter.id,
                              ),
                              onTap: () => _select(index),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    key: const ValueKey('monster-planet-start'),
                    onPressed: _start,
                    style: FilledButton.styleFrom(
                      backgroundColor: _selected.color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 34,
                        vertical: 14,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    icon: const Icon(Icons.rocket_launch_rounded),
                    label: Text(
                      '${_selected.name}，出发！',
                      style: const TextStyle(fontFamily: 'Hiragino Sans GB'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FighterCard extends StatelessWidget {
  const _FighterCard({
    super.key,
    required this.fighter,
    required this.selected,
    required this.horizontal,
    required this.completed,
    required this.onTap,
  });

  final UltraFighter fighter;
  final bool selected;
  final bool horizontal;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = Expanded(
      flex: horizontal ? 6 : 4,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: UltraFighterImage(index: fighter.imageIndex),
      ),
    );
    final details = Expanded(
      flex: horizontal ? 5 : 6,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    fighter.name,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (completed)
                  const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFFFD84A),
                    size: 18,
                  ),
              ],
            ),
            Text(
              fighter.title,
              style: TextStyle(
                color: fighter.color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              fighter.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 7),
            _StatBar(
              label: '速度',
              value: fighter.speed / 400,
              color: fighter.color,
            ),
            _StatBar(
              label: '力量',
              value: fighter.attack / 1.25,
              color: fighter.color,
            ),
          ],
        ),
      ),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: const Color(0xE9122146),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? fighter.color : Colors.white24,
              width: selected ? 4 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: fighter.color.withValues(alpha: 0.45),
                      blurRadius: 20,
                    ),
                  ]
                : null,
          ),
          child: horizontal
              ? Column(children: [image, details])
              : Row(children: [image, details]),
        ),
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  const _StatBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 9),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: value.clamp(0, 1),
                minHeight: 5,
                color: color,
                backgroundColor: Colors.white12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum BattleStatus { playing, won, lost }

@immutable
class BattleUiState {
  const BattleUiState({
    required this.playerHealth,
    required this.maxPlayerHealth,
    required this.monsterHealth,
    required this.energy,
    required this.status,
  });

  final int playerHealth;
  final int maxPlayerHealth;
  final int monsterHealth;
  final double energy;
  final BattleStatus status;
}

class MonsterPlanetBattleScreen extends StatefulWidget {
  const MonsterPlanetBattleScreen({
    super.key,
    required this.progress,
    required this.audio,
    required this.fighter,
  });

  final IslandProgress progress;
  final GameAudioController audio;
  final UltraFighter fighter;

  @override
  State<MonsterPlanetBattleScreen> createState() =>
      _MonsterPlanetBattleScreenState();
}

class _MonsterPlanetBattleScreenState extends State<MonsterPlanetBattleScreen> {
  late final MonsterPlanetGame _game;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _game = MonsterPlanetGame(
      fighter: widget.fighter,
      progress: widget.progress,
      audio: widget.audio,
    );
    unawaited(
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]),
    );
  }

  @override
  void dispose() {
    unawaited(
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]),
    );
    super.dispose();
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
    if (_paused) {
      _game.pauseEngine();
      unawaited(widget.audio.speak('游戏暂停了。'));
    } else {
      _game.resumeEngine();
      unawaited(widget.audio.speak('继续战斗！'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return NarrateOnMount(
      audio: widget.audio,
      text:
          '战斗开始！拖动左下角摇杆移动。右下角蓝色按钮跳跃躲开怪兽，红色按钮出拳。拳击命中或成功躲避都会积攒能量，黄色能量满了以后，点击闪电按钮发射必杀光线！',
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Semantics(
              label: '怪兽星球战斗画面。左下摇杆移动，右下按钮跳跃、拳击和发射光线。',
              child: RepaintBoundary(
                key: const ValueKey('monster-planet-game'),
                child: GameWidget<MonsterPlanetGame>(game: _game),
              ),
            ),
            SafeArea(
              minimum: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: Align(
                alignment: Alignment.topCenter,
                child: ValueListenableBuilder<BattleUiState>(
                  valueListenable: _game.battleState,
                  builder: (context, state, _) => _BattleHud(
                    state: state,
                    fighter: widget.fighter,
                    paused: _paused,
                    onBack: () => Navigator.of(context).pop(),
                    onPause: _togglePause,
                    audio: widget.audio,
                  ),
                ),
              ),
            ),
            ValueListenableBuilder<BattleUiState>(
              valueListenable: _game.battleState,
              builder: (context, state, _) {
                if (state.status == BattleStatus.playing) {
                  return const SizedBox.shrink();
                }
                return _BattleResult(
                  won: state.status == BattleStatus.won,
                  fighter: widget.fighter,
                  onAgain: () {
                    setState(() => _paused = false);
                    _game.resetBattle();
                  },
                  onChangeHero: () => Navigator.of(context).pop(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BattleHud extends StatelessWidget {
  const _BattleHud({
    required this.state,
    required this.fighter,
    required this.paused,
    required this.onBack,
    required this.onPause,
    required this.audio,
  });

  final BattleUiState state;
  final UltraFighter fighter;
  final bool paused;
  final VoidCallback onBack;
  final VoidCallback onPause;
  final GameAudioController audio;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundIconButton(
          key: const ValueKey('monster-battle-back'),
          icon: Icons.arrow_back_rounded,
          label: '返回选择角色',
          onPressed: onBack,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _BattleMeter(
            label: fighter.name,
            value: state.playerHealth / state.maxPlayerHealth,
            color: fighter.color,
            icon: Icons.shield_rounded,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _BattleMeter(
            label: '岩角怪兽',
            value: state.monsterHealth / 120,
            color: const Color(0xFFA66AE0),
            icon: Icons.pets_rounded,
          ),
        ),
        const SizedBox(width: 9),
        SizedBox(
          width: 128,
          child: _BattleMeter(
            label: state.energy >= 100 ? '必杀就绪！' : '光线能量',
            value: state.energy / 100,
            color: const Color(0xFFFFD84A),
            icon: Icons.bolt_rounded,
          ),
        ),
        const SizedBox(width: 7),
        _RoundIconButton(
          icon: paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          label: paused ? '继续游戏' : '暂停游戏',
          onPressed: onPause,
        ),
        const SizedBox(width: 5),
        AudioToggleButton(
          audio: audio,
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xAA10234D),
        ),
      ],
    );
  }
}

class _BattleMeter extends StatelessWidget {
  const _BattleMeter({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final double value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xCC081632),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: value.clamp(0, 1),
                    minHeight: 7,
                    color: color,
                    backgroundColor: Colors.white12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: onPressed,
      tooltip: label,
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xCC10234D),
        foregroundColor: Colors.white,
      ),
      icon: Icon(icon),
    );
  }
}

class _BattleResult extends StatelessWidget {
  const _BattleResult({
    required this.won,
    required this.fighter,
    required this.onAgain,
    required this.onChangeHero,
  });

  final bool won;
  final UltraFighter fighter;
  final VoidCallback onAgain;
  final VoidCallback onChangeHero;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0x88040B1A),
      child: Center(
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xF20C1B3E),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: won ? const Color(0xFFFFD84A) : Colors.white30,
              width: 2,
            ),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 28)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(won ? '🌟' : '🛡️', style: const TextStyle(fontSize: 54)),
              Text(
                won ? '守护成功！' : '能量用完啦',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                won ? '${fighter.name}击退了怪兽，获得一颗守护星！' : '没关系，移动躲开攻击，多用拳击积攒能量。',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('monster-change-hero'),
                      onPressed: onChangeHero,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                      ),
                      icon: const Icon(Icons.people_alt_rounded),
                      label: const Text('换英雄'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      key: const ValueKey('monster-play-again'),
                      onPressed: onAgain,
                      style: FilledButton.styleFrom(
                        backgroundColor: fighter.color,
                      ),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('再战一次'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MonsterPlanetGame extends FlameGame {
  MonsterPlanetGame({
    required this.fighter,
    required this.progress,
    required this.audio,
  }) : super(
         camera: CameraComponent.withFixedResolution(width: 1280, height: 720),
       ) {
    images = Images(prefix: 'assets/ultra/');
  }

  static const worldWidth = 2200.0;
  static const groundY = 610.0;
  static const monsterMaxHealth = 120;

  final UltraFighter fighter;
  final IslandProgress progress;
  final GameAudioController audio;

  late final JoystickComponent joystick;
  late final UltraPlayer player;
  late final KaijuEnemy monster;
  late final Sprite _impactSprite;
  late final Sprite _shieldSprite;
  late final Sprite _beamSprite;
  late final Sprite _victorySprite;
  late final ui.Image _kaijuImage;

  int _playerHealth = 0;
  int _monsterHealth = monsterMaxHealth;
  double _energy = 0;
  double _punchCooldown = 0;
  bool _rewardRecorded = false;
  int _monsterVariant = 0;

  final ValueNotifier<BattleUiState> battleState = ValueNotifier(
    const BattleUiState(
      playerHealth: 100,
      maxPlayerHealth: 100,
      monsterHealth: monsterMaxHealth,
      energy: 0,
      status: BattleStatus.playing,
    ),
  );

  BattleStatus get status => battleState.value.status;
  double get energy => _energy;

  @override
  Color backgroundColor() => const Color(0xFF071229);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final loaded = await images.loadAll(const [
      'hero-selection-sheet.png',
      'kaiju-sheet.png',
      'monster-planet.png',
      'battle-vfx-sheet.png',
    ]);
    final heroImage = loaded[0];
    final kaijuImage = loaded[1];
    _kaijuImage = kaijuImage;
    final planetImage = loaded[2];
    final vfxImage = loaded[3];

    _impactSprite = _quarterSprite(vfxImage, 0);
    _shieldSprite = _quarterSprite(vfxImage, 1);
    _beamSprite = _quarterSprite(vfxImage, 2);
    _victorySprite = _quarterSprite(vfxImage, 3);

    world.add(
      SpriteComponent(
        sprite: Sprite(planetImage),
        size: Vector2(worldWidth, 720),
        priority: -20,
      ),
    );
    world.add(_GroundGlow(priority: -10));

    player = UltraPlayer(
      fighter: fighter,
      sprite: Sprite(
        heroImage,
        srcPosition: Vector2(fighter.imageIndex * 512, 0),
        srcSize: Vector2(512, 1024),
      ),
      position: Vector2(850, groundY),
    );
    monster = KaijuEnemy(
      sprite: _quarterSprite(kaijuImage, 0),
      position: Vector2(1350, groundY),
      variantIndex: 0,
    );
    world.addAll([player, monster]);

    camera.viewfinder
      ..anchor = Anchor.center
      ..position = Vector2(850, 360);
    camera.follow(player, horizontalOnly: true, maxSpeed: 520);

    joystick = JoystickComponent(
      knob: CircleComponent(
        radius: 35,
        paint: Paint()..color = const Color(0xE64CD8F4),
      ),
      background: CircleComponent(
        radius: 70,
        paint: Paint()..color = const Color(0x6630568A),
      ),
      knobRadius: 50,
      margin: const EdgeInsets.only(left: 62, bottom: 48),
      priority: 100,
    );
    camera.viewport.add(joystick);
    camera.viewport.addAll([
      _hudButton(
        glyph: _ControlGlyphKind.jump,
        color: const Color(0xFF2F9DE3),
        size: 86,
        margin: const EdgeInsets.only(right: 245, bottom: 55),
        onPressed: jump,
      ),
      _hudButton(
        glyph: _ControlGlyphKind.punch,
        color: const Color(0xFFE65B5F),
        size: 94,
        margin: const EdgeInsets.only(right: 142, bottom: 43),
        onPressed: punch,
      ),
      _hudButton(
        glyph: _ControlGlyphKind.beam,
        color: const Color(0xFFFFBE2E),
        size: 104,
        margin: const EdgeInsets.only(right: 32, bottom: 72),
        onPressed: special,
      ),
    ]);

    _playerHealth = fighter.maxHealth;
    _syncState(status: BattleStatus.playing);
  }

  Sprite _quarterSprite(ui.Image image, int index) {
    const size = 627.0;
    return Sprite(
      image,
      srcPosition: Vector2((index % 2) * size, (index ~/ 2) * size),
      srcSize: Vector2.all(size),
    );
  }

  HudButtonComponent _hudButton({
    required _ControlGlyphKind glyph,
    required Color color,
    required double size,
    required EdgeInsets margin,
    required VoidCallback onPressed,
  }) {
    PositionComponent face(Color buttonColor) => CircleComponent(
      radius: size / 2,
      paint: Paint()..color = buttonColor,
      children: [
        _ControlGlyph(
          kind: glyph,
          position: Vector2.all(size / 2),
          size: Vector2.all(size * 0.48),
          anchor: Anchor.center,
        ),
      ],
    );

    return HudButtonComponent(
      button: face(color.withValues(alpha: 0.90)),
      buttonDown: face(color.withValues(alpha: 0.62)),
      size: Vector2.all(size),
      margin: margin,
      priority: 100,
      onPressed: onPressed,
    );
  }

  @override
  void update(double dt) {
    super.update(math.min(dt, 0.05));
    _punchCooldown = math.max(0, _punchCooldown - dt);
  }

  void jump() {
    if (status != BattleStatus.playing || !player.jump()) return;
    _playEffect('battle_jump.wav', volume: 0.55);
    unawaited(HapticFeedback.selectionClick());
  }

  void punch() {
    if (status != BattleStatus.playing || _punchCooldown > 0) return;
    _punchCooldown = 0.42;
    player.punch();
    _playEffect('battle_punch.wav', volume: 0.72);
    unawaited(HapticFeedback.lightImpact());

    final distance = (monster.position.x - player.position.x).abs();
    if (distance > 245 || monster.isDefeated) return;
    final damage = MonsterBattleRules.punchDamage(fighter);
    _monsterHealth = math.max(0, _monsterHealth - damage);
    _energy = MonsterBattleRules.energyAfterHit(_energy);
    monster.hit();
    _spawnImpact(monster.position + Vector2(0, -130));
    _spawnDamage(monster.position + Vector2(0, -240), damage);
    _syncState();
    if (_monsterHealth == 0) _finishWon();
  }

  void special() {
    if (status != BattleStatus.playing || _energy < 100) return;
    _energy = 0;
    player.special();
    _playEffect('battle_beam.wav', volume: 0.78);
    unawaited(HapticFeedback.heavyImpact());
    final direction = monster.position.x >= player.position.x ? 1.0 : -1.0;
    final distance = (monster.position.x - player.position.x).abs() + 130;
    world.add(
      _TimedSpriteEffect(
        sprite: _beamSprite,
        position: player.position + Vector2(direction * 55, -150),
        size: Vector2(distance.clamp(300, 950), 170),
        anchor: Anchor.centerLeft,
        horizontalDirection: direction,
        duration: 0.70,
        grow: 1.08,
        priority: 25,
      ),
    );
    final damage = MonsterBattleRules.specialDamage(fighter);
    _monsterHealth = math.max(0, _monsterHealth - damage);
    monster.hit(big: true);
    _spawnDamage(monster.position + Vector2(0, -250), damage, special: true);
    _syncState();
    if (_monsterHealth == 0) _finishWon();
  }

  void damagePlayer(int amount) {
    if (status != BattleStatus.playing) return;
    _playerHealth = math.max(0, _playerHealth - amount);
    player.hit();
    _playEffect('battle_hurt.wav', volume: 0.60);
    unawaited(HapticFeedback.mediumImpact());
    world.add(
      _TimedSpriteEffect(
        sprite: _shieldSprite,
        position: player.position + Vector2(0, -145),
        size: Vector2.all(210),
        anchor: Anchor.center,
        duration: 0.35,
        grow: 1.18,
        priority: 24,
      ),
    );
    _spawnDamage(player.position + Vector2(0, -250), amount);
    _syncState();
    if (_playerHealth == 0) {
      _syncState(status: BattleStatus.lost);
      unawaited(
        audio.announce('能量用完啦。没关系，移动躲开怪兽，再试一次吧！', sound: GameSound.wrong),
      );
    }
  }

  void rewardDodge() {
    if (status != BattleStatus.playing) return;
    _energy = (_energy + 10).clamp(0, 100).toDouble();
    world.add(
      _TimedSpriteEffect(
        sprite: _shieldSprite,
        position: player.position + Vector2(0, -145),
        size: Vector2.all(190),
        anchor: Anchor.center,
        duration: 0.28,
        grow: 1.12,
        priority: 24,
      ),
    );
    _syncState();
    unawaited(HapticFeedback.selectionClick());
  }

  void _finishWon() {
    if (status != BattleStatus.playing) return;
    monster.defeat();
    if (!_rewardRecorded) {
      progress.recordMonsterPlanetWin(fighter.id);
      _rewardRecorded = true;
    }
    world.add(
      _TimedSpriteEffect(
        sprite: _victorySprite,
        position: monster.position + Vector2(0, -150),
        size: Vector2.all(310),
        anchor: Anchor.center,
        duration: 1.4,
        grow: 1.35,
        priority: 30,
      ),
    );
    _playEffect('battle_victory.wav', volume: 0.85);
    _syncState(status: BattleStatus.won);
    unawaited(
      audio.announce(
        '守护成功！${fighter.name}击退了怪兽，获得一颗守护星！',
        sound: GameSound.complete,
      ),
    );
  }

  void resetBattle() {
    _playerHealth = fighter.maxHealth;
    _monsterHealth = monsterMaxHealth;
    _energy = 0;
    _punchCooldown = 0;
    _monsterVariant = (_monsterVariant + 1) % 4;
    player.resetAt(Vector2(850, groundY));
    monster
      ..sprite = _quarterSprite(_kaijuImage, _monsterVariant)
      ..resetAt(Vector2(1350, groundY), variantIndex: _monsterVariant);
    camera.viewfinder.position = Vector2(850, 360);
    resumeEngine();
    _syncState(status: BattleStatus.playing);
    unawaited(audio.speak('再次出发！先靠近怪兽，再用拳击积攒能量。'));
  }

  void _spawnImpact(Vector2 at) {
    world.add(
      _TimedSpriteEffect(
        sprite: _impactSprite,
        position: at,
        size: Vector2.all(165),
        anchor: Anchor.center,
        duration: 0.28,
        grow: 1.25,
        priority: 24,
      ),
    );
  }

  void _spawnDamage(Vector2 at, int damage, {bool special = false}) {
    world.add(_DamageText(damage: damage, position: at, special: special));
  }

  void _syncState({BattleStatus? status}) {
    battleState.value = BattleUiState(
      playerHealth: _playerHealth,
      maxPlayerHealth: fighter.maxHealth,
      monsterHealth: _monsterHealth,
      energy: _energy,
      status: status ?? battleState.value.status,
    );
  }

  void _playEffect(String file, {double volume = 1}) {
    if (!audio.enabled) return;
    unawaited(() async {
      try {
        await FlameAudio.play(file, volume: volume);
      } catch (_) {
        // Sound is a bonus; a simulator without an audio device can still play.
      }
    }());
  }
}

class UltraPlayer extends SpriteComponent
    with HasGameReference<MonsterPlanetGame> {
  UltraPlayer({
    required this.fighter,
    required super.sprite,
    required super.position,
  }) : super(
         size: Vector2(178, 330),
         anchor: Anchor.bottomCenter,
         priority: 10,
       );

  final UltraFighter fighter;
  double _verticalVelocity = 0;
  double _animationClock = 0;
  double _punchTimer = 0;
  double _specialTimer = 0;
  double _hitTimer = 0;
  bool _grounded = true;

  bool get isAirborne => !_grounded;

  bool jump() {
    if (!_grounded) return false;
    _grounded = false;
    _verticalVelocity = fighter.id == 'gale' ? -735 : -665;
    return true;
  }

  void punch() => _punchTimer = 0.26;

  void special() => _specialTimer = 0.75;

  void hit() => _hitTimer = 0.28;

  @visibleForTesting
  void applyHorizontalInput(double input, double dt) {
    position.x = (position.x + input * fighter.speed * dt).clamp(
      640,
      MonsterPlanetGame.worldWidth - 640,
    );
    if (input.abs() > 0.08) {
      scale.x = input < 0 ? -1 : 1;
    }
  }

  void resetAt(Vector2 at) {
    position.setFrom(at);
    _verticalVelocity = 0;
    _animationClock = 0;
    _punchTimer = 0;
    _specialTimer = 0;
    _hitTimer = 0;
    _grounded = true;
    angle = 0;
    opacity = 1;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.status != BattleStatus.playing) return;
    final safeDt = math.min(dt, 0.05);
    _animationClock += safeDt;
    _punchTimer = math.max(0, _punchTimer - safeDt);
    _specialTimer = math.max(0, _specialTimer - safeDt);
    _hitTimer = math.max(0, _hitTimer - safeDt);

    final movement = game.joystick.relativeDelta.x;
    applyHorizontalInput(movement, safeDt);

    if (!_grounded) {
      _verticalVelocity += 1600 * safeDt;
      position.y += _verticalVelocity * safeDt;
      if (position.y >= MonsterPlanetGame.groundY) {
        position.y = MonsterPlanetGame.groundY;
        _verticalVelocity = 0;
        _grounded = true;
      }
    } else {
      position.y =
          MonsterPlanetGame.groundY +
          (movement.abs() > 0.08 ? math.sin(_animationClock * 14) * 4 : 0);
    }

    if (_specialTimer > 0) {
      angle = scale.x > 0 ? -0.10 : 0.10;
    } else if (_punchTimer > 0) {
      angle = scale.x > 0 ? -0.16 : 0.16;
    } else {
      angle = movement.abs() > 0.08
          ? math.sin(_animationClock * 12) * 0.035
          : 0;
    }
    opacity = _hitTimer > 0 && (_hitTimer * 30).floor().isEven ? 0.38 : 1;
  }
}

class KaijuEnemy extends SpriteComponent
    with HasGameReference<MonsterPlanetGame> {
  KaijuEnemy({
    required super.sprite,
    required super.position,
    required this.variantIndex,
  }) : super(size: Vector2.all(265), anchor: Anchor.bottomCenter, priority: 9);

  int variantIndex;

  double _attackCooldown = 1.05;
  double _hitTimer = 0;
  double _lungeTimer = 0;
  double _clock = 0;
  bool isDefeated = false;

  void hit({bool big = false}) {
    _hitTimer = big ? 0.52 : 0.25;
  }

  void defeat() {
    isDefeated = true;
    angle = math.pi / 2;
    position.y += 45;
    opacity = 0.65;
  }

  void resetAt(Vector2 at, {required int variantIndex}) {
    position.setFrom(at);
    this.variantIndex = variantIndex;
    _attackCooldown = 1.05;
    _hitTimer = 0;
    _lungeTimer = 0;
    _clock = 0;
    isDefeated = false;
    angle = 0;
    opacity = 1;
    scale.setValues(1, 1);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.status != BattleStatus.playing || isDefeated) return;
    final safeDt = math.min(dt, 0.05);
    _clock += safeDt;
    _attackCooldown = math.max(0, _attackCooldown - safeDt);
    _hitTimer = math.max(0, _hitTimer - safeDt);
    _lungeTimer = math.max(0, _lungeTimer - safeDt);

    final delta = game.player.position.x - position.x;
    final distance = delta.abs();
    if (distance > 188) {
      const monsterPaces = [132.0, 154.0, 118.0, 143.0];
      final pace = monsterPaces[variantIndex % monsterPaces.length];
      position.x += delta.sign * pace * safeDt;
      scale.x = delta < 0 ? -1 : 1;
    } else if (_attackCooldown <= 0) {
      _attackCooldown = 1.15;
      _lungeTimer = 0.25;
      if (game.player.isAirborne &&
          game.player.position.y < MonsterPlanetGame.groundY - 55) {
        game.rewardDodge();
      } else {
        const monsterDamage = [9, 7, 12, 10];
        game.damagePlayer(monsterDamage[variantIndex % monsterDamage.length]);
      }
    }
    position.y = MonsterPlanetGame.groundY + math.sin(_clock * 5) * 3;
    angle = _lungeTimer > 0 ? delta.sign * 0.13 : 0;
    opacity = _hitTimer > 0 && (_hitTimer * 32).floor().isEven ? 0.32 : 1;
  }
}

class _TimedSpriteEffect extends SpriteComponent {
  _TimedSpriteEffect({
    required super.sprite,
    required super.position,
    required super.size,
    required super.anchor,
    required this.duration,
    this.horizontalDirection = 1,
    this.grow = 1,
    super.priority,
  }) : _remaining = duration {
    scale.x = horizontalDirection;
  }

  final double duration;
  final double horizontalDirection;
  final double grow;
  double _remaining;

  @override
  void update(double dt) {
    super.update(dt);
    _remaining -= dt;
    final progress = (1 - _remaining / duration).clamp(0, 1);
    final factor = 1 + (grow - 1) * progress;
    scale.setValues(horizontalDirection * factor, factor);
    opacity = (1 - math.max(0, progress - 0.58) / 0.42).clamp(0, 1);
    if (_remaining <= 0) removeFromParent();
  }
}

class _DamageText extends TextComponent {
  _DamageText({
    required int damage,
    required super.position,
    required bool special,
  }) : _life = 0.7,
       super(
         text: special ? '⚡ -$damage' : '-$damage',
         textRenderer: TextPaint(
           style: TextStyle(
             color: special ? const Color(0xFFFFE15A) : Colors.white,
             fontSize: special ? 34 : 25,
             fontWeight: FontWeight.w900,
             fontFamily: 'Hiragino Sans GB',
             shadows: const [Shadow(color: Colors.black, blurRadius: 7)],
           ),
         ),
         anchor: Anchor.center,
         priority: 35,
       );

  double _life;

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    position.y -= 72 * dt;
    opacity = (_life / 0.7).clamp(0, 1);
    if (_life <= 0) removeFromParent();
  }
}

enum _ControlGlyphKind { jump, punch, beam }

class _ControlGlyph extends PositionComponent {
  _ControlGlyph({
    required this.kind,
    required super.position,
    required super.size,
    required super.anchor,
  });

  final _ControlGlyphKind kind;
  final Paint _paint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    switch (kind) {
      case _ControlGlyphKind.jump:
        final path = Path()
          ..moveTo(size.x * 0.50, size.y * 0.05)
          ..lineTo(size.x * 0.92, size.y * 0.48)
          ..lineTo(size.x * 0.66, size.y * 0.48)
          ..lineTo(size.x * 0.66, size.y * 0.95)
          ..lineTo(size.x * 0.34, size.y * 0.95)
          ..lineTo(size.x * 0.34, size.y * 0.48)
          ..lineTo(size.x * 0.08, size.y * 0.48)
          ..close();
        canvas.drawPath(path, _paint);
        return;
      case _ControlGlyphKind.punch:
        final fingerRadius = size.x * 0.12;
        for (var index = 0; index < 4; index++) {
          canvas.drawCircle(
            Offset(size.x * (0.19 + index * 0.205), size.y * 0.32),
            fingerRadius,
            _paint,
          );
        }
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.x * 0.14,
              size.y * 0.30,
              size.x * 0.72,
              size.y * 0.52,
            ),
            Radius.circular(size.x * 0.16),
          ),
          _paint,
        );
        canvas.drawCircle(
          Offset(size.x * 0.18, size.y * 0.68),
          size.x * 0.16,
          _paint,
        );
        return;
      case _ControlGlyphKind.beam:
        final path = Path()
          ..moveTo(size.x * 0.57, 0)
          ..lineTo(size.x * 0.16, size.y * 0.56)
          ..lineTo(size.x * 0.46, size.y * 0.56)
          ..lineTo(size.x * 0.34, size.y)
          ..lineTo(size.x * 0.86, size.y * 0.39)
          ..lineTo(size.x * 0.56, size.y * 0.39)
          ..close();
        canvas.drawPath(path, _paint);
        return;
    }
  }
}

class _GroundGlow extends PositionComponent {
  _GroundGlow({super.priority})
    : super(position: Vector2.zero(), size: Vector2(2200, 720));

  final Paint _linePaint = Paint()
    ..color = const Color(0x665CE8FF)
    ..strokeWidth = 3;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    for (var x = 40.0; x < size.x; x += 150) {
      canvas.drawLine(
        Offset(x, MonsterPlanetGame.groundY + 12),
        Offset(x + 68, MonsterPlanetGame.groundY + 12),
        _linePaint,
      );
    }
  }
}
