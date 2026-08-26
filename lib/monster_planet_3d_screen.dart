import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';

import 'game_audio.dart';
import 'island_progress.dart';

class MonsterPlanet3DGameScreen extends StatefulWidget {
  const MonsterPlanet3DGameScreen({
    super.key,
    required this.progress,
    required this.audio,
    required this.fighterIndex,
    required this.fighterId,
    required this.fighterName,
    required this.fighterColor,
  });

  final IslandProgress progress;
  final GameAudioController audio;
  final int fighterIndex;
  final String fighterId;
  final String fighterName;
  final Color fighterColor;

  @override
  State<MonsterPlanet3DGameScreen> createState() =>
      _MonsterPlanet3DGameScreenState();
}

class _MonsterPlanet3DGameScreenState extends State<MonsterPlanet3DGameScreen> {
  static const _bridgeObject = 'MonsterPlanetBridge';

  bool _ready = false;
  bool _leaving = false;
  bool _won = false;
  Timer? _loadingHintTimer;

  @override
  void initState() {
    super.initState();
    unawaited(widget.audio.stopSpeech());
    unawaited(
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]),
    );
    unawaited(
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
    );
    _loadingHintTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && !_ready) setState(() {});
    });
  }

  void _handleUnityMessage(String message) {
    try {
      final payload = jsonDecode(message);
      if (payload is! Map<String, dynamic>) return;
      switch (payload['event']) {
        case 'ready':
          if (mounted) {
            setState(() => _ready = true);
          }
          sendToUnity(
            _bridgeObject,
            'SelectHeroFromFlutter',
            widget.fighterIndex.toString(),
          );
          break;
        case 'battle_finished':
          if (payload['result'] == 'win' && !_won) {
            _won = true;
            widget.progress.recordMonsterPlanetWin(widget.fighterId);
          }
          break;
        case 'exit':
          _leaveGame();
          break;
      }
    } on FormatException {
      debugPrint('Ignored malformed Unity message: $message');
    }
  }

  void _leaveGame() {
    if (_leaving || !mounted) return;
    _leaving = true;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _loadingHintTimer?.cancel();
    unawaited(
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]),
    );
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showSlowHint =
        !_ready && (_loadingHintTimer == null || !_loadingHintTimer!.isActive);
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFF020612),
        body: Stack(
          fit: StackFit.expand,
          children: [
            EmbedUnity(onMessageFromUnity: _handleUnityMessage),
            if (!_ready)
              ColoredBox(
                color: const Color(0xF2020612),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.public_rounded,
                        color: Color(0xFF65D8FF),
                        size: 72,
                      ),
                      const SizedBox(height: 20),
                      CircularProgressIndicator(color: widget.fighterColor),
                      const SizedBox(height: 18),
                      Text(
                        '${widget.fighterName}正在降落怪兽星球…',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (showSlowHint) ...[
                        const SizedBox(height: 8),
                        const Text(
                          '第一次进入需要准备 3D 资源，请稍等',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            SafeArea(
              minimum: const EdgeInsets.all(10),
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton.filled(
                  key: const ValueKey('monster-planet-3d-back'),
                  onPressed: _leaveGame,
                  tooltip: '返回训练营',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xB80A1732),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
