import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import '../game_audio.dart';
import 'town_progress.dart';

class TownAudio {
  TownAudio(this.voice, this.progress, {bool native = true}) {
    if (native) {
      _music = AudioPlayer();
      _effects = List.generate(4, (_) => AudioPlayer());
    }
    voice.addListener(_sync);
    progress.addListener(_sync);
  }
  final GameAudioController voice;
  final TownProgress progress;
  AudioPlayer? _music;
  List<AudioPlayer> _effects = [];
  bool _closed = false,
      _active = true,
      _musicStarted = false,
      _speaking = false;
  int _channel = 0, _speechEpoch = 0;
  DateTime _lastSpeech = DateTime.fromMillisecondsSinceEpoch(0);
  final Map<String, DateTime> _words = {};
  String english = 'Hello, little friend!', meaning = '你好呀，小朋友！';
  Future<void> _commands = Future.value();
  Future<void> start() async {
    await progress.ready;
    _sync();
  }

  void _sync() {
    _commands = _commands.then((_) async {
      if (_closed) return;
      final enabled = _active && voice.enabled;
      try {
        if (enabled && progress.music) {
          await _music?.setVolume(_speaking ? .055 : .16);
          if (!_musicStarted) {
            await _music?.setReleaseMode(ReleaseMode.loop);
            await _music?.play(AssetSource('silly_town/audio/town_loop.wav'));
            _musicStarted = true;
          } else {
            await _music?.resume();
          }
        } else {
          await _music?.pause();
        }
        if (!enabled) {
          for (final p in _effects) {
            await p.stop();
          }
        }
      } catch (_) {
        /* Detached audio devices do not interrupt play. */
      }
    });
  }

  void effect(String name) {
    if (_closed || !_active || !voice.enabled || _effects.isEmpty) return;
    final p = _effects[_channel++ % _effects.length];
    unawaited(() async {
      try {
        await p.play(
          AssetSource('silly_town/audio/$name.wav'),
          volume: name == 'celebrate' ? .48 : .62,
        );
        if (_closed || !_active || !voice.enabled) await p.stop();
      } catch (_) {
        /* Optional sound device. */
      }
    }());
  }

  Future<void> say(
    String text,
    String chinese, {
    bool force = false,
    bool collect = true,
  }) async {
    if (_closed || !_active) return;
    english = text;
    meaning = chinese;
    final now = DateTime.now();
    if (!force &&
        (_speaking ||
            now.difference(_lastSpeech).inMilliseconds < 2100 ||
            now.difference(_words[text] ?? DateTime(2000)).inMilliseconds <
                6500)) {
      return;
    }
    if (!voice.enabled) return;
    if (collect) progress.encounter(text);
    _lastSpeech = now;
    _words[text] = now;
    final epoch = ++_speechEpoch;
    _speaking = true;
    _sync();
    await voice.speakEnglish(text);
    if (epoch == _speechEpoch) {
      _speaking = false;
      _sync();
    }
  }

  Future<void> guide(String chinese) async {
    if (_closed || !_active || !voice.enabled) return;
    final epoch = ++_speechEpoch;
    _speaking = true;
    _lastSpeech = DateTime.now();
    _sync();
    await voice.speak(chinese);
    if (epoch == _speechEpoch) {
      _speaking = false;
      _sync();
    }
  }

  void repeat() => unawaited(say(english, meaning, force: true));
  void active(bool value) {
    _active = value;
    if (!value) {
      _speechEpoch++;
      _speaking = false;
      unawaited(voice.stopSpeech());
    }
    _sync();
  }

  void dispose() {
    _closed = true;
    _speechEpoch++;
    voice.removeListener(_sync);
    progress.removeListener(_sync);
    unawaited(voice.stopSpeech());
    final players = [?_music, ..._effects];
    unawaited(
      _commands.whenComplete(() async {
        for (final player in players) {
          await player.dispose();
        }
      }),
    );
  }
}
