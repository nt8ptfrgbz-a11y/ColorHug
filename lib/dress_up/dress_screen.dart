import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game_audio.dart';
import 'dress_art.dart';
import 'dress_catalog.dart';
import 'dress_model.dart';
import 'dress_music.dart';
import 'dress_native.dart';

typedef DressStageBuilder =
    Widget Function(BuildContext context, Map<String, Object> values);

TextStyle _type(
  double size, {
  Color color = dressInk,
  FontWeight weight = FontWeight.w600,
  double? spacing,
}) => TextStyle(
  fontSize: size,
  color: color,
  fontWeight: weight,
  letterSpacing: spacing,
  height: 1.25,
);

class DressUpScreen extends StatefulWidget {
  const DressUpScreen({
    super.key,
    required this.audio,
    this.model,
    this.stageBuilder,
    this.onOpenTown,
    this.nativeController,
  });
  final GameAudioController audio;
  final DressModel? model;
  final DressStageBuilder? stageBuilder;
  final Future<void> Function()? onOpenTown;
  final DressNativeController? nativeController;
  @override
  State<DressUpScreen> createState() => _DressUpScreenState();
}

class _DressUpScreenState extends State<DressUpScreen>
    with WidgetsBindingObserver {
  DressModel? model;
  DressNativeController? native;
  DressCategory category = DressCategory.outfit;
  double angle = 0;
  bool busy = false, flash = false, nativeFailed = false, active = true;
  bool _sendingTurn = false, _pendingTurn = false;
  bool _covered = false;
  int _speechEpoch = 0;
  int nativeGeneration = 0;
  int pose = 0;
  String? feedback;
  Timer? _feedbackTimer, _flashTimer;
  final Map<String, Future<Uint8List?>> photoCache = {};
  late final DressMusic music;
  Map<String, Object> get values => {
    ...model!.look.toJson(),
    'place': model!.place.name,
    'reducedMotion':
        model!.reducedMotion || MediaQuery.disableAnimationsOf(context),
  };

  @override
  void initState() {
    super.initState();
    music = DressMusic(native: widget.stageBuilder == null);
    widget.audio.addListener(_syncMusic);
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  Future<void> _load() async {
    final loaded = widget.model ?? await DressModel.load();
    if (!mounted) {
      if (widget.model == null) loaded.dispose();
      return;
    }
    model = loaded;
    native = widget.nativeController;
    loaded.addListener(_onChange);
    setState(() {});
    _syncMusic();
    _say('欢迎来到绒绒衣橱。点点衣服，给小伙伴换上吧。');
  }

  void _onChange() {
    if (!mounted) return;
    setState(() {});
    _syncMusic();
    unawaited(_native('update', values));
  }

  void _syncMusic() => music.active(
    model?.sound == true && widget.audio.enabled && active && !_covered,
  );

  Future<T?> _native<T>(String method, [Object? arguments]) async {
    try {
      return await native?.call<T>(method, arguments);
    } on PlatformException {
      if (mounted &&
          !nativeFailed &&
          method != 'readPhoto' &&
          method != 'capture') {
        setState(() => nativeFailed = true);
      }
      return null;
    } on MissingPluginException {
      if (mounted && !nativeFailed) setState(() => nativeFailed = true);
      return null;
    }
  }

  void _ready(DressNativeController controller) {
    if (!mounted) {
      unawaited(controller.dispose());
      return;
    }
    native = controller;
    unawaited(_native('update', values));
    unawaited(_native('active', active));
    unawaited(_native('turn', {'angle': angle, 'animated': false}));
    setState(() => nativeFailed = false);
  }

  void _say(String text) {
    final epoch = ++_speechEpoch;
    if (model?.sound == true && active) {
      unawaited(
        widget.audio.stopSpeech().then((_) async {
          if (mounted &&
              active &&
              !_covered &&
              model!.sound &&
              epoch == _speechEpoch) {
            music.duck(true);
            await widget.audio.speak(text);
            if (mounted && epoch == _speechEpoch) music.duck(false);
          }
        }),
      );
    }
  }

  void _sound(GameSound sound) {
    if (model!.sound && active) unawaited(widget.audio.play(sound));
  }

  void _notice(String text) {
    _feedbackTimer?.cancel();
    setState(() => feedback = text);
    _feedbackTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => feedback = null);
    });
  }

  void _wear(DressItem item) {
    model!.wear(item);
    _sound(GameSound.tap);
    _notice(item.name);
    _say('穿上${item.name}啦');
  }

  void _turn(double delta) {
    angle = (angle + delta) % (math.pi * 2);
    _pendingTurn = true;
    if (!_sendingTurn) unawaited(_flushTurn());
  }

  Future<void> _flushTurn() async {
    _sendingTurn = true;
    while (_pendingTurn && mounted && active) {
      _pendingTurn = false;
      await _native('turn', {'angle': angle, 'animated': false});
    }
    _sendingTurn = false;
  }

  void _front() {
    angle = 0;
    unawaited(_native('turn', {'angle': 0.0, 'animated': true}));
  }

  void _pose() {
    pose = (pose + 1) % 3;
    unawaited(_native('pose', pose));
    _notice(const ['站好啦', '歪歪头，笑一笑', '挥挥手，你好呀'][pose]);
  }

  Future<void> _play() async {
    await _native('action');
    if (!mounted) return;
    model!.discover();
    _sound(switch (model!.place) {
      DressPlace.garden => GameSound.splash,
      DressPlace.tea => GameSound.bell,
      DressPlace.night => GameSound.discover,
      _ => GameSound.bounce,
    });
    _notice(switch (model!.place) {
      DressPlace.garden => '噗通！小水花跳起来啦',
      DressPlace.tea => '谢谢你，小兔喝到花茶啦',
      DressPlace.night => '又一颗小星星亮起来啦',
      _ => '每一种搭配，都有自己的可爱',
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    active = state == AppLifecycleState.resumed;
    _syncMusic();
    _pendingTurn = false;
    unawaited(_native('active', active && !_covered));
    if (!active) unawaited(widget.audio.stopSpeech());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (model != null && native != null) unawaited(_native('update', values));
  }

  @override
  void dispose() {
    _speechEpoch++;
    widget.audio.removeListener(_syncMusic);
    music.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _feedbackTimer?.cancel();
    _flashTimer?.cancel();
    model?.removeListener(_onChange);
    if (widget.model == null) model?.dispose();
    unawaited(native?.dispose() ?? Future.value());
    unawaited(widget.audio.stopSpeech());
    super.dispose();
  }

  Future<void> _moreGames() async {
    if (widget.onOpenTown == null) {
      Navigator.pop(context);
      return;
    }
    _covered = true;
    _syncMusic();
    _speechEpoch++;
    await widget.audio.stopSpeech();
    await _native('active', false);
    if (!mounted) return;
    try {
      await widget.onOpenTown!();
    } finally {
      _covered = false;
      _syncMusic();
      if (mounted) await _native('active', active);
    }
  }

  Future<void> _capture() async {
    if (busy || (native == null && widget.stageBuilder == null)) return;
    setState(() => busy = true);
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final filename = 'look_$id.png';
    final capturedLook = model!.look, capturedPlace = model!.place;
    try {
      final data = await _native<Uint8List>('capture', filename);
      if (!mounted) return;
      if (data == null) {
        _notice('照片还没准备好，请再试一次');
        return;
      }
      final expired = model!.addMemory(
        DressMemory(
          id: id,
          look: capturedLook,
          place: capturedPlace,
          photo: filename,
        ),
      );
      photoCache[filename] = Future.value(data);
      for (final file in expired) {
        photoCache.remove(file);
      }
      // Persist the album before removing images no longer referenced by it.
      await model!.saved;
      if (!mounted) return;
      if (!model!.saveFailed) await _native('removePhotos', expired);
      if (!mounted) return;
      setState(
        () => flash =
            !model!.reducedMotion && !MediaQuery.disableAnimationsOf(context),
      );
      _flashTimer?.cancel();
      _flashTimer = Timer(const Duration(milliseconds: 160), () {
        if (mounted) setState(() => flash = false);
      });
      _sound(GameSound.complete);
      _notice('咔嚓！已经放进你的搭配相册');
      _say('照片保存啦');
      await _memory(model!.memories.first);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _travel() async {
    _say('想去哪里玩呢');
    final selected = await showModalBottomSheet<DressPlace>(
      context: context,
      backgroundColor: dressCream,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('穿好啦，去玩吧', style: _type(24)),
              const SizedBox(height: 6),
              Text('带上你喜欢的样子', style: _type(13, color: dressMuted)),
              const SizedBox(height: 22),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * .6,
                  maxWidth: 720,
                ),
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: MediaQuery.sizeOf(context).width > 650
                      ? 4
                      : 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.28,
                  children: [
                    for (final place in DressPlace.values)
                      _PlaceCard(
                        place: place,
                        selected: model!.place == place,
                        discovered: model!.discoveries.contains(place),
                        onTap: () => Navigator.pop(context, place),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    model!.visit(selected);
    _front();
    _say(selected.invitation);
  }

  Future<void> _album() async {
    _say('这里是你的小小搭配相册');
    await _native('active', false);
    if (!mounted) return;
    final selected = await showModalBottomSheet<DressMemory>(
      context: context,
      backgroundColor: dressCream,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .78,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('我的搭配相册', style: _type(23)),
                          Text(
                            '点一张照片，贴上小小的喜欢',
                            style: _type(12, color: dressMuted),
                          ),
                        ],
                      ),
                    ),
                    _RoundButton(
                      label: '关闭相册',
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.pop(context),
                      size: 48,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: model!.memories.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.photo_camera_outlined,
                                size: 64,
                                color: dressRose,
                              ),
                              const SizedBox(height: 20),
                              Text('给今天的搭配拍张照吧', style: _type(18)),
                              const SizedBox(height: 8),
                              Text(
                                '衣帽间里的相机，正在等你',
                                style: _type(13, color: dressMuted),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 260,
                                childAspectRatio: .78,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                              ),
                          itemCount: model!.memories.length,
                          itemBuilder: (context, index) {
                            final memory = model!.memories[index];
                            final image = photoCache.putIfAbsent(
                              memory.photo,
                              () =>
                                  _native<Uint8List>('readPhoto', memory.photo),
                            );
                            return Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                key: ValueKey('dress-memory-${memory.id}'),
                                borderRadius: BorderRadius.circular(18),
                                onTap: () => Navigator.pop(context, memory),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: FutureBuilder<Uint8List?>(
                                            future: image,
                                            builder: (context, snapshot) =>
                                                snapshot.data != null
                                                ? _MemoryImage(
                                                    bytes: snapshot.data!,
                                                    sticker: memory.sticker,
                                                  )
                                                : ColoredBox(
                                                    color: const Color(
                                                      0xFFF0E5D6,
                                                    ),
                                                    child: Center(
                                                      child:
                                                          snapshot.connectionState ==
                                                              ConnectionState
                                                                  .waiting
                                                          ? const SizedBox.square(
                                                              dimension: 22,
                                                              child:
                                                                  CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2,
                                                                  ),
                                                            )
                                                          : const Icon(
                                                              Icons
                                                                  .checkroom_rounded,
                                                              size: 48,
                                                              color: dressRose,
                                                            ),
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              memory.place.icon,
                                              size: 17,
                                              color: dressRose,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              memory.place.label,
                                              style: _type(13),
                                            ),
                                          ],
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
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    '在这台设备上珍藏最近 24 张搭配',
                    style: _type(11, color: dressMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (mounted && selected != null) await _memory(selected);
    if (mounted) await _native('active', active);
  }

  Future<void> _memory(DressMemory memory) async {
    if (!mounted) return;
    await _native('active', false);
    if (!mounted) return;
    var sticker = model!.memories
        .firstWhere((m) => m.id == memory.id, orElse: () => memory)
        .sticker;
    final image = photoCache.putIfAbsent(
      memory.photo,
      () => _native<Uint8List>('readPhoto', memory.photo),
    );
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: dressCream,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, refresh) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .8,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('今天的可爱，收藏好啦', style: _type(20))),
                      _RoundButton(
                        label: '收好照片',
                        icon: Icons.close_rounded,
                        onTap: () => Navigator.pop(context),
                        size: 44,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: FutureBuilder<Uint8List?>(
                        future: image,
                        builder: (context, snapshot) => snapshot.data == null
                            ? const Center(
                                child: Icon(
                                  Icons.photo_outlined,
                                  color: dressRose,
                                  size: 48,
                                ),
                              )
                            : _MemoryImage(
                                bytes: snapshot.data!,
                                sticker: sticker,
                                fit: BoxFit.contain,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 4; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          child: _RoundButton(
                            key: ValueKey('dress-sticker-$i'),
                            label: const ['不放贴纸', '小花贴纸', '星星贴纸', '爱心贴纸'][i],
                            icon: const [
                              Icons.block_rounded,
                              Icons.local_florist_rounded,
                              Icons.star_rounded,
                              Icons.favorite_rounded,
                            ][i],
                            fill: sticker == i
                                ? const Color(0xFFEED7CC)
                                : Colors.white,
                            onTap: () {
                              model!.setSticker(memory.id, i);
                              refresh(() => sticker = i);
                              _sound(GameSound.tap);
                            },
                            size: 46,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SoftButton(
                    key: const ValueKey('dress-restore-memory'),
                    label: '再穿一次这套搭配',
                    icon: Icons.checkroom_rounded,
                    filled: true,
                    onTap: () {
                      model!.restoreMemory(memory);
                      _front();
                      Navigator.pop(context);
                      _say('又穿上这一套啦');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (mounted) await _native('active', active);
  }

  Future<void> _settings() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: dressCream,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .92,
      ),
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, refresh) => SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('陪伴设置', style: _type(23)),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: Text('语音与声音', style: _type(16)),
                    subtitle: const Text('点衣服时，听一听它的名字'),
                    value: model!.sound && widget.audio.enabled,
                    activeThumbColor: dressRose,
                    onChanged: (v) {
                      model!.setSound(v);
                      if (v && !widget.audio.enabled) {
                        unawaited(widget.audio.toggle());
                      }
                      if (!v) unawaited(widget.audio.stopSpeech());
                      refresh(() {});
                    },
                  ),
                  SwitchListTile(
                    title: Text('安静的小动作', style: _type(16)),
                    subtitle: const Text('减少摆动、闪光和庆祝特效'),
                    value: model!.reducedMotion,
                    activeThumbColor: dressRose,
                    onChanged: (v) {
                      model!.setReducedMotion(v);
                      refresh(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '衣服全部开放 · 无广告 · 离线可玩',
                    style: _type(12, color: dressMuted),
                  ),
                  const SizedBox(height: 12),
                  _SoftButton(
                    label: '继续玩',
                    icon: Icons.favorite_border_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (model == null) {
      return const Scaffold(
        backgroundColor: dressCream,
        body: Center(child: CircularProgressIndicator(color: dressRose)),
      );
    }
    return Scaffold(
      backgroundColor: dressCream,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide =
                constraints.maxWidth >= 760 ||
                constraints.maxWidth > constraints.maxHeight * 1.3;
            final compact = constraints.maxHeight < 530;
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 26 : 16,
                    compact ? 7 : 14,
                    wide ? 22 : 14,
                    compact ? 7 : 12,
                  ),
                  child: Row(
                    children: [
                      if (widget.onOpenTown != null ||
                          Navigator.canPop(context)) ...[
                        _RoundButton(
                          label: '更多游戏',
                          icon: Icons.grid_view_rounded,
                          onTap: _moreGames,
                          size: compact ? 42 : 48,
                        ),
                        const SizedBox(width: 12),
                      ],
                      Container(
                        width: compact ? 37 : 44,
                        height: compact ? 37 : 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1DFD4),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.local_florist_rounded,
                          color: dressRose,
                          size: 27,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '绒绒衣橱',
                              style: _type(compact ? 21 : 24, spacing: 2),
                            ),
                            Text(
                              'LITTLE WARDROBE',
                              style: _type(8, color: dressMuted, spacing: 2.1),
                            ),
                          ],
                        ),
                      ),
                      _RoundButton(
                        key: const ValueKey('dress-album'),
                        label: '搭配相册',
                        icon: Icons.photo_library_outlined,
                        onTap: _album,
                        size: compact ? 42 : 48,
                      ),
                      const SizedBox(width: 7),
                      _RoundButton(
                        key: const ValueKey('dress-settings'),
                        label: '陪伴设置',
                        icon: Icons.tune_rounded,
                        onTap: _settings,
                        size: compact ? 42 : 48,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      wide ? 20 : 10,
                      0,
                      wide ? 20 : 10,
                      compact ? 8 : 12,
                    ),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: _stage(compact)),
                              const SizedBox(width: 18),
                              SizedBox(
                                width: (constraints.maxWidth * .32).clamp(
                                  290,
                                  370,
                                ),
                                child: _wardrobe(compact),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: _stage(constraints.maxHeight < 680),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: (constraints.maxHeight * .43).clamp(
                                  240,
                                  370,
                                ),
                                child: _wardrobe(constraints.maxHeight < 680),
                              ),
                            ],
                          ),
                  ),
                ),
                if (model!.saveFailed)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      '这次的搭配暂时没能保存，下一次操作会重试',
                      style: _type(11, color: dressRose),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _stage(bool compact) => ClipRRect(
    borderRadius: BorderRadius.circular(compact ? 22 : 28),
    child: ColoredBox(
      color: const Color(0xFFF0E3D2),
      child: DragTarget<DressItem>(
        onAcceptWithDetails: (details) => _wear(details.data),
        builder: (context, candidates, rejected) => Stack(
          fit: StackFit.expand,
          children: [
            KeyedSubtree(
              key: ValueKey('native-$nativeGeneration'),
              child:
                  widget.stageBuilder?.call(context, values) ??
                  DressNativeStage(values: values, onReady: _ready),
            ),
            GestureDetector(
              key: const ValueKey('dress-stage'),
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (details) =>
                  _turn(details.delta.dx * .012),
              onTap: _play,
              child: const ColoredBox(color: Colors.transparent),
            ),
            if (candidates.isNotEmpty)
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFABBD9B),
                      width: 4,
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            Positioned(
              top: compact ? 12 : 18,
              left: compact ? 12 : 18,
              child: _SoftButton(
                key: const ValueKey('dress-travel'),
                label: model!.place.label,
                icon: model!.place.icon,
                onTap: _travel,
                trailing: Icons.expand_more_rounded,
                small: true,
              ),
            ),
            Positioned(
              top: compact ? 12 : 18,
              right: compact ? 12 : 18,
              child: _RoundButton(
                key: const ValueKey('dress-camera'),
                label: '拍一张照片',
                icon: busy
                    ? Icons.hourglass_top_rounded
                    : Icons.photo_camera_outlined,
                onTap: busy ? null : _capture,
                size: compact ? 48 : 58,
                fill: const Color(0xFFFDF7EB),
              ),
            ),
            Positioned(
              left: compact ? 12 : 18,
              top: compact ? 68 : 82,
              child: Column(
                children: [
                  for (var i = 0; i < 2; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Semantics(
                        label: i == 0 ? '选择桃桃' : '选择可可',
                        button: true,
                        selected: model!.look.character == i,
                        child: GestureDetector(
                          key: ValueKey('dress-character-$i'),
                          onTap: () {
                            model!.chooseCharacter(i);
                            _say(i == 0 ? '桃桃来啦' : '可可来啦');
                          },
                          child: Container(
                            width: compact ? 42 : 48,
                            height: compact ? 42 : 48,
                            decoration: BoxDecoration(
                              color: i == 0
                                  ? const Color(0xFFEDD3BC)
                                  : const Color(0xFFC69575),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: model!.look.character == i
                                    ? dressRose
                                    : const Color(0xCCFFFFFF),
                                width: model!.look.character == i ? 3 : 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x104E3421),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              i == 0
                                  ? Icons.face_3_rounded
                                  : Icons.face_4_rounded,
                              size: compact ? 30 : 34,
                              color: i == 0
                                  ? const Color(0xFF86614F)
                                  : const Color(0xFF593E34),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              right: compact ? 14 : 23,
              top: compact ? 68 : 87,
              child: _RoundButton(
                key: const ValueKey('dress-pose'),
                label: '换一个拍照姿势',
                icon: Icons.emoji_people_rounded,
                onTap: _pose,
                size: compact ? 40 : 48,
              ),
            ),
            Positioned(
              bottom: compact ? 12 : 18,
              left: compact ? 12 : 18,
              right: compact ? 12 : 18,
              child: Row(
                children: [
                  _RoundButton(
                    key: const ValueKey('dress-action'),
                    label: model!.place.action,
                    icon: model!.place == DressPlace.studio
                        ? Icons.waving_hand_outlined
                        : model!.place.icon,
                    onTap: _play,
                    size: compact ? 44 : 50,
                  ),
                  const Spacer(),
                  _RoundButton(
                    key: const ValueKey('dress-turn-left'),
                    label: '向左转身',
                    icon: Icons.rotate_left_rounded,
                    onTap: () => _turn(-math.pi / 4),
                    size: compact ? 44 : 50,
                  ),
                  const SizedBox(width: 8),
                  _RoundButton(
                    key: const ValueKey('dress-front'),
                    label: '转回正面',
                    icon: Icons.face_retouching_natural,
                    onTap: _front,
                    size: compact ? 40 : 44,
                  ),
                  const SizedBox(width: 8),
                  _RoundButton(
                    key: const ValueKey('dress-turn-right'),
                    label: '向右转身',
                    icon: Icons.rotate_right_rounded,
                    onTap: () => _turn(math.pi / 4),
                    size: compact ? 44 : 50,
                  ),
                  const Spacer(),
                  _RoundButton(
                    key: const ValueKey('dress-undo'),
                    label: '撤销换装',
                    icon: Icons.undo_rounded,
                    onTap: model!.canUndo ? model!.undo : null,
                    size: compact ? 44 : 50,
                  ),
                ],
              ),
            ),
            if (!compact)
              Positioned(
                bottom: 80,
                left: 65,
                right: 65,
                child: IgnorePointer(
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Container(
                        key: ValueKey(feedback ?? model!.place.name),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xDFFFFAF2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          feedback ?? '左右滑动，看看背面',
                          textAlign: TextAlign.center,
                          style: _type(11, color: const Color(0xFF887464)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (flash)
              const IgnorePointer(child: ColoredBox(color: Color(0x77FFFFFF))),
            if (nativeFailed)
              ColoredBox(
                color: const Color(0xEFF8ECDD),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.checkroom_rounded,
                        color: dressRose,
                        size: 52,
                      ),
                      const SizedBox(height: 12),
                      Text('衣帽间需要重新打开一下', style: _type(16)),
                      const SizedBox(height: 16),
                      _SoftButton(
                        label: '重新打开',
                        icon: Icons.refresh_rounded,
                        onTap: () {
                          unawaited(native?.dispose() ?? Future.value());
                          native = null;
                          setState(() {
                            nativeFailed = false;
                            nativeGeneration++;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Widget _wardrobe(bool compact) {
    final items = dressCatalog
        .where((item) => item.category == category)
        .toList();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFEDE3D7)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              compact ? 9 : 16,
              14,
              compact ? 6 : 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text('今天，穿什么呢？', style: _type(compact ? 15 : 18)),
                ),
                Text('自由搭配', style: _type(10, color: dressMuted)),
              ],
            ),
          ),
          SizedBox(
            height: compact ? 53 : 63,
            child: LayoutBuilder(
              builder: (context, box) => ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                children: [
                  for (final value in DressCategory.values)
                    SizedBox(
                      width: math.max(47, (box.maxWidth - 12) / 6),
                      child: Semantics(
                        selected: category == value,
                        child: InkWell(
                          key: ValueKey('dress-category-${value.name}'),
                          onTap: () {
                            setState(() => category = value);
                            _sound(GameSound.tap);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: category == value
                                  ? const Color(0xFFF0DFD5)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  value.icon,
                                  color: category == value
                                      ? dressRose
                                      : dressMuted,
                                  size: compact ? 22 : 26,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  value.label,
                                  style: _type(
                                    11,
                                    color: category == value
                                        ? dressRose
                                        : dressMuted,
                                  ),
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
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                final horizontal = box.maxHeight < 230;
                final columns = horizontal ? 6 : (box.maxWidth > 380 ? 3 : 2);
                final rows = (6 / columns).ceil();
                final itemWidth = horizontal
                    ? 106.0
                    : (box.maxWidth - 24 - (columns - 1) * 9) / columns;
                final itemHeight = horizontal
                    ? (box.maxHeight - 20).clamp(62.0, 160.0)
                    : ((box.maxHeight - 20 - (rows - 1) * 9) / rows).clamp(
                        83.0,
                        160.0,
                      );
                return GridView.builder(
                  key: ValueKey('dress-grid-${category.name}'),
                  scrollDirection: horizontal ? Axis.horizontal : Axis.vertical,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: horizontal ? 1 : columns,
                    childAspectRatio: horizontal
                        ? (box.maxHeight - 20) / itemWidth
                        : itemWidth / itemHeight,
                    crossAxisSpacing: 9,
                    mainAxisSpacing: 9,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index],
                        selected =
                            model!.look.itemFor(category) == items[index].id;
                    return Draggable<DressItem>(
                      affinity: horizontal ? Axis.vertical : Axis.horizontal,
                      data: item,
                      maxSimultaneousDrags: 1,
                      feedbackOffset: const Offset(-30, -60),
                      dragAnchorStrategy: pointerDragAnchorStrategy,
                      feedback: Material(
                        color: Colors.transparent,
                        child: Transform.translate(
                          offset: const Offset(-50, -80),
                          child: Container(
                            width: 100,
                            height: 110,
                            decoration: BoxDecoration(
                              color: dressCream.withValues(alpha: .94),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x335F4434),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                            child: DressItemArt(item),
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: .35,
                        child: _itemCard(item, selected, itemHeight),
                      ),
                      child: _itemCard(item, selected, itemHeight),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              compact ? 3 : 7,
              12,
              compact ? 7 : 12,
            ),
            child: Row(
              children: [
                if (category == DressCategory.accessory)
                  Expanded(
                    child: _SoftButton(
                      key: const ValueKey('dress-remove-accessory'),
                      label: '摘下配饰',
                      icon: Icons.remove_circle_outline,
                      onTap: model!.removeAccessory,
                      small: true,
                    ),
                  )
                else ...[
                  Icon(
                    Icons.palette_outlined,
                    color: dressMuted,
                    size: compact ? 18 : 21,
                  ),
                  const SizedBox(width: 4),
                  for (var i = 0; i < 6; i++)
                    Expanded(
                      child: Semantics(
                        label:
                            '把衣服换成${['粉色', '绿色', '蓝色', '紫色', '黄色', '奶油色'][i]}',
                        selected: model!.look.tint == i,
                        button: true,
                        child: InkWell(
                          key: ValueKey('dress-tint-$i'),
                          onTap: () {
                            model!.tint(i);
                            _sound(GameSound.tap);
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: SizedBox(
                            height: compact ? 32 : 40,
                            child: Center(
                              child: Container(
                                width: compact ? 23 : 27,
                                height: compact ? 23 : 27,
                                decoration: BoxDecoration(
                                  color: const [
                                    Color(0xFFE7A6B1),
                                    Color(0xFFA7BCA8),
                                    Color(0xFFA1BDCD),
                                    Color(0xFFC0AED2),
                                    Color(0xFFEBC774),
                                    Color(0xFFF0DDC3),
                                  ][i],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: model!.look.tint == i
                                        ? dressInk
                                        : const Color(0xFFE4D6C8),
                                    width: model!.look.tint == i ? 2.5 : 1,
                                  ),
                                ),
                                child: model!.look.tint == i
                                    ? const Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  InkWell(
                    key: const ValueKey('dress-tint-original'),
                    onTap: () => model!.tint(-1),
                    borderRadius: BorderRadius.circular(25),
                    child: const SizedBox(
                      width: 32,
                      height: 40,
                      child: Icon(
                        Icons.restart_alt_rounded,
                        size: 20,
                        color: dressMuted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!compact)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 13),
              child: _SoftButton(
                key: const ValueKey('dress-go-play'),
                label: '穿好啦，去玩吧',
                icon: Icons.explore_outlined,
                onTap: _travel,
                filled: true,
              ),
            ),
        ],
      ),
    );
  }

  Widget _itemCard(DressItem item, bool selected, double height) => Semantics(
    button: true,
    selected: selected,
    label: item.name,
    child: Material(
      color: selected ? const Color(0xFFF8EAE0) : const Color(0xFFFAF7F0),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: ValueKey('dress-item-${item.id}'),
        onTap: () => _wear(item),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFFCAA496)
                  : const Color(0xFFF0EADF),
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 3, 8, 5),
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: DressItemArt(
                            item,
                            size: (height - 22).clamp(52, 112),
                          ),
                        ),
                      ),
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _type(
                          11,
                          color: selected
                              ? const Color(0xFF8B5E59)
                              : const Color(0xFF8C7B6E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (selected)
                const Positioned(
                  top: 6,
                  right: 6,
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 17,
                    color: dressRose,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _MemoryImage extends StatelessWidget {
  const _MemoryImage({
    required this.bytes,
    required this.sticker,
    this.fit = BoxFit.cover,
  });
  final Uint8List bytes;
  final int sticker;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.memory(
        bytes,
        width: double.infinity,
        fit: fit,
        gaplessPlayback: true,
      ),
      if (sticker > 0)
        Positioned(
          right: 12,
          bottom: 12,
          child: Transform.rotate(
            angle: -.16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xF5FFF9ED),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x226E5038),
                    blurRadius: 9,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                const [
                  Icons.block,
                  Icons.local_florist_rounded,
                  Icons.star_rounded,
                  Icons.favorite_rounded,
                ][sticker.clamp(0, 3)],
                size: 34,
                color: const [
                  dressMuted,
                  Color(0xFFD49A8A),
                  Color(0xFFD9B365),
                  Color(0xFFBE8895),
                ][sticker.clamp(0, 3)],
              ),
            ),
          ),
        ),
    ],
  );
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.size = 52,
    this.fill = const Color(0xEFFFFAF2),
  });
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color fill;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Semantics(
      label: label,
      button: true,
      enabled: onTap != null,
      child: Material(
        color: fill,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: size,
            child: Icon(
              icon,
              size: size * .45,
              color: onTap == null
                  ? const Color(0xFFCCBDAE)
                  : const Color(0xFF8F7362),
            ),
          ),
        ),
      ),
    ),
  );
}

class _SoftButton extends StatelessWidget {
  const _SoftButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.trailing,
    this.filled = false,
    this.small = false,
  });
  final String label;
  final IconData icon;
  final IconData? trailing;
  final VoidCallback onTap;
  final bool filled, small;
  @override
  Widget build(BuildContext context) => Material(
    color: filled ? const Color(0xFF9B7D66) : const Color(0xEDFFF9EE),
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: small ? 12 : 17,
          vertical: small ? 11 : 14,
        ),
        child: Row(
          mainAxisSize: filled ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: small ? 18 : 21,
              color: filled ? dressCream : const Color(0xFF9A8068),
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: _type(
                  small ? 12 : 14,
                  color: filled ? dressCream : const Color(0xFF856D58),
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 5),
              Icon(trailing, size: 18, color: const Color(0xFF9A8068)),
            ],
          ],
        ),
      ),
    ),
  );
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.place,
    required this.selected,
    required this.discovered,
    required this.onTap,
  });
  final DressPlace place;
  final bool selected, discovered;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Color.lerp(place.color, Colors.white, .65),
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      key: ValueKey('dress-place-${place.name}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? place.color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    place.icon,
                    size: 37,
                    color: Color.lerp(place.color, dressInk, .18),
                  ),
                  const SizedBox(height: 9),
                  Text(place.label, style: _type(15)),
                ],
              ),
            ),
            if (discovered)
              Positioned(
                top: 10,
                right: 10,
                child: Icon(
                  Icons.favorite_rounded,
                  size: 16,
                  color: place.color,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
