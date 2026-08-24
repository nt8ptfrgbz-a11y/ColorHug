import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GameSound { tap, correct, wrong, discover, complete }

class GameAudioController extends ChangeNotifier {
  GameAudioController._({this._speech, this._effects, this._preferences}) {
    if (_preferences != null) {
      _ready = _initialize();
      unawaited(_ready);
    }
  }

  factory GameAudioController.live() {
    return GameAudioController._(
      speech: FlutterTts(),
      effects: AudioPlayer(),
      preferences: SharedPreferencesAsync(),
    );
  }

  factory GameAudioController.silent() => GameAudioController._();

  static const _enabledKey = 'color_hug.audio_enabled';
  static const _soundFiles = <GameSound, String>{
    GameSound.tap: 'audio/tap.wav',
    GameSound.correct: 'audio/correct.wav',
    GameSound.wrong: 'audio/wrong.wav',
    GameSound.discover: 'audio/discover.wav',
    GameSound.complete: 'audio/complete.wav',
  };

  final FlutterTts? _speech;
  final AudioPlayer? _effects;
  final SharedPreferencesAsync? _preferences;
  bool _enabled = true;
  bool _disposed = false;
  Future<void> _ready = Future<void>.value();

  bool get enabled => _enabled;

  @visibleForTesting
  String? lastSpokenText;

  @visibleForTesting
  GameSound? lastSound;

  Future<void> _initialize() async {
    try {
      _enabled = await _preferences?.getBool(_enabledKey) ?? true;
      final speech = _speech;
      if (speech != null) {
        await speech.setLanguage('zh-CN');
        await speech.setSpeechRate(0.43);
        await speech.setPitch(1.08);
        await speech.setVolume(0.92);
        await speech.awaitSpeakCompletion(false);
      }
      if (!_disposed) notifyListeners();
    } catch (_) {
      // Audio is an enhancement; unavailable platform services never block play.
    }
  }

  Future<void> toggle() async {
    await _ready;
    if (_enabled) {
      _enabled = false;
      notifyListeners();
      await stopSpeech();
    } else {
      _enabled = true;
      notifyListeners();
      await announce('声音打开啦！', sound: GameSound.correct);
    }
    try {
      await _preferences?.setBool(_enabledKey, _enabled);
    } catch (_) {
      // Keep the in-memory setting if persistence is unavailable.
    }
  }

  Future<void> speak(String text) async {
    await _ready;
    if (!_enabled || text.trim().isEmpty) return;
    lastSpokenText = text;
    final speech = _speech;
    if (speech == null) return;
    try {
      await speech.stop();
      await speech.speak(text);
    } catch (_) {
      // Some simulators do not have an installed Chinese system voice.
    }
  }

  Future<void> play(GameSound sound) async {
    await _ready;
    if (!_enabled) return;
    lastSound = sound;
    final effects = _effects;
    final file = _soundFiles[sound];
    if (effects == null || file == null) return;
    try {
      await effects.play(AssetSource(file));
    } catch (_) {
      // Missing audio output should not interrupt the game.
    }
  }

  Future<void> announce(String text, {GameSound sound = GameSound.tap}) async {
    if (!_enabled) return;
    await play(sound);
    if (_speech != null || _effects != null) {
      await Future<void>.delayed(const Duration(milliseconds: 90));
    }
    await speak(text);
  }

  Future<void> stopSpeech() async {
    try {
      await _speech?.stop();
    } catch (_) {
      // The speech engine may already have been detached.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(stopSpeech());
    unawaited(_effects?.dispose());
    super.dispose();
  }
}

class AudioToggleButton extends StatelessWidget {
  const AudioToggleButton({
    super.key,
    required this.audio,
    this.foregroundColor,
    this.backgroundColor,
  });

  final GameAudioController audio;
  final Color? foregroundColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: audio,
      builder: (context, _) {
        return Semantics(
          button: true,
          label: audio.enabled ? '关闭声音' : '打开声音',
          child: IconButton.filledTonal(
            key: const ValueKey('audio-toggle'),
            onPressed: audio.toggle,
            tooltip: audio.enabled ? '关闭声音' : '打开声音',
            color: foregroundColor,
            style: IconButton.styleFrom(backgroundColor: backgroundColor),
            icon: Icon(
              audio.enabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
            ),
          ),
        );
      },
    );
  }
}

class RepeatVoiceButton extends StatelessWidget {
  const RepeatVoiceButton({
    super.key,
    required this.audio,
    required this.text,
    this.foregroundColor,
    this.backgroundColor,
  });

  final GameAudioController audio;
  final String text;
  final Color? foregroundColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '再听一遍',
      child: IconButton.filledTonal(
        key: const ValueKey('repeat-voice'),
        onPressed: audio.enabled
            ? () => audio.announce(text, sound: GameSound.tap)
            : audio.toggle,
        tooltip: audio.enabled ? '再听一遍' : '打开声音',
        color: foregroundColor,
        style: IconButton.styleFrom(backgroundColor: backgroundColor),
        icon: Icon(
          audio.enabled
              ? Icons.record_voice_over_rounded
              : Icons.volume_off_rounded,
        ),
      ),
    );
  }
}

class NarrateOnMount extends StatefulWidget {
  const NarrateOnMount({
    super.key,
    required this.audio,
    required this.text,
    required this.child,
  });

  final GameAudioController audio;
  final String text;
  final Widget child;

  @override
  State<NarrateOnMount> createState() => _NarrateOnMountState();
}

class _NarrateOnMountState extends State<NarrateOnMount> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(widget.audio.speak(widget.text));
    });
  }

  @override
  void dispose() {
    unawaited(widget.audio.stopSpeech());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
