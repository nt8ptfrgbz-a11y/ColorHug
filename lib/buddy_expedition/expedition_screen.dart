import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../game_audio.dart';
import '../island_progress.dart';
import 'expedition_assets.dart';
import 'expedition_controller.dart';
import 'expedition_models.dart';
import 'expedition_scene.dart';
import 'expedition_world.dart';

class ExpeditionScreen extends StatefulWidget {
  const ExpeditionScreen({
    super.key,
    required this.progress,
    required this.audio,
  });
  final IslandProgress progress;
  final GameAudioController audio;
  @override
  State<ExpeditionScreen> createState() => _ExpeditionState();
}

class _ExpeditionState extends State<ExpeditionScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final model = ExpeditionController();
  ExpeditionAssets assets = ExpeditionAssets();
  late Ticker _ticker;
  Duration? _previous;
  bool loaded = false, failed = false, _disposing = false, _speechBusy = false;
  double _lastSpeech = -100;
  int _speechGeneration = 0;
  Timer? _saveTimer;
  int? _pointer;
  String? _chapterTarget;
  int _seenRegion = 0;
  bool _menuOpen = false;
  Offset? _down, _touch;
  double _downTime = 0;
  bool _moved = false, _pickedDown = false;
  ExpeditionInput _gesture = ExpeditionInput.none;
  final ValueNotifier<ExpeditionEvent> caption = ValueNotifier(
    const ExpeditionEvent('welcome', "A little adventure", '今天，去河谷交一个新朋友。'),
  );
  final ValueNotifier<int> hud = ValueNotifier(0);
  Size _stageSize = Size.zero;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_tick)..start();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      await Future.wait([assets.load(), widget.progress.ready]);
      if (!mounted) return;
      model.restore(widget.progress.expeditionJournal.checkpoint);
      _seenRegion = model.regionRevision;
      caption.value = ExpeditionEvent(
        "resume",
        islandRegions[model.region]!.english,
        model.hint,
      );
      setState(() {
        loaded = true;
        failed = false;
      });
      unawaited(widget.audio.speak(model.hint));
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
  }

  void _tick(Duration elapsed) {
    final dt = _previous == null
        ? 0.0
        : (elapsed - _previous!).inMicroseconds / 1000000;
    _previous = elapsed;
    if (!loaded || model.paused || ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    if (_gesture == ExpeditionInput.road &&
        _pointer != null &&
        _touch != null &&
        (model.driveTarget != null || model.dino == DinoAction.boarding)) {
      model.driveTarget = view.toWorld(_touch!).dx.clamp(120.0, model.worldEnd);
    }
    model.update(dt);
    if (_seenRegion != model.regionRevision) {
      _seenRegion = model.regionRevision;
      _pointer = null;
      _touch = null;
      _down = null;
      _gesture = ExpeditionInput.none;
      _chapterTarget = null;
    }
    _events();
    if (model.takeChanged()) {
      _queueSave();
      hud.value++;
    }
  }

  void _events() {
    for (final e in model.takeEvents()) {
      caption.value = e;
      if (e.sound != null) {
        final sound = switch (e.sound) {
          'engine' => GameSound.expeditionEngine,
          'grab' => GameSound.expeditionGrab,
          'wood' => GameSound.expeditionWood,
          'splash' => GameSound.expeditionSplash,
          'echo' => GameSound.expeditionEcho,
          'dino' => GameSound.expeditionDino,
          'home' => GameSound.expeditionHome,
          _ => GameSound.horn,
        };
        unawaited(widget.audio.play(sound));
      }
      if ((!_speechBusy && model.time - _lastSpeech > 3) || e.important) {
        final generation = ++_speechGeneration;
        _speechBusy = true;
        _lastSpeech = model.time;
        unawaited(
          widget.audio.speakEnglish(e.english).whenComplete(() {
            if (generation == _speechGeneration) _speechBusy = false;
          }),
        );
      }
    }
  }

  void _repeat() {
    final e = caption.value;
    _speechGeneration++;
    _speechBusy = false;
    _lastSpeech = model.time;
    unawaited(
      widget.audio.speakLines([
        SpokenLine(model.hint),
        SpokenLine(e.english, language: GameLanguage.english),
      ]),
    );
  }

  void _queueSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 350), _flush);
  }

  void _flush({bool notify = true}) {
    _saveTimer?.cancel();
    if (loaded) {
      widget.progress.saveExpedition(model.checkpoint(), notify: notify);
    }
  }

  ValleyView get view =>
      ValleyView(_stageSize, model.cameraX, region: model.region);
  bool _near(Offset p, Offset target, double radius) =>
      view.toScreen(p).distanceSquared.isFinite &&
      (view.toScreen(p) - view.toScreen(target)).distance <
          math.max(32, radius * view.scale);
  Offset _localPosition(Offset global) =>
      (context.findRenderObject()! as RenderBox).globalToLocal(global);

  void _downPointer(PointerDownEvent e) {
    if (!loaded || model.paused || model.transition > 0 || _pointer != null) {
      return;
    }
    _pointer = e.pointer;
    _down = _localPosition(e.position);
    _touch = _localPosition(e.position);
    _downTime = model.time;
    _moved = false;
    _pickedDown = false;
    final p = view.toWorld(_localPosition(e.position));
    _chapterTarget = null;
    if (model.region == IslandRegion.bay && model.bay.holding && p.dy < 30) {
      _chapterTarget = 'rescue-basket';
      model.chapterGesture = 'rescue-basket';
      model.chapterMove(p);
      _gesture = ExpeditionInput.none;
      setState(() {});
      return;
    }
    final targets = model.chapterTargets.toList()
      ..sort(
        (a, b) =>
            (a.at - p).distanceSquared.compareTo((b.at - p).distanceSquared),
      );
    for (final target in targets) {
      if (p.dy < model.terrain(p.dx) + 12 &&
          _near(p, target.at, target.radius)) {
        _chapterTarget = target.id;
        model.chapterDown(target.id, target.at);
        _gesture = ExpeditionInput.none;
        _events();
        _queueSave();
        hud.value++;
        setState(() {});
        return;
      }
    }
    if (model.region != IslandRegion.valley) {
      if (p.dy >= model.terrain(p.dx) - 15 &&
          p.dy < model.terrain(p.dx) + 150) {
        _gesture = ExpeditionInput.road;
        model.drive(p.dx);
      } else {
        model.honk();
        _gesture = ExpeditionInput.none;
      }
      _events();
      hud.value++;
      setState(() {});
      return;
    }
    // The clear road band wins over nearby bridge, fruit and passenger hot zones.
    if (p.dy >= model.terrain(p.dx) + 18 &&
        p.dy < model.terrain(p.dx) + 150 &&
        model.logPlace != LogPlace.hook) {
      _gesture = ExpeditionInput.road;
      model.drive(p.dx);
    } else if (model.logPlace == LogPlace.hook) {
      _gesture = ExpeditionInput.hook;
      model.beginHook(p - const Offset(0, 24));
    } else if (model.riverWork &&
        _near(p, model.hook + const Offset(0, 15), 46)) {
      _gesture = ExpeditionInput.hook;
      model.beginHook(p - const Offset(0, 24));
    } else if (model.riverWork &&
        !(model.bridge &&
            _near(
              p,
              Offset(model.dinoX, model.terrain(model.dinoX) - 65),
              60,
            )) &&
        (p.dx - model.logX).abs() < 155 &&
        (p.dy - model.logY).abs() < 60) {
      _gesture = ExpeditionInput.hook;
      _pickedDown = model.pickLog();
    } else if (!model.fed && _near(p, model.fruitPosition, 45)) {
      _gesture = ExpeditionInput.fruit;
      model.beginFruit();
    } else if (_near(
      p,
      Offset(
        model.dino == DinoAction.riding ? model.carX - 55 : model.dinoX,
        model.terrain(model.dinoX) - 65,
      ),
      60,
    )) {
      model.interactDino();
      _gesture = ExpeditionInput.none;
    } else if ((p.dx - model.carX).abs() < 100 &&
        p.dy < model.terrain(model.carX) - 20 &&
        p.dy > model.terrain(model.carX) - 150) {
      model.honk();
      _gesture = ExpeditionInput.none;
    } else if (p.dy < 18 &&
        _near(p, const Offset(535, 14), 24) &&
        model.velocity.abs() < 8) {
      model.leaf();
      _gesture = ExpeditionInput.none;
    } else if (p.dy > -40 && p.dy < 130) {
      _gesture = ExpeditionInput.road;
      model.drive(p.dx);
    } else {
      _gesture = ExpeditionInput.none;
    }
    _events();
    if (model.takeChanged()) _queueSave();
    hud.value++;
    setState(() {});
  }

  void _movePointer(PointerMoveEvent e) {
    if (e.pointer != _pointer || _down == null) return;
    _touch = _localPosition(e.position);
    _moved |= (_localPosition(e.position) - _down!).distance > 10;
    final p = view.toWorld(_localPosition(e.position));
    if (_chapterTarget != null) {
      model.chapterMove(p);
      setState(() {});
      return;
    }
    if (_gesture == ExpeditionInput.hook) {
      model.moveHook(p - const Offset(0, 24));
    }
    if (_gesture == ExpeditionInput.fruit) model.moveFruit(p);
    if (_gesture == ExpeditionInput.road) {
      model.driveTarget = p.dx.clamp(120.0, model.worldEnd);
    }
    setState(() {});
  }

  void _upPointer(PointerUpEvent e) {
    if (e.pointer != _pointer) return;
    if (_chapterTarget != null) {
      model.chapterUp(tapped: !_moved);
      _chapterTarget = null;
      _pointer = null;
      _touch = null;
      _down = null;
      _events();
      _queueSave();
      hud.value++;
      setState(() {});
      return;
    }
    final p = view.toWorld(_localPosition(e.position));
    if (_gesture == ExpeditionInput.road) {
      if (!_moved && model.time - _downTime < .24) {
        model.drive(p.dx, automatic: true);
      } else {
        model.stopDrive();
      }
    }
    if (_gesture == ExpeditionInput.hook) {
      if (!_moved && _pickedDown) {
        /* Tap-to-pick keeps the object attached for a second tap. */
      } else if (!_moved && model.logPlace == LogPlace.hook) {
        model.placeAt(p);
      } else {
        model.putLog();
      }
    }
    if (_gesture == ExpeditionInput.fruit) {
      if (!_moved && model.home && (model.carX - model.dinoX).abs() < 180) {
        model.moveFruit(Offset(model.dinoX, model.terrain(model.dinoX)));
      } else if (!_moved) {
        model.moveFruit(
          Offset(model.carX - 60, model.terrain(model.carX) - 90),
        );
      }
      model.releaseFruit();
    }
    _pointer = null;
    _touch = null;
    _down = null;
    _gesture = ExpeditionInput.none;
    _events();
    _queueSave();
    hud.value++;
    setState(() {});
  }

  void _cancel() {
    if (_chapterTarget != null) model.chapterUp(cancelled: true);
    _chapterTarget = null;
    _pointer = null;
    _touch = null;
    _down = null;
    _gesture = ExpeditionInput.none;
    model.cancel();
    _queueSave();
    if (mounted && !_disposing) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _previous = null;
    if (state == AppLifecycleState.resumed) {
      if (!_menuOpen) model.resume();
    } else {
      _cancel();
      model.pause();
      _speechGeneration++;
      _speechBusy = false;
      unawaited(widget.audio.stopSpeech());
      unawaited(widget.audio.stopEffects());
      _flush();
    }
  }

  Future<void> _pause() async {
    _menuOpen = true;
    _cancel();
    model.pause();
    unawaited(widget.audio.stopSpeech());
    unawaited(widget.audio.stopEffects());
    _flush();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF7EED8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('在河谷歇一会儿'),
        content: const Text('小伙伴会等你。已经搭好的桥和交到的朋友会保留。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'leave'),
            child: const Text('回到小家'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'reset'),
            child: const Text('重玩这次冒险'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'continue'),
            child: const Text('继续探险'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (result == 'leave') {
      _menuOpen = false;
      Navigator.pop(context);
      return;
    }
    if (result == 'reset') {
      final yes = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('重新开始河谷冒险？'),
          content: const Text('只重玩恐龙岛的故事，其他游戏、作品和旅行纪念保留。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('不重置'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('重新出发'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (yes == true) {
        model.replayStory();
        _flush();
        caption.value = const ExpeditionEvent(
          'welcome',
          "Let's explore!",
          '去河谷交一个新朋友。',
        );
      }
    }
    _menuOpen = false;
    model.resume();
    _previous = null;
    hud.value++;
  }

  Future<void> _map() async {
    _menuOpen = true;
    _cancel();
    model.pause();
    _flush();
    unawaited(widget.audio.stopSpeech());
    final destination = await showModalBottomSheet<IslandRegion>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFF5DE),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                model.story.celebrated ? '朋友们的旅行纪念' : '我们的探险绘本',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: expeditionInk,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                model.story.celebrated
                    ? '搭好桥、分享果子、找到星灯、带小翼龙回家。每个地方还能再去玩！'
                    : model.hint,
              ),
              if (model.story.memories > 0)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3EACF),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '我们一起走过恐龙岛',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 19,
                          color: expeditionInk,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (final name in [
                            'car',
                            'basket',
                            'lantern',
                            'flyer',
                          ])
                            Flexible(
                              child: Image.asset(
                                'assets/expedition/$name.png',
                                height: 65,
                                fit: BoxFit.contain,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '搭桥 · 分享 · 点亮 · 救助 · 团聚',
                        style: TextStyle(color: expeditionInk),
                      ),
                    ],
                  ),
                ),
              if (model.story.memories > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('完成过 ${model.story.memories} 次朋友冒险 · 纪念记录会保留'),
                ),
              for (final region in IslandRegion.values)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Material(
                    color: islandRegions[region]!.sky,
                    borderRadius: BorderRadius.circular(22),
                    child: InkWell(
                      key: ValueKey('island-map-${region.name}'),
                      borderRadius: BorderRadius.circular(22),
                      onTap: model.story.visited.contains(region)
                          ? () => Navigator.pop(context, region)
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/expedition/${const ['tent', 'basket', 'lantern', 'boat'][region.index]}.png',
                              width: 72,
                              height: 56,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    islandRegions[region]!.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: region == IslandRegion.cave
                                          ? Colors.white
                                          : expeditionInk,
                                    ),
                                  ),
                                  Text(
                                    model.story.visited.contains(region)
                                        ? '回去看看 · Visit again'
                                        : '继续探险会到达这里',
                                    style: TextStyle(
                                      color: region == IslandRegion.cave
                                          ? Colors.white70
                                          : expeditionInk,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              model.story.visited.contains(region)
                                  ? Icons.arrow_forward_rounded
                                  : Icons.explore_outlined,
                              color: region == IslandRegion.cave
                                  ? Colors.white
                                  : expeditionInk,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (destination != null) model.travel(destination);
    _menuOpen = false;
    model.resume();
    _previous = null;
    _events();
    _queueSave();
    hud.value++;
  }

  @override
  void dispose() {
    _disposing = true;
    _saveTimer?.cancel();
    model.cancel();
    _flush(notify: false);
    _ticker.dispose();
    model.dispose();
    assets.dispose();
    caption.dispose();
    hud.dispose();
    _speechGeneration++;
    unawaited(widget.audio.stopSpeech());
    unawaited(widget.audio.stopEffects());
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFE6EAD5),
    body: LayoutBuilder(
      builder: (context, constraints) {
        _stageSize = constraints.biggest;
        return Stack(
          children: [
            if (loaded)
              Positioned.fill(
                child: RepaintBoundary(
                  key: const ValueKey('expedition-capture'),
                  child: Listener(
                    key: const ValueKey('expedition-world'),
                    onPointerDown: _downPointer,
                    onPointerMove: _movePointer,
                    onPointerUp: _upPointer,
                    onPointerCancel: (e) {
                      if (e.pointer == _pointer) _cancel();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: CustomPaint(
                      painter: ExpeditionScene(
                        model,
                        assets,
                        reducedMotion: MediaQuery.disableAnimationsOf(context),
                        touch: _touch,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.landscape_rounded,
                      size: 64,
                      color: Color(0xFF658A75),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      failed ? '河谷素材没准备好' : '正在打开河谷绘本…',
                      style: const TextStyle(
                        color: expeditionInk,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (failed)
                      FilledButton(
                        onPressed: () {
                          assets = ExpeditionAssets();
                          setState(() => failed = false);
                          unawaited(_load());
                        },
                        child: const Text('再试一次'),
                      )
                    else
                      const CircularProgressIndicator(color: Color(0xFF7C9E7A)),
                  ],
                ),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _round(
                      Icons.arrow_back_rounded,
                      '返回小家',
                      () => Navigator.maybePop(context),
                      'expedition-back',
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '抱抱探险队',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: expeditionInk,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '朋友们的恐龙岛',
                            style: TextStyle(
                              fontSize: 12,
                              color: expeditionInk.withValues(alpha: .65),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ValueListenableBuilder(
                            valueListenable: hud,
                            builder: (context, _, child) => Text(
                              model.chapter,
                              style: const TextStyle(
                                fontSize: 11,
                                letterSpacing: 1,
                                color: Color(0xFF8A9972),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListenableBuilder(
                      listenable: widget.audio,
                      builder: (context, _) => _round(
                        widget.audio.enabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        '声音',
                        widget.audio.toggle,
                        'expedition-audio',
                      ),
                    ),
                    const SizedBox(width: 6),
                    _round(
                      Icons.map_outlined,
                      '探险绘本',
                      loaded ? _map : () {},
                      'expedition-map',
                    ),
                    _round(
                      Icons.pause_rounded,
                      '暂停',
                      loaded ? _pause : () => {},
                      'expedition-pause',
                    ),
                  ],
                ),
              ),
            ),
            if (loaded)
              Positioned(
                left: 16,
                right: 16,
                bottom: MediaQuery.paddingOf(context).bottom + 12,
                child: ValueListenableBuilder(
                  valueListenable: caption,
                  builder: (context, e, _) => Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 580),
                      child: Material(
                        color: const Color(0xEDFDF6E6),
                        borderRadius: BorderRadius.circular(24),
                        child: InkWell(
                          key: const ValueKey('expedition-repeat'),
                          borderRadius: BorderRadius.circular(24),
                          onTap: _repeat,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.record_voice_over_rounded,
                                  color: Color(0xFF668975),
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        e.english,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: expeditionInk,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        e.chinese,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF778A70),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.touch_app_outlined,
                                  size: 17,
                                  color: Color(0xFF9BA98B),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (loaded)
              ValueListenableBuilder(
                valueListenable: hud,
                builder: (context, _, child) => _semantics(),
              ),
          ],
        );
      },
    ),
  );
  Widget _round(IconData icon, String label, VoidCallback onTap, String key) =>
      Material(
        color: const Color(0xCCFFF8E5),
        shape: const CircleBorder(),
        child: IconButton(
          key: ValueKey(key),
          tooltip: label,
          onPressed: onTap,
          icon: Icon(icon, color: expeditionInk),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
      );
  Widget _semantics() => ListenableBuilder(
    listenable: model,
    builder: (context, _) => _liveSemantics(),
  );

  Widget _liveSemantics() => Stack(
    children: [
      for (final entry
          in <String, ({Offset at, String label, VoidCallback action})>{
            'expedition-road-right': (
              at: view.toWorld(
                Offset(_stageSize.width * .90, view.horizon + 55 * view.scale),
              ),
              label: '向右慢慢开车',
              action: () => model.drive(
                (model.carX + 250).clamp(120.0, model.worldEnd),
                automatic: true,
              ),
            ),
            'expedition-road-left': (
              at: view.toWorld(
                Offset(_stageSize.width * .08, view.horizon + 55 * view.scale),
              ),
              label: '向左慢慢开车',
              action: () => model.drive(
                (model.carX - 250).clamp(120.0, model.worldEnd),
                automatic: true,
              ),
            ),
            for (final target in model.chapterTargets)
              'island-${target.id}': (
                at: target.at,
                label: target.label,
                action: () {
                  model.chapterDown(target.id, target.at);
                  model.chapterUp(tapped: true);
                  _events();
                },
              ),
            if (model.region == IslandRegion.valley)
              'expedition-log': (
                at: model.logPosition,
                label: '提起木头，再点河面放下',
                action: () {
                  model.pickLog();
                  _events();
                },
              ),
            if (model.region == IslandRegion.valley)
              'expedition-hook': (
                at: model.hook,
                label: '吊钩',
                action: () {
                  model.pickLog();
                  _events();
                },
              ),
            if (model.region == IslandRegion.valley)
              'expedition-dino': (
                at: Offset(model.dinoX, model.terrain(model.dinoX) - 65),
                label: '邀请小恐龙上车',
                action: () {
                  model.interactDino();
                  _events();
                },
              ),
            if (model.region == IslandRegion.valley)
              'expedition-bridge': (
                at: const Offset(bridgeCenter, -19),
                label: '把木头放在河的两岸',
                action: () {
                  model.placeAt(const Offset(bridgeCenter, -19));
                },
              ),
          }.entries)
        Positioned(
          left: view.toScreen(entry.value.at).dx - 30,
          top: view.toScreen(entry.value.at).dy - 30,
          width: 60,
          height: 60,
          child: Semantics(
            key: ValueKey(entry.key),
            label: entry.value.label,
            button: true,
            onTap: entry.value.action,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: _downPointer,
              onPointerMove: _movePointer,
              onPointerUp: _upPointer,
              onPointerCancel: (e) {
                if (e.pointer == _pointer) _cancel();
              },
              child: const SizedBox.expand(),
            ),
          ),
        ),
    ],
  );
}
