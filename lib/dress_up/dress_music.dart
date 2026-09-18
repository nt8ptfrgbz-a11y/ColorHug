import 'package:audioplayers/audioplayers.dart';

/// Serial playback operations prevent a late asset load from restarting music
/// after the child has left the wardrobe or the app has entered the background.
class DressMusic {
  DressMusic({this.native = true});
  final bool native;
  AudioPlayer? _player;
  Future<void> _queue = Future.value();
  bool _disposed = false,
      _playing = false,
      _wanted = false,
      _started = false,
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
        final player = _player ??= AudioPlayer();
        await player.setVolume(_ducked ? .04 : .12);
        if (_wanted && !_playing) {
          await player.setReleaseMode(ReleaseMode.loop);
          if (_started) {
            await player.resume();
          } else {
            await player.play(
              AssetSource('dress_up/audio/wardrobe_waltz.wav'),
              volume: _ducked ? .04 : .12,
            );
            _started = true;
          }
          _playing = true;
        } else if (!_wanted && _playing) {
          await player.pause();
          _playing = false;
        }
      } catch (_) {
        _playing = false;
      }
    });
  }

  void dispose() {
    _disposed = true;
    _queue = _queue.then((_) async {
      try {
        await _player?.dispose();
      } catch (_) {}
    });
  }
}
