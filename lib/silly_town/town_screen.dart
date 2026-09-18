import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../game_audio.dart';
import 'town_art.dart';
import 'town_audio.dart';
import 'town_catalog.dart';
import 'town_model.dart';
import 'town_progress.dart';

const _rounded = BorderRadius.all(Radius.circular(28));
TextStyle _type(
  double size, {
  Color color = townInk,
  FontWeight weight = FontWeight.w700,
  double? height,
}) => TextStyle(
  fontSize: size,
  color: color,
  fontWeight: weight,
  height: height,
  letterSpacing: .2,
);

class TownHomeScreen extends StatefulWidget {
  const TownHomeScreen({
    super.key,
    required this.audio,
    this.progress,
    this.onOpenClassic,
    this.onBack,
    this.nativeAudio = true,
  });
  final GameAudioController audio;
  final TownProgress? progress;
  final Future<void> Function()? onOpenClassic;
  final VoidCallback? onBack;
  final bool nativeAudio;
  @override
  State<TownHomeScreen> createState() => _TownHomeScreenState();
}

class _TownHomeScreenState extends State<TownHomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final TownProgress progress;
  late final TownAudio sound;
  late final AnimationController motion;
  bool ready = false, active = true;
  bool visitingClassic = false;
  @override
  void initState() {
    super.initState();
    progress = widget.progress ?? TownProgress.persistent();
    sound = TownAudio(widget.audio, progress, native: widget.nativeAudio);
    motion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    WidgetsBinding.instance.addObserver(this);
    unawaited(
      progress.ready.then((_) {
        if (!mounted) return;
        setState(() => ready = true);
        unawaited(sound.start());
      }),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    active = state == AppLifecycleState.resumed;
    sound.active(active && !visitingClassic);
    if (active) {
      if (!motion.isAnimating) motion.repeat();
    } else {
      motion.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    motion.dispose();
    sound.dispose();
    if (widget.progress == null) progress.dispose();
    super.dispose();
  }

  Future<void> openLevel(int id) async {
    if (!ready) return;
    sound.effect('pick');
    await widget.audio.stopSpeech();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TownPlayScreen(
          level: townLevels[id],
          progress: progress,
          sound: sound,
        ),
      ),
    );
    if (mounted) {
      sound.active(active);
      setState(() {});
    }
  }

  Future<void> district(int id) async {
    sound.effect('pick');
    final area = townDistricts[id];
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: townCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => SafeArea(
        child: SizedBox(
          height: math.min(MediaQuery.sizeOf(context).height * .88, 650),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 14, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(area.name, style: _type(26)),
                          Text(
                            '${area.english} · 每个小故事都可以玩',
                            style: _type(
                              12,
                              color: area.dark,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TownIconButton(
                      label: '关闭街区',
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
                  itemCount: 5,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final level = townLevels[id * 5 + index],
                        done = progress.completed.contains(level.id);
                    return Material(
                      color: Color.lerp(area.color, Colors.white, .80),
                      borderRadius: BorderRadius.circular(22),
                      child: InkWell(
                        key: ValueKey('town-level-${level.id}'),
                        borderRadius: BorderRadius.circular(22),
                        onTap: () => Navigator.pop(context, level.id),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 65,
                                height: 65,
                                child: CustomPaint(
                                  painter: _ObjectPainter(
                                    level.subject,
                                    subject: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 13),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${level.number.toString().padLeft(2, '0')}   ${level.title}',
                                      style: _type(17),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      level.phrase,
                                      style: _type(
                                        12,
                                        color: area.dark,
                                        weight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                done
                                    ? Icons.stars_rounded
                                    : Icons.play_circle_fill_rounded,
                                color: area.dark,
                                size: 30,
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
      ),
    );
    if (selected != null && mounted) await openLevel(selected);
  }

  Future<void> album() async {
    await widget.audio.stopSpeech();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: townCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .8,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 12, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('小耳朵收藏册', style: _type(25)),
                          const SizedBox(height: 4),
                          Text(
                            '玩的时候听过的英语，点一下再听听',
                            style: _type(12, weight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    TownIconButton(
                      label: '关闭收藏册',
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              if (progress.words.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.headphones_rounded,
                            size: 64,
                            color: townGreen,
                          ),
                          const SizedBox(height: 18),
                          Text('先去和啵啵玩一会儿吧', style: _type(20)),
                          const SizedBox(height: 8),
                          Text(
                            '听到的新词会来到这里',
                            style: _type(14, weight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      for (final level in townLevels)
                        if (level.words.any(progress.words.contains) ||
                            progress.words.contains(level.phrase)) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 8),
                            child: Text(
                              level.title,
                              style: _type(14, color: level.area.dark),
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (var i = 0; i < level.words.length; i++)
                                if (progress.words.contains(level.words[i]))
                                  ActionChip(
                                    avatar: const Icon(
                                      Icons.volume_up_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      '${level.words[i]} · ${level.meanings[i]}',
                                    ),
                                    onPressed: () => sound.say(
                                      level.words[i],
                                      level.meanings[i],
                                      force: true,
                                    ),
                                  ),
                              if (progress.words.contains(level.phrase))
                                ActionChip(
                                  avatar: const Icon(
                                    Icons.volume_up_rounded,
                                    size: 18,
                                  ),
                                  label: Text(level.phrase),
                                  onPressed: () => sound.say(
                                    level.phrase,
                                    level.translation,
                                    force: true,
                                  ),
                                ),
                            ],
                          ),
                        ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    unawaited(widget.audio.stopSpeech());
  }

  Future<void> classic() async {
    visitingClassic = true;
    sound.active(false);
    await widget.onOpenClassic?.call();
    visitingClassic = false;
    if (mounted) sound.active(active);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: townCream,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([progress, widget.audio]),
          builder: (context, _) => LayoutBuilder(
            builder: (context, box) {
              final wide = box.maxWidth > 760;
              final pad = wide ? 36.0 : 20.0;
              return CustomScrollView(
                key: const ValueKey('town-home-scroll'),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(pad, 14, pad, 8),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5EEDC),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              Icons.spa_rounded,
                              color: townInk,
                              size: 23,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('啵啵 & 朋友们', style: _type(16)),
                                Text(
                                  'PLAY · LAUGH · GROW',
                                  style: _type(
                                    9,
                                    color: const Color(0xFF879184),
                                    weight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.onBack != null) ...[
                            TownIconButton(
                              key: const ValueKey('town-back-to-wardrobe'),
                              label: '返回绒绒衣橱',
                              icon: Icons.checkroom_rounded,
                              onTap: widget.onBack!,
                            ),
                            const SizedBox(width: 7),
                          ],
                          TownIconButton(
                            key: const ValueKey('town-album'),
                            label: '小耳朵收藏册',
                            icon: Icons.auto_stories_rounded,
                            onTap: album,
                          ),
                          const SizedBox(width: 7),
                          TownIconButton(
                            key: const ValueKey('town-sound'),
                            label: widget.audio.enabled ? '关闭声音' : '打开声音',
                            icon: widget.audio.enabled
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            onTap: () => widget.audio.toggle(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(pad, 15, pad, 24),
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2DC),
                          borderRadius: BorderRadius.circular(34),
                        ),
                        child: wide
                            ? SizedBox(
                                height: 350,
                                child: Row(
                                  children: [
                                    Expanded(flex: 44, child: _intro(true)),
                                    Expanded(flex: 56, child: _hero(reduce)),
                                  ],
                                ),
                              )
                            : Column(
                                children: [
                                  _intro(false),
                                  SizedBox(height: 225, child: _hero(reduce)),
                                ],
                              ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(pad, 0, pad, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('小镇里的新鲜事', style: _type(wide ? 24 : 21)),
                                const SizedBox(height: 4),
                                Text(
                                  '6 个街区，30 次奇妙的小冒险',
                                  style: _type(
                                    12,
                                    color: const Color(0xFF8A9183),
                                    weight: FontWeight.w500,
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
                              color: const Color(0xFFF5EBD3),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.local_florist_rounded,
                                  size: 18,
                                  color: Color(0xFFB78B38),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${progress.completed.length} / 30',
                                  style: _type(
                                    13,
                                    color: const Color(0xFF927A42),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(pad, 0, pad, 24),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _districtCard(i),
                        childCount: 6,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: wide ? 3 : 2,
                        crossAxisSpacing: wide ? 18 : 12,
                        mainAxisSpacing: wide ? 18 : 12,
                        mainAxisExtent: wide ? 228 : 205,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(pad, 0, pad, 24),
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: 14,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '每一次小小的触碰，都有大大的回应。',
                            style: _type(
                              12,
                              color: const Color(0xFF94988A),
                              weight: FontWeight.w500,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => progress.toggleMusic(),
                            icon: Icon(
                              progress.music
                                  ? Icons.music_note_rounded
                                  : Icons.music_off_rounded,
                              size: 18,
                            ),
                            label: Text(progress.music ? '轻音乐开着' : '轻音乐关着'),
                            style: TextButton.styleFrom(
                              foregroundColor: townInk,
                            ),
                          ),
                          if (widget.onOpenClassic != null)
                            TextButton(
                              onPressed: classic,
                              child: const Text('颜色实验室'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _intro(bool wide) => Padding(
    padding: EdgeInsets.fromLTRB(
      wide ? 34 : 24,
      wide ? 28 : 24,
      20,
      wide ? 28 : 0,
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: townGreen,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              'SILLY LITTLE TOWN',
              style: _type(
                10,
                color: const Color(0xFF6D8975),
                weight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          '小怪兽的\n胡闹小镇',
          style: _type(wide ? 39 : 32, height: 1.25, weight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Text(
          '摸摸小肚子，吹个大泡泡。\n和啵啵一起，把今天变好玩！',
          style: _type(
            13,
            color: const Color(0xFF7D8874),
            weight: FontWeight.w500,
            height: 1.75,
          ),
        ),
        const SizedBox(height: 20),
        TownButton(
          key: const ValueKey('town-start'),
          label: progress.completed.isEmpty ? '出发去玩' : '继续小冒险',
          icon: Icons.play_arrow_rounded,
          onTap: ready ? () => openLevel(progress.nextLevel) : null,
        ),
        const SizedBox(height: 10),
        Text(
          '第 ${progress.nextLevel + 1} 关 · ${townLevels[progress.nextLevel].title}',
          style: _type(
            11,
            color: const Color(0xFF87917D),
            weight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
  Widget _hero(bool reduce) => Semantics(
    button: true,
    label: '和小怪兽啵啵打招呼',
    child: GestureDetector(
      key: const ValueKey('town-greet'),
      onTap: () {
        sound.effect('giggle');
        unawaited(
          sound.say(
            'Hello, my friend!',
            '你好，我的朋友！',
            force: true,
            collect: false,
          ),
        );
      },
      child: AnimatedBuilder(
        animation: motion,
        builder: (context, _) => CustomPaint(
          painter: TownPostcardPainter(
            district: 0,
            time: reduce ? 0 : motion.value * 18,
            hero: true,
            stamps: progress.completed.length,
          ),
          size: Size.infinite,
        ),
      ),
    ),
  );
  Widget _districtCard(int i) {
    final area = townDistricts[i];
    return Material(
      color: Color.lerp(area.color, Colors.white, .87),
      borderRadius: _rounded,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('town-district-$i'),
        onTap: () => district(i),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: TownPostcardPainter(district: i),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    top: 11,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: townCream.withValues(alpha: .88),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${i * 5 + 1} — ${(i + 1) * 5}',
                        style: _type(10, color: area.dark),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(area.name, style: _type(16))),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: area.dark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      for (var j = 0; j < 5; j++)
                        Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: Icon(
                            progress.completed.contains(i * 5 + j)
                                ? Icons.local_florist_rounded
                                : Icons.circle,
                            size: progress.completed.contains(i * 5 + j)
                                ? 12
                                : 6,
                            color: progress.completed.contains(i * 5 + j)
                                ? area.dark
                                : area.color,
                          ),
                        ),
                      const Spacer(),
                      Text(
                        '${progress.countIn(i)}/5',
                        style: _type(10, color: area.dark),
                      ),
                    ],
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

class TownPlayScreen extends StatefulWidget {
  const TownPlayScreen({
    super.key,
    required this.level,
    required this.progress,
    required this.sound,
  });
  final TownLevel level;
  final TownProgress progress;
  final TownAudio sound;
  @override
  State<TownPlayScreen> createState() => _TownPlayScreenState();
}

class _TownPlayScreenState extends State<TownPlayScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TownModel model;
  late final Ticker ticker;
  Duration? previous;
  Timer? opening, closing;
  Size sceneSize = Size.zero;
  bool active = true;
  String english = '', meaning = '';
  int session = 0;
  @override
  void initState() {
    super.initState();
    model = TownModel(widget.level);
    WidgetsBinding.instance.addObserver(this);
    ticker = createTicker((elapsed) {
      final dt = previous == null
          ? 0.0
          : (elapsed - previous!).inMicroseconds / 1000000;
      previous = elapsed;
      if (!active ||
          !mounted ||
          sceneSize.isEmpty ||
          ModalRoute.of(context)?.isCurrent == false) {
        return;
      }
      model.step(dt, TownLayout(sceneSize));
      _events();
    })..start();
    _welcome();
  }

  void _welcome() {
    final token = ++session;
    english = model.level.words.first;
    meaning = model.level.meanings.first;
    widget.sound.english = english;
    widget.sound.meaning = meaning;
    opening = Timer(const Duration(milliseconds: 650), () async {
      if (!mounted || !active || token != session) return;
      await widget.sound.guide(model.level.instruction);
      if (mounted && active && token == session && model.actionCount == 0) {
        await widget.sound.say(english, meaning, force: true);
      }
    });
  }

  void _events() {
    for (final event in model.takeEvents()) {
      widget.sound.effect(event.sound);
      if (event.finish) {
        widget.progress.finish(model.level.id);
        opening?.cancel();
        final token = ++session;
        setState(() {
          english = model.level.phrase;
          meaning = model.level.translation;
        });
        closing?.cancel();
        closing = Timer(const Duration(milliseconds: 900), () {
          if (mounted && active && token == session) {
            unawaited(widget.sound.say(english, meaning, force: true));
          }
        });
      } else if (event.wordIndex != null) {
        final i = event.wordIndex!;
        setState(() {
          english = model.level.words[i];
          meaning = model.level.meanings[i];
        });
        unawaited(
          widget.sound.say(
            english,
            meaning,
            force: event.sound == 'pick' || model.actionCount == 1,
          ),
        );
      }
    }
  }

  void _input(void Function(TownModel, TownLayout) fn) {
    if (!active || sceneSize.isEmpty) return;
    final actions = model.actionCount;
    final selected = model.selected;
    fn(model, TownLayout(sceneSize));
    if (actions != model.actionCount || selected != model.selected) {
      opening?.cancel();
      session++;
    }
    _events();
  }

  void _replay() {
    opening?.cancel();
    closing?.cancel();
    session++;
    unawaited(widget.sound.voice.stopSpeech());
    final old = model;
    setState(() {
      model = TownModel(old.level)..reduceMotion = old.reduceMotion;
    });
    old.dispose();
    previous = null;
    _welcome();
  }

  void _next() {
    if (model.level.id == townLevels.length - 1) {
      Navigator.pop(context);
      return;
    }
    opening?.cancel();
    closing?.cancel();
    session++;
    unawaited(widget.sound.voice.stopSpeech());
    final old = model;
    setState(() {
      model = TownModel(townLevels[old.level.id + 1])
        ..reduceMotion = old.reduceMotion;
    });
    old.dispose();
    previous = null;
    _welcome();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    active = state == AppLifecycleState.resumed;
    model.paused = !active;
    model.cancel();
    previous = null;
    widget.sound.active(active);
    if (!active) {
      opening?.cancel();
      closing?.cancel();
      session++;
      ticker.stop();
    } else {
      ticker.start();
    }
  }

  @override
  void dispose() {
    session++;
    opening?.cancel();
    closing?.cancel();
    ticker.dispose();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(widget.sound.voice.stopSpeech());
    model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    model.reduceMotion = MediaQuery.disableAnimationsOf(context);
    final level = model.level;
    return Scaffold(
      backgroundColor: townCream,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            final compact = box.maxHeight < 500;
            final wide = box.maxWidth > 700;
            final header = Padding(
              padding: EdgeInsets.fromLTRB(
                wide ? 24 : 12,
                compact ? 4 : 10,
                wide ? 24 : 12,
                compact ? 4 : 10,
              ),
              child: Row(
                children: [
                  TownIconButton(
                    key: const ValueKey('town-back'),
                    label: '回到小镇',
                    icon: Icons.home_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(level.title, style: _type(compact ? 17 : 20)),
                        if (!compact)
                          Text(
                            '${level.area.name}  /  ${level.number.toString().padLeft(2, '0')} · 30',
                            style: _type(
                              11,
                              color: const Color(0xFF939789),
                              weight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  TownIconButton(
                    key: const ValueKey('town-guide'),
                    label: '听玩法提示',
                    icon: Icons.help_outline_rounded,
                    onTap: () => widget.sound.guide(level.instruction),
                  ),
                  const SizedBox(width: 6),
                  AnimatedBuilder(
                    animation: widget.sound.voice,
                    builder: (context, _) => TownIconButton(
                      label: widget.sound.voice.enabled ? '关闭声音' : '打开声音',
                      icon: widget.sound.voice.enabled
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      onTap: () => widget.sound.voice.toggle(),
                    ),
                  ),
                ],
              ),
            );
            return Column(
              children: [
                header,
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      wide ? 24 : 10,
                      0,
                      wide ? 24 : 10,
                      compact ? 8 : 12,
                    ),
                    child: compact
                        ? Row(
                            children: [
                              Expanded(child: _scene()),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 220,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _lesson(true),
                                    const SizedBox(height: 12),
                                    _footer(true),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _lesson(false),
                              const SizedBox(height: 10),
                              Expanded(child: _scene()),
                              const SizedBox(height: 10),
                              _footer(false),
                            ],
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _lesson(bool compact) => Semantics(
    button: true,
    label: '听英语：$english，$meaning',
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(23),
      child: InkWell(
        key: const ValueKey('town-repeat-english'),
        borderRadius: BorderRadius.circular(23),
        onTap: () => widget.sound.say(english, meaning, force: true),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 19,
            vertical: compact ? 12 : 13,
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 35 : 43,
                height: compact ? 35 : 43,
                decoration: BoxDecoration(
                  color: model.level.area.sky,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.volume_up_rounded,
                  color: model.level.area.dark,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      english,
                      style: _type(
                        compact ? 20 : 24,
                        color: model.level.area.dark,
                        weight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meaning,
                      style: _type(
                        12,
                        color: const Color(0xFF909589),
                        weight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact)
                Text(
                  '听一听',
                  style: _type(
                    11,
                    color: const Color(0xFFA0A497),
                    weight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget _scene() => ClipRRect(
    borderRadius: BorderRadius.circular(28),
    child: LayoutBuilder(
      builder: (context, box) {
        sceneSize = box.biggest;
        return Stack(
          children: [
            Positioned.fill(
              child: Semantics(
                label: model.level.instruction,
                child: Listener(
                  key: const ValueKey('town-canvas'),
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (e) =>
                      _input((m, l) => m.down(e.localPosition, l, e.pointer)),
                  onPointerMove: (e) =>
                      _input((m, l) => m.move(e.localPosition, l, e.pointer)),
                  onPointerUp: (e) =>
                      _input((m, l) => m.up(e.localPosition, l, e.pointer)),
                  onPointerCancel: (_) => model.cancel(),
                  child: RepaintBoundary(
                    child: CustomPaint(painter: TownScenePainter(model)),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 15,
              left: 16,
              right: 16,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: model,
                  builder: (context, _) => Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: townCream.withValues(alpha: .86),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              model.finished
                                  ? Icons.favorite_rounded
                                  : Icons.touch_app_rounded,
                              size: 15,
                              color: model.level.area.dark,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              model.finished ? '好开心呀！' : '一起玩一玩',
                              style: _type(11, color: model.level.area.dark),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      ...List.generate(
                        3,
                        (i) => Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: Icon(
                            model.progress >= (i + 1) / 3
                                ? Icons.local_florist_rounded
                                : Icons.circle_outlined,
                            size: 18,
                            color: model.level.area.dark.withValues(
                              alpha: model.progress >= (i + 1) / 3 ? .8 : .23,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 11,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: model,
                  builder: (context, _) => Text(
                    model.finished ? model.level.surprise : _gestureHint(),
                    textAlign: TextAlign.center,
                    style: _type(
                      12,
                      color: model.level.area.dark,
                      weight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
  String _gestureHint() => switch (model.level.play) {
    TownPlay.tickle => '轻轻挠一挠 · 也可以点一点',
    TownPlay.inflate => '按住吹大泡泡 · 点一点也可以',
    TownPlay.scrub => '擦一擦小泥点',
    TownPlay.stretch => '拉一拉，让面条变长',
    TownPlay.catchToy => '点点跳来跳去的小伙伴',
    TownPlay.music => '点点下面的三个小乐器',
    TownPlay.bounce => '点一下，蹦起来！',
    TownPlay.drive => '点点小车，出发啦',
    _ => model.selected != null ? '再点一下中间的小伙伴' : '拖给小伙伴 · 也可以先点物品，再点它',
  };
  Widget _footer(bool compact) => AnimatedBuilder(
    animation: model,
    builder: (context, _) {
      if (model.showNext) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TownIconButton(
              key: const ValueKey('town-replay'),
              label: '再玩一次',
              icon: Icons.replay_rounded,
              onTap: _replay,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: TownButton(
                key: const ValueKey('town-next'),
                label: model.level.id == 29 ? '回到小镇' : '下一个小故事',
                icon: Icons.arrow_forward_rounded,
                onTap: _next,
                small: compact,
              ),
            ),
          ],
        );
      }
      return SizedBox(
        height: compact ? 70 : 51,
        child: Center(
          child: Text(
            model.finished ? '啵啵还有一个小惊喜…' : model.level.instruction,
            textAlign: TextAlign.center,
            style: _type(
              compact ? 12 : 13,
              color: const Color(0xFF7D897D),
              weight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ),
      );
    },
  );
}

class TownIconButton extends StatelessWidget {
  const TownIconButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: label,
    onPressed: onTap,
    icon: Icon(icon, size: 23),
    style: IconButton.styleFrom(
      backgroundColor: const Color(0xFFEEEFE4),
      foregroundColor: townInk,
      minimumSize: const Size(46, 46),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
    ),
  );
}

class TownButton extends StatelessWidget {
  const TownButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.arrow_forward_rounded,
    this.small = false,
  });
  final String label;
  final VoidCallback? onTap;
  final IconData icon;
  final bool small;
  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: small ? 20 : 23),
    label: Text(label, style: _type(small ? 13 : 16, color: townCream)),
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF66896E),
      foregroundColor: townCream,
      padding: EdgeInsets.symmetric(
        horizontal: small ? 16 : 23,
        vertical: small ? 15 : 18,
      ),
      minimumSize: const Size(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
      elevation: 0,
    ),
  );
}

class _ObjectPainter extends CustomPainter {
  const _ObjectPainter(this.kind, {this.subject = false});
  final String kind;
  final bool subject;
  @override
  void paint(Canvas c, Size s) {
    if (subject) {
      TownArt.subject(
        c,
        kind,
        s.center(Offset.zero),
        s.shortestSide * .32,
        progress: 1,
        joy: .2,
      );
    } else {
      TownArt.object(c, kind, s.center(Offset.zero), s.shortestSide * .4);
    }
  }

  @override
  bool shouldRepaint(covariant _ObjectPainter old) =>
      old.kind != kind || old.subject != subject;
}
