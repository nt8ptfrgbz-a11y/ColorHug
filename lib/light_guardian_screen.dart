import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'color_challenges.dart';
import 'color_mixer.dart';
import 'game_audio.dart';
import 'island_progress.dart';
import 'ultra_assets.dart';

@immutable
class GuardianMission {
  const GuardianMission({
    required this.place,
    required this.monster,
    required this.shield,
    required this.answer,
    required this.discovery,
  });

  final String place;
  final String monster;
  final ColorSeed shield;
  final ColorSeed answer;
  final String discovery;

  ColorIngredient get shieldColor => ingredientForSeed(shield);
  ColorIngredient get answerColor => ingredientForSeed(answer);

  String get prompt =>
      '$place出现了$monster，它举起${shieldColor.name}护盾。选择一种对比色能量，让护盾恢复平衡！';
}

const guardianMissions = <GuardianMission>[
  GuardianMission(
    place: '星光城市',
    monster: '雾角兽',
    shield: ColorSeed.red,
    answer: ColorSeed.cyan,
    discovery: '红色和青色站在色环两边，是醒目的互补伙伴',
  ),
  GuardianMission(
    place: '海边灯塔',
    monster: '泡泡兽',
    shield: ColorSeed.orange,
    answer: ColorSeed.blue,
    discovery: '橙色与蓝色互相衬托，会让彼此更加明亮',
  ),
  GuardianMission(
    place: '月亮基地',
    monster: '影子兽',
    shield: ColorSeed.yellow,
    answer: ColorSeed.purple,
    discovery: '黄色和紫色是一组很有力量的对比色',
  ),
  GuardianMission(
    place: '森林电站',
    monster: '藤蔓兽',
    shield: ColorSeed.green,
    answer: ColorSeed.magenta,
    discovery: '绿色与品红色相遇，会形成强烈又活泼的对比',
  ),
  GuardianMission(
    place: '云端机场',
    monster: '旋风兽',
    shield: ColorSeed.blue,
    answer: ColorSeed.orange,
    discovery: '蓝色的冷静和橙色的温暖能互相平衡',
  ),
  GuardianMission(
    place: '水晶山谷',
    monster: '晶石兽',
    shield: ColorSeed.purple,
    answer: ColorSeed.yellow,
    discovery: '紫色旁边放上黄色，两种颜色都会更突出',
  ),
  GuardianMission(
    place: '珊瑚海沟',
    monster: '深潜兽',
    shield: ColorSeed.cyan,
    answer: ColorSeed.red,
    discovery: '青色和红色的距离很远，所以对比特别清楚',
  ),
  GuardianMission(
    place: '机器人港口',
    monster: '磁铁兽',
    shield: ColorSeed.magenta,
    answer: ColorSeed.green,
    discovery: '品红色与绿色是舞台上常用的醒目搭档',
  ),
  GuardianMission(
    place: '沙漠列车站',
    monster: '沙丘兽',
    shield: ColorSeed.amber,
    answer: ColorSeed.indigo,
    discovery: '温暖的琥珀色与冷静的靛蓝色可以取得平衡',
  ),
  GuardianMission(
    place: '极光研究所',
    monster: '冰镜兽',
    shield: ColorSeed.indigo,
    answer: ColorSeed.amber,
    discovery: '靛蓝色配上琥珀色，就像夜空中的温暖灯光',
  ),
  GuardianMission(
    place: '花朵王国',
    monster: '花粉兽',
    shield: ColorSeed.rose,
    answer: ColorSeed.mint,
    discovery: '玫红色和薄荷色是一组清新又活泼的对比',
  ),
  GuardianMission(
    place: '彩虹空间站',
    monster: '黑洞兽',
    shield: ColorSeed.lime,
    answer: ColorSeed.purple,
    discovery: '黄绿色与紫色能制造充满想象力的视觉能量',
  ),
];

const _guardianEnergySeeds = <ColorSeed>[
  ColorSeed.red,
  ColorSeed.orange,
  ColorSeed.yellow,
  ColorSeed.green,
  ColorSeed.mint,
  ColorSeed.cyan,
  ColorSeed.blue,
  ColorSeed.indigo,
  ColorSeed.purple,
  ColorSeed.magenta,
  ColorSeed.amber,
];

class LightGuardianScreen extends StatefulWidget {
  const LightGuardianScreen({
    super.key,
    required this.progress,
    required this.audio,
  });

  final IslandProgress progress;
  final GameAudioController audio;

  @override
  State<LightGuardianScreen> createState() => _LightGuardianScreenState();
}

class _LightGuardianScreenState extends State<LightGuardianScreen>
    with SingleTickerProviderStateMixin {
  late int _missionIndex;
  late final AnimationController _beamController;
  bool _solved = false;
  ColorSeed? _selected;
  String _message = '观察怪兽护盾的颜色，选择它的对比色能量！';

  GuardianMission get _mission => guardianMissions[_missionIndex];

  @override
  void initState() {
    super.initState();
    _missionIndex = widget.progress.guardianWins % guardianMissions.length;
    _beamController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _beamController.dispose();
    super.dispose();
  }

  void _choose(ColorSeed seed) {
    if (_solved) return;
    final picked = ingredientForSeed(seed);
    final correct = seed == _mission.answer;
    HapticFeedback.selectionClick();
    setState(() {
      _selected = seed;
      _solved = correct;
      _message = correct
          ? '能量平衡成功！${_mission.discovery}。'
          : '${picked.name}能量还没有平衡护盾，再观察一下色环的另一边！';
    });
    if (correct) {
      widget.progress.recordGuardianWin(_missionIndex, picked.name);
      HapticFeedback.heavyImpact();
      _beamController.forward(from: 0);
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
      _missionIndex = (_missionIndex + 1) % guardianMissions.length;
      _solved = false;
      _selected = null;
      _message = '新的守护任务来了！观察护盾，再选择对比色能量。';
    });
    _beamController.reset();
    unawaited(widget.audio.announce(_mission.prompt, voice: GameVoice.hero));
  }

  @override
  Widget build(BuildContext context) {
    final narration = '欢迎加入奥特曼守护队。${_mission.prompt} 点击下方的颜色能量球来回答。';
    return NarrateOnMount(
      audio: widget.audio,
      text: narration,
      voice: GameVoice.hero,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A1231),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF111A4D), Color(0xFF351B58), Color(0xFF0B3555)],
            ),
          ),
          child: SafeArea(
            minimum: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              children: [
                _GuardianHeader(
                  mission: _missionIndex + 1,
                  stars: widget.progress.stars,
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: AnimatedBuilder(
                      animation: _beamController,
                      builder: (context, _) => _GuardianAssetScene(
                        key: const ValueKey('guardian-scene'),
                        shieldColor: _mission.shieldColor.color,
                        energyColor: _mission.answerColor.color,
                        beam: _beamController.value,
                        solved: _solved,
                        monsterIndex: _missionIndex % 4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _GuardianControls(
                  mission: _mission,
                  message: _message,
                  selected: _selected,
                  solved: _solved,
                  audio: widget.audio,
                  onChoose: _choose,
                  onNext: _next,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuardianHeader extends StatelessWidget {
  const _GuardianHeader({required this.mission, required this.stars});

  final int mission;
  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: () => Navigator.of(context).pop(),
          tooltip: '返回奥特曼训练营',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 9),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⚡ 奥特曼·能量护盾',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '互补色能量任务',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Text(
          '任务 $mission/${guardianMissions.length}   ⭐ $stars',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _GuardianControls extends StatelessWidget {
  const _GuardianControls({
    required this.mission,
    required this.message,
    required this.selected,
    required this.solved,
    required this.audio,
    required this.onChoose,
    required this.onNext,
  });

  final GuardianMission mission;
  final String message;
  final ColorSeed? selected;
  final bool solved;
  final GameAudioController audio;
  final ValueChanged<ColorSeed> onChoose;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: mission.shieldColor.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: mission.shieldColor.color.withValues(alpha: 0.45),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  solved || selected != null ? message : mission.prompt,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF33405D),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              RepeatVoiceButton(
                audio: audio,
                text: solved || selected != null ? message : mission.prompt,
                voice: GameVoice.hero,
              ),
              if (solved)
                IconButton.filled(
                  key: const ValueKey('guardian-next'),
                  onPressed: onNext,
                  tooltip: '下一个守护任务',
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
            ],
          ),
          const SizedBox(height: 9),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 7,
            children: _guardianEnergySeeds.map((seed) {
              final ingredient = ingredientForSeed(seed);
              final active = selected == seed;
              final correct = solved && seed == mission.answer;
              return Semantics(
                button: true,
                label: '${ingredient.name}能量',
                child: InkWell(
                  key: ValueKey('guardian-energy-${ingredient.name}'),
                  onTap: solved ? null : () => onChoose(seed),
                  customBorder: const CircleBorder(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 43,
                    height: 43,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ingredient.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: correct
                            ? const Color(0xFFFFD84A)
                            : active
                            ? const Color(0xFF2E3452)
                            : Colors.white,
                        width: active || correct ? 4 : 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ingredient.color.withValues(alpha: 0.38),
                          blurRadius: correct ? 14 : 7,
                        ),
                      ],
                    ),
                    child: correct
                        ? const Icon(Icons.bolt_rounded, color: Colors.white)
                        : null,
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

class _GuardianAssetScene extends StatelessWidget {
  const _GuardianAssetScene({
    super.key,
    required this.shieldColor,
    required this.energyColor,
    required this.beam,
    required this.solved,
    required this.monsterIndex,
  });

  final Color shieldColor;
  final Color energyColor;
  final double beam;
  final bool solved;
  final int monsterIndex;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(UltraAssets.trainingBase, fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0x66010A22), Color(0x990A1130)],
            ),
          ),
        ),
        const Positioned(
          left: 8,
          bottom: -28,
          width: 215,
          height: 330,
          child: UltraHeroImage(),
        ),
        Positioned(
          right: 24,
          bottom: 20,
          width: 205,
          height: 205,
          child: Stack(
            fit: StackFit.expand,
            children: [
              KaijuSprite(index: monsterIndex),
              Align(
                alignment: const Alignment(0, -0.15),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: shieldColor.withValues(alpha: solved ? 0.08 : 0.25),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: solved ? Colors.white24 : shieldColor,
                      width: solved ? 2 : 8,
                    ),
                    boxShadow: solved
                        ? null
                        : [
                            BoxShadow(
                              color: shieldColor.withValues(alpha: 0.62),
                              blurRadius: 28,
                              spreadRadius: 6,
                            ),
                          ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (beam > 0)
          Positioned(
            left: 140,
            right: 104,
            top: 120,
            height: 28,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: beam,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        energyColor,
                        energyColor.withValues(alpha: 0),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: energyColor.withValues(alpha: 0.8),
                        blurRadius: 22,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (solved)
          const Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 14),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xDD112652),
                  borderRadius: BorderRadius.all(Radius.circular(18)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  child: Text(
                    '✨ 护盾已破解！',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class GuardianScenePainter extends CustomPainter {
  GuardianScenePainter({
    required this.shieldColor,
    required this.energyColor,
    required this.beam,
    required this.solved,
  });

  final Color shieldColor;
  final Color energyColor;
  final double beam;
  final bool solved;

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF111943), Color(0xFF192B55), Color(0xFF4A2B61)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    final starPaint = Paint()..color = Colors.white70;
    for (var index = 0; index < 32; index++) {
      final x = ((index * 71) % 101) / 101 * size.width;
      final y = ((index * 47) % 61) / 100 * size.height;
      canvas.drawCircle(Offset(x, y), 1 + (index % 3) * 0.55, starPaint);
    }

    final groundY = size.height * 0.80;
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, size.width, size.height - groundY),
      Paint()..color = const Color(0xFF101629),
    );
    for (var index = 0; index < 12; index++) {
      final buildingWidth = size.width / 12;
      final height = size.height * (0.09 + (index % 4) * 0.025);
      final rect = Rect.fromLTWH(
        index * buildingWidth,
        groundY - height,
        buildingWidth - 3,
        height,
      );
      canvas.drawRect(rect, Paint()..color = const Color(0xFF1F2941));
      canvas.drawCircle(
        Offset(rect.center.dx, rect.top + 12),
        2.2,
        Paint()..color = const Color(0xFFFFD84A),
      );
    }

    _paintHero(canvas, Offset(size.width * 0.27, groundY), size);
    _paintMonster(canvas, Offset(size.width * 0.74, groundY), size);

    if (beam > 0) {
      final start = Offset(size.width * 0.36, size.height * 0.47);
      final end = Offset(size.width * (0.36 + 0.30 * beam), size.height * 0.43);
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = energyColor.withValues(alpha: 0.35)
          ..strokeWidth = 22
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = Color.lerp(energyColor, Colors.white, 0.42)!
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintHero(Canvas canvas, Offset feet, Size size) {
    final scale = math.min(size.width, size.height) / 430;
    final body = Paint()..color = const Color(0xFFD9E2F1);
    final blue = Paint()..color = const Color(0xFF3F83E6);
    canvas.drawOval(
      Rect.fromCenter(
        center: feet - Offset(0, 125 * scale),
        width: 72 * scale,
        height: 70 * scale,
      ),
      body,
    );
    final torso = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: feet - Offset(0, 65 * scale),
        width: 82 * scale,
        height: 120 * scale,
      ),
      Radius.circular(28 * scale),
    );
    canvas.drawRRect(torso, body);
    final stripe = Path()
      ..moveTo(feet.dx - 38 * scale, feet.dy - 100 * scale)
      ..lineTo(feet.dx + 34 * scale, feet.dy - 48 * scale)
      ..lineTo(feet.dx + 38 * scale, feet.dy - 76 * scale)
      ..lineTo(feet.dx - 22 * scale, feet.dy - 118 * scale)
      ..close();
    canvas.drawPath(stripe, blue);
    for (final side in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: feet - Offset(side * 14 * scale, 132 * scale),
          width: 12 * scale,
          height: 7 * scale,
        ),
        Paint()..color = const Color(0xFFFFF0A8),
      );
    }
    canvas.drawCircle(
      feet - Offset(0, 77 * scale),
      8 * scale,
      Paint()
        ..color = const Color(0xFF55E6FF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      feet - Offset(0, 77 * scale),
      5 * scale,
      Paint()..color = Colors.white,
    );
  }

  void _paintMonster(Canvas canvas, Offset feet, Size size) {
    final scale = math.min(size.width, size.height) / 430;
    final monster = Paint()
      ..color = solved ? const Color(0xFF6D79A8) : const Color(0xFF292941);
    final bodyRect = Rect.fromCenter(
      center: feet - Offset(0, 70 * scale),
      width: 100 * scale,
      height: 130 * scale,
    );
    canvas.drawOval(bodyRect, monster);
    final horn = Path()
      ..moveTo(feet.dx - 36 * scale, feet.dy - 125 * scale)
      ..lineTo(feet.dx - 52 * scale, feet.dy - 170 * scale)
      ..lineTo(feet.dx - 12 * scale, feet.dy - 138 * scale)
      ..moveTo(feet.dx + 36 * scale, feet.dy - 125 * scale)
      ..lineTo(feet.dx + 52 * scale, feet.dy - 170 * scale)
      ..lineTo(feet.dx + 12 * scale, feet.dy - 138 * scale);
    canvas.drawPath(
      horn,
      Paint()
        ..color = monster.color
        ..strokeWidth = 16 * scale
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      feet - Offset(0, 76 * scale),
      54 * scale,
      Paint()
        ..color = shieldColor.withValues(alpha: solved ? 0.12 : 0.30)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      feet - Offset(0, 76 * scale),
      54 * scale,
      Paint()
        ..color = shieldColor.withValues(alpha: solved ? 0.24 : 0.92)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6 * scale,
    );
    for (final side in [-1.0, 1.0]) {
      canvas.drawCircle(
        feet - Offset(side * 18 * scale, 116 * scale),
        5 * scale,
        Paint()..color = solved ? Colors.white70 : const Color(0xFFFF6464),
      );
    }
  }

  @override
  bool shouldRepaint(covariant GuardianScenePainter oldDelegate) {
    return oldDelegate.beam != beam ||
        oldDelegate.solved != solved ||
        oldDelegate.shieldColor != shieldColor ||
        oldDelegate.energyColor != energyColor;
  }
}
