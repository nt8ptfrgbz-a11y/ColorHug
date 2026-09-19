import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'color_lab_screen.dart';
import 'game_audio.dart';
import 'island_progress.dart';
import 'rainbow_island_screen.dart';
import 'silly_town/town_screen.dart';
import 'dress_up/dress_screen.dart';
import 'seed_lab/seed_screen.dart';
import 'shanhai/shanhai_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const ColorHugApp(startInShanhai: true));
}

class ColorHugApp extends StatefulWidget {
  const ColorHugApp({
    super.key,
    this.progress,
    this.audio,
    this.startInTown = false,
    this.startInDressUp = false,
    this.startInSeedLab = false,
    this.startInShanhai = false,
  });

  final IslandProgress? progress;
  final GameAudioController? audio;
  final bool startInTown;
  final bool startInDressUp;
  final bool startInSeedLab;
  final bool startInShanhai;

  @override
  State<ColorHugApp> createState() => _ColorHugAppState();
}

class _ColorHugAppState extends State<ColorHugApp> {
  late final IslandProgress _progress;
  late final GameAudioController _audio;
  late final bool _ownsProgress;
  late final bool _ownsAudio;

  @override
  void initState() {
    super.initState();
    _ownsProgress = widget.progress == null;
    _progress = widget.progress ?? IslandProgress.persistent();
    _ownsAudio = widget.audio == null;
    _audio = widget.audio ?? GameAudioController.live();
  }

  @override
  void dispose() {
    if (_ownsProgress) _progress.dispose();
    if (_ownsAudio) _audio.dispose();
    super.dispose();
  }

  void _openIsland(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (islandContext) => RainbowIslandScreen(
          progress: _progress,
          audio: _audio,
          onOpenLab: () => Navigator.of(islandContext).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: widget.startInShanhai
          ? '山海唤灵师'
          : widget.startInSeedLab
          ? '奇怪种子实验室'
          : widget.startInDressUp
          ? '绒绒衣橱'
          : widget.startInTown
          ? '小怪兽的胡闹小镇'
          : '颜色抱抱',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        splashFactory: InkRipple.splashFactory,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7957D5),
          brightness: Brightness.light,
        ),
        fontFamilyFallback: const [
          'PingFang SC',
          'Hiragino Sans GB',
          'Arial Unicode MS',
        ],
      ),
      home: Builder(
        builder: (context) => widget.startInShanhai
            ? ShanhaiScreen(
                audio: _audio,
                nativeAudio: _ownsAudio,
                onOpenGames: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (context) => SeedLabScreen(
                      audio: _audio,
                      nativeAudio: _ownsAudio,
                      onBack: () => Navigator.of(context).pop(),
                      onOpenWardrobe: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (context) => DressUpScreen(
                            audio: _audio,
                            onBack: () => Navigator.of(context).pop(),
                            onOpenTown: () => Navigator.of(context).push<void>(
                              MaterialPageRoute(
                                builder: (context) => TownHomeScreen(
                                  audio: _audio,
                                  nativeAudio: _ownsAudio,
                                  onBack: () => Navigator.of(context).pop(),
                                  onOpenClassic: () =>
                                      Navigator.of(context).push<void>(
                                        MaterialPageRoute(
                                          builder: (context) => ColorLabScreen(
                                            progress: _progress,
                                            audio: _audio,
                                            onBack: () =>
                                                Navigator.of(context).pop(),
                                            onOpenIsland: () =>
                                                _openIsland(context),
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
                ),
              )
            : widget.startInSeedLab
            ? SeedLabScreen(
                audio: _audio,
                nativeAudio: _ownsAudio,
                onOpenWardrobe: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (context) => DressUpScreen(
                      audio: _audio,
                      onBack: () => Navigator.of(context).pop(),
                      onOpenTown: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (context) => TownHomeScreen(
                            audio: _audio,
                            nativeAudio: _ownsAudio,
                            onBack: () => Navigator.of(context).pop(),
                            onOpenClassic: () =>
                                Navigator.of(context).push<void>(
                                  MaterialPageRoute(
                                    builder: (context) => ColorLabScreen(
                                      progress: _progress,
                                      audio: _audio,
                                      onBack: () => Navigator.of(context).pop(),
                                      onOpenIsland: () => _openIsland(context),
                                    ),
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : widget.startInDressUp
            ? DressUpScreen(
                audio: _audio,
                onOpenTown: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (context) => TownHomeScreen(
                      audio: _audio,
                      nativeAudio: _ownsAudio,
                      onBack: () => Navigator.of(context).pop(),
                      onOpenClassic: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (context) => ColorLabScreen(
                            progress: _progress,
                            audio: _audio,
                            onBack: () => Navigator.of(context).pop(),
                            onOpenIsland: () => _openIsland(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : widget.startInTown
            ? TownHomeScreen(
                audio: _audio,
                nativeAudio: _ownsAudio,
                onOpenClassic: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (context) => ColorLabScreen(
                      progress: _progress,
                      audio: _audio,
                      onBack: () => Navigator.of(context).pop(),
                      onOpenIsland: () => _openIsland(context),
                    ),
                  ),
                ),
              )
            : ColorLabScreen(
                progress: _progress,
                audio: _audio,
                onOpenIsland: () => _openIsland(context),
              ),
      ),
    );
  }
}
