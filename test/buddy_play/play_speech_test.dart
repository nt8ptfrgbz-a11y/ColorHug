import 'package:flutter_test/flutter_test.dart';
import 'package:color_hug/game_audio.dart';
import 'package:color_hug/island_progress.dart';
import 'package:color_hug/buddy_play/buddy_play_catalog.dart';
import 'package:color_hug/buddy_play/buddy_play_session.dart';

void main() {
  test('英文情境词冷却、同词去重、显式重听和退出取消', () async {
    final audio = GameAudioController.silent();
    final progress = IslandProgress();
    var now = 0;
    final speech = PlaySpeech(
      BuddyPlay.rolling,
      audio,
      progress,
      timeSource: () => now,
    );
    Future<void> settle() => Future<void>.delayed(Duration.zero);
    speech.say('ball', '小球', phrase: 'A ball!');
    await settle();
    expect(audio.lastLanguage, GameLanguage.english);
    expect(audio.lastSpokenText, 'A ball!');
    now = 500;
    speech.say('big', '大', phrase: 'Big!');
    await settle();
    expect(audio.lastSpokenText, 'A ball!');
    expect(progress.buddyWords, containsAll(['ball', 'big']));
    speech.repeat();
    await settle();
    expect(audio.lastSpokenText, 'Big!');
    now = 3000;
    speech.say('ball', '小球');
    await settle();
    expect(audio.lastSpokenText, 'Big!');
    now = 7000;
    speech.say('ball', '小球');
    await settle();
    expect(audio.lastSpokenText, 'ball');
    await audio.toggle();
    speech.say('small', '小', force: true);
    await settle();
    expect(audio.lastSpokenText, 'ball');
    speech.dispose();
    speech.say('roll', '滚', force: true);
    await settle();
    expect(audio.lastSpokenText, 'ball');
    progress.dispose();
    audio.dispose();
  });
}
