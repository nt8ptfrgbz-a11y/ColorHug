import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../buddy_effects.dart';
import '../buddy_widgets.dart';
import '../game_audio.dart';
import '../island_progress.dart';
import 'buddy_play_catalog.dart';
import 'buddy_play_session.dart';

abstract class ToyScreen extends StatefulWidget {
  const ToyScreen({super.key, required this.progress, required this.audio});
  final IslandProgress progress;
  final GameAudioController audio;
}

abstract class ToyState<W extends ToyScreen, M extends ToyModel>
    extends State<W>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  BuddyPlay get game;
  M createModel();
  late final M model;
  late final PlaySpeech speech;
  late final Ticker _ticker;
  final effects = BuddyEffectsController();
  Duration? _previous;
  bool _active = true, loaded = false;
  Timer? _saveTimer;
  int _edits = 0;
  String get invitation;
  Widget scene(BuildContext context);
  List<Widget> tools();
  CustomPainter previewPainter(M snapshot);
  final Map<GameSound, int> _effectTimes = {};
  void onLoaded() {}

  @override
  void initState() {
    super.initState();
    model = createModel();
    speech = PlaySpeech(game, widget.audio, widget.progress);
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker((elapsed) {
      final dt = _previous == null
          ? 0.0
          : ((elapsed - _previous!).inMicroseconds / 1000000).clamp(0.0, .05);
      _previous = elapsed;
      if (!_active || !loaded || ModalRoute.of(context)?.isCurrent == false) {
        return;
      }
      model.step(dt);
      _events();
      if (mounted) setState(() {});
    })..start();
    final version = _edits;
    unawaited(
      widget.progress.ready.then((_) {
        if (!mounted) return;
        if (_edits == version) {
          final data = widget.progress.playJournal.draft(game);
          if (data != null) model.restore(data);
        }
        setState(() => loaded = true);
        onLoaded();
        unawaited(widget.audio.speak(invitation));
      }),
    );
  }

  void _events() {
    for (final e in model.takeEvents()) {
      if (e.word.isNotEmpty) speech.say(e.word, e.meaning, phrase: e.phrase);
      if (e.sound != null) {
        final now = speech.clock.elapsedMilliseconds;
        if (now - (_effectTimes[e.sound!] ?? -1000) >= 90) {
          _effectTimes[e.sound!] = now;
          unawaited(widget.audio.play(e.sound!));
        }
      }
      if (e.discovery != null) {
        widget.progress.discoverPlay(game, e.discovery!);
        dirty();
        effects.burst(const Offset(.5, .45), kind: BuddyBurst.stars, count: 12);
      }
    }
  }

  void act(VoidCallback action, {bool save = true}) {
    if (!loaded) return;
    setState(action);
    _events();
    if (save) dirty();
  }

  void dirty() {
    _edits++;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), flush);
  }

  void flush({bool notify = true}) {
    _saveTimer?.cancel();
    if (loaded) widget.progress.savePlay(game, model.toJson(), notify: notify);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    _previous = null;
    if (!_active) {
      model.pause();
      speech.stop();
      unawaited(widget.audio.stopEffects());
      flush();
    }
  }

  Future<void> collect() async {
    if (!loaded) return;
    widget.progress.savePlay(game, model.toJson(), collect: true);
    unawaited(widget.audio.play(GameSound.discover));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('放进作品盒啦！最多保留 6 个不同作品。'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> album() async {
    if (!loaded) return;
    model.pause();
    speech.stop();
    unawaited(widget.audio.stopEffects());
    final items = widget.progress.playJournal.album(game);
    final snapshots = [for (final data in items) createModel()..restore(data)];
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '我的作品盒',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('先玩一玩，再点爱心收藏。'),
                ),
              for (var i = 0; i < items.length; i++)
                ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 72,
                      height: 56,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: 400,
                          height: 340,
                          child: CustomPaint(
                            painter: previewPainter(snapshots[i]),
                          ),
                        ),
                      ),
                    ),
                  ),
                  title: Text('小创作 ${items.length - i}'),
                  subtitle: Text(snapshotLabel(items[i])),
                  trailing: const Icon(Icons.play_arrow_rounded),
                  onTap: () => Navigator.pop(context, i),
                ),
            ],
          ),
        ),
      ),
    );
    for (final snapshot in snapshots) {
      snapshot.dispose();
    }
    if (selected != null && mounted) act(() => model.restore(items[selected]));
  }

  String snapshotLabel(Map<String, dynamic> data) => switch (game) {
    BuddyPlay.rolling =>
      '轨道 ${(data['scene'] as int) + 1} · ${[
        for (final p in data['parts']) ['弹跳', '变大', '小鸭', '岔路', '铃铛'][p],
      ].join(' → ')}',
    BuddyPlay.salon => '客人 ${(data['guest'] as int) + 1} · 三位朋友的造型',
    BuddyPlay.water => '水桌 ${(data['scene'] as int) + 1} · 水管 ${data['pipes']}',
    BuddyPlay.delivery =>
      '小镇 · ${(data['gifts'] as List).where((v) => v == true).length} 件礼物',
    BuddyPlay.squishy =>
      '${['开心', '困困', '惊喜'][data['mood']]} · ${['薄荷', '葡萄', '蜜桃', '奶油'][data['color']]}小怪',
    BuddyPlay.soundTrain =>
      '${[
        for (final c in data['cars']) ['🐸', '🥁', '🐱', '🔔'][c],
      ].join(' → ')} · ${['慢慢', '轻快', '快快'][data['speed']]}',
    BuddyPlay.shadows =>
      '${(data['toys'] as List).length} 个玩具 · 帐篷 ${(data['scene'] as int) + 1}',
    BuddyPlay.tinyWorld =>
      '${(data['objects'] as List).length} 件小家具 · ${data['rain'] == true ? '雨天' : '晴天'}',
  };

  Future<void> confirmReset(VoidCallback reset) async {
    if (!loaded) return;
    model.pause();
    speech.stop();
    unawaited(widget.audio.stopEffects());
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重新摆一摆？'),
        content: const Text('当前场景会重新开始，作品盒里的收藏仍然保留。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('继续玩'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('重新开始'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) act(reset);
  }

  @override
  void dispose() {
    flush(notify: false);
    _ticker.dispose();
    speech.dispose();
    model.dispose();
    effects.dispose();
    unawaited(widget.audio.stopEffects());
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = playCatalog[game]!;
    return Scaffold(
      backgroundColor: buddyCream,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            final wide = box.maxWidth >= 800;
            final stage = ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BuddyEffects(
                controller: effects,
                child: RepaintBoundary(child: scene(context)),
              ),
            );
            final panel = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(spacing: 8, runSpacing: 8, children: tools()),
                const SizedBox(height: 12),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    key: const ValueKey('play-repeat'),
                    borderRadius: BorderRadius.circular(18),
                    onTap: speech.repeat,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.volume_up_rounded,
                            color: Color(0xFF367F69),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  speech.english.isEmpty
                                      ? 'Touch & discover!'
                                      : speech.english,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: buddyInk,
                                  ),
                                ),
                                Text(
                                  speech.chinese.isEmpty
                                      ? '点点场景，一起发现'
                                      : speech.chinese,
                                  style: const TextStyle(color: buddyInk),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const ValueKey('play-collect'),
                        onPressed: collect,
                        icon: const Icon(Icons.favorite_border_rounded),
                        label: const Text('收藏'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const ValueKey('play-album'),
                        onPressed: album,
                        icon: const Icon(Icons.collections_bookmark_outlined),
                        label: const Text('作品盒'),
                      ),
                    ),
                  ],
                ),
                ExpansionTile(
                  title: const Text(
                    '一起听听 · 英语小口袋',
                    style: TextStyle(fontSize: 14),
                  ),
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final word in info.words)
                          ActionChip(
                            label: Text('${word.icon} ${word.english}'),
                            tooltip: word.chinese,
                            onPressed: () => act(
                              () => speech.say(
                                word.english,
                                word.chinese,
                                force: true,
                              ),
                              save: false,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            );
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        IconButton.filledTonal(
                          key: const ValueKey('play-back'),
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                          tooltip: '返回小伙伴乐园',
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                info.title,
                                style: TextStyle(
                                  fontSize: wide ? 24 : 19,
                                  fontWeight: FontWeight.w900,
                                  color: buddyInk,
                                ),
                              ),
                              Text(
                                info.english,
                                style: const TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 1.4,
                                  color: Color(0xFF738580),
                                ),
                              ),
                            ],
                          ),
                        ),
                        AudioToggleButton(audio: widget.audio),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            invitation,
                            style: const TextStyle(
                              fontSize: 13,
                              color: buddyInk,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: '再听玩法',
                          onPressed: () => widget.audio.speak(invitation),
                          icon: const Icon(
                            Icons.record_voice_over_rounded,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: stage),
                              const SizedBox(width: 18),
                              SizedBox(
                                width: 300,
                                child: SingleChildScrollView(child: panel),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              Expanded(flex: 6, child: stage),
                              const SizedBox(height: 10),
                              Expanded(
                                flex: 5,
                                child: SingleChildScrollView(child: panel),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class ToyTool extends StatelessWidget {
  const ToyTool({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });
  final String icon, label;
  final VoidCallback? onTap;
  final bool selected;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: Material(
      color: selected ? const Color(0xFF367F69) : Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          constraints: const BoxConstraints(minHeight: 60, minWidth: 64),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 23)),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : buddyInk,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ToyCanvas extends StatelessWidget {
  const ToyCanvas({
    super.key,
    required this.painter,
    this.onDown,
    this.onMove,
    this.onUp,
    this.onCancel,
    this.onTap,
  });
  final CustomPainter painter;
  final void Function(Offset)? onDown, onMove, onTap;
  final VoidCallback? onUp, onCancel;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      if (painter is ToyPainter) {
        (painter as ToyPainter).reducedMotion = MediaQuery.disableAnimationsOf(
          context,
        );
      }
      Offset point(Offset p) => Offset(
        (p.dx / c.maxWidth).clamp(0.0, 1.0),
        (p.dy / c.maxHeight).clamp(0.0, 1.0),
      );
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: onTap == null ? null : (d) => onTap!(point(d.localPosition)),
        onPanStart: onDown == null
            ? null
            : (d) => onDown!(point(d.localPosition)),
        onPanUpdate: onMove == null
            ? null
            : (d) => onMove!(point(d.localPosition)),
        onPanEnd: onUp == null ? null : (_) => onUp!(),
        onPanCancel: onCancel ?? onUp,
        child: CustomPaint(painter: painter, child: const SizedBox.expand()),
      );
    },
  );
}

abstract class ToyPainter extends CustomPainter {
  bool reducedMotion = false;
  double motionTime(double time) => reducedMotion ? 0 : time;
  late Canvas c;
  late Size size;
  double get w => size.width;
  double get h => size.height;
  void start(Canvas canvas, Size s, Color background) {
    c = canvas;
    size = s;
    c.drawRect(Offset.zero & s, Paint()..color = background);
  }

  Offset p(double x, double y) => Offset(x * w, y * h);
  void line(Offset a, Offset b, Color color, double width) {
    c.drawLine(
      p(a.dx, a.dy),
      p(b.dx, b.dy),
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  void oval(double x, double y, double rx, double ry, Color color) {
    c.drawOval(
      Rect.fromCenter(center: p(x, y), width: rx * w * 2, height: ry * h * 2),
      Paint()..color = color,
    );
  }

  void box(
    double x,
    double y,
    double width,
    double height,
    Color color, {
    double radius = 16,
  }) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x * w, y * h, width * w, height * h),
        Radius.circular(radius),
      ),
      Paint()..color = color,
    );
  }

  void text(
    String text,
    double x,
    double y, {
    double font = 22,
    Color color = buddyInk,
    bool center = true,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: font,
          color: color,
          fontWeight: FontWeight.w700,
          fontFamily: 'Hiragino Sans GB',
          fontFamilyFallback: const ['PingFang SC', 'Apple Color Emoji'],
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: w * .95);
    final at = p(x, y) - Offset(center ? tp.width / 2 : 0, tp.height / 2);
    tp.paint(
      c,
      Offset(
        at.dx.clamp(2.0, math.max(2.0, w - tp.width - 2)),
        at.dy.clamp(2.0, math.max(2.0, h - tp.height - 2)),
      ),
    );
  }

  void eyes(double x, double y, {double spread = .055, bool happy = false}) {
    for (final dx in [-spread, spread]) {
      oval(x + dx, y, .024, .032, Colors.white);
      oval(x + dx, y + .005, .011, happy ? .008 : .018, buddyInk);
    }
    oval(x, y + .067, .026, .013, buddyInk);
  }

  void cloud(double x, double y) {
    oval(x, y, .09, .035, Colors.white.withValues(alpha: .65));
    oval(x - .04, y - .02, .04, .04, Colors.white.withValues(alpha: .65));
    oval(x + .015, y - .03, .045, .045, Colors.white.withValues(alpha: .65));
  }

  void sparkle(double x, double y, Color color) {
    line(Offset(x - .015, y), Offset(x + .015, y), color, 2);
    line(Offset(x, y - .022), Offset(x, y + .022), color, 2);
  }

  double wave(double time, [double frequency = 1]) =>
      math.sin(time * frequency * math.pi * 2);
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
