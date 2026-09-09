import 'package:color_hug/game_audio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('英语启蒙先讲引导再读英文，后续中文恢复中文语言', () async {
    final audio = GameAudioController.silent();
    addTearDown(audio.dispose);
    await audio.speakLesson('听一听苹果的英语。', 'Apple');
    expect(audio.lastSpokenText, 'Apple');
    expect(audio.lastLanguage, GameLanguage.english);
    await audio.speak('再来做一杯吧！');
    expect(audio.lastLanguage, GameLanguage.chinese);
  });

  test('新提示和静音取消尚未完成的双语引导', () async {
    final audio = GameAudioController.silent();
    addTearDown(audio.dispose);
    final obsolete = audio.speakLesson('旧的提示', 'Old');
    final current = audio.speakEnglish('New');
    await Future.wait([obsolete, current]);
    expect(audio.lastSpokenText, 'New');
    await audio.toggle();
    await audio.speakLesson('不要播放', 'Muted');
    expect(audio.lastSpokenText, 'New');
  });

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
