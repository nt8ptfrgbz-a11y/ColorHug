import 'package:color_hug/game_audio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('静音测试控制器会记录语音与音效意图', () async {
    final audio = GameAudioController.silent();
    addTearDown(audio.dispose);

    await audio.announce(
      '找到了黄色！',
      sound: GameSound.correct,
      voice: GameVoice.hero,
    );

    expect(audio.lastSpokenText, '找到了黄色！');
    expect(audio.lastSound, GameSound.correct);
    expect(audio.lastVoice, GameVoice.hero);
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

  test('自动优先选择增强版中文音色并区分英雄与怪兽角色', () {
    final voices = <Map<String, String>>[
      {
        'name': 'Tingting',
        'locale': 'zh-CN',
        'quality': 'enhanced',
        'gender': 'female',
      },
      {
        'name': 'Xiaoxiao',
        'locale': 'zh-CN',
        'quality': 'enhanced',
        'gender': 'female',
      },
      {
        'name': 'Eddy',
        'locale': 'zh-CN',
        'quality': 'enhanced',
        'gender': 'male',
      },
      {
        'name': 'Rocko',
        'locale': 'zh-CN',
        'quality': 'enhanced',
        'gender': 'male',
      },
      {'name': 'English Voice', 'locale': 'en-US', 'quality': 'premium'},
    ];

    expect(
      GameAudioController.preferredVoiceFor(
        voices,
        GameVoice.narrator,
      )?['name'],
      'Tingting',
    );
    expect(
      GameAudioController.preferredVoiceFor(voices, GameVoice.child)?['name'],
      'Xiaoxiao',
    );
    expect(
      GameAudioController.preferredVoiceFor(voices, GameVoice.hero)?['name'],
      'Eddy',
    );
    expect(
      GameAudioController.preferredVoiceFor(voices, GameVoice.monster)?['name'],
      'Rocko',
    );
    expect(
      GameAudioController.speechProfileFor(GameVoice.child).volume,
      lessThan(GameAudioController.speechProfileFor(GameVoice.hero).volume),
    );
  });
}
