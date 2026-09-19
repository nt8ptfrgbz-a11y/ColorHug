import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class ShanhaiSound {
  ShanhaiSound({this.native = true});
  final bool native;
  AudioPlayer? _music, _effect;
  Future<void> _queue = Future.value();
  bool _wanted = false,
      _playing = false,
      _started = false,
      _disposed = false,
      _ducked = false;
  void duck(bool value) {
    _ducked = value;
    active(_wanted);
  }

  void active(bool value) {
    _wanted = value;
    if (!native || _disposed) return;
    _queue = _queue.then((_) async {
      if (_disposed) return;
      try {
        final player = _music ??= AudioPlayer();
        await player.setVolume(_ducked ? .035 : .11);
        if (_wanted && !_playing) {
          await player.setReleaseMode(ReleaseMode.loop);
          if (_started) {
            await player.resume();
          } else {
            await player.play(
              AssetSource('shanhai/audio/realm.wav'),
              volume: _ducked ? .035 : .11,
            );
            _started = true;
          }
          _playing = true;
        } else if (!_wanted) {
          if (_playing) await player.pause();
          _playing = false;
          await _effect?.stop();
        }
      } catch (_) {
        _playing = false;
      }
    });
  }

  void effect(String name) {
    if (!native || _disposed || !_wanted) return;
    _queue = _queue.then((_) async {
      if (_disposed || !_wanted) return;
      try {
        await (_effect ??= AudioPlayer()).play(
          AssetSource('shanhai/audio/$name.wav'),
          volume: .36,
        );
      } catch (_) {}
    });
  }

  void dispose() {
    _disposed = true;
    unawaited(
      _queue.then((_) async {
        try {
          await _music?.dispose();
          await _effect?.dispose();
        } catch (_) {}
      }),
    );
  }
}
