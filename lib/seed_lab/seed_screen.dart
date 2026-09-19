import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game_audio.dart';
import 'seed_art.dart';
import 'seed_model.dart';
import 'seed_sound.dart';

TextStyle _type(
  double size, {
  Color color = labInk,
  FontWeight weight = FontWeight.w600,
  double? spacing,
}) => TextStyle(
  fontSize: size,
  color: color,
  fontWeight: weight,
  height: 1.3,
  letterSpacing: spacing,
);

class SeedLabScreen extends StatefulWidget {
  const SeedLabScreen({
    super.key,
    required this.audio,
    this.model,
    this.onOpenWardrobe,
    this.nativeAudio = true,
    this.onBack,
  });
  final GameAudioController audio;
  final SeedLabModel? model;
  final Future<void> Function()? onOpenWardrobe;
  final bool nativeAudio;
  final VoidCallback? onBack;
  @override
  State<SeedLabScreen> createState() => _SeedLabScreenState();
}

class _SeedLabScreenState extends State<SeedLabScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  SeedLabModel? _model;
  late final AnimationController _ambient, _growth, _feed, _reaction;
  late final SeedSound _sound;
  final ScrollController _playScroll = ScrollController();
  Nutrient? _pouring;
  bool _active = true,
      _covered = false,
      _sheet = false,
      _feeding = false,
      _quiet = false;
  bool _newDiscovery = false;
  int _speechEpoch = 0;
  String? _message;
  SeedLabModel get m => _model!;
  bool get _reduce => _quiet || (_model?.reducedMotion ?? false);
  bool get _available => _active && !_covered && !_sheet;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    );
    _growth = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..addStatusListener(_growthStatus);
    _feed =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1250),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() => _feeding = false);
          }
        });
    _reaction = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _sound = SeedSound(native: widget.nativeAudio);
    widget.audio.addListener(_syncSound);
    _load();
  }

  Future<void> _load() async {
    final model = widget.model ?? await SeedLabModel.load();
    if (!mounted) {
      if (widget.model == null) model.dispose();
      return;
    }
    _model = model;
    model.addListener(_changed);
    if (model.phase == LabPhase.grown) _growth.value = 1;
    setState(() {});
    _syncAnimations();
    _syncSound();
    _say(
      model.phase == LabPhase.grown
          ? '你的小植物在等你，摸摸它吧。'
          : '欢迎来到奇怪种子实验室！选一颗种子，再给它两份神奇养料。',
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _quiet = MediaQuery.disableAnimationsOf(context);
    _syncAnimations();
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    _syncAnimations();
  }

  void _syncAnimations() {
    if (_available && !_reduce) {
      if (!_ambient.isAnimating) _ambient.repeat();
    } else {
      _ambient.stop();
    }
    _feed.duration = Duration(milliseconds: _reduce ? 280 : 1250);
    _growth.duration = Duration(milliseconds: _reduce ? 550 : 3800);
    if (!_available) {
      _growth.stop();
      _feed.stop();
      _reaction.stop();
    } else {
      if (_model?.phase == LabPhase.growing && !_growth.isAnimating) {
        _growth.forward();
      }
      if (_feeding && !_feed.isAnimating) _feed.forward();
    }
  }

  void _syncSound() => _sound.active(widget.audio.enabled && _available);
  void _say(String text) {
    final epoch = ++_speechEpoch;
    if (!_available) return;
    _sound.duck(true);
    unawaited(
      widget.audio.speak(text).whenComplete(() {
        if (mounted && epoch == _speechEpoch) _sound.duck(false);
      }),
    );
  }

  void _receive(Nutrient nutrient) {
    if (_feeding || !_available || !m.add(nutrient)) return;
    setState(() {
      _pouring = nutrient;
      _feeding = true;
      _message = null;
    });
    _feed.forward(from: 0);
    unawaited(
      widget.audio.play(switch (nutrient) {
        Nutrient.moon => GameSound.bell,
        Nutrient.music => GameSound.drum,
        Nutrient.soda => GameSound.splash,
        Nutrient.rainbow => GameSound.discover,
      }),
    );
    if (widget.nativeAudio) unawaited(HapticFeedback.selectionClick());
    _say(
      m.ready
          ? '养料配好啦！点让它长大，看看会发生什么。'
          : '${nutrientNames[nutrient.index]}，咕噜咕噜！再加一份试试。',
    );
  }

  void _grow() {
    if (_feeding || !_available || !m.ready) return;
    _growth.value = 0;
    _newDiscovery = false;
    _message = null;
    m.startGrowing();
    _growth.forward(from: 0);
    if (_playScroll.hasClients) {
      unawaited(
        _playScroll.animateTo(
          0,
          duration: Duration(milliseconds: _reduce ? 1 : 450),
          curve: Curves.easeOutCubic,
        ),
      );
    }
    _sound.effect('grow');
    _say('小种子，伸个懒腰，长大吧！');
  }

  void _growthStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed ||
        !mounted ||
        _model?.phase != LabPhase.growing) {
      return;
    }
    _newDiscovery = m.finishGrowing();
    _message = _newDiscovery ? '新朋友已住进图鉴！' : '老朋友又来做客啦！';
    if (_available) {
      _sound.effect('bloom');
      if (widget.nativeAudio) unawaited(HapticFeedback.lightImpact());
      _say('哇！是${m.result!.name}！摸摸它，和它打个招呼吧。');
    }
    setState(() {});
  }

  void _pet() {
    if (m.phase != LabPhase.grown || _reaction.isAnimating || !_available) {
      return;
    }
    _reaction.forward(from: 0);
    _sound.effect(m.result!.second == Nutrient.music ? 'sing' : 'pop');
    if (widget.nativeAudio) unawaited(HapticFeedback.selectionClick());
  }

  void _newPot() {
    if (m.phase == LabPhase.growing) return;
    _feed.reset();
    _growth.reset();
    _reaction.reset();
    _feeding = false;
    _message = null;
    _newDiscovery = false;
    m.newPot();
    _say('新的花盆准备好了！这次试试不一样的搭配吧。');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (!_active) {
      _speechEpoch++;
      unawaited(widget.audio.stopSpeech());
      unawaited(widget.audio.stopEffects());
    }
    _syncAnimations();
    _syncSound();
  }

  Future<void> _openWardrobe() async {
    if (widget.onOpenWardrobe == null) return;
    setState(() => _covered = true);
    _speechEpoch++;
    unawaited(widget.audio.stopSpeech());
    unawaited(widget.audio.stopEffects());
    _syncAnimations();
    _syncSound();
    try {
      await widget.onOpenWardrobe!();
    } finally {
      if (mounted) {
        setState(() => _covered = false);
        _syncAnimations();
        _syncSound();
      }
    }
  }

  Future<void> _showCollection({bool cross = false}) async {
    if (_sheet || m.phase == LabPhase.growing) return;
    setState(() => _sheet = true);
    _syncAnimations();
    _syncSound();
    _speechEpoch++;
    unawaited(widget.audio.stopSpeech());
    final result = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      backgroundColor: labCream,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => _CollectionSheet(model: m, cross: cross),
    );
    if (!mounted) return;
    setState(() => _sheet = false);
    _syncAnimations();
    _syncSound();
    if (result is List<PlantDiscovery> && result.length == 2) {
      _newPot();
      m.cross(result[0], result[1]);
      _say('两位朋友的种子准备好啦，点让它长大，发现双生植物！');
    } else if (result is PlantDiscovery) {
      _newPot();
      m.selectSeed(result.seed);
      m.add(result.first);
      m.add(result.second);
      _say('配方准备好啦，再种一次吧。');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.audio.removeListener(_syncSound);
    _speechEpoch++;
    unawaited(widget.audio.stopSpeech());
    unawaited(widget.audio.stopEffects());
    _model?.removeListener(_changed);
    if (widget.model == null) _model?.dispose();
    _ambient.dispose();
    _growth.dispose();
    _feed.dispose();
    _reaction.dispose();
    _sound.dispose();
    _playScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_model == null) {
      return const Scaffold(
        backgroundColor: labCream,
        body: Center(child: CircularProgressIndicator(color: labGreen)),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7EE),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide =
                constraints.maxWidth >= 900 && constraints.maxHeight >= 600;
            final short =
                constraints.maxHeight < 700 && constraints.maxWidth >= 640;
            final pad = wide ? 28.0 : 16.0;
            return Padding(
              padding: EdgeInsets.fromLTRB(pad, wide ? 18 : 8, pad, 8),
              child: Column(
                children: [
                  _header(wide),
                  SizedBox(height: wide ? 20 : 10),
                  Expanded(
                    child: wide
                        ? _desktop()
                        : short
                        ? _landscape()
                        : _mobile(constraints.maxWidth),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header(bool wide) => Row(
    children: [
      if (widget.onBack != null)
        IconButton(
          onPressed: widget.onBack,
          tooltip: '返回山海',
          icon: const Icon(Icons.arrow_back_rounded, color: labInk),
        )
      else
        Container(
          width: wide ? 57 : 44,
          height: wide ? 57 : 44,
          decoration: BoxDecoration(
            color: const Color(0xFFE4EDDA),
            borderRadius: BorderRadius.circular(17),
          ),
          child: const SeedGlyph(seed: SeedKind.tree, size: 46),
        ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '奇怪种子实验室',
              style: _type(wide ? 27 : 19, weight: FontWeight.w800, spacing: 1),
            ),
            if (wide)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  '云间花房  /  让好奇心，慢慢发芽',
                  style: _type(12, color: const Color(0xFF899486), spacing: 2),
                ),
              ),
          ],
        ),
      ),
      if (wide) ...[
        _LabButton(
          label: '植物图鉴',
          icon: Icons.auto_stories_rounded,
          trailing: '${m.discoveries.length}',
          onTap: () => _showCollection(),
          key: const ValueKey('seed-collection'),
        ),
        const SizedBox(width: 10),
        _LabButton(
          label: '种子杂交',
          icon: Icons.spa_rounded,
          onTap: () => _showCollection(cross: true),
          key: const ValueKey('seed-cross'),
        ),
        const SizedBox(width: 12),
      ] else ...[
        IconButton(
          key: const ValueKey('seed-collection'),
          onPressed: () => _showCollection(),
          tooltip: '植物图鉴',
          icon: const Icon(Icons.auto_stories_rounded, color: labGreen),
        ),
      ],
      AudioToggleButton(
        audio: widget.audio,
        foregroundColor: labInk,
        backgroundColor: const Color(0xFFEAF0DF),
      ),
      PopupMenuButton<String>(
        tooltip: '更多',
        icon: const Icon(Icons.more_horiz_rounded, color: labInk),
        onSelected: (value) {
          if (value == 'wardrobe') _openWardrobe();
          if (value == 'motion') m.setReducedMotion(!m.reducedMotion);
          if (value == 'cross') _showCollection(cross: true);
        },
        itemBuilder: (context) => [
          if (!wide) const PopupMenuItem(value: 'cross', child: Text('种子杂交')),
          PopupMenuItem(
            value: 'motion',
            child: Text(m.reducedMotion ? '打开丰富动画' : '切换轻柔动画'),
          ),
          if (widget.onOpenWardrobe != null)
            const PopupMenuItem(value: 'wardrobe', child: Text('绒绒衣橱 · 更多游戏')),
        ],
      ),
    ],
  );

  Widget _desktop() => Column(
    children: [
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _stage()),
            const SizedBox(width: 20),
            SizedBox(width: 292, child: _controlPanel()),
          ],
        ),
      ),
      const SizedBox(height: 18),
      _ingredientsShelf(false),
      const SizedBox(height: 10),
      _footer(),
    ],
  );

  Widget _landscape() => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(child: _stage()),
      const SizedBox(width: 14),
      SizedBox(
        width: 300,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _seedChoices(true),
              const SizedBox(height: 10),
              _ingredientsShelf(true),
              const SizedBox(height: 10),
              _recipe(),
              const SizedBox(height: 10),
              _action(),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _mobile(double width) => SingleChildScrollView(
    controller: _playScroll,
    child: Column(
      children: [
        SizedBox(height: (width * .81).clamp(265.0, 410.0), child: _stage()),
        const SizedBox(height: 14),
        _seedChoices(true),
        const SizedBox(height: 14),
        _ingredientsShelf(true),
        const SizedBox(height: 14),
        _recipe(),
        const SizedBox(height: 12),
        _action(),
        const SizedBox(height: 14),
        _footer(),
        const SizedBox(height: 8),
      ],
    ),
  );

  Widget _stage() => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 550 || constraints.maxHeight < 400;
      final full = m.phase == LabPhase.grown;
      final tip = _feeding
          ? '咕噜咕噜，魔法正在融进去…'
          : m.phase == LabPhase.growing
          ? '嘘…小种子正在伸懒腰！'
          : full
          ? '摸摸它，看看它的小魔法'
          : m.ready
          ? '准备好啦！让好奇心开花吧'
          : '点选或拖入养料，开始奇妙实验';
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFDEE6D6)),
          boxShadow: [
            BoxShadow(
              color: labInk.withValues(alpha: .035),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(27),
          child: Stack(
            children: [
              const Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(painter: GreenhousePainter()),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _ambient,
                      builder: (context, _) => CustomPaint(
                        painter: LabAtmospherePainter(
                          _reduce ? 0 : _ambient.value * 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: compact ? 16 : 24,
                left: compact ? 18 : 26,
                right: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: labGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          '云间花房',
                          style: _type(11, color: labGreen, spacing: 2),
                        ),
                        const Spacer(),
                        _tag(
                          '实验  ${((m.experiments + (full ? 0 : 1))).toString().padLeft(2, '0')}',
                          small: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Align(
                        key: ValueKey(full ? m.result!.name : 'start'),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          full ? m.result!.name : '今天，会长出什么呢？',
                          style: _type(
                            compact ? 21 : 29,
                            weight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    if (!compact)
                      Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Text(
                          full ? m.result!.secret : '一点月光，一点奇思妙想。种下你的第一个小惊喜。',
                          style: _type(12, color: const Color(0xFF8A9986)),
                        ),
                      ),
                  ],
                ),
              ),
              Positioned.fill(
                top: compact ? 55 : 80,
                bottom: compact ? 22 : 32,
                child: DragTarget<Nutrient>(
                  onWillAcceptWithDetails: (_) =>
                      !_feeding &&
                      m.phase == LabPhase.planting &&
                      m.ingredients.length < 2 &&
                      !m.isHybrid,
                  onAcceptWithDetails: (details) => _receive(details.data),
                  builder: (context, candidates, rejected) => AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    decoration: BoxDecoration(
                      color: candidates.isNotEmpty
                          ? const Color(0xFFDCEDD4).withValues(alpha: .4)
                          : Colors.transparent,
                    ),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Semantics(
                          button: full,
                          label: full ? '摸摸${m.result!.name}' : '种子花盆，拖入养料',
                          child: GestureDetector(
                            key: const ValueKey('seed-pot'),
                            behavior: HitTestBehavior.opaque,
                            onTap: full ? _pet : null,
                            child: RepaintBoundary(
                              child: AnimatedBuilder(
                                animation: Listenable.merge([
                                  _ambient,
                                  _growth,
                                  _feed,
                                  _reaction,
                                ]),
                                builder: (context, _) => CustomPaint(
                                  painter: PlantPainter(
                                    seed: m.seed,
                                    plant: m.result,
                                    time: _ambient.value * 24,
                                    growth: m.phase == LabPhase.planting
                                        ? 0
                                        : _growth.value,
                                    feed: _feeding ? _feed.value : 0,
                                    nutrient: _pouring,
                                    reaction: _reduce
                                        ? 0
                                        : (_reaction.isAnimating
                                              ? _reaction.value
                                              : 0),
                                    ingredients: m.ingredients.length,
                                    ambient: !_reduce,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (full && _newDiscovery)
                Positioned(
                  right: compact ? 16 : 26,
                  top: compact ? 77 : 117,
                  child: Transform.rotate(
                    angle: .10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE9AC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE9CE83)),
                      ),
                      child: Text(
                        '新发现！',
                        style: _type(
                          12,
                          color: const Color(0xFF98732F),
                          weight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 12,
                right: 12,
                bottom: compact ? 12 : 17,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: labCream.withValues(alpha: .88),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          full
                              ? Icons.touch_app_rounded
                              : Icons.auto_awesome_rounded,
                          size: 15,
                          color: labGreen,
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            tip,
                            style: _type(11, color: labGreen),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _controlPanel() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: labCream,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: const Color(0xFFE4E8D8)),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('01', '选一颗小种子'),
                  const SizedBox(height: 14),
                  _seedChoices(false),
                  const SizedBox(height: 24),
                  _sectionTitle('02', '调配奇妙养料'),
                  const SizedBox(height: 8),
                  Text(
                    '任意两份搭配，会有怎样的惊喜？',
                    style: _type(11, color: const Color(0xFF919A87)),
                  ),
                  const SizedBox(height: 15),
                  _recipe(),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  children: [
                    _action(),
                    const SizedBox(height: 12),
                    Text(
                      m.phase == LabPhase.grown
                          ? (_message ?? '这位朋友已经住进图鉴')
                          : '每一次好奇，都值得一朵小花。',
                      style: _type(10, color: const Color(0xFF9AA08D)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _seedChoices(bool horizontal) {
    final children = SeedKind.values.map((seed) {
      final selected = m.seed == seed,
          enabled = m.phase == LabPhase.planting && !m.isHybrid && !_feeding;
      return Semantics(
        button: true,
        selected: selected,
        label: seedNames[seed.index],
        child: InkWell(
          key: ValueKey('seed-kind-${seed.name}'),
          onTap: enabled
              ? () {
                  m.selectSeed(seed);
                  unawaited(widget.audio.play(GameSound.tap));
                }
              : null,
          borderRadius: BorderRadius.circular(17),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: EdgeInsets.symmetric(
              horizontal: horizontal ? 4 : 12,
              vertical: horizontal ? 8 : 7,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFEDF2E3)
                  : const Color(0xFFF8F7EF),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: selected
                    ? const Color(0xFF9CB78D)
                    : const Color(0xFFEEEEE3),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: horizontal
                ? Column(
                    children: [
                      SeedGlyph(seed: seed, size: 42),
                      const SizedBox(height: 3),
                      Text(seedNames[seed.index], style: _type(11)),
                    ],
                  )
                : Row(
                    children: [
                      SeedGlyph(seed: seed, size: 46),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(seedNames[seed.index], style: _type(13)),
                            const SizedBox(height: 3),
                            Text(
                              ['圆滚滚的小心愿', '藏着星星的梦', '想开花的小脑袋'][seed.index],
                              style: _type(10, color: const Color(0xFF9AA18D)),
                            ),
                          ],
                        ),
                      ),
                      if (selected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: labGreen,
                          size: 18,
                        ),
                    ],
                  ),
          ),
        ),
      );
    }).toList();
    if (horizontal) {
      return Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 9),
            Expanded(child: children[i]),
          ],
        ],
      );
    }
    return Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 9),
          children[i],
        ],
      ],
    );
  }

  Widget _recipe() => Row(
    children: [
      Expanded(child: _slot(0)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9),
        child: Text('+', style: _type(22, color: const Color(0xFFBBC3AB))),
      ),
      Expanded(child: _slot(1)),
      if (m.ingredients.isNotEmpty &&
          m.phase == LabPhase.planting &&
          !m.isHybrid)
        IconButton(
          key: const ValueKey('seed-undo'),
          tooltip: '拿走最后一份养料',
          onPressed: _feeding ? null : m.removeLast,
          icon: const Icon(Icons.undo_rounded, size: 19, color: labGreen),
        ),
    ],
  );

  Widget _slot(int i) {
    final nutrient = m.ingredients.length > i ? m.ingredients[i] : null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      height: 79,
      decoration: BoxDecoration(
        color: nutrient == null
            ? const Color(0xFFF5F4E9)
            : nutrientColors[nutrient.index].withValues(alpha: .13),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: nutrient == null
              ? const Color(0xFFE1E5D4)
              : nutrientColors[nutrient.index].withValues(alpha: .5),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (nutrient == null) ...[
            Icon(Icons.add_rounded, color: const Color(0xFFC2C9B0), size: 27),
            const SizedBox(height: 5),
            Text(
              '第 ${i + 1} 份养料',
              style: _type(10, color: const Color(0xFFA6AE96)),
            ),
          ] else ...[
            SeedGlyph(nutrient: nutrient, size: 45),
            Text(nutrientShortNames[nutrient.index], style: _type(11)),
          ],
        ],
      ),
    );
  }

  Widget _action() {
    final grown = m.phase == LabPhase.grown;
    return _LabButton(
      key: ValueKey(grown ? 'seed-again' : 'seed-grow'),
      label: grown
          ? '再种一盆'
          : m.phase == LabPhase.growing
          ? '正在悄悄长大…'
          : m.isHybrid
          ? '唤醒双生种子'
          : '让它长大吧',
      icon: grown ? Icons.add_rounded : Icons.auto_awesome_rounded,
      primary: true,
      expand: true,
      onTap: grown
          ? _newPot
          : (m.ready && !_feeding)
          ? _grow
          : null,
    );
  }

  Widget _ingredientsShelf(bool compact) => Container(
    padding: EdgeInsets.all(compact ? 12 : 18),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFCF4),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE8E8DA)),
    ),
    child: compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('神奇养料', style: _type(13, weight: FontWeight.w800)),
                  const Spacer(),
                  Text(
                    '选两份，也可以重复哦',
                    style: _type(10, color: const Color(0xFF9AA18D)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _nutrientCards(true),
            ],
          )
        : Row(
            children: [
              SizedBox(
                width: 157,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _tag('MAGIC INGREDIENTS', small: true),
                    const SizedBox(height: 8),
                    Text('加一点想象力', style: _type(20, weight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                      '点一点，或拖进花盆',
                      style: _type(11, color: const Color(0xFF919985)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(child: _nutrientCards(false)),
            ],
          ),
  );

  Widget _nutrientCards(bool compact) => Row(
    children: [
      for (final n in Nutrient.values) ...[
        if (n.index > 0) SizedBox(width: compact ? 6 : 12),
        Expanded(
          child: Builder(
            builder: (context) {
              final enabled =
                  m.phase == LabPhase.planting &&
                  m.ingredients.length < 2 &&
                  !_feeding &&
                  !m.isHybrid;
              final card = Semantics(
                button: true,
                label: '加入${nutrientNames[n.index]}',
                enabled: enabled,
                child: InkWell(
                  key: ValueKey('nutrient-${n.name}'),
                  borderRadius: BorderRadius.circular(17),
                  onTap: enabled ? () => _receive(n) : null,
                  child: AnimatedOpacity(
                    opacity: enabled ? 1 : .58,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      height: compact ? 90 : 104,
                      decoration: BoxDecoration(
                        color: nutrientColors[n.index].withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(
                          color: nutrientColors[n.index].withValues(alpha: .2),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SeedGlyph(nutrient: n, size: compact ? 47 : 54),
                          Text(
                            compact
                                ? nutrientShortNames[n.index]
                                : nutrientNames[n.index],
                            style: _type(compact ? 11 : 13),
                          ),
                          if (!compact) ...[
                            const SizedBox(height: 3),
                            Text(
                              nutrientHints[n.index],
                              style: _type(10, color: const Color(0xFF999C8C)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
              if (!enabled) return card;
              return Draggable<Nutrient>(
                data: n,
                maxSimultaneousDrags: 1,
                feedback: Material(
                  color: Colors.transparent,
                  child: SeedGlyph(nutrient: n, size: 82),
                ),
                childWhenDragging: Opacity(opacity: .4, child: card),
                child: card,
              );
            },
          ),
        ),
      ],
    ],
  );

  Widget _footer() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.eco_outlined, size: 13, color: Color(0xFF9FA990)),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          '小小的种子，大大的不可思议。',
          style: _type(10, color: const Color(0xFF9FA990), spacing: 1),
        ),
      ),
    ],
  );
}

Widget _tag(String text, {bool small = false}) => Container(
  padding: EdgeInsets.symmetric(
    horizontal: small ? 9 : 12,
    vertical: small ? 5 : 7,
  ),
  decoration: BoxDecoration(
    color: const Color(0xFFEAF0DF),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text(
    text,
    style: _type(
      small ? 9 : 11,
      color: const Color(0xFF829573),
      spacing: small ? 1 : 0,
    ),
  ),
);

Widget _sectionTitle(String number, String title) => Row(
  children: [
    Text(number, style: _type(12, color: const Color(0xFFA4B490), spacing: 1)),
    const SizedBox(width: 9),
    Text(title, style: _type(16, weight: FontWeight.w800)),
  ],
);

class _LabButton extends StatefulWidget {
  const _LabButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.primary = false,
    this.expand = false,
    this.trailing,
  });
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool primary, expand;
  final String? trailing;
  @override
  State<_LabButton> createState() => _LabButtonState();
}

class _LabButtonState extends State<_LabButton> {
  bool down = false;
  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final foreground = widget.primary ? Colors.white : labInk;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: AnimatedScale(
        scale: down ? .96 : 1,
        duration: const Duration(milliseconds: 120),
        child: Material(
          color: enabled
              ? (widget.primary ? labGreen : const Color(0xFFF1F3E7))
              : const Color(0xFFBAC9AB),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (value) => setState(() => down = value),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: widget.expand ? double.infinity : null,
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
              child: Row(
                mainAxisSize: widget.expand
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: foreground, size: 19),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      widget.label,
                      style: _type(
                        widget.primary ? 15 : 12,
                        color: foreground,
                        weight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (widget.trailing != null) ...[
                    const SizedBox(width: 8),
                    Text(widget.trailing!, style: _type(12, color: labGreen)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CollectionSheet extends StatefulWidget {
  const _CollectionSheet({required this.model, required this.cross});
  final SeedLabModel model;
  final bool cross;
  @override
  State<_CollectionSheet> createState() => _CollectionSheetState();
}

class _CollectionSheetState extends State<_CollectionSheet> {
  final List<PlantDiscovery> selected = [];
  PlantDiscovery? detail;
  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    final plants = model.discoveries
        .where((p) => !widget.cross || !p.hybrid)
        .toList();
    final height = MediaQuery.sizeOf(context).height;
    return SizedBox(
      height: height * .88,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8DECA),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    detail?.name ?? (widget.cross ? '让两份魔法，长在一起' : '我的奇妙植物图鉴'),
                    style: _type(21, weight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  key: const ValueKey('seed-close-collection'),
                  tooltip: '回到花房',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: labInk),
                ),
              ],
            ),
            Text(
              widget.cross
                  ? '选择两株不同的基础植物，培育双生种子。'
                  : '已经发现 ${model.baseCount} / 30 种基础植物 · ${model.discoveries.length - model.baseCount} 种双生植物',
              style: _type(12, color: const Color(0xFF929D85)),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: detail != null
                  ? _detail(detail!)
                  : plants.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SeedGlyph(seed: SeedKind.tree, size: 100),
                          const SizedBox(height: 18),
                          Text('第一位植物朋友，还在种子里做梦', style: _type(16)),
                          const SizedBox(height: 8),
                          Text(
                            '回到花房，试试「月光 + 音乐」吧。',
                            style: _type(12, color: const Color(0xFF929D85)),
                          ),
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, box) => GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: math.max(
                            2,
                            (box.maxWidth / 190).floor(),
                          ),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: .85,
                        ),
                        itemCount:
                            plants.length +
                            (widget.cross
                                ? 0
                                : math.max(0, 30 - model.baseCount)),
                        itemBuilder: (context, index) {
                          if (index >= plants.length) {
                            return Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F2E7),
                                borderRadius: BorderRadius.circular(21),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.eco_outlined,
                                    size: 47,
                                    color: const Color(0xFFCBD3BC),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '等待一场奇遇',
                                    style: _type(
                                      12,
                                      color: const Color(0xFFA8B097),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          final p = plants[index],
                              chosen = selected.contains(p);
                          return Semantics(
                            button: true,
                            selected: chosen,
                            label: p.name,
                            child: InkWell(
                              key: ValueKey('plant-${p.id}'),
                              borderRadius: BorderRadius.circular(21),
                              onTap: () => setState(() {
                                if (widget.cross) {
                                  if (chosen) {
                                    selected.remove(p);
                                  } else if (selected.length < 2) {
                                    selected.add(p);
                                  }
                                } else {
                                  detail = p;
                                }
                              }),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: chosen
                                      ? const Color(0xFFE4EFD8)
                                      : const Color(0xFFF2F3E9),
                                  borderRadius: BorderRadius.circular(21),
                                  border: Border.all(
                                    color: chosen
                                        ? labGreen
                                        : const Color(0xFFE1E6D5),
                                    width: chosen ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: SizedBox.expand(
                                        child: CustomPaint(
                                          painter: PlantPainter(
                                            seed: p.seed,
                                            plant: p,
                                            ambient: false,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      p.name,
                                      style: _type(12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      p.hybrid ? '双生植物' : p.recipe,
                                      style: _type(
                                        10,
                                        color: const Color(0xFF949D86),
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
            ),
            if (widget.cross)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: _LabButton(
                  key: const ValueKey('seed-cross-confirm'),
                  label: plants.length < 2
                      ? '先发现两株植物，再来试试'
                      : selected.length < 2
                      ? '选好两位植物朋友（${selected.length}/2）'
                      : '把魔法装进一颗种子',
                  primary: true,
                  expand: true,
                  onTap: selected.length == 2
                      ? () => Navigator.pop(
                          context,
                          List<PlantDiscovery>.of(selected),
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detail(PlantDiscovery p) => SingleChildScrollView(
    child: Column(
      children: [
        SizedBox(
          height: 240,
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: CustomPaint(
                painter: PlantPainter(seed: p.seed, plant: p, ambient: false),
              ),
            ),
          ),
        ),
        Text(p.secret, style: _type(15), textAlign: TextAlign.center),
        const SizedBox(height: 18),
        _tag('${seedNames[p.seed.index]}  ·  ${p.recipe}'),
        const SizedBox(height: 24),
        if (!p.hybrid)
          _LabButton(
            label: '照着配方，再种一盆',
            primary: true,
            onTap: () => Navigator.pop(context, p),
          ),
        TextButton(
          onPressed: () => setState(() => detail = null),
          child: const Text('返回图鉴', style: TextStyle(color: labGreen)),
        ),
      ],
    ),
  );
}
