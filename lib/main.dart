import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'color_lab_screen.dart';
import 'game_audio.dart';
import 'island_progress.dart';
import 'rainbow_island_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const ColorHugApp());
}

class ColorHugApp extends StatefulWidget {
  const ColorHugApp({super.key, this.progress, this.audio});

  final IslandProgress? progress;
  final GameAudioController? audio;

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
      title: '颜色抱抱',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
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
        builder: (context) => ColorLabScreen(
          progress: _progress,
          audio: _audio,
          onOpenIsland: () => _openIsland(context),
        ),
      ),
    );
  }
}
