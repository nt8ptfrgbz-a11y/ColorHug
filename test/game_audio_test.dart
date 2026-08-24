import 'package:color_hug/game_audio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('静音测试控制器会记录语音与音效意图', () async {
    final audio = GameAudioController.silent();
    addTearDown(audio.dispose);

    await audio.announce('找到了黄色！', sound: GameSound.correct);

    expect(audio.lastSpokenText, '找到了黄色！');
    expect(audio.lastSound, GameSound.correct);
  });

  test('关闭声音后不播放，重新打开会给出语音确认', () async {
    final audio = GameAudioController.silent();
    addTearDown(audio.dispose);

    await audio.toggle();
    expect(audio.enabled, isFalse);
    await audio.announce('不应该播放', sound: GameSound.wrong);
    expect(audio.lastSpokenText, isNull);

    await audio.toggle();
    expect(audio.enabled, isTrue);
    expect(audio.lastSpokenText, '声音打开啦！');
    expect(audio.lastSound, GameSound.correct);
  });
}
