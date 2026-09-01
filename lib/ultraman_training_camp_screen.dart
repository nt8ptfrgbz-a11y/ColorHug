import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'fruit_slice_game_screen.dart';
import 'game_audio.dart';
import 'island_progress.dart';
import 'light_guardian_screen.dart';
import 'ultra_assets.dart';

class UltramanTrainingCampScreen extends StatelessWidget {
  const UltramanTrainingCampScreen({
    super.key,
    required this.progress,
    required this.audio,
  });

  final IslandProgress progress;
  final GameAudioController audio;

  static const _welcome = '欢迎来到奥特曼训练营！先用一根手指玩水果切切乐，也可以挑战怪兽雷达、光线发射、宇宙救援和能量护盾。';

  void _open(BuildContext context, Widget screen) {
    unawaited(audio.play(GameSound.tap));
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return NarrateOnMount(
      audio: audio,
      text: _welcome,
      voice: GameVoice.hero,
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, _) => Scaffold(
          backgroundColor: const Color(0xFF071635),
          body: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(UltraAssets.trainingBase, fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xAA07112D), Color(0x3307132D)],
                  ),
                ),
              ),
              SafeArea(
                minimum: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Column(
                  children: [
                    _TrainingHeader(
                      title: '🚀 奥特曼训练营',
                      subtitle: '听指令、练本领、守护宇宙',
                      stars: progress.stars,
                    ),
                    const SizedBox(height: 10),
                    _CampWelcome(audio: audio),
                    const SizedBox(height: 10),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 720 ? 2 : 1;
                          return GridView.count(
                            key: const ValueKey('ultra-game-grid'),
                            crossAxisCount: columns,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: columns == 2 ? 2.65 : 2.55,
                            children: [
                              _TrainingCard(
                                key: const ValueKey('ultra-game-fruit-slice'),
                                title: '水果切切乐',
                                subtitle: '一根手指划过大水果，漏掉不扣分',
                                badge:
                                    '${progress.fruitSliceWins}/${fruitSliceLevels.length}',
                                preview: const _FruitSlicePreview(),
                                color: const Color(0xFFE84C75),
                                onTap: () => _open(
                                  context,
                                  FruitSliceGameScreen(
                                    progress: progress,
                                    audio: audio,
                                  ),
                                ),
                              ),
                              _TrainingCard(
                                key: const ValueKey('ultra-game-radar'),
                                title: '怪兽雷达',
                                subtitle: '听特征，找到雷达锁定的怪兽',
                                badge:
                                    '${progress.monsterRadarWins}/${radarMissions.length}',
                                preview: const KaijuSprite(index: 0),
                                color: const Color(0xFF7B4BD2),
                                onTap: () => _open(
                                  context,
                                  MonsterRadarScreen(
                                    progress: progress,
                                    audio: audio,
                                  ),
                                ),
                              ),
                              _TrainingCard(
                                key: const ValueKey('ultra-game-beam'),
                                title: '光线发射',
                                subtitle: '看准能量环，在正确时机发射',
                                badge:
                                    '${progress.beamTrainingWins}/$beamMissionTotal',
                                preview: const UltraHeroImage(),
                                color: const Color(0xFF237BC9),
                                onTap: () => _open(
                                  context,
                                  BeamTrainingScreen(
                                    progress: progress,
                                    audio: audio,
                                  ),
                                ),
                              ),
                              _TrainingCard(
                                key: const ValueKey('ultra-game-rescue'),
                                title: '宇宙救援',
                                subtitle: '观察遇到的困难，选择救援工具',
                                badge:
                                    '${progress.spaceRescueWins}/${rescueMissions.length}',
                                preview: const RescueSceneImage(index: 0),
                                color: const Color(0xFF13A58B),
                                onTap: () => _open(
                                  context,
                                  SpaceRescueScreen(
                                    progress: progress,
                                    audio: audio,
                                  ),
                                ),
                              ),
                              _TrainingCard(
                                key: const ValueKey('ultra-game-guardian'),
                                title: '互补色护盾',
                                subtitle: '用对比色能量破解怪兽护盾',
                                badge:
                                    '${progress.guardianWins}/${guardianMissions.length}',
                                preview: const KaijuSprite(index: 3),
                                color: const Color(0xFFE14E84),
                                onTap: () => _open(
                                  context,
                                  LightGuardianScreen(
                                    progress: progress,
                                    audio: audio,
                                  ),
                                ),
                              ),
                            ],
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

class _CampWelcome extends StatelessWidget {
  const _CampWelcome({required this.audio});

  final GameAudioController audio;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xE6112148),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD84A)),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
              '先试试一根手指就能玩的水果切切乐，英雄会用声音为你加油！',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          RepeatVoiceButton(
            audio: audio,
            text: UltramanTrainingCampScreen._welcome,
            voice: GameVoice.hero,
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _FruitSlicePreview extends StatelessWidget {
  const _FruitSlicePreview();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(23)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/fruit_game/fruit-training-bg.png',
            fit: BoxFit.cover,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x001C65A3), Color(0x66133C76)],
              ),
            ),
          ),
          const Center(
            child: Text(
              '🍉  🍓\n  🍊',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 27,
                height: 0.9,
                shadows: [Shadow(color: Colors.black38, blurRadius: 5)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainingCard extends StatelessWidget {
  const _TrainingCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.preview,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String badge;
  final Widget preview;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.96), const Color(0xEB101E45)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white30),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(width: 116, height: double.infinity, child: preview),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
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
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 7),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          child: Text(
                            '$badge ⭐',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrainingHeader extends StatelessWidget {
  const _TrainingHeader({
    required this.title,
    required this.subtitle,
    required this.stars,
    this.backTooltip = '返回彩虹小岛',
  });

  final String title;
  final String subtitle;
  final int stars;
  final String backTooltip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: () => Navigator.of(context).pop(),
          tooltip: backTooltip,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
        ),
        Text(
          '⭐ $stars',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

@immutable
class RadarMission {
  const RadarMission({
    required this.monsterIndex,
    required this.clue,
    required this.visualClue,
  });

  final int monsterIndex;
  final String clue;
  final String visualClue;
}

const radarMissions = <RadarMission>[
  RadarMission(monsterIndex: 0, clue: '找到长着三只大眼睛的紫色怪兽', visualClue: '👁️ × 3'),
  RadarMission(
    monsterIndex: 1,
    clue: '找到背着硬硬龟壳、有两只金角的怪兽',
    visualClue: '🛡️ + 🛸',
  ),
  RadarMission(
    monsterIndex: 2,
    clue: '找到只有一只大眼睛、身上有黄斑点的蓝怪兽',
    visualClue: '👁️ × 1',
  ),
  RadarMission(
    monsterIndex: 3,
    clue: '找到头上有两根天线的橙色机器怪兽',
    visualClue: '📡 + 🤖',
  ),
];

class MonsterRadarScreen extends StatefulWidget {
  const MonsterRadarScreen({
    super.key,
    required this.progress,
    required this.audio,
  });

  final IslandProgress progress;
  final GameAudioController audio;

  @override
  State<MonsterRadarScreen> createState() => _MonsterRadarScreenState();
}

class _MonsterRadarScreenState extends State<MonsterRadarScreen> {
  late int _round;
  int? _selected;
  bool _solved = false;
  String _message = '听一听奥特曼的雷达提示，再点击怪兽。';

  RadarMission get _mission => radarMissions[_round];

  @override
  void initState() {
    super.initState();
    _round = widget.progress.monsterRadarWins % radarMissions.length;
  }

  void _choose(int index) {
    if (_solved) return;
    final correct = index == _mission.monsterIndex;
    setState(() {
      _selected = index;
      _solved = correct;
      _message = correct ? '雷达锁定成功！你的观察力真厉害！' : '这只怪兽的特征不一样，再听一遍提示吧。';
    });
    if (correct) {
      widget.progress.recordUltraTrainingWin('radar', _round);
      HapticFeedback.heavyImpact();
    }
    unawaited(
      widget.audio.announce(
        _message,
        sound: correct ? GameSound.correct : GameSound.wrong,
        voice: correct ? GameVoice.hero : GameVoice.monster,
      ),
    );
  }

  void _next() {
    setState(() {
      _round = (_round + 1) % radarMissions.length;
      _selected = null;
      _solved = false;
      _message = '新的雷达信号来了！';
    });
    unawaited(widget.audio.announce(_mission.clue, voice: GameVoice.hero));
  }

  @override
  Widget build(BuildContext context) {
    final narration = '怪兽雷达已启动。${_mission.clue}。';
    return NarrateOnMount(
      audio: widget.audio,
      text: narration,
      voice: GameVoice.hero,
      child: _GameBackdrop(
        child: Column(
          children: [
            _TrainingHeader(
              title: '🛰️ 怪兽雷达',
              subtitle: '任务 ${_round + 1}/${radarMissions.length} · 观察力训练',
              stars: widget.progress.stars,
              backTooltip: '返回奥特曼训练营',
            ),
            const SizedBox(height: 10),
            _InstructionPanel(
              icon: _mission.visualClue,
              text: _solved || _selected != null ? _message : _mission.clue,
              audio: widget.audio,
              onNext: _solved ? _next : null,
              nextKey: 'radar-next',
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                key: const ValueKey('radar-grid'),
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.sizeOf(context).width >= 700
                      ? 4
                      : 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemCount: 4,
                itemBuilder: (context, index) {
                  final selected = _selected == index;
                  final correct = _solved && index == _mission.monsterIndex;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: ValueKey('radar-monster-$index'),
                      onTap: _solved ? null : () => _choose(index),
                      borderRadius: BorderRadius.circular(24),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: const Color(0xDE152856),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: correct
                                ? const Color(0xFFFFD84A)
                                : selected
                                ? const Color(0xFFFF7D95)
                                : Colors.white30,
                            width: selected || correct ? 4 : 2,
                          ),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: KaijuSprite(index: index),
                            ),
                            if (correct)
                              const Align(
                                alignment: Alignment.topRight,
                                child: Padding(
                                  padding: EdgeInsets.all(9),
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFFFFD84A),
                                    size: 30,
                                  ),
                                ),
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
    );
  }
}

const beamMissionTotal = 8;
const _beamTargets = <double>[0.50, 0.34, 0.66, 0.44, 0.72, 0.28, 0.58, 0.40];

class BeamTrainingScreen extends StatefulWidget {
  const BeamTrainingScreen({
    super.key,
    required this.progress,
    required this.audio,
  });

  final IslandProgress progress;
  final GameAudioController audio;

  @override
  State<BeamTrainingScreen> createState() => _BeamTrainingScreenState();
}

class _BeamTrainingScreenState extends State<BeamTrainingScreen>
    with SingleTickerProviderStateMixin {
  late int _round;
  late final AnimationController _cursorController;
  bool _solved = false;
  String _message = '等发光能量球进入黄色能量环，就点击发射！';

  double get _cursor => 0.05 + (_cursorController.value * 0.90);
  double get _target => _beamTargets[_round];

  @override
  void initState() {
    super.initState();
    _round = widget.progress.beamTrainingWins % beamMissionTotal;
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  void _fire() {
    if (_solved) return;
    final tolerance = math.max(0.075, 0.13 - (_round * 0.007));
    final hit = (_cursor - _target).abs() <= tolerance;
    setState(() {
      _solved = hit;
      _message = hit ? '命中能量环！奥特光线发射成功！' : '差一点点！看着发光能量球，进入黄色环再发射。';
    });
    if (hit) {
      _cursorController.stop();
      widget.progress.recordUltraTrainingWin('beam', _round);
      HapticFeedback.heavyImpact();
    }
    unawaited(
      widget.audio.announce(
        _message,
        sound: hit ? GameSound.complete : GameSound.wrong,
        voice: GameVoice.hero,
      ),
    );
  }

  void _next() {
    setState(() {
      _round = (_round + 1) % beamMissionTotal;
      _solved = false;
      _message = '新的能量环出现了，准备发射！';
    });
    _cursorController.repeat(reverse: true);
    unawaited(widget.audio.announce(_message, voice: GameVoice.hero));
  }

  @override
  Widget build(BuildContext context) {
    return NarrateOnMount(
      audio: widget.audio,
      text: _message,
      voice: GameVoice.hero,
      child: _GameBackdrop(
        child: Column(
          children: [
            _TrainingHeader(
              title: '✨ 光线发射',
              subtitle: '第 ${_round + 1}/$beamMissionTotal 训练 · 反应力',
              stars: widget.progress.stars,
              backTooltip: '返回奥特曼训练营',
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                key: const ValueKey('beam-scene'),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white30),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(UltraAssets.trainingBase, fit: BoxFit.cover),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0x44000000), Color(0x77051438)],
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 12,
                      bottom: -12,
                      width: 185,
                      height: 285,
                      child: UltraHeroImage(),
                    ),
                    Positioned(
                      right: 18,
                      top: 16,
                      width: 145,
                      height: 145,
                      child: KaijuSprite(index: _round % 4),
                    ),
                    if (_solved)
                      Positioned(
                        left: 150,
                        right: 112,
                        top: 130,
                        height: 24,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.white,
                                Color(0xFF65DFFF),
                                Color(0x0000D9FF),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFF42D7FF),
                                blurRadius: 22,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 18,
                      height: 62,
                      child: AnimatedBuilder(
                        animation: _cursorController,
                        builder: (context, _) => _EnergyTimingBar(
                          cursor: _cursor,
                          target: _target,
                          solved: _solved,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 9, 10, 9),
              decoration: BoxDecoration(
                color: const Color(0xF2FFFFFF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF273657),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  RepeatVoiceButton(
                    audio: widget.audio,
                    text: _message,
                    voice: GameVoice.hero,
                  ),
                  const SizedBox(width: 6),
                  if (_solved)
                    FilledButton.icon(
                      key: const ValueKey('beam-next'),
                      onPressed: _next,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('下一关'),
                    )
                  else
                    FilledButton.icon(
                      key: const ValueKey('beam-launch'),
                      onPressed: _fire,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFED405D),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                      ),
                      icon: const Icon(Icons.bolt_rounded),
                      label: const Text('发射！'),
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

class _EnergyTimingBar extends StatelessWidget {
  const _EnergyTimingBar({
    required this.cursor,
    required this.target,
    required this.solved,
  });

  final double cursor;
  final double target;
  final bool solved;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final targetX = constraints.maxWidth * target;
        final cursorX = constraints.maxWidth * cursor;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              top: 18,
              bottom: 18,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xCC0B1737),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white54, width: 2),
                ),
              ),
            ),
            Positioned(
              left: targetX - 29,
              top: 4,
              width: 58,
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFD84A), width: 6),
                  boxShadow: const [
                    BoxShadow(color: Color(0xAAFFD84A), blurRadius: 18),
                  ],
                ),
              ),
            ),
            Positioned(
              left: cursorX - 17,
              top: 14,
              width: 34,
              height: 34,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: solved
                      ? const Color(0xFFFFF5A8)
                      : const Color(0xFF62DDFF),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFF62DDFF),
                      blurRadius: 18,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Color(0xFF25355D),
                  size: 20,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

@immutable
class RescueTool {
  const RescueTool(this.id, this.emoji, this.name);

  final String id;
  final String emoji;
  final String name;
}

@immutable
class RescueMission {
  const RescueMission({
    required this.scene,
    required this.prompt,
    required this.answer,
    required this.options,
    required this.success,
  });

  final int scene;
  final String prompt;
  final String answer;
  final List<RescueTool> options;
  final String success;
}

const _rope = RescueTool('rope', '🪢', '安全绳');
const _extinguisher = RescueTool('extinguisher', '🧯', '灭火器');
const _bridge = RescueTool('bridge', '🌉', '便携浮桥');
const _medical = RescueTool('medical', '🩹', '急救箱');
const _flashlight = RescueTool('flashlight', '🔦', '手电筒');
const _radio = RescueTool('radio', '📻', '宇宙电台');
const _snack = RescueTool('snack', '🍪', '能量饼干');

const rescueMissions = <RescueMission>[
  RescueMission(
    scene: 0,
    prompt: '小宇航员飘离了空间站，选什么能安全地把他拉回来？',
    answer: 'rope',
    options: [_rope, _flashlight, _snack],
    success: '安全绳连住了宇航员，救援成功！',
  ),
  RescueMission(
    scene: 1,
    prompt: '外星森林里有一堆小火苗，用什么可以把火安全熄灭？',
    answer: 'extinguisher',
    options: [_radio, _extinguisher, _rope],
    success: '灭火器把小火苗熄灭了，森林安全啦！',
  ),
  RescueMission(
    scene: 2,
    prompt: '月球车前面的水晶桥断了，选什么让它安全通过？',
    answer: 'bridge',
    options: [_medical, _bridge, _flashlight],
    success: '便携浮桥搭好了，月球车可以继续前进！',
  ),
  RescueMission(
    scene: 3,
    prompt: '宇宙宝宝的脚受伤了，我们应该选哪个工具帮助它？',
    answer: 'medical',
    options: [_snack, _radio, _medical],
    success: '用急救箱包扎好伤口，宇宙宝宝微笑了！',
  ),
];

class SpaceRescueScreen extends StatefulWidget {
  const SpaceRescueScreen({
    super.key,
    required this.progress,
    required this.audio,
  });

  final IslandProgress progress;
  final GameAudioController audio;

  @override
  State<SpaceRescueScreen> createState() => _SpaceRescueScreenState();
}

class _SpaceRescueScreenState extends State<SpaceRescueScreen> {
  late int _round;
  String? _selected;
  bool _solved = false;
  String _message = '观察救援画面，听完问题，再选择工具。';

  RescueMission get _mission => rescueMissions[_round];

  @override
  void initState() {
    super.initState();
    _round = widget.progress.spaceRescueWins % rescueMissions.length;
  }

  void _choose(RescueTool tool) {
    if (_solved) return;
    final correct = tool.id == _mission.answer;
    setState(() {
      _selected = tool.id;
      _solved = correct;
      _message = correct ? _mission.success : '${tool.name}这次帮不上忙，再想想什么工具最安全。';
    });
    if (correct) {
      widget.progress.recordUltraTrainingWin('rescue', _round);
      HapticFeedback.heavyImpact();
    }
    unawaited(
      widget.audio.announce(
        _message,
        sound: correct ? GameSound.complete : GameSound.wrong,
        voice: correct ? GameVoice.hero : GameVoice.monster,
      ),
    );
  }

  void _next() {
    setState(() {
      _round = (_round + 1) % rescueMissions.length;
      _selected = null;
      _solved = false;
      _message = '新的救援任务来了！';
    });
    unawaited(widget.audio.announce(_mission.prompt, voice: GameVoice.hero));
  }

  @override
  Widget build(BuildContext context) {
    return NarrateOnMount(
      audio: widget.audio,
      text: _mission.prompt,
      voice: GameVoice.hero,
      child: _GameBackdrop(
        child: Column(
          children: [
            _TrainingHeader(
              title: '🛸 宇宙救援',
              subtitle: '任务 ${_round + 1}/${rescueMissions.length} · 安全判断',
              stars: widget.progress.stars,
              backTooltip: '返回奥特曼训练营',
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                key: const ValueKey('rescue-scene'),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white30),
                ),
                clipBehavior: Clip.antiAlias,
                child: RescueSceneImage(index: _mission.scene),
              ),
            ),
            const SizedBox(height: 10),
            _InstructionPanel(
              icon: '🆘',
              text: _solved || _selected != null ? _message : _mission.prompt,
              audio: widget.audio,
              onNext: _solved ? _next : null,
              nextKey: 'rescue-next',
            ),
            const SizedBox(height: 9),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 8,
              children: _mission.options.map((tool) {
                final selected = _selected == tool.id;
                final correct = _solved && tool.id == _mission.answer;
                return Semantics(
                  button: true,
                  label: tool.name,
                  child: InkWell(
                    key: ValueKey('rescue-tool-${tool.id}'),
                    onTap: _solved ? null : () => _choose(tool),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 112,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xEEFFFFFF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: correct
                              ? const Color(0xFFFFC928)
                              : selected
                              ? const Color(0xFFFF718C)
                              : Colors.white,
                          width: selected || correct ? 4 : 2,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tool.emoji,
                            style: const TextStyle(fontSize: 31),
                          ),
                          Text(
                            tool.name,
                            style: const TextStyle(
                              color: Color(0xFF283858),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructionPanel extends StatelessWidget {
  const _InstructionPanel({
    required this.icon,
    required this.text,
    required this.audio,
    required this.onNext,
    required this.nextKey,
  });

  final String icon;
  final String text;
  final GameAudioController audio;
  final VoidCallback? onNext;
  final String nextKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 9, 9, 9),
      decoration: BoxDecoration(
        color: const Color(0xF2FFFFFF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF273657),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          RepeatVoiceButton(audio: audio, text: text, voice: GameVoice.hero),
          if (onNext != null)
            IconButton.filled(
              key: ValueKey(nextKey),
              onPressed: onNext,
              tooltip: '下一个任务',
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
        ],
      ),
    );
  }
}

class _GameBackdrop extends StatelessWidget {
  const _GameBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071635),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(UltraAssets.trainingBase, fit: BoxFit.cover),
          const ColoredBox(color: Color(0xA6071431)),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: child,
          ),
        ],
      ),
    );
  }
}
