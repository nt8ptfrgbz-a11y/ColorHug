import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game_audio.dart';
import 'island_progress.dart';
import 'rainbow_repair_levels.dart';

const _repairColors = <({String name, Color color})>[
  (name: '红色', color: Color(0xFFFF4F64)),
  (name: '橙色', color: Color(0xFFFF922E)),
  (name: '黄色', color: Color(0xFFFFD84A)),
  (name: '黄绿色', color: Color(0xFF9BC94A)),
  (name: '绿色', color: Color(0xFF45CE75)),
  (name: '薄荷色', color: Color(0xFF72DEB1)),
  (name: '青色', color: Color(0xFF42D7D0)),
  (name: '湖蓝色', color: Color(0xFF31B9D8)),
  (name: '蓝色', color: Color(0xFF4687FF)),
  (name: '靛蓝色', color: Color(0xFF5C58C9)),
  (name: '紫色', color: Color(0xFF9B67E8)),
  (name: '粉色', color: Color(0xFFFF9DB1)),
  (name: '棕色', color: Color(0xFF8A654A)),
  (name: '白色', color: Color(0xFFF8F5EB)),
  (name: '灰色', color: Color(0xFF8C8F99)),
  (name: '黑色', color: Color(0xFF30333D)),
];

enum RepairPlayMode { choose, drag, listen, mix }

const _mixRecipes = <String, ({String first, String second})>{
  '橙色': (first: '红色', second: '黄色'),
  '绿色': (first: '黄色', second: '蓝色'),
  '紫色': (first: '红色', second: '蓝色'),
  '青色': (first: '蓝色', second: '绿色'),
  '粉色': (first: '红色', second: '白色'),
  '棕色': (first: '红色', second: '绿色'),
  '灰色': (first: '黑色', second: '白色'),
};

Color _repairColor(String name) => _repairColors
    .firstWhere((item) => item.name == name, orElse: () => _repairColors.first)
    .color;

RepairPlayMode _repairModeForLevel(int levelIndex, RepairTask task) {
  return switch (repairStageInMap(levelIndex)) {
    0 => RepairPlayMode.choose,
    1 => RepairPlayMode.drag,
    2 when _mixRecipes.containsKey(task.colorName) => RepairPlayMode.mix,
    2 => RepairPlayMode.listen,
    3 => RepairPlayMode.listen,
    _ => RepairPlayMode.drag,
  };
}

String _repairVoiceInstruction(int levelIndex, RepairTask task) {
  final action = switch (_repairModeForLevel(levelIndex, task)) {
    RepairPlayMode.choose => '点击正确的颜色球。',
    RepairPlayMode.drag => '把正确的颜色球拖进图案。',
    RepairPlayMode.listen => '先认真听线索，再凭耳朵找到颜色。',
    RepairPlayMode.mix => '选择两种颜料，把目标颜色调出来。',
  };
  return '${task.title}。${task.prompt}。$action';
}

List<({String name, Color color})> _repairOptionsForLevel(
  int levelIndex,
  String answer,
) {
  final answerItem = _repairColors.firstWhere((item) => item.name == answer);
  final options = <({String name, Color color})>[answerItem];
  var cursor = (levelIndex * 7 + 3) % _repairColors.length;
  while (options.length < 6) {
    final candidate = _repairColors[cursor];
    if (candidate.name != answer &&
        !options.any((item) => item.name == candidate.name)) {
      options.add(candidate);
    }
    cursor = (cursor + 5) % _repairColors.length;
  }
  final answerPosition = (levelIndex * 3 + levelIndex ~/ 5) % options.length;
  final answerSwatch = options.removeAt(0);
  options.insert(answerPosition, answerSwatch);
  return options;
}

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
  bool _awaitingNextMap = false;
  bool _userSelectedLevel = false;

  bool get _completed => _step >= repairLevelTotal;
  RepairTask? get _task => _completed ? null : repairTasks[_step];
  int get _displayMapIndex {
    if (_completed) return repairMaps.length - 1;
    if (_awaitingNextMap) return (_step - 1) ~/ repairStagesPerMap;
    return repairMapIndexForLevel(_step);
  }

  RepairMap get _displayMap => repairMaps[_displayMapIndex];
  int get _restoredOnMap {
    if (_completed || _awaitingNextMap) return repairStagesPerMap;
    return repairStageInMap(_step);
  }

  @override
  void initState() {
    super.initState();
    _step = widget.progress.repairedParts.clamp(0, repairLevelTotal);
    if (_completed) {
      _message = '太棒啦！100关全部完成，整个彩虹世界都恢复颜色了！';
    }
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    widget.progress.addListener(_syncSavedProgress);
  }

  @override
  void dispose() {
    widget.progress.removeListener(_syncSavedProgress);
    _sparkleController.dispose();
    super.dispose();
  }

  void _syncSavedProgress() {
    if (!mounted || _userSelectedLevel) return;
    final saved = widget.progress.repairedParts.clamp(0, repairLevelTotal);
    if (saved <= _step) return;
    setState(() {
      _step = saved;
      _awaitingNextMap = false;
      _wrongColor = null;
      _message = _completed
          ? '太棒啦！100关全部完成，整个彩虹世界都恢复颜色了！'
          : '已接着上次的进度，继续第${_step + 1}关！';
    });
  }

  void _chooseColor(String name) {
    final task = _task;
    if (task == null) return;
    _userSelectedLevel = true;
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
    final finishedMap =
        nextStep % repairStagesPerMap == 0 && nextStep < repairLevelTotal;
    widget.progress.repairPart(nextStep, name);
    HapticFeedback.mediumImpact();
    setState(() {
      _step = nextStep;
      _wrongColor = null;
      _awaitingNextMap = finishedMap;
      _message = _completed
          ? '太棒啦！100关全部完成，整个彩虹世界都恢复颜色了！'
          : finishedMap
          ? '${_displayMap.emoji} ${_displayMap.name}恢复颜色啦！'
          : '${task.emoji} ${task.title}成功！下一处也在等你。';
    });
    _sparkleController.forward(from: 0);
    final narration = _completed || finishedMap
        ? _message
        : '$_message ${_repairVoiceInstruction(_step, _task!)}';
    unawaited(
      widget.audio.announce(
        narration,
        sound: _completed ? GameSound.complete : GameSound.correct,
      ),
    );
  }

  void _replay() {
    setState(() {
      _userSelectedLevel = true;
      _step = 0;
      _message = '再施展一次颜色魔法吧！';
      _wrongColor = null;
      _awaitingNextMap = false;
    });
    unawaited(widget.audio.announce('再施展一次颜色魔法吧！${repairTasks.first.prompt}'));
  }

  void _openNextMap() {
    setState(() {
      _awaitingNextMap = false;
      _message = '新地图解锁！选出正确的颜色继续修复吧！';
    });
    final map = _displayMap;
    unawaited(
      widget.audio.announce(
        '新地图，${map.name}！第${_step + 1}关。${_repairVoiceInstruction(_step, _task!)}',
        sound: GameSound.discover,
      ),
    );
  }

  Future<void> _showLevelPicker() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RepairLevelPicker(
        completedLevels: widget.progress.repairedParts.clamp(
          0,
          repairLevelTotal,
        ),
        currentLevel: _completed ? repairLevelTotal - 1 : _step,
      ),
    );
    if (!mounted || selected == null) return;
    final task = repairTasks[selected];
    setState(() {
      _userSelectedLevel = true;
      _step = selected;
      _awaitingNextMap = false;
      _wrongColor = null;
      _message = '已选择第${selected + 1}关：${task.title}';
    });
    unawaited(
      widget.audio.announce(
        '第${selected + 1}关。${_repairVoiceInstruction(selected, task)}',
        sound: GameSound.discover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final narration = _completed || _awaitingNextMap
        ? _message
        : '第${_step + 1}关。${_repairVoiceInstruction(_step, _task!)}';
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
                  IconButton.filledTonal(
                    key: const ValueKey('repair-level-picker'),
                    onPressed: _showLevelPicker,
                    tooltip: '选择关卡',
                    icon: const Icon(Icons.grid_view_rounded),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '${widget.progress.repairedParts.clamp(0, repairLevelTotal)}/$repairLevelTotal   ⭐ ${widget.progress.stars}',
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
                  child: Stack(
                    key: const ValueKey('repair-garden'),
                    children: [
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _sparkleController,
                          builder: (context, _) {
                            return CustomPaint(
                              key: ValueKey('repair-map-$_displayMapIndex'),
                              size: Size.infinite,
                              painter: GardenRepairPainter(
                                map: _displayMap,
                                restoredSteps: _restoredOnMap,
                                sparkle: _sparkleController.value,
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        left: 12,
                        top: 12,
                        child: _MapBadge(
                          map: _displayMap,
                          mapNumber: _displayMapIndex + 1,
                          restoredSteps: _restoredOnMap,
                        ),
                      ),
                    ],
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
              else if (_awaitingNextMap)
                _CompletedMapCard(
                  key: const ValueKey('repair-map-completed'),
                  map: _displayMap,
                  nextMap: repairMapForLevel(_step),
                  onNext: _openNextMap,
                )
              else
                _RepairControls(
                  key: ValueKey('repair-step-$_step'),
                  levelIndex: _step,
                  task: _task!,
                  mode: _repairModeForLevel(_step, _task!),
                  options: _repairOptionsForLevel(_step, _task!.colorName),
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

class _RepairLevelPicker extends StatelessWidget {
  const _RepairLevelPicker({
    required this.completedLevels,
    required this.currentLevel,
  });

  final int completedLevels;
  final int currentLevel;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.90,
      child: Material(
        color: const Color(0xFFFFF9EE),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD5C9C0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 13, 8, 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🗺️ 选择关卡',
                            style: TextStyle(
                              color: Color(0xFF503F47),
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '完成过的关卡可以随时重玩，继续关已自动解锁',
                            style: TextStyle(
                              color: Color(0xFF7B6871),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: '关闭选关',
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  key: const ValueKey('repair-level-list'),
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                  itemCount: repairMaps.length,
                  itemBuilder: (context, mapIndex) {
                    final map = repairMaps[mapIndex];
                    final tasks = repairTasksForMap(mapIndex);
                    final firstLevel = mapIndex * repairStagesPerMap;
                    final finishedInMap = (completedLevels - firstLevel).clamp(
                      0,
                      repairStagesPerMap,
                    );
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            map.skyBottom,
                            map.accent.withValues(alpha: 0.16),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                map.emoji,
                                style: const TextStyle(fontSize: 25),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '地图 ${mapIndex + 1} · ${map.name}',
                                  style: const TextStyle(
                                    color: Color(0xFF503F47),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              Text(
                                '$finishedInMap/$repairStagesPerMap',
                                style: TextStyle(
                                  color: map.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 9),
                          Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            children: List.generate(repairStagesPerMap, (
                              stageIndex,
                            ) {
                              final levelIndex = firstLevel + stageIndex;
                              final unlocked = levelIndex <= completedLevels;
                              final completed = levelIndex < completedLevels;
                              final current = levelIndex == currentLevel;
                              final task = tasks[stageIndex];
                              return Semantics(
                                button: unlocked,
                                label: unlocked
                                    ? '第${levelIndex + 1}关，${task.title}'
                                    : '第${levelIndex + 1}关，未解锁',
                                child: InkWell(
                                  key: ValueKey(
                                    'repair-select-level-$levelIndex',
                                  ),
                                  onTap: unlocked
                                      ? () => Navigator.of(
                                          context,
                                        ).pop(levelIndex)
                                      : null,
                                  borderRadius: BorderRadius.circular(15),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 88,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: current
                                          ? map.accent
                                          : unlocked
                                          ? Colors.white.withValues(alpha: 0.88)
                                          : const Color(0x99D6D2D1),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: current
                                            ? Colors.white
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          unlocked ? task.emoji : '🔒',
                                          style: const TextStyle(fontSize: 22),
                                        ),
                                        Text(
                                          '第${levelIndex + 1}关${completed ? ' ✓' : ''}',
                                          maxLines: 1,
                                          style: TextStyle(
                                            color: current
                                                ? Colors.white
                                                : const Color(0xFF66515B),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
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
  }
}

class _MapBadge extends StatelessWidget {
  const _MapBadge({
    required this.map,
    required this.mapNumber,
    required this.restoredSteps,
  });

  final RepairMap map;
  final int mapNumber;
  final int restoredSteps;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xEFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x220B4778), blurRadius: 10)],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(map.emoji, style: const TextStyle(fontSize: 17)),
            const SizedBox(width: 6),
            Text(
              '地图 $mapNumber/${repairMaps.length} · ${map.name}',
              style: const TextStyle(
                color: Color(0xFF57424D),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$restoredSteps/$repairStagesPerMap',
              style: TextStyle(
                color: map.accent,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedMapCard extends StatelessWidget {
  const _CompletedMapCard({
    super.key,
    required this.map,
    required this.nextMap,
    required this.onNext,
  });

  final RepairMap map;
  final RepairMap nextMap;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [map.accent.withValues(alpha: 0.20), nextMap.skyBottom],
        ),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(
        children: [
          Text(map.emoji, style: const TextStyle(fontSize: 31)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${map.name}修复完成！',
                  style: const TextStyle(
                    color: Color(0xFF513E47),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '下一站 ${nextMap.emoji} ${nextMap.name}',
                  style: const TextStyle(
                    color: Color(0xFF765D68),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            key: const ValueKey('repair-next-map'),
            onPressed: onNext,
            icon: const Icon(Icons.explore_rounded),
            label: const Text('出发'),
          ),
        ],
      ),
    );
  }
}

class _RepairControls extends StatelessWidget {
  const _RepairControls({
    super.key,
    required this.levelIndex,
    required this.task,
    required this.mode,
    required this.options,
    required this.message,
    required this.wrongColor,
    required this.onChoose,
    required this.audio,
  });

  final int levelIndex;
  final RepairTask task;
  final RepairPlayMode mode;
  final List<({String name, Color color})> options;
  final String message;
  final String? wrongColor;
  final ValueChanged<String> onChoose;
  final GameAudioController audio;

  String get _modeLabel => switch (mode) {
    RepairPlayMode.choose => '👆 点一点',
    RepairPlayMode.drag => '🖐️ 拖一拖',
    RepairPlayMode.listen => '👂 听声音',
    RepairPlayMode.mix => '🧪 调一调',
  };

  String get _visiblePrompt => switch (mode) {
    RepairPlayMode.listen => '先听语音线索，再凭耳朵找到颜色',
    RepairPlayMode.drag => '把正确的颜色球拖进${task.emoji}',
    RepairPlayMode.mix => '选择两种颜料，调出${task.colorName}',
    RepairPlayMode.choose => task.prompt,
  };

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
                      '第${levelIndex + 1}关 · ${task.title}',
                      style: const TextStyle(
                        color: Color(0xFF503F47),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      _visiblePrompt,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDC8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _modeLabel,
                  style: const TextStyle(
                    color: Color(0xFF79543E),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              RepeatVoiceButton(
                audio: audio,
                text: _repairVoiceInstruction(levelIndex, task),
              ),
            ],
          ),
          const SizedBox(height: 10),
          switch (mode) {
            RepairPlayMode.mix => _MixRepairControls(
              key: ValueKey('repair-mix-$levelIndex'),
              task: task,
              onChoose: onChoose,
            ),
            RepairPlayMode.drag => _DragRepairControls(
              task: task,
              options: options,
              onChoose: onChoose,
            ),
            RepairPlayMode.choose ||
            RepairPlayMode.listen => _TapRepairControls(
              options: options,
              onChoose: onChoose,
              hideLabels: mode == RepairPlayMode.listen,
            ),
          },
        ],
      ),
    );
  }
}

class _TapRepairControls extends StatelessWidget {
  const _TapRepairControls({
    required this.options,
    required this.onChoose,
    required this.hideLabels,
  });

  final List<({String name, Color color})> options;
  final ValueChanged<String> onChoose;
  final bool hideLabels;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: options
          .map(
            (item) => _RepairColorOrb(
              key: ValueKey('repair-color-${item.name}'),
              item: item,
              onTap: () => onChoose(item.name),
              hideLabel: hideLabels,
            ),
          )
          .toList(growable: false),
    );
  }
}

class _DragRepairControls extends StatelessWidget {
  const _DragRepairControls({
    required this.task,
    required this.options,
    required this.onChoose,
  });

  final RepairTask task;
  final List<({String name, Color color})> options;
  final ValueChanged<String> onChoose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DragTarget<String>(
          onAcceptWithDetails: (details) => onChoose(details.data),
          builder: (context, candidates, _) {
            final active = candidates.isNotEmpty;
            return AnimatedContainer(
              key: const ValueKey('repair-color-drop-target'),
              duration: const Duration(milliseconds: 160),
              width: 190,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFFFE17D)
                    : const Color(0xFFF2ECF5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: active
                      ? const Color(0xFFFF9C3D)
                      : const Color(0xFFC8BCCC),
                  width: 2,
                ),
              ),
              child: Text(
                '${task.emoji} 把颜色拖到这里',
                style: const TextStyle(
                  color: Color(0xFF5E4C57),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: options
              .map((item) {
                return Draggable<String>(
                  data: item.name,
                  feedback: Material(
                    color: Colors.transparent,
                    child: _RepairColorOrb(item: item, hideLabel: false),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.25,
                    child: _RepairColorOrb(item: item, hideLabel: false),
                  ),
                  child: _RepairColorOrb(
                    key: ValueKey('repair-color-${item.name}'),
                    item: item,
                    onTap: () => onChoose(item.name),
                    hideLabel: false,
                  ),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _MixRepairControls extends StatefulWidget {
  const _MixRepairControls({
    super.key,
    required this.task,
    required this.onChoose,
  });

  final RepairTask task;
  final ValueChanged<String> onChoose;

  @override
  State<_MixRepairControls> createState() => _MixRepairControlsState();
}

class _MixRepairControlsState extends State<_MixRepairControls> {
  final List<String> _picked = [];

  static const _ingredients = ['红色', '黄色', '蓝色', '绿色', '白色', '黑色'];

  void _pick(String name) {
    if (_picked.contains(name)) return;
    setState(() => _picked.add(name));
    if (_picked.length < 2) return;
    final recipe = _mixRecipes[widget.task.colorName];
    final correct =
        recipe != null &&
        _picked.toSet().containsAll([recipe.first, recipe.second]);
    final result = correct
        ? widget.task.colorName
        : '${_picked.first}+${_picked.last}';
    if (!correct) setState(_picked.clear);
    widget.onChoose(result);
  }

  @override
  Widget build(BuildContext context) {
    final target = _repairColor(widget.task.colorName);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _MixSlot(name: _picked.firstOrNull),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 7),
              child: Text(
                '+',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ),
            _MixSlot(name: _picked.length > 1 ? _picked[1] : null),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 7),
              child: Icon(Icons.arrow_forward_rounded),
            ),
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: target,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: target.withValues(alpha: 0.35),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Text(
                '?',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: _ingredients
              .map((name) {
                final item = (name: name, color: _repairColor(name));
                final selected = _picked.contains(name);
                return _RepairColorOrb(
                  key: ValueKey('repair-mix-$name'),
                  item: item,
                  onTap: selected ? null : () => _pick(name),
                  hideLabel: false,
                  selected: selected,
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _MixSlot extends StatelessWidget {
  const _MixSlot({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: name == null ? const Color(0xFFE4E0E3) : _repairColor(name!),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(
        name == null ? '？' : name!.substring(0, 1),
        style: TextStyle(
          color: name == null || _repairColor(name!).computeLuminance() > 0.55
              ? const Color(0xFF36323B)
              : Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RepairColorOrb extends StatelessWidget {
  const _RepairColorOrb({
    super.key,
    required this.item,
    required this.hideLabel,
    this.onTap,
    this.selected = false,
  });

  final ({String name, Color color}) item;
  final VoidCallback? onTap;
  final bool hideLabel;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ink = item.color.computeLuminance() > 0.55
        ? const Color(0xFF36323B)
        : Colors.white;
    return Semantics(
      button: onTap != null,
      label: '选择${item.name}',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: item.color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? const Color(0xFFFFA33D) : Colors.white,
              width: selected ? 4 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: item.color.withValues(alpha: 0.38),
                blurRadius: 9,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            hideLabel ? '●' : item.name.substring(0, 1),
            style: TextStyle(
              color: ink,
              fontSize: hideLabel ? 9 : 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
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
  GardenRepairPainter({
    required this.map,
    required this.restoredSteps,
    required this.sparkle,
  });

  final RepairMap map;
  final int restoredSteps;
  final double sparkle;

  int get _mapIndex => repairMaps.indexOf(map);
  List<RepairTask> get _mapTasks => repairTasksForMap(_mapIndex);

  Color _active(int threshold, Color color) {
    return restoredSteps >= threshold ? color : const Color(0xFFADB3BA);
  }

  Color _taskColor(int index) {
    return _repairColor(_mapTasks[index].colorName);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_active(2, map.skyTop), _active(2, map.skyBottom)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    _paintTerrain(canvas, size);
    _paintCreativeBackdrop(canvas, size);
    _paintTaskObjects(canvas, size);
    _paintSparkles(canvas, size);
  }

  void _paintCreativeBackdrop(Canvas canvas, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    final seed = _mapIndex + 1;
    final patternPaint = Paint()
      ..color = _active(1, map.accent).withValues(alpha: 0.13);
    for (var index = 0; index < 15; index++) {
      final x = ((index * 73 + seed * 41) % 97) / 97 * size.width;
      final y = (0.18 + ((index * 47 + seed * 29) % 73) / 100) * size.height;
      final radius = (8 + (index * seed) % 18) * unit;
      if ((index + seed).isEven) {
        canvas.drawCircle(Offset(x, y), radius, patternPaint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(x, y),
              width: radius * 2.5,
              height: radius * 1.25,
            ),
            Radius.circular(radius),
          ),
          patternPaint,
        );
      }
    }

    final mapMark = TextPainter(
      text: TextSpan(
        text: map.emoji,
        style: TextStyle(
          fontSize: 155 * unit,
          color: Colors.white.withValues(alpha: 0.16),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    mapMark.paint(
      canvas,
      Offset(
        size.width * 0.5 - mapMark.width * 0.5,
        size.height * 0.5 - mapMark.height * 0.42,
      ),
    );
  }

  void _paintTaskObjects(Canvas canvas, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    const positionPatterns = <List<Offset>>[
      [
        Offset(0.15, 0.38),
        Offset(0.47, 0.29),
        Offset(0.80, 0.40),
        Offset(0.29, 0.72),
        Offset(0.68, 0.72),
      ],
      [
        Offset(0.22, 0.29),
        Offset(0.61, 0.35),
        Offset(0.84, 0.64),
        Offset(0.47, 0.73),
        Offset(0.13, 0.67),
      ],
      [
        Offset(0.14, 0.54),
        Offset(0.38, 0.31),
        Offset(0.74, 0.28),
        Offset(0.82, 0.67),
        Offset(0.43, 0.72),
      ],
      [
        Offset(0.24, 0.68),
        Offset(0.15, 0.35),
        Offset(0.52, 0.28),
        Offset(0.82, 0.39),
        Offset(0.67, 0.72),
      ],
    ];
    final positions = positionPatterns[_mapIndex % positionPatterns.length];

    for (var index = 0; index < repairStagesPerMap; index++) {
      final task = _mapTasks[index];
      final center = Offset(
        positions[index].dx * size.width,
        positions[index].dy * size.height,
      );
      final restored = index < restoredSteps;
      final current =
          index == restoredSteps && restoredSteps < repairStagesPerMap;
      final visible = restored || current;
      final color = _taskColor(index);

      canvas.drawCircle(
        center,
        (restored ? 43 : 38) * unit,
        Paint()
          ..color = visible
              ? Colors.white.withValues(alpha: restored ? 0.90 : 0.62)
              : const Color(0x99D0D2D5),
      );
      canvas.drawCircle(
        center,
        (restored ? 43 : 38) * unit,
        Paint()
          ..color = visible ? color : const Color(0xFF9EA3AA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (current ? 5 : 3) * unit,
      );

      if (visible) {
        canvas.saveLayer(
          Rect.fromCircle(center: center, radius: 48 * unit),
          Paint()..color = Colors.white.withValues(alpha: restored ? 1 : 0.62),
        );
        final emoji = TextPainter(
          text: TextSpan(
            text: task.emoji,
            style: TextStyle(fontSize: (restored ? 40 : 35) * unit),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        emoji.paint(
          canvas,
          center - Offset(emoji.width * 0.5, emoji.height * 0.55),
        );
        canvas.restore();
      } else {
        final number = TextPainter(
          text: TextSpan(
            text: '${index + 1}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19 * unit,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        number.paint(
          canvas,
          center - Offset(number.width * 0.5, number.height * 0.5),
        );
      }

      if (visible) {
        final label = TextPainter(
          text: TextSpan(
            text: task.title,
            style: TextStyle(
              color: const Color(0xFF4F4048),
              fontSize: 10.5 * unit,
              fontWeight: FontWeight.w800,
              backgroundColor: Colors.white.withValues(alpha: 0.84),
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '…',
        )..layout(maxWidth: 120 * unit);
        label.paint(canvas, center + Offset(-label.width * 0.5, 47 * unit));
      }
    }
  }

  // Legacy primitive kept as a reference for future hand-drawn task variants.
  // ignore: unused_element
  void _paintLight(Canvas canvas, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    final center = Offset(size.width * 0.82, size.height * 0.19);
    final color = _active(1, _taskColor(0));
    if (restoredSteps >= 1) {
      canvas.drawCircle(
        center,
        43 * unit,
        Paint()
          ..color = color.withValues(alpha: 0.38)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 13),
      );
    }
    if (map.scene == RepairSceneKind.space ||
        map.scene == RepairSceneKind.ice) {
      _paintStar(canvas, center, 35 * unit, color);
    } else {
      canvas.drawCircle(center, 30 * unit, Paint()..color = color);
      for (var ray = 0; ray < 8; ray++) {
        final angle = ray * math.pi / 4;
        canvas.drawLine(
          center + Offset(math.cos(angle), math.sin(angle)) * 39 * unit,
          center + Offset(math.cos(angle), math.sin(angle)) * 51 * unit,
          Paint()
            ..color = color
            ..strokeWidth = 4 * unit
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  void _paintTerrain(Canvas canvas, Size size) {
    final groundColor = _active(3, map.ground);
    if (map.scene == RepairSceneKind.ocean) {
      canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28),
        Paint()..color = groundColor,
      );
      return;
    }

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.22, size.height * 0.86),
        width: size.width * 0.82,
        height: size.height * 0.50,
      ),
      Paint()..color = groundColor,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.78, size.height * 0.85),
        width: size.width * 0.88,
        height: size.height * 0.56,
      ),
      Paint()
        ..color = Color.lerp(
          groundColor,
          _active(3, const Color(0xFF2F8A62)),
          0.18,
        )!,
    );

    const wateryScenes = {
      RepairSceneKind.garden,
      RepairSceneKind.coast,
      RepairSceneKind.forest,
      RepairSceneKind.farm,
      RepairSceneKind.canyon,
      RepairSceneKind.village,
      RepairSceneKind.lake,
    };
    if (wateryScenes.contains(map.scene)) {
      _paintWater(canvas, size);
    }
  }

  // Legacy scene library is intentionally not painted: task-specific objects
  // above prevent narration and artwork from drifting apart.
  // ignore: unused_element
  void _paintScene(Canvas canvas, Size size) {
    switch (map.scene) {
      case RepairSceneKind.garden:
        _paintTree(canvas, Offset(size.width * 0.16, size.height * 0.57), size);
        _paintTree(canvas, Offset(size.width * 0.74, size.height * 0.57), size);
        _paintFlowers(canvas, size, count: 14);
      case RepairSceneKind.coast:
        _paintSeaBand(canvas, size);
        _paintPalm(canvas, Offset(size.width * 0.20, size.height * 0.64), size);
        _paintUmbrella(
          canvas,
          Offset(size.width * 0.72, size.height * 0.65),
          size,
        );
        _paintDots(canvas, size, count: 8, color: _taskColor(4));
      case RepairSceneKind.forest:
        for (final x in [0.12, 0.30, 0.72, 0.88]) {
          _paintPine(canvas, Offset(size.width * x, size.height * 0.62), size);
        }
        _paintHouse(
          canvas,
          Offset(size.width * 0.53, size.height * 0.68),
          size,
        );
        _paintMushrooms(canvas, size);
      case RepairSceneKind.snow:
        _paintMountains(canvas, size, snowy: true);
        _paintHouse(
          canvas,
          Offset(size.width * 0.60, size.height * 0.70),
          size,
        );
        _paintDots(canvas, size, count: 24, color: Colors.white);
      case RepairSceneKind.desert:
        _paintCactus(
          canvas,
          Offset(size.width * 0.20, size.height * 0.70),
          size,
        );
        _paintCactus(
          canvas,
          Offset(size.width * 0.83, size.height * 0.65),
          size,
        );
        _paintTent(canvas, Offset(size.width * 0.55, size.height * 0.73), size);
        _paintCrystals(canvas, size);
      case RepairSceneKind.candy:
        _paintLollipop(
          canvas,
          Offset(size.width * 0.18, size.height * 0.65),
          size,
        );
        _paintLollipop(
          canvas,
          Offset(size.width * 0.82, size.height * 0.62),
          size,
        );
        _paintHouse(
          canvas,
          Offset(size.width * 0.51, size.height * 0.68),
          size,
        );
        _paintBalloons(canvas, size);
      case RepairSceneKind.farm:
        _paintFieldLines(canvas, size);
        _paintBarn(canvas, Offset(size.width * 0.56, size.height * 0.67), size);
        _paintFence(canvas, size);
        _paintDots(canvas, size, count: 7, color: Colors.white);
      case RepairSceneKind.ocean:
        _paintSeaweed(canvas, size);
        _paintCoral(
          canvas,
          Offset(size.width * 0.52, size.height * 0.77),
          size,
        );
        _paintBubbles(canvas, size);
      case RepairSceneKind.space:
        _paintPlanet(
          canvas,
          Offset(size.width * 0.20, size.height * 0.34),
          size,
        );
        _paintAlienPlants(canvas, size);
        _paintRocket(
          canvas,
          Offset(size.width * 0.55, size.height * 0.65),
          size,
        );
        _paintStars(canvas, size);
      case RepairSceneKind.volcano:
        _paintPine(canvas, Offset(size.width * 0.14, size.height * 0.69), size);
        _paintPine(canvas, Offset(size.width * 0.85, size.height * 0.67), size);
        _paintVolcano(canvas, size);
        _paintCrystals(canvas, size);
      case RepairSceneKind.station:
        _paintTrack(canvas, size);
        _paintPine(canvas, Offset(size.width * 0.18, size.height * 0.59), size);
        _paintTrain(
          canvas,
          Offset(size.width * 0.56, size.height * 0.70),
          size,
        );
        _paintFlowers(canvas, size, count: 9);
      case RepairSceneKind.canyon:
        _paintMountains(canvas, size);
        _paintFerns(canvas, size);
        _paintEgg(canvas, Offset(size.width * 0.56, size.height * 0.72), size);
        _paintCrystals(canvas, size);
      case RepairSceneKind.village:
        _paintTree(canvas, Offset(size.width * 0.16, size.height * 0.61), size);
        _paintHouse(
          canvas,
          Offset(size.width * 0.49, size.height * 0.69),
          size,
        );
        _paintHive(canvas, Offset(size.width * 0.78, size.height * 0.67), size);
        _paintFlowers(canvas, size, count: 11);
      case RepairSceneKind.ice:
        _paintMountains(canvas, size, snowy: true);
        _paintSled(canvas, Offset(size.width * 0.55, size.height * 0.76), size);
        _paintAurora(canvas, size);
      case RepairSceneKind.castle:
        _paintClouds(canvas, size);
        _paintCastle(
          canvas,
          Offset(size.width * 0.51, size.height * 0.66),
          size,
        );
        _paintFlags(canvas, size);
      case RepairSceneKind.orchard:
        for (final x in [0.16, 0.38, 0.70, 0.87]) {
          _paintTree(canvas, Offset(size.width * x, size.height * 0.60), size);
        }
        _paintCart(canvas, Offset(size.width * 0.55, size.height * 0.75), size);
        _paintFruit(canvas, size);
      case RepairSceneKind.music:
        _paintTree(canvas, Offset(size.width * 0.17, size.height * 0.58), size);
        _paintTree(canvas, Offset(size.width * 0.83, size.height * 0.58), size);
        _paintDrum(canvas, Offset(size.width * 0.51, size.height * 0.71), size);
        _paintNotes(canvas, size);
      case RepairSceneKind.lake:
        _paintReeds(canvas, size);
        _paintHouse(
          canvas,
          Offset(size.width * 0.24, size.height * 0.61),
          size,
        );
        _paintBoat(canvas, Offset(size.width * 0.65, size.height * 0.73), size);
        _paintDots(canvas, size, count: 10, color: _taskColor(4));
      case RepairSceneKind.factory:
        _paintPipes(canvas, size);
        _paintFactory(
          canvas,
          Offset(size.width * 0.52, size.height * 0.66),
          size,
        );
        _paintGears(canvas, size);
      case RepairSceneKind.festival:
        _paintFountain(
          canvas,
          Offset(size.width * 0.25, size.height * 0.72),
          size,
        );
        _paintFerrisWheel(
          canvas,
          Offset(size.width * 0.62, size.height * 0.57),
          size,
        );
        _paintBalloons(canvas, size);
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

  void _paintWater(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.43, size.height * 0.54)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.70,
        size.width * 0.68,
        size.height * 0.78,
        size.width * 0.54,
        size.height,
      )
      ..lineTo(size.width * 0.86, size.height)
      ..cubicTo(
        size.width * 0.82,
        size.height * 0.78,
        size.width * 0.53,
        size.height * 0.68,
        size.width * 0.58,
        size.height * 0.55,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = _active(2, _taskColor(1)));
  }

  void _paintSeaBand(Canvas canvas, Size size) {
    final water = Paint()..color = _active(2, _taskColor(1));
    final path = Path()
      ..moveTo(0, size.height * 0.51)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.47,
        size.width * 0.50,
        size.height * 0.52,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.57,
        size.width,
        size.height * 0.51,
      )
      ..lineTo(size.width, size.height * 0.69)
      ..lineTo(0, size.height * 0.69)
      ..close();
    canvas.drawPath(path, water);
  }

  void _paintPine(Canvas canvas, Offset base, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    canvas.drawRect(
      Rect.fromCenter(
        center: base - Offset(0, 32 * unit),
        width: 12 * unit,
        height: 64 * unit,
      ),
      Paint()..color = _active(3, const Color(0xFF805A43)),
    );
    for (var tier = 0; tier < 3; tier++) {
      final y = base.dy - (52 + tier * 30) * unit;
      final half = (42 - tier * 7) * unit;
      canvas.drawPath(
        Path()
          ..moveTo(base.dx, y - 39 * unit)
          ..lineTo(base.dx - half, y + 30 * unit)
          ..lineTo(base.dx + half, y + 30 * unit)
          ..close(),
        Paint()..color = _active(3, _taskColor(2)),
      );
    }
  }

  void _paintFlowers(Canvas canvas, Size size, {required int count}) {
    final unit = math.min(size.width, size.height) / 430;
    final color = _active(4, _taskColor(3));
    final finalColor = _active(5, _taskColor(4));
    for (var index = 0; index < count; index++) {
      final x = size.width * (0.07 + (index % 7) * 0.145);
      final y = size.height * (0.76 + (index ~/ 7) * 0.12);
      canvas.drawLine(
        Offset(x, y),
        Offset(x, y + 17 * unit),
        Paint()
          ..color = _active(3, const Color(0xFF347C49))
          ..strokeWidth = 3 * unit,
      );
      final petalColor = index.isEven ? color : finalColor;
      for (var petal = 0; petal < 5; petal++) {
        final angle = petal * math.pi * 2 / 5;
        canvas.drawCircle(
          Offset(
            x + math.cos(angle) * 6 * unit,
            y + math.sin(angle) * 6 * unit,
          ),
          4.5 * unit,
          Paint()..color = petalColor,
        );
      }
      canvas.drawCircle(Offset(x, y), 3.5 * unit, Paint()..color = color);
    }
  }

  void _paintHouse(Canvas canvas, Offset center, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    final body = Rect.fromCenter(
      center: center,
      width: 105 * unit,
      height: 76 * unit,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(7 * unit)),
      Paint()..color = _active(4, map.accent),
    );
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - 67 * unit, center.dy - 34 * unit)
        ..lineTo(center.dx, center.dy - 93 * unit)
        ..lineTo(center.dx + 67 * unit, center.dy - 34 * unit)
        ..close(),
      Paint()..color = _active(4, _taskColor(3)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center + Offset(0, 17 * unit),
          width: 25 * unit,
          height: 42 * unit,
        ),
        Radius.circular(5 * unit),
      ),
      Paint()..color = _active(5, _taskColor(4)),
    );
  }

  void _paintPalm(Canvas canvas, Offset base, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    final trunk = Path()
      ..moveTo(base.dx - 8 * unit, base.dy)
      ..quadraticBezierTo(
        base.dx + 13 * unit,
        base.dy - 68 * unit,
        base.dx + 5 * unit,
        base.dy - 125 * unit,
      )
      ..lineTo(base.dx + 18 * unit, base.dy - 124 * unit)
      ..quadraticBezierTo(
        base.dx + 25 * unit,
        base.dy - 60 * unit,
        base.dx + 10 * unit,
        base.dy,
      )
      ..close();
    canvas.drawPath(
      trunk,
      Paint()..color = _active(3, const Color(0xFF98633D)),
    );
    final leaves = Paint()..color = _active(3, _taskColor(2));
    final crown = base + Offset(12 * unit, -125 * unit);
    for (var index = 0; index < 7; index++) {
      final angle = -math.pi + index * math.pi / 6;
      canvas.drawOval(
        Rect.fromCenter(
          center: crown + Offset(math.cos(angle), math.sin(angle)) * 31 * unit,
          width: 73 * unit,
          height: 20 * unit,
        ),
        leaves,
      );
    }
  }

  void _paintUmbrella(Canvas canvas, Offset base, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    canvas.drawLine(
      base,
      base - Offset(0, 91 * unit),
      Paint()
        ..color = _active(4, const Color(0xFF805641))
        ..strokeWidth = 6 * unit,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: base - Offset(0, 88 * unit),
        width: 118 * unit,
        height: 75 * unit,
      ),
      math.pi,
      math.pi,
      true,
      Paint()..color = _active(4, _taskColor(3)),
    );
  }

  void _paintMountains(Canvas canvas, Size size, {bool snowy = false}) {
    final color = _active(3, map.ground);
    for (var index = 0; index < 4; index++) {
      final x = size.width * (-0.05 + index * 0.31);
      final peak = size.height * (0.30 + (index.isEven ? 0.03 : 0.11));
      final path = Path()
        ..moveTo(x, size.height * 0.73)
        ..lineTo(x + size.width * 0.19, peak)
        ..lineTo(x + size.width * 0.39, size.height * 0.73)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
      if (snowy) {
        canvas.drawPath(
          Path()
            ..moveTo(x + size.width * 0.12, peak + size.height * 0.12)
            ..lineTo(x + size.width * 0.19, peak)
            ..lineTo(x + size.width * 0.27, peak + size.height * 0.15)
            ..close(),
          Paint()..color = _active(3, const Color(0xFFF8FCFF)),
        );
      }
    }
  }

  void _paintCactus(Canvas canvas, Offset base, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    final paint = Paint()
      ..color = _active(3, _taskColor(2))
      ..strokeWidth = 18 * unit
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(base, base - Offset(0, 104 * unit), paint);
    canvas.drawLine(
      base - Offset(0, 65 * unit),
      base + Offset(28 * unit, -65 * unit),
      paint,
    );
    canvas.drawLine(
      base + Offset(28 * unit, -65 * unit),
      base + Offset(28 * unit, -88 * unit),
      paint,
    );
  }

  void _paintTent(Canvas canvas, Offset base, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    canvas.drawPath(
      Path()
        ..moveTo(base.dx - 77 * unit, base.dy)
        ..lineTo(base.dx, base.dy - 100 * unit)
        ..lineTo(base.dx + 77 * unit, base.dy)
        ..close(),
      Paint()..color = _active(4, _taskColor(3)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(base.dx, base.dy - 100 * unit)
        ..lineTo(base.dx, base.dy)
        ..lineTo(base.dx + 39 * unit, base.dy)
        ..close(),
      Paint()..color = _active(4, map.accent.withValues(alpha: 0.78)),
    );
  }

  void _paintCrystals(Canvas canvas, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    final paint = Paint()..color = _active(5, _taskColor(4));
    for (var index = 0; index < 7; index++) {
      final center = Offset(
        size.width * (0.16 + index * 0.115),
        size.height * (0.78 + (index % 2) * 0.09),
      );
      canvas.drawPath(
        Path()
          ..moveTo(center.dx, center.dy - 24 * unit)
          ..lineTo(center.dx + 11 * unit, center.dy)
          ..lineTo(center.dx, center.dy + 15 * unit)
          ..lineTo(center.dx - 11 * unit, center.dy)
          ..close(),
        paint,
      );
    }
  }

  void _paintLollipop(Canvas canvas, Offset base, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    canvas.drawLine(
      base,
      base - Offset(0, 105 * unit),
      Paint()
        ..color = _active(3, Colors.white)
        ..strokeWidth = 8 * unit,
    );
    canvas.drawCircle(
      base - Offset(0, 118 * unit),
      40 * unit,
      Paint()..color = _active(3, _taskColor(2)),
    );
  }

  void _paintBalloons(Canvas canvas, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    for (var index = 0; index < 8; index++) {
      final center = Offset(
        size.width * (0.10 + index * 0.115),
        size.height * (0.32 + (index % 3) * 0.08),
      );
      canvas.drawLine(
        center + Offset(0, 22 * unit),
        center + Offset(0, 74 * unit),
        Paint()
          ..color = _active(5, const Color(0xFF7A6870))
          ..strokeWidth = 1.5 * unit,
      );
      canvas.drawOval(
        Rect.fromCenter(center: center, width: 30 * unit, height: 43 * unit),
        Paint()..color = _active(5, _taskColor(4)),
      );
    }
  }

  void _paintFieldLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _active(3, const Color(0xFFB4D45B))
      ..strokeWidth = 5;
    for (var index = 0; index < 7; index++) {
      canvas.drawLine(
        Offset(size.width * 0.05, size.height * (0.73 + index * 0.045)),
        Offset(size.width * 0.95, size.height * (0.69 + index * 0.045)),
        paint,
      );
    }
  }

  void _paintBarn(Canvas canvas, Offset center, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    canvas.drawRect(
      Rect.fromCenter(center: center, width: 135 * unit, height: 95 * unit),
      Paint()..color = _active(4, _taskColor(3)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - 78 * unit, center.dy - 45 * unit)
        ..lineTo(center.dx, center.dy - 105 * unit)
        ..lineTo(center.dx + 78 * unit, center.dy - 45 * unit)
        ..close(),
      Paint()..color = _active(4, const Color(0xFF7B4D45)),
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: center + Offset(0, 18 * unit),
        width: 43 * unit,
        height: 58 * unit,
      ),
      Paint()..color = _active(5, _taskColor(4)),
    );
  }

  void _paintFence(Canvas canvas, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    final paint = Paint()
      ..color = _active(5, const Color(0xFFF6E3B3))
      ..strokeWidth = 7 * unit;
    canvas.drawLine(
      Offset(size.width * 0.05, size.height * 0.82),
      Offset(size.width * 0.95, size.height * 0.82),
      paint,
    );
    for (var index = 0; index < 11; index++) {
      final x = size.width * (0.06 + index * 0.088);
      canvas.drawLine(
        Offset(x, size.height * 0.75),
        Offset(x, size.height * 0.91),
        paint,
      );
    }
  }

  void _paintSeaweed(Canvas canvas, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    final paint = Paint()
      ..color = _active(3, _taskColor(2))
      ..strokeWidth = 10 * unit
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var index = 0; index < 9; index++) {
      final x = size.width * (0.06 + index * 0.115);
      canvas.drawPath(
        Path()
          ..moveTo(x, size.height)
          ..quadraticBezierTo(
            x - 24 * unit,
            size.height * 0.84,
            x + (index.isEven ? 18 : -18) * unit,
            size.height * 0.70,
          ),
        paint,
      );
    }
  }

  void _paintCoral(Canvas canvas, Offset base, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    final paint = Paint()
      ..color = _active(4, _taskColor(3))
      ..strokeWidth = 13 * unit
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(base, base - Offset(0, 87 * unit), paint);
    canvas.drawLine(
      base - Offset(0, 48 * unit),
      base + Offset(-38 * unit, -81 * unit),
      paint,
    );
    canvas.drawLine(
      base - Offset(0, 65 * unit),
      base + Offset(40 * unit, -102 * unit),
      paint,
    );
  }

  void _paintBubbles(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _active(5, _taskColor(4)).withValues(alpha: 0.70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (var index = 0; index < 16; index++) {
      canvas.drawCircle(
        Offset(
          size.width * (0.07 + (index % 8) * 0.125),
          size.height * (0.19 + (index ~/ 8) * 0.25 + (index % 3) * 0.05),
        ),
        6.0 + (index % 4) * 3,
        paint,
      );
    }
  }

  void _paintPlanet(Canvas canvas, Offset center, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    canvas.drawCircle(
      center,
      42 * unit,
      Paint()..color = _active(2, _taskColor(1)),
    );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 117 * unit, height: 27 * unit),
      Paint()
        ..color = _active(2, const Color(0xFFFFCF62))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8 * unit,
    );
  }

  void _paintAlienPlants(Canvas canvas, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    final paint = Paint()
      ..color = _active(3, _taskColor(2))
      ..strokeWidth = 6 * unit
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 8; index++) {
      final base = Offset(
        size.width * (0.08 + index * 0.13),
        size.height * 0.88,
      );
      canvas.drawLine(
        base,
        base - Offset(0, (37 + index % 3 * 9) * unit),
        paint,
      );
      canvas.drawCircle(
        base - Offset(0, (45 + index % 3 * 9) * unit),
        10 * unit,
        Paint()..color = _active(3, _taskColor(2)),
      );
    }
  }

  void _paintRocket(Canvas canvas, Offset center, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 70 * unit, height: 145 * unit),
      Radius.circular(35 * unit),
    );
    canvas.drawRRect(body, Paint()..color = _active(4, _taskColor(3)));
    canvas.drawCircle(
      center - Offset(0, 31 * unit),
      17 * unit,
      Paint()..color = _active(4, _taskColor(1)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - 25 * unit, center.dy + 62 * unit)
        ..lineTo(center.dx - 54 * unit, center.dy + 92 * unit)
        ..lineTo(center.dx - 23 * unit, center.dy + 84 * unit)
        ..close(),
      Paint()..color = _active(4, map.accent),
    );
  }

  void _paintStars(Canvas canvas, Size size) {
    for (var index = 0; index < 18; index++) {
      _paintStar(
        canvas,
        Offset(
          size.width * (0.05 + (index % 9) * 0.115),
          size.height * (0.10 + (index ~/ 9) * 0.30 + (index % 2) * 0.06),
        ),
        6.0 + (index % 3) * 2,
        _active(5, _taskColor(4)),
      );
    }
  }

  void _paintVolcano(Canvas canvas, Size size) {
    final peak = Offset(size.width * 0.51, size.height * 0.39);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.26, size.height * 0.78)
        ..lineTo(peak.dx - size.width * 0.07, peak.dy)
        ..lineTo(peak.dx + size.width * 0.07, peak.dy)
        ..lineTo(size.width * 0.80, size.height * 0.78)
        ..close(),
      Paint()..color = _active(4, const Color(0xFF765B58)),
    );
    final lava = Paint()
      ..color = _active(1, _taskColor(0))
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(peak, Offset(size.width * 0.57, size.height * 0.69), lava);
  }

  void _paintTrack(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _active(3, const Color(0xFF555B65))
      ..strokeWidth = 6;
    canvas.drawLine(
      Offset(0, size.height * 0.80),
      Offset(size.width, size.height * 0.80),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.88),
      Offset(size.width, size.height * 0.88),
      paint,
    );
    for (var index = 0; index < 18; index++) {
      final x = size.width * index / 17;
      canvas.drawLine(
        Offset(x, size.height * 0.77),
        Offset(x, size.height * 0.91),
        paint..strokeWidth = 3,
      );
    }
  }

  void _paintTrain(Canvas canvas, Offset center, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 185 * unit, height: 79 * unit),
        Radius.circular(12 * unit),
      ),
      Paint()..color = _active(4, _taskColor(3)),
    );
    for (var index = 0; index < 3; index++) {
      canvas.drawCircle(
        center + Offset((-58 + index * 58) * unit, 43 * unit),
        18 * unit,
        Paint()..color = _active(4, const Color(0xFF454752)),
      );
    }
    canvas.drawRect(
      Rect.fromCenter(
        center: center - Offset(40 * unit, 5 * unit),
        width: 48 * unit,
        height: 35 * unit,
      ),
      Paint()..color = _active(4, _taskColor(1)),
    );
  }

  void _paintFerns(Canvas canvas, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    final paint = Paint()
      ..color = _active(3, _taskColor(2))
      ..strokeWidth = 5 * unit
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 7; index++) {
      final base = Offset(
        size.width * (0.08 + index * 0.145),
        size.height * 0.86,
      );
      canvas.drawLine(base, base - Offset(0, 72 * unit), paint);
      for (var leaf = 0; leaf < 4; leaf++) {
        final y = (22 + leaf * 14) * unit;
        canvas.drawLine(
          base - Offset(0, y),
          base + Offset(23 * unit, -y - 12),
          paint,
        );
        canvas.drawLine(
          base - Offset(0, y),
          base + Offset(-23 * unit, -y - 12),
          paint,
        );
      }
    }
  }

  void _paintEgg(Canvas canvas, Offset center, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 70 * unit, height: 96 * unit),
      Paint()..color = _active(4, _taskColor(3)),
    );
    for (var index = 0; index < 5; index++) {
      canvas.drawCircle(
        center +
            Offset(
              (index % 2 == 0 ? -15 : 15) * unit,
              (-27 + index * 14) * unit,
            ),
        6 * unit,
        Paint()..color = _active(4, const Color(0xFFFFD8B8)),
      );
    }
  }

  void _paintHive(Canvas canvas, Offset center, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    for (var index = 0; index < 4; index++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center + Offset(0, index * 16 * unit),
          width: (79 - index * 5) * unit,
          height: 35 * unit,
        ),
        Paint()..color = _active(4, _taskColor(3)),
      );
    }
    canvas.drawCircle(
      center + Offset(0, 31 * unit),
      10 * unit,
      Paint()..color = _active(5, const Color(0xFF594438)),
    );
  }

  void _paintSled(Canvas canvas, Offset center, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    final paint = Paint()
      ..color = _active(4, _taskColor(3))
      ..strokeWidth = 10 * unit
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center - Offset(55 * unit, 20 * unit),
      center + Offset(55 * unit, 20 * unit),
      paint,
    );
    canvas.drawLine(
      center - Offset(55 * unit, 20 * unit),
      center - Offset(28 * unit, 62 * unit),
      paint,
    );
    canvas.drawLine(
      center + Offset(55 * unit, 20 * unit),
      center + Offset(28 * unit, -62 * unit),
      paint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: center + Offset(0, 29 * unit),
        width: 150 * unit,
        height: 55 * unit,
      ),
      0,
      math.pi,
      false,
      Paint()
        ..color = _active(4, const Color(0xFF755866))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 * unit,
    );
  }

  void _paintAurora(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _active(5, _taskColor(4)).withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 3; index++) {
      canvas.drawPath(
        Path()
          ..moveTo(-20, size.height * (0.25 + index * 0.08))
          ..cubicTo(
            size.width * 0.25,
            size.height * (0.05 + index * 0.08),
            size.width * 0.65,
            size.height * (0.48 + index * 0.04),
            size.width + 20,
            size.height * (0.18 + index * 0.06),
          ),
        paint,
      );
    }
  }

  void _paintClouds(Canvas canvas, Size size) {
    for (var index = 0; index < 5; index++) {
      final center = Offset(
        size.width * (0.10 + index * 0.21),
        size.height * (0.38 + index % 2 * 0.15),
      );
      final paint = Paint()..color = _active(3, Colors.white);
      canvas.drawCircle(center, 24, paint);
      canvas.drawCircle(center + const Offset(24, 5), 31, paint);
      canvas.drawCircle(center + const Offset(51, 9), 22, paint);
    }
  }

  void _paintCastle(Canvas canvas, Offset center, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    final paint = Paint()..color = _active(4, map.accent);
    canvas.drawRect(
      Rect.fromCenter(center: center, width: 145 * unit, height: 100 * unit),
      paint,
    );
    for (final x in [-66.0, 0.0, 66.0]) {
      canvas.drawRect(
        Rect.fromCenter(
          center: center + Offset(x * unit, -44 * unit),
          width: 43 * unit,
          height: 129 * unit,
        ),
        paint,
      );
      canvas.drawPath(
        Path()
          ..moveTo(center.dx + (x - 30) * unit, center.dy - 105 * unit)
          ..lineTo(center.dx + x * unit, center.dy - 149 * unit)
          ..lineTo(center.dx + (x + 30) * unit, center.dy - 105 * unit)
          ..close(),
        Paint()..color = _active(4, _taskColor(3)),
      );
    }
  }

  void _paintFlags(Canvas canvas, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    for (var index = 0; index < 7; index++) {
      final x = size.width * (0.16 + index * 0.115);
      canvas.drawLine(
        Offset(x, size.height * 0.23),
        Offset(x, size.height * 0.36),
        Paint()
          ..color = _active(5, const Color(0xFF624F58))
          ..strokeWidth = 3 * unit,
      );
      canvas.drawPath(
        Path()
          ..moveTo(x, size.height * 0.23)
          ..lineTo(x + 27 * unit, size.height * 0.27)
          ..lineTo(x, size.height * 0.31)
          ..close(),
        Paint()..color = _active(5, _taskColor(4)),
      );
    }
  }

  void _paintCart(Canvas canvas, Offset center, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 125 * unit, height: 55 * unit),
        Radius.circular(8 * unit),
      ),
      Paint()..color = _active(4, _taskColor(3)),
    );
    for (final x in [-43.0, 43.0]) {
      canvas.drawCircle(
        center + Offset(x * unit, 38 * unit),
        17 * unit,
        Paint()..color = _active(4, const Color(0xFF604B42)),
      );
    }
  }

  void _paintFruit(Canvas canvas, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    for (var index = 0; index < 22; index++) {
      canvas.drawCircle(
        Offset(
          size.width * (0.10 + (index % 11) * 0.085),
          size.height * (0.42 + (index ~/ 11) * 0.16 + (index % 3) * 0.025),
        ),
        7 * unit,
        Paint()..color = _active(5, _taskColor(4)),
      );
    }
  }

  void _paintDrum(Canvas canvas, Offset center, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 105 * unit, height: 87 * unit),
        Radius.circular(17 * unit),
      ),
      Paint()..color = _active(4, _taskColor(3)),
    );
    final line = Paint()
      ..color = _active(4, const Color(0xFFFFDFA2))
      ..strokeWidth = 5 * unit;
    canvas.drawLine(
      center - Offset(46 * unit, 35 * unit),
      center + Offset(46 * unit, 35 * unit),
      line,
    );
    canvas.drawLine(
      center + Offset(46 * unit, -35 * unit),
      center - Offset(46 * unit, -35 * unit),
      line,
    );
  }

  void _paintNotes(Canvas canvas, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    final paint = Paint()
      ..color = _active(5, _taskColor(4))
      ..strokeWidth = 5 * unit
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 10; index++) {
      final center = Offset(
        size.width * (0.12 + index * 0.085),
        size.height * (0.27 + (index % 3) * 0.10),
      );
      canvas.drawCircle(center, 9 * unit, paint);
      canvas.drawLine(
        center + Offset(8 * unit, 0),
        center + Offset(8 * unit, -45 * unit),
        paint,
      );
    }
  }

  void _paintReeds(Canvas canvas, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    final paint = Paint()
      ..color = _active(3, _taskColor(2))
      ..strokeWidth = 5 * unit;
    for (var index = 0; index < 15; index++) {
      final x = size.width * (0.04 + index * 0.067);
      final base = Offset(x, size.height * 0.88);
      canvas.drawLine(
        base,
        base - Offset(0, (38 + index % 4 * 9) * unit),
        paint,
      );
    }
  }

  void _paintBoat(Canvas canvas, Offset center, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - 70 * unit, center.dy)
        ..quadraticBezierTo(
          center.dx,
          center.dy + 65 * unit,
          center.dx + 70 * unit,
          center.dy,
        )
        ..close(),
      Paint()..color = _active(4, _taskColor(3)),
    );
    canvas.drawLine(
      center,
      center - Offset(0, 105 * unit),
      Paint()
        ..color = _active(5, const Color(0xFF6B5145))
        ..strokeWidth = 5 * unit,
    );
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy - 100 * unit)
        ..lineTo(center.dx + 64 * unit, center.dy - 33 * unit)
        ..lineTo(center.dx, center.dy - 33 * unit)
        ..close(),
      Paint()..color = _active(5, _taskColor(4)),
    );
  }

  void _paintPipes(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _active(3, _taskColor(2))
      ..strokeWidth = 20
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * 0.55)
        ..lineTo(size.width * 0.20, size.height * 0.55)
        ..lineTo(size.width * 0.20, size.height * 0.75)
        ..lineTo(size.width * 0.38, size.height * 0.75),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width, size.height * 0.40)
        ..lineTo(size.width * 0.83, size.height * 0.40)
        ..lineTo(size.width * 0.83, size.height * 0.67),
      paint,
    );
  }

  void _paintFactory(Canvas canvas, Offset center, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    canvas.drawRect(
      Rect.fromCenter(center: center, width: 190 * unit, height: 112 * unit),
      Paint()..color = _active(4, map.accent),
    );
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - 95 * unit, center.dy - 55 * unit)
        ..lineTo(center.dx - 40 * unit, center.dy - 96 * unit)
        ..lineTo(center.dx - 40 * unit, center.dy - 55 * unit)
        ..lineTo(center.dx + 15 * unit, center.dy - 96 * unit)
        ..lineTo(center.dx + 15 * unit, center.dy - 55 * unit)
        ..lineTo(center.dx + 95 * unit, center.dy - 55 * unit)
        ..close(),
      Paint()..color = _active(4, _taskColor(3)),
    );
    for (var index = 0; index < 4; index++) {
      canvas.drawRect(
        Rect.fromCenter(
          center: center + Offset((-63 + index * 42) * unit, -5 * unit),
          width: 25 * unit,
          height: 31 * unit,
        ),
        Paint()..color = _active(4, _taskColor(1)),
      );
    }
  }

  void _paintGears(Canvas canvas, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    for (var index = 0; index < 6; index++) {
      final center = Offset(
        size.width * (0.10 + index * 0.16),
        size.height * (0.33 + index % 2 * 0.13),
      );
      final paint = Paint()
        ..color = _active(5, _taskColor(4))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8 * unit;
      canvas.drawCircle(center, (19 + index % 2 * 7) * unit, paint);
      for (var tooth = 0; tooth < 8; tooth++) {
        final angle = tooth * math.pi / 4;
        canvas.drawLine(
          center + Offset(math.cos(angle), math.sin(angle)) * 26 * unit,
          center + Offset(math.cos(angle), math.sin(angle)) * 36 * unit,
          paint,
        );
      }
    }
  }

  void _paintFountain(Canvas canvas, Offset center, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    final water = Paint()
      ..color = _active(2, _taskColor(1))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7 * unit
      ..strokeCap = StrokeCap.round;
    for (var index = -2; index <= 2; index++) {
      canvas.drawArc(
        Rect.fromCenter(
          center: center + Offset(index * 10 * unit, -16 * unit),
          width: (58 + index.abs() * 15) * unit,
          height: (95 + index.abs() * 12) * unit,
        ),
        math.pi,
        math.pi,
        false,
        water,
      );
    }
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 165 * unit, height: 42 * unit),
      Paint()..color = _active(2, _taskColor(1)),
    );
  }

  void _paintFerrisWheel(Canvas canvas, Offset center, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    final paint = Paint()
      ..color = _active(4, _taskColor(3))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7 * unit;
    canvas.drawCircle(center, 88 * unit, paint);
    for (var index = 0; index < 10; index++) {
      final angle = index * math.pi / 5;
      final edge =
          center + Offset(math.cos(angle), math.sin(angle)) * 88 * unit;
      canvas.drawLine(center, edge, paint);
      canvas.drawCircle(
        edge,
        13 * unit,
        Paint()..color = _active(5, _taskColor(4)),
      );
    }
    canvas.drawLine(center, center + Offset(-55 * unit, 142 * unit), paint);
    canvas.drawLine(center, center + Offset(55 * unit, 142 * unit), paint);
  }

  void _paintDots(
    Canvas canvas,
    Size size, {
    required int count,
    required Color color,
  }) {
    final unit = math.min(size.width, size.height) / 430;
    for (var index = 0; index < count; index++) {
      canvas.drawCircle(
        Offset(
          size.width * (0.08 + (index % 8) * 0.12),
          size.height * (0.25 + (index ~/ 8) * 0.16 + (index % 3) * 0.04),
        ),
        (5 + index % 4) * unit,
        Paint()..color = _active(5, color),
      );
    }
  }

  void _paintMushrooms(Canvas canvas, Size size) {
    final unit = math.min(size.width, size.height) / 430;
    for (var index = 0; index < 9; index++) {
      final base = Offset(
        size.width * (0.08 + index * 0.11),
        size.height * (0.80 + index % 2 * 0.10),
      );
      canvas.drawRect(
        Rect.fromCenter(center: base, width: 8 * unit, height: 25 * unit),
        Paint()..color = _active(5, const Color(0xFFFFE5C0)),
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: base - Offset(0, 13 * unit),
          width: 34 * unit,
          height: 25 * unit,
        ),
        math.pi,
        math.pi,
        true,
        Paint()..color = _active(5, _taskColor(4)),
      );
    }
  }

  void _paintStar(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    for (var point = 0; point < 10; point++) {
      final angle = -math.pi / 2 + point * math.pi / 5;
      final distance = point.isEven ? radius : radius * 0.43;
      final offset =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      if (point == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _paintSparkles(Canvas canvas, Size size) {
    if (sparkle <= 0 || sparkle >= 1) return;
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

  @override
  bool shouldRepaint(covariant GardenRepairPainter oldDelegate) {
    return oldDelegate.map != map ||
        oldDelegate.restoredSteps != restoredSteps ||
        oldDelegate.sparkle != sparkle;
  }
}
