import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum GameSound { tap, correct, wrong, discover, complete }

/// Distinct in-game speaking styles. Hero and monster are original character
/// treatments; they do not imitate a specific performer.
enum GameVoice { narrator, hero, monster }

const _speechProfiles =
    <GameVoice, ({double rate, double pitch, double volume})>{
      GameVoice.narrator: (rate: 0.54, pitch: 1.02, volume: 0.96),
      GameVoice.hero: (rate: 0.51, pitch: 0.84, volume: 1.00),
      GameVoice.monster: (rate: 0.47, pitch: 0.58, volume: 1.00),
    };

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
  int _speechRequest = 0;
  Future<void> _ready = Future<void>.value();
  final Map<GameVoice, Map<String, String>> _preferredVoices = {};

  bool get enabled => _enabled;

  @visibleForTesting
  String? lastSpokenText;

  @visibleForTesting
  GameVoice? lastVoice;

  @visibleForTesting
  GameSound? lastSound;

  Future<void> _initialize() async {
    try {
      _enabled = await _preferences?.getBool(_enabledKey) ?? true;
      final speech = _speech;
      if (speech != null) {
        await speech.setLanguage('zh-CN');
        await _loadPreferredVoices(speech);
        await _applyVoiceProfile(speech, GameVoice.narrator);
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

  Future<void> speak(
    String text, {
    GameVoice voice = GameVoice.narrator,
  }) async {
    final request = ++_speechRequest;
    await _ready;
    if (!_enabled || text.trim().isEmpty) return;
    lastSpokenText = text;
    lastVoice = voice;
    final speech = _speech;
    if (speech == null) return;
    try {
      await speech.stop();
      if (request != _speechRequest || !_enabled) return;
      await _applyVoiceProfile(speech, voice);
      if (request != _speechRequest || !_enabled) return;
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

  Future<void> announce(
    String text, {
    GameSound sound = GameSound.tap,
    GameVoice voice = GameVoice.narrator,
  }) async {
    if (!_enabled) return;
    await play(sound);
    if (_speech != null || _effects != null) {
      await Future<void>.delayed(const Duration(milliseconds: 90));
    }
    await speak(text, voice: voice);
  }

  Future<void> stopSpeech() async {
    _speechRequest++;
    try {
      await _speech?.stop();
    } catch (_) {
      // The speech engine may already have been detached.
    }
  }

  Future<void> _loadPreferredVoices(FlutterTts speech) async {
    try {
      final rawVoices = await speech.getVoices;
      if (rawVoices is! List) return;
      final voices = rawVoices
          .whereType<Map>()
          .map(
            (voice) => voice.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            ),
          )
          .toList(growable: false);
      for (final role in GameVoice.values) {
        final voice = preferredVoiceFor(voices, role);
        if (voice != null) _preferredVoices[role] = voice;
      }
    } catch (_) {
      // The platform default Chinese voice remains available as a fallback.
    }
  }

  Future<void> _applyVoiceProfile(FlutterTts speech, GameVoice voice) async {
    final selected = _preferredVoices[voice];
    var appliedSelectedVoice = false;
    if (selected != null) {
      try {
        final identifier = selected['identifier'];
        if (identifier != null && identifier.isNotEmpty) {
          await speech.setVoice({'identifier': identifier});
          appliedSelectedVoice = true;
        } else {
          final name = selected['name'];
          final locale = selected['locale'];
          if (name != null && locale != null) {
            await speech.setVoice({'name': name, 'locale': locale});
            appliedSelectedVoice = true;
          }
        }
      } catch (_) {
        // Fall back to the platform's default Mandarin voice below.
      }
    }
    if (!appliedSelectedVoice) {
      try {
        await speech.setLanguage('zh-CN');
      } catch (_) {
        // Continue applying the remaining supported speech parameters.
      }
    }
    final profile = _speechProfiles[voice]!;
    try {
      await speech.setSpeechRate(profile.rate);
    } catch (_) {
      // Keep the platform rate when this setting is unsupported.
    }
    try {
      await speech.setPitch(profile.pitch);
    } catch (_) {
      // Keep the platform pitch when this setting is unsupported.
    }
    try {
      await speech.setVolume(profile.volume);
    } catch (_) {
      // Keep the platform volume when this setting is unsupported.
    }
  }

  @visibleForTesting
  static Map<String, String>? preferredVoiceFor(
    List<Map<String, String>> voices,
    GameVoice role,
  ) {
    final chineseVoices = voices.where((voice) {
      final locale = (voice['locale'] ?? '').toLowerCase().replaceAll('_', '-');
      return locale == 'zh' || locale.startsWith('zh-');
    });
    if (chineseVoices.isEmpty) return null;

    Map<String, String>? best;
    var bestScore = -1;
    for (final voice in chineseVoices) {
      final score = _voiceScore(voice, role);
      if (score > bestScore) {
        best = voice;
        bestScore = score;
      }
    }
    return best;
  }

  static int _voiceScore(Map<String, String> voice, GameVoice role) {
    final locale = (voice['locale'] ?? '').toLowerCase().replaceAll('_', '-');
    final name = (voice['name'] ?? '').toLowerCase();
    final quality = (voice['quality'] ?? '').toLowerCase();
    final gender = (voice['gender'] ?? '').toLowerCase();
    var score = locale.startsWith('zh-cn') || locale.contains('hans') ? 90 : 30;

    score += switch (quality) {
      'premium' => 500,
      'enhanced' => 400,
      'very high' => 330,
      'high' => 260,
      'default' || 'normal' => 140,
      'low' => 60,
      'very low' => 20,
      _ => 100,
    };

    const preferredNames = <GameVoice, List<String>>{
      GameVoice.narrator: [
        'tingting',
        'xiaoxiao',
        'xiaoyi',
        'sandy',
        'flo',
        'shelley',
        'meijia',
      ],
      GameVoice.hero: [
        'eddy',
        'reed',
        'yunxi',
        'yunyang',
        'kangkang',
        'rocko',
        'grandpa',
      ],
      GameVoice.monster: ['rocko', 'grandpa', 'eddy', 'reed', 'yunyang'],
    };
    final names = preferredNames[role]!;
    final preferredIndex = names.indexWhere(name.contains);
    if (preferredIndex >= 0) score += 240 - preferredIndex * 22;

    if (role == GameVoice.narrator && gender.contains('female')) score += 25;
    if (role != GameVoice.narrator && gender.contains('male')) score += 55;
    if (voice['network_required'] == '0') score += 15;
    return score;
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
    this.voice = GameVoice.narrator,
    this.foregroundColor,
    this.backgroundColor,
  });

  final GameAudioController audio;
  final String text;
  final GameVoice voice;
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
            ? () => audio.announce(text, sound: GameSound.tap, voice: voice)
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
    this.voice = GameVoice.narrator,
  });

  final GameAudioController audio;
  final String text;
  final Widget child;
  final GameVoice voice;

  @override
  State<NarrateOnMount> createState() => _NarrateOnMountState();
}

class _NarrateOnMountState extends State<NarrateOnMount> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(widget.audio.speak(widget.text, voice: widget.voice));
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
