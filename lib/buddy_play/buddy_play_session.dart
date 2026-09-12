import 'dart:async';
import 'package:flutter/material.dart';
import '../game_audio.dart';
import '../island_progress.dart';
import 'buddy_play_catalog.dart';

class PlaySpeech {
  PlaySpeech(this.game, this.audio, this.progress, {this.timeSource});
  final int Function()? timeSource;
  int get now => timeSource?.call() ?? clock.elapsedMilliseconds;
  final BuddyPlay game;
  final GameAudioController audio;
  final IslandProgress progress;
  final Stopwatch clock = Stopwatch()..start();
  final Map<String, int> _recent = {};
  int _last = -10000;
  bool _busy = false, _closed = false;
  int _generation = 0;
  String english = '', chinese = '';

  void say(String word, String meaning, {String? phrase, bool force = false}) {
    if (_closed) return;
    english = phrase ?? word;
    chinese = meaning;
    progress.encounterPlayWord(game, word);
    final now = this.now;
    if (!force &&
        (_busy ||
            now - _last < 2200 ||
            now - (_recent[word] ?? -10000) < 6500)) {
      return;
    }
    _last = now;
    _recent[word] = now;
    final generation = ++_generation;
    _busy = true;
    unawaited(
      audio.speakEnglish(english).whenComplete(() {
        if (generation == _generation) _busy = false;
      }),
    );
  }

  void repeat() {
    if (_closed || english.isEmpty) return;
    final generation = ++_generation;
    _busy = true;
    _last = now;
    unawaited(
      audio.speakEnglish(english).whenComplete(() {
        if (generation == _generation) _busy = false;
      }),
    );
  }

  void stop() {
    _generation++;
    _busy = false;
    unawaited(audio.stopSpeech());
  }

  void dispose() {
    _closed = true;
    stop();
    clock.stop();
  }
}

abstract class ToyModel extends ChangeNotifier {
  final List<
    ({
      String word,
      String meaning,
      String? phrase,
      GameSound? sound,
      String? discovery,
    })
  >
  _events = [];
  List<
    ({
      String word,
      String meaning,
      String? phrase,
      GameSound? sound,
      String? discovery,
    })
  >
  takeEvents() {
    final events = List.of(_events);
    _events.clear();
    return events;
  }

  void event(
    String word,
    String meaning, {
    String? phrase,
    GameSound? sound,
    String? discovery,
  }) {
    if (_events.length < 12) {
      _events.add((
        word: word,
        meaning: meaning,
        phrase: phrase,
        sound: sound,
        discovery: discovery,
      ));
    }
  }

  void step(double dt);
  Map<String, dynamic> toJson();
  void restore(Map<String, dynamic> data);
  void pause() {}
}
