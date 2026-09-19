import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../game_audio.dart';
import 'shanhai_model.dart';
import 'shanhai_native.dart';
import 'shanhai_sound.dart';

const shanGold = Color(0xFFE6C889),
    shanIvory = Color(0xFFF0E8D1),
    shanTeal = Color(0xFF91D9CA);
const shanNight = Color(0xFF081422);
TextStyle _text(
  double size, {
  Color color = shanIvory,
  FontWeight weight = FontWeight.w500,
  double spacing = 0,
}) => TextStyle(
  fontSize: size,
  color: color,
  fontWeight: weight,
  letterSpacing: spacing,
  height: 1.4,
);
typedef ShanhaiStageBuilder =
    Widget Function(BuildContext, Map<String, Object>);

class ShanhaiScreen extends StatefulWidget {
  const ShanhaiScreen({
    super.key,
    required this.audio,
    this.model,
    this.stageBuilder,
    this.nativeController,
    this.onOpenGames,
    this.nativeAudio = true,
  });
  final GameAudioController audio;
  final ShanhaiModel? model;
  final ShanhaiStageBuilder? stageBuilder;
  final ShanhaiNativeController? nativeController;
  final Future<void> Function()? onOpenGames;
  final bool nativeAudio;
  @override
  State<ShanhaiScreen> createState() => _ShanhaiScreenState();
}

class _ShanhaiScreenState extends State<ShanhaiScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  ShanhaiModel? model;
  ShanhaiNativeController? _native;
  late final Ticker _ticker;
  late final ShanhaiSound _sound;
  Duration? _last;
  double _time = 0, _sendClock = 0;
  bool _active = true,
      _covered = false,
      _modal = false,
      _nativeFailed = false,
      _sending = false,
      _pending = false;
  bool _systemReduced = false;
  int _speechEpoch = 0, _nativeGeneration = 0;
  ShanPhase? _previousPhase;
  int _lastStars = 0;
  List<Offset> _trail = [];
  Size _stageSize = Size.zero;
  ShanhaiModel get m => model!;
  bool get _running => _active && !_covered && !_modal;
  bool get _reduced => _systemReduced || (model?.reducedMotion ?? false);
  static const seals = [Offset(.28, .68), Offset(.50, .77), Offset(.73, .65)];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sound = ShanhaiSound(
      native: widget.nativeAudio && widget.stageBuilder == null,
    );
    widget.audio.addListener(_syncSound);
    _ticker = createTicker(_tick);
    _load();
  }

  Future<void> _load() async {
    final loaded = widget.model ?? await ShanhaiModel.load();
    if (!mounted) {
      if (widget.model == null) loaded.dispose();
      return;
    }
    model = loaded;
    _native = widget.nativeController;
    _previousPhase = m.phase;
    m.addListener(_changed);
    _ticker.start();
    _syncSound();
    setState(() {});
    _say(
      m.awakened
          ? '青璃在等你。摸摸它，或喂它一颗灵珠，再一起飞向云海吧。'
          : '湖中沉睡着青玉龙。沿着湖面划一划，连起三个发光的灵印，唤醒它吧。',
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _systemReduced = MediaQuery.disableAnimationsOf(context);
  }

  void _tick(Duration elapsed) {
    final dt = _last == null
        ? 0.0
        : (elapsed - _last!).inMicroseconds / 1000000;
    _last = elapsed;
    if (!_running || model == null || dt <= 0) return;
    _time += dt.clamp(0, .1);
    _sendClock += dt;
    m.advance(dt);
    if (_sendClock >= 1 / 24) {
      _sendClock = 0;
      _sendValues();
    }
  }

  void _changed() {
    if (!mounted) return;
    if (_previousPhase != m.phase) {
      _previousPhase = m.phase;
      switch (m.phase) {
        case ShanPhase.awakening:
          _trail = [];
          _sound.effect('awaken');
          _say('听，山海在回应。青璃，醒来吧！');
        case ShanPhase.companion:
          _say('你好，青璃！摸摸它的龙角，或者送它一颗灵珠。');
        case ShanPhase.flying:
          _lastStars = 0;
          _sound.effect('takeoff');
          _say('出发！左右滑动，带青璃穿过前面的光环。');
        case ShanPhase.arrival:
          _sound.effect('arrival');
          _say('山海之旅完成啦！你们收集了${m.flightStars}束星辉。');
        case ShanPhase.sleeping:
          _say('用手指划过三个灵印，再次唤醒青璃吧。');
      }
      _sendValues();
    }
    if (m.flightStars > _lastStars) {
      _lastStars = m.flightStars;
      _sound.effect('chime');
      _call('burst', 'collect');
    }
    setState(() {});
  }

  Map<String, Object> get _values => {
    ...m.nativeValues,
    'reducedMotion': _reduced,
  };

  Future<void> _call(String method, [Object? args]) async {
    try {
      await _native?.call<void>(method, args);
    } on PlatformException {
      if (mounted) setState(() => _nativeFailed = true);
    } on MissingPluginException {
      if (mounted) setState(() => _nativeFailed = true);
    }
  }

  void _sendValues() {
    if (_native == null || !_running || model == null) return;
    if (_sending) {
      _pending = true;
      return;
    }
    _sending = true;
    unawaited(
      _call('update', _values).whenComplete(() {
        _sending = false;
        if (_pending && mounted) {
          _pending = false;
          _sendValues();
        }
      }),
    );
  }

  void _ready(ShanhaiNativeController controller) {
    if (!mounted) {
      controller.dispose();
      return;
    }
    _native = controller;
    _sendValues();
    _call('active', _running);
  }

  void _syncSound() => _sound.active(widget.audio.enabled && _running);
  void _say(String line) {
    if (!_running) return;
    final epoch = ++_speechEpoch;
    _sound.duck(true);
    unawaited(
      widget.audio.speak(line).whenComplete(() {
        if (mounted && epoch == _speechEpoch) _sound.duck(false);
      }),
    );
  }

  void _suspend() {
    _last = null;
    _speechEpoch++;
    _call('active', _running);
    _syncSound();
    if (!_running) {
      unawaited(widget.audio.stopSpeech());
      unawaited(widget.audio.stopEffects());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    _suspend();
  }

  void _touch(Offset point, {Offset? delta}) {
    if (!_running || _nativeFailed) return;
    if (m.phase == ShanPhase.sleeping) {
      final normalized = Offset(
        point.dx / _stageSize.width,
        point.dy / _stageSize.height,
      );
      _trail = [..._trail, point];
      if (_trail.length > 65) _trail.removeAt(0);
      for (var i = 0; i < seals.length; i++) {
        if ((normalized - seals[i]).distance < .115 && m.traceSeal(i)) {
          _sound.effect('seal');
          if (widget.nativeAudio) unawaited(HapticFeedback.selectionClick());
        }
      }
    } else if (m.phase == ShanPhase.flying) {
      m.steer((point.dx / _stageSize.width - .5) * 2.4);
    } else if (m.phase == ShanPhase.companion && delta != null) {
      m.turn(delta.dx / _stageSize.width * 2.3);
      _sendValues();
    }
  }

  void _pet() {
    if (!_nativeFailed && m.pet()) {
      _sound.effect('pet');
      _call('burst', 'pet');
      _sendValues();
    }
  }

  void _feed() {
    if (!_nativeFailed && m.feed()) {
      _sound.effect('feed');
      _call('burst', 'feed');
      _sendValues();
      _say('青璃收到了你的灵珠，它很喜欢你！');
    }
  }

  Future<void> _games() async {
    if (widget.onOpenGames == null) return;
    _covered = true;
    _suspend();
    try {
      await widget.onOpenGames!();
    } finally {
      if (mounted) {
        _covered = false;
        _suspend();
      }
    }
  }

  Future<void> _journal() async {
    if (_modal) return;
    _modal = true;
    _suspend();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF102433),
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('山海灵契', style: _text(26, color: shanGold, spacing: 3)),
                    const Spacer(),
                    IconButton(
                      key: const ValueKey('shan-close-journal'),
                      tooltip: '返回山海',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: shanIvory),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('青璃 · 青玉灵龙', style: _text(18)),
                const SizedBox(height: 7),
                Text('生于碧水，喜食月华。以星为路，以你为伴。', style: _text(12, color: shanTeal)),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _stat('相伴', m.affection.toString()),
                    _stat('灵珠', m.feeds.toString()),
                    _stat('同游', m.flights.toString()),
                    _stat('星辉', m.totalStarlight.toString()),
                  ],
                ),
                const SizedBox(height: 24),
                ...ShanRealm.values.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(
                          m.visited.contains(r)
                              ? Icons.auto_awesome
                              : Icons.radio_button_unchecked,
                          size: 18,
                          color: m.visited.contains(r)
                              ? shanGold
                              : const Color(0xFF59717E),
                        ),
                        const SizedBox(width: 12),
                        Text(realmNames[r.index], style: _text(14)),
                        const Spacer(),
                        Text(
                          m.visited.contains(r) ? '已结灵缘' : '等待同游',
                          style: _text(11, color: shanTeal),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '你的灵契会自动保存在这台设备上。',
                  style: _text(11, color: const Color(0xFF83969D)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (mounted) {
      _modal = false;
      _suspend();
    }
  }

  Widget _stat(String label, String value) => Container(
    width: 94,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      border: Border.all(color: shanGold.withValues(alpha: .23)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Text(value, style: _text(25, color: shanGold)),
        Text(label, style: _text(11, color: shanTeal, spacing: 2)),
      ],
    ),
  );

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _speechEpoch++;
    widget.audio.removeListener(_syncSound);
    unawaited(widget.audio.stopSpeech());
    unawaited(widget.audio.stopEffects());
    _sound.dispose();
    model?.removeListener(_changed);
    if (widget.model == null) model?.dispose();
    unawaited(_native?.dispose() ?? Future.value());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (model == null) {
      return const Scaffold(
        backgroundColor: shanNight,
        body: Center(child: CircularProgressIndicator(color: shanGold)),
      );
    }
    return Scaffold(
      backgroundColor: shanNight,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            final wide = box.maxWidth >= 900, compact = box.maxHeight < 540;
            final headerHeight = compact ? 61.0 : 82.0;
            return Column(
              children: [
                SizedBox(height: headerHeight, child: _header(wide, compact)),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      wide ? 24 : 12,
                      0,
                      wide ? 24 : 12,
                      compact ? 8 : 14,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _stage(wide, compact)),
                        if (wide) ...[
                          const SizedBox(width: 18),
                          SizedBox(width: 248, child: _sidebar()),
                        ],
                      ],
                    ),
                  ),
                ),
                _bottom(wide, compact),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(bool wide, bool compact) => Padding(
    padding: EdgeInsets.symmetric(horizontal: wide ? 28 : 16),
    child: Row(
      children: [
        Container(
          width: compact ? 37 : 44,
          height: compact ? 37 : 44,
          decoration: BoxDecoration(
            border: Border.all(color: shanGold.withValues(alpha: .6)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const CustomPaint(painter: _SigilPainter(color: shanGold)),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '山海唤灵师',
                  style: _text(
                    wide ? 26 : 20,
                    color: shanGold,
                    weight: FontWeight.w700,
                    spacing: wide ? 5 : 2,
                  ),
                ),
              ),
              if (wide && !compact)
                Text(
                  'SHAN HAI  ·  SPIRIT KEEPER',
                  style: _text(8, color: const Color(0xFF8297A2), spacing: 2),
                ),
            ],
          ),
        ),
        if (wide) ...[
          Text(
            '卷壹  /  青璃入梦',
            style: _text(11, color: const Color(0xFFA5A993), spacing: 2),
          ),
          const SizedBox(width: 28),
        ],
        IconButton(
          key: const ValueKey('shan-journal'),
          tooltip: '山海灵契',
          onPressed: _journal,
          icon: const Icon(
            Icons.auto_stories_outlined,
            color: shanGold,
            size: 21,
          ),
        ),
        AudioToggleButton(
          audio: widget.audio,
          foregroundColor: shanGold,
          backgroundColor: const Color(0xFF172B37),
        ),
        PopupMenuButton<String>(
          tooltip: '更多',
          color: const Color(0xFF18313E),
          icon: const Icon(Icons.more_horiz, color: shanGold),
          onSelected: (value) {
            if (value == 'games') _games();
            if (value == 'motion') {
              m.setReducedMotion(!m.reducedMotion);
              _sendValues();
            }
            if (value == 'wake') m.replayAwakening();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'motion',
              child: Text(
                m.reducedMotion ? '丰富动态效果' : '轻柔动态效果',
                style: _text(13),
              ),
            ),
            if (m.phase == ShanPhase.companion)
              PopupMenuItem(
                value: 'wake',
                child: Text('重温唤醒', style: _text(13)),
              ),
            if (widget.onOpenGames != null)
              PopupMenuItem(
                value: 'games',
                child: Text('种子花房 · 更多游戏', style: _text(13)),
              ),
          ],
        ),
      ],
    ),
  );

  Widget _stage(bool wide, bool compact) => LayoutBuilder(
    builder: (context, box) {
      _stageSize = box.biggest;
      final sleeping = m.phase == ShanPhase.sleeping,
          flying = m.phase == ShanPhase.flying;
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: shanGold.withValues(alpha: .26)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: Stack(
            children: [
              Positioned.fill(
                child:
                    widget.stageBuilder?.call(context, _values) ??
                    ShanhaiNativeStage(
                      key: ValueKey('shan-native-$_nativeGeneration'),
                      values: _values,
                      onReady: _ready,
                    ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF06111D).withValues(alpha: .62),
                          Colors.transparent,
                          Colors.transparent,
                          const Color(0xFF05111B).withValues(alpha: .72),
                        ],
                        stops: const [0, .26, .72, 1],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DragTarget<String>(
                  onWillAcceptWithDetails: (d) =>
                      d.data == 'pearl' && m.canFeed,
                  onAcceptWithDetails: (_) => _feed(),
                  builder: (context, candidates, rejected) => GestureDetector(
                    key: const ValueKey('shan-stage-touch'),
                    behavior: HitTestBehavior.opaque,
                    onPanDown: (d) => _touch(d.localPosition),
                    onPanStart: (d) => _touch(d.localPosition),
                    onPanUpdate: (d) => _touch(d.localPosition, delta: d.delta),
                    onPanEnd: (_) => setState(() => _trail = []),
                    onTapUp: (d) {
                      if (sleeping) {
                        _touch(d.localPosition);
                        _trail = [];
                      } else if (!flying) {
                        _pet();
                      }
                    },
                    child: CustomPaint(
                      painter: _SpiritOverlay(
                        time: _reduced ? 0 : _time,
                        points: _trail,
                        seals: sleeping ? seals : const [],
                        active: m.seals,
                        awaken: m.phase == ShanPhase.awakening ? m.awaken : 0,
                        feeding: candidates.isNotEmpty,
                        reaction: m.reaction,
                        reduced: _reduced,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: compact ? 18 : 26,
                top: compact ? 16 : 24,
                right: 16,
                child: IgnorePointer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: shanTeal,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            flying ? '御风 · 山海同游' : realmNames[m.realm.index],
                            style: _text(10, color: shanTeal, spacing: 3),
                          ),
                          const Spacer(),
                          _badge(
                            flying ? '${m.flightStars} / 7  星辉' : '实时 3D',
                            small: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        sleeping
                            ? '有灵，眠于碧水。'
                            : m.phase == ShanPhase.awakening
                            ? '一念起，山海应。'
                            : flying
                            ? '风起，随龙入云。'
                            : '青璃',
                        style: _text(
                          compact
                              ? 23
                              : wide
                              ? 34
                              : 26,
                          weight: FontWeight.w600,
                          spacing: 3,
                        ),
                      ),
                      if (!compact)
                        Padding(
                          padding: const EdgeInsets.only(top: 7),
                          child: Text(
                            sleeping
                                ? '指尖连起灵印，唤醒湖中的青玉龙。'
                                : flying
                                ? '左右滑动，穿过流光。'
                                : m.phase == ShanPhase.awakening
                                ? '湖水凝作鳞甲，月光化为龙魂。'
                                : '碧玉为鳞，月华为魂。',
                            style: _text(
                              11,
                              color: const Color(0xFFB4C8C8),
                              spacing: 1,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (!sleeping && !flying && m.phase != ShanPhase.awakening)
                Positioned(
                  right: 18,
                  bottom: 72,
                  child: Column(
                    children: [
                      _roundIcon(Icons.rotate_left, '向左看', () {
                        m.turn(-.25);
                        _sendValues();
                      }),
                      const SizedBox(height: 8),
                      _roundIcon(Icons.rotate_right, '向右看', () {
                        m.turn(.25);
                        _sendValues();
                      }),
                    ],
                  ),
                ),
              if (sleeping)
                Positioned(
                  bottom: 18,
                  left: 15,
                  right: 15,
                  child: IgnorePointer(
                    child: Center(
                      child: _badge('连起三个灵印  ·  ${m.seals.length} / 3'),
                    ),
                  ),
                ),
              if (m.phase == ShanPhase.awakening)
                Positioned(
                  bottom: 22,
                  left: 38,
                  right: 38,
                  child: Column(
                    children: [
                      Text(
                        '灵龙苏醒',
                        style: _text(12, color: shanGold, spacing: 4),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: m.awaken,
                          minHeight: 3,
                          backgroundColor: Colors.white12,
                          color: shanGold,
                        ),
                      ),
                    ],
                  ),
                ),
              if (m.phase == ShanPhase.companion)
                Positioned(
                  bottom: 18,
                  left: 12,
                  right: 12,
                  child: IgnorePointer(
                    child: Center(child: _badge('轻触亲近  ·  滑动环视  ·  拖入灵珠')),
                  ),
                ),
              if (flying) ...[
                Positioned(
                  bottom: 18,
                  left: 22,
                  right: 22,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text('启程', style: _text(10, color: shanTeal)),
                          const Spacer(),
                          Text('归来', style: _text(10, color: shanTeal)),
                        ],
                      ),
                      const SizedBox(height: 7),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: m.flight,
                          minHeight: 3,
                          color: shanGold,
                          backgroundColor: Colors.white12,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 57,
                  left: 16,
                  right: 16,
                  child: Center(child: _badge(_flightHint(), small: true)),
                ),
              ],
              if (m.phase == ShanPhase.arrival)
                Positioned.fill(
                  child: Container(
                    color: shanNight.withValues(alpha: .65),
                    child: Center(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                color: shanGold,
                                size: 35,
                              ),
                              const SizedBox(height: 15),
                              Text(
                                '星辉入怀，山海同归',
                                textAlign: TextAlign.center,
                                style: _text(
                                  compact ? 20 : 26,
                                  color: shanGold,
                                  spacing: 2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '与青璃收集了 ${m.flightStars} 束星辉',
                                style: _text(13, color: shanTeal),
                              ),
                              const SizedBox(height: 22),
                              _ShanButton(
                                key: const ValueKey('shan-return'),
                                label: '回到青池',
                                icon: Icons.spa_outlined,
                                onTap: m.returnToLake,
                                primary: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_nativeFailed)
                Positioned.fill(
                  child: ColoredBox(
                    color: shanNight,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('山海画境正在休息', style: _text(20, color: shanGold)),
                          const SizedBox(height: 12),
                          _ShanButton(
                            label: '重新开启',
                            onTap: () {
                              _native?.dispose();
                              _native = null;
                              setState(() {
                                _nativeFailed = false;
                                _nativeGeneration++;
                              });
                            },
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

  String _flightHint() {
    var i = 0;
    while (i < 7 && ShanhaiModel.gateTime(i) <= m.flight) {
      i++;
    }
    if (i >= 7) return '把星光带回家';
    final delta = ShanhaiModel.gateSteering(i) - m.steering;
    return delta.abs() < .30
        ? '方向正好，乘风向前'
        : delta < 0
        ? '向左滑，追上那道光'
        : '向右滑，追上那道光';
  }

  Widget _sidebar() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF132B39), Color(0xFF0C1C2B)],
      ),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: shanGold.withValues(alpha: .20)),
    ),
    child: LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '山 海 灵 契',
                    style: _text(10, color: shanGold, spacing: 3),
                  ),
                  const SizedBox(height: 21),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '青璃',
                              style: _text(
                                37,
                                color: shanIvory,
                                weight: FontWeight.w600,
                                spacing: 7,
                              ),
                            ),
                            Text(
                              'QING LI  /  青玉灵龙',
                              style: _text(9, color: shanTeal, spacing: 1),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 29,
                        height: 63,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF9B6757)),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '水\n灵',
                          style: _text(
                            13,
                            color: const Color(0xFFD79C82),
                            spacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    '生于碧水，喜食月华。\n以星为路，以你为伴。',
                    style: _text(
                      12,
                      color: const Color(0xFFA6BAC0),
                      spacing: 1,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Divider(color: shanGold.withValues(alpha: .17)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text('灵缘', style: _text(11, color: shanTeal)),
                      const Spacer(),
                      Text('${m.affection}', style: _text(18, color: shanGold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: math.min(1, m.affection / 30),
                      minHeight: 3,
                      color: shanGold,
                      backgroundColor: Colors.white10,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    '今 日 同 游',
                    style: _text(10, color: shanGold, spacing: 2),
                  ),
                  const SizedBox(height: 14),
                  ...ShanRealm.values.map((realm) => _realmOption(realm)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '「 ${realmPoems[m.realm.index]} 」',
                      style: _text(11, color: const Color(0xFF839CA6)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.nights_stay_outlined,
                          size: 16,
                          color: shanGold,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${m.totalStarlight} 星辉  ·  ${m.flights} 次同游',
                          style: _text(11, color: shanTeal),
                        ),
                      ],
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

  Widget _realmOption(ShanRealm realm) {
    final selected = m.realm == realm;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: InkWell(
        key: ValueKey('shan-realm-${realm.name}'),
        onTap: () {
          m.setRealm(realm);
          _sendValues();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF213E48) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? shanGold.withValues(alpha: .48)
                  : Colors.white.withValues(alpha: .08),
            ),
          ),
          child: Row(
            children: [
              Icon(
                [
                  Icons.nightlight_outlined,
                  Icons.auto_awesome_outlined,
                  Icons.wb_twilight,
                ][realm.index],
                size: 20,
                color: selected ? shanGold : shanTeal,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  realmNames[realm.index],
                  style: _text(
                    12,
                    color: selected ? shanIvory : const Color(0xFF8AA6AF),
                  ),
                ),
              ),
              if (selected) const Icon(Icons.circle, size: 5, color: shanGold),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottom(bool wide, bool compact) => Container(
    padding: EdgeInsets.fromLTRB(
      wide ? 28 : 14,
      compact ? 5 : 8,
      wide ? 28 : 14,
      compact ? 10 : 18,
    ),
    child: Column(
      children: [
        if (!wide && !compact)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                for (final r in ShanRealm.values) ...[
                  if (r.index > 0) const SizedBox(width: 7),
                  Expanded(child: _realmOption(r)),
                ],
              ],
            ),
          ),
        Row(
          children: [
            if (wide)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.phase == ShanPhase.sleeping
                          ? '第一章 · 月下初逢'
                          : m.phase == ShanPhase.flying
                          ? '第二章 · 御风同游'
                          : '一份灵契，一段相伴',
                      style: _text(15, color: shanIvory, spacing: 2),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '无须胜负，自有奇遇。',
                      style: _text(
                        10,
                        color: const Color(0xFF7C96A3),
                        spacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            if (m.phase == ShanPhase.flying) ...[
              Expanded(
                child: _ShanButton(
                  label: '轻点向左',
                  icon: Icons.west,
                  onTap: () => m.steer(m.steering - .22),
                  key: const ValueKey('shan-left'),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _ShanButton(
                  label: '轻点向右',
                  icon: Icons.east,
                  onTap: () => m.steer(m.steering + .22),
                  key: const ValueKey('shan-right'),
                ),
              ),
              const SizedBox(width: 9),
              _ShanButton(
                label: '回青池',
                onTap: m.returnToLake,
                key: const ValueKey('shan-end-flight'),
              ),
            ] else ...[
              if (wide) _feedButton() else Expanded(child: _feedButton()),
              const SizedBox(width: 10),
              if (wide) _petButton() else Expanded(child: _petButton()),
              const SizedBox(width: 10),
              if (wide) _flyButton() else Expanded(child: _flyButton()),
            ],
          ],
        ),
      ],
    ),
  );

  Widget _feedButton() {
    final button = _ShanButton(
      key: const ValueKey('shan-feed'),
      label: '赠灵珠',
      icon: Icons.brightness_7_outlined,
      onTap: m.canFeed ? _feed : null,
    );
    if (!m.canFeed) return button;
    return Draggable<String>(
      data: 'pearl',
      maxSimultaneousDrags: 1,
      feedback: const Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 68,
          height: 68,
          child: CustomPaint(painter: _PearlPainter()),
        ),
      ),
      childWhenDragging: Opacity(opacity: .4, child: button),
      child: button,
    );
  }

  Widget _petButton() => _ShanButton(
    key: const ValueKey('shan-pet'),
    label: '摸摸青璃',
    icon: Icons.touch_app_outlined,
    onTap: m.canPet ? _pet : null,
  );
  Widget _flyButton() => _ShanButton(
    key: const ValueKey('shan-fly'),
    label: '御风同游',
    icon: Icons.air,
    primary: true,
    onTap: m.phase == ShanPhase.companion && !_nativeFailed
        ? () {
            m.startFlight();
            _sendValues();
          }
        : null,
  );
  Widget _roundIcon(IconData icon, String label, VoidCallback onTap) =>
      IconButton.filledTonal(
        tooltip: label,
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        color: shanGold,
        style: IconButton.styleFrom(
          backgroundColor: shanNight.withValues(alpha: .65),
        ),
      );
}

Widget _badge(String label, {bool small = false}) => Container(
  padding: EdgeInsets.symmetric(
    horizontal: small ? 10 : 16,
    vertical: small ? 6 : 9,
  ),
  decoration: BoxDecoration(
    color: shanNight.withValues(alpha: .55),
    borderRadius: BorderRadius.circular(30),
    border: Border.all(color: shanGold.withValues(alpha: .22)),
  ),
  child: Text(
    label,
    style: _text(small ? 9 : 11, color: shanTeal, spacing: 1),
    textAlign: TextAlign.center,
  ),
);

class _ShanButton extends StatelessWidget {
  const _ShanButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.primary = false,
  });
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool primary;
  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Opacity(
        opacity: enabled ? 1 : .37,
        child: Material(
          color: primary ? const Color(0xFFD6BB81) : const Color(0xFF18333E),
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(13),
            child: Container(
              constraints: const BoxConstraints(minHeight: 51),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: shanGold.withValues(alpha: primary ? .8 : .28),
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 19, color: primary ? shanNight : shanGold),
                    const SizedBox(width: 7),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: _text(
                        12,
                        color: primary ? shanNight : shanIvory,
                        weight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SigilPainter extends CustomPainter {
  const _SigilPainter({required this.color});
  final Color color;
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.translate(s.width / 2, s.height / 2);
    final r = math.min(s.width, s.height) * .29;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    c.drawCircle(Offset.zero, r, p);
    c.drawCircle(Offset.zero, r * .62, p);
    final path = Path()
      ..moveTo(0, -r * 1.25)
      ..lineTo(r * .7, 0)
      ..lineTo(0, r * 1.25)
      ..lineTo(-r * .7, 0)
      ..close();
    c.drawPath(path, p);
    c.drawLine(Offset(-r * 1.1, 0), Offset(r * 1.1, 0), p);
    c.restore();
  }

  @override
  bool shouldRepaint(_SigilPainter old) => old.color != color;
}

class _PearlPainter extends CustomPainter {
  const _PearlPainter();
  @override
  void paint(Canvas c, Size size) {
    final r = math.min(size.width, size.height) / 2,
        center = size.center(Offset.zero);
    c.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            shanGold.withValues(alpha: .6),
            shanGold.withValues(alpha: 0),
          ],
        ).createShader(Offset.zero & size),
    );
    c.drawCircle(
      center,
      r * .44,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.4, -.4),
          colors: [Color(0xFFFFFFEB), Color(0xFFEAD491), Color(0xFF8B8151)],
        ).createShader(Rect.fromCircle(center: center, radius: r * .44)),
    );
  }

  @override
  bool shouldRepaint(_PearlPainter old) => false;
}

class _SpiritOverlay extends CustomPainter {
  const _SpiritOverlay({
    required this.time,
    required this.points,
    required this.seals,
    required this.active,
    required this.awaken,
    required this.feeding,
    required this.reaction,
    required this.reduced,
  });
  final double time, awaken, reaction;
  final List<Offset> points, seals;
  final Set<int> active;
  final bool feeding, reduced;
  @override
  void paint(Canvas c, Size s) {
    if (points.length > 1) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      c.drawPath(
        path,
        Paint()
          ..color = shanTeal.withValues(alpha: .25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
      c.drawPath(
        path,
        Paint()
          ..color = shanIvory.withValues(alpha: .8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
    for (var i = 0; i < seals.length; i++) {
      final p = Offset(seals[i].dx * s.width, seals[i].dy * s.height),
          lit = active.contains(i);
      final r = math.min(s.width, s.height) * .068;
      c.save();
      c.translate(p.dx, p.dy);
      c.drawCircle(
        Offset.zero,
        r * 1.9,
        Paint()
          ..shader = RadialGradient(
            colors: [
              (lit ? shanGold : shanTeal).withValues(alpha: .30),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: r * 1.9)),
      );
      c.rotate(time * .18 * (i.isEven ? 1 : -1));
      final paint = Paint()
        ..color = (lit ? shanGold : shanTeal).withValues(alpha: .8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3;
      c.drawCircle(Offset.zero, r, paint);
      c.drawCircle(Offset.zero, r * .8, paint);
      for (var j = 0; j < 8; j++) {
        final a = j * math.pi / 4;
        c.drawLine(
          Offset(math.cos(a) * r * .83, math.sin(a) * r * .83),
          Offset(math.cos(a) * r, math.sin(a) * r),
          paint,
        );
      }
      c.rotate(-time * .18 * (i.isEven ? 1 : -1));
      final path = Path()
        ..moveTo(0, -r * .47)
        ..lineTo(r * .30, 0)
        ..lineTo(0, r * .47)
        ..lineTo(-r * .30, 0)
        ..close();
      c.drawPath(path, paint);
      if (lit) c.drawCircle(Offset.zero, 3, Paint()..color = shanGold);
      c.restore();
    }
    if (feeding) {
      final p = Paint()
        ..color = shanGold.withValues(alpha: .5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      c.drawOval(
        Rect.fromCenter(
          center: s.center(Offset.zero),
          width: s.width * .55,
          height: s.height * .45,
        ),
        p,
      );
    }
    if (awaken > 0 && !reduced) {
      final count = 50;
      for (var i = 0; i < count; i++) {
        final a = i * 2.39996 + awaken * 3,
            r = (1 - awaken) * s.shortestSide * .36;
        final p = Offset(
          s.width * .5 + math.cos(a) * r,
          s.height * .58 + math.sin(a) * r * .5 - awaken * s.height * .28,
        );
        c.drawCircle(
          p,
          1.2 + i % 3,
          Paint()
            ..color = (i % 3 == 0 ? shanGold : shanTeal).withValues(
              alpha: math.sin(awaken * math.pi) * .7,
            ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_SpiritOverlay old) => true;
}
