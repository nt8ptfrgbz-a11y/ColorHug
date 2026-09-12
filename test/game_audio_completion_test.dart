import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:color_hug/game_audio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('原生完成后才读下一种语言；取消旧句不会悬挂或串入旧英文', () async {
    final tts = FlutterTts();
    final spoken = <String>[];
    final languages = <String>[];
    var active = false;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(const MethodChannel('flutter_tts'), (
      call,
    ) async {
      switch (call.method) {
        case 'getVoices':
          return <Map<String, String>>[];
        case 'setLanguage':
          languages.add(call.arguments as String);
        case 'speak':
          spoken.add(call.arguments as String);
          active = true;
        case 'stop':
          if (active) {
            active = false;
            await tts.platformCallHandler(const MethodCall('speak.onCancel'));
          }
      }
      return 1;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(
        const MethodChannel('flutter_tts'),
        null,
      ),
    );
    final audio = GameAudioController.withSpeech(tts);
    Future<void> settle() => Future<void>.delayed(Duration.zero);
    final lesson = audio.speakLesson('先听中文', 'A little ball!');
    await settle();
    expect(spoken, ['先听中文']);
    active = false;
    await tts.platformCallHandler(const MethodCall('speak.onComplete'));
    await settle();
    expect(spoken, ['先听中文', 'A little ball!']);
    expect(languages.last, 'en-US');
    final next = audio.speakLesson('新的提示', 'New!');
    await settle();
    expect(spoken.last, '新的提示');
    await lesson;
    await audio.stopSpeech();
    await next;
    expect(spoken, isNot(contains('New!')));
    final fresh = audio.speakEnglish('Hello!');
    await settle();
    expect(spoken.last, 'Hello!');
    active = false;
    await tts.platformCallHandler(const MethodCall('speak.onComplete'));
    await fresh;
    await audio.toggle();
    final count = spoken.length;
    await audio.speakEnglish('Muted');
    expect(spoken.length, count);
    audio.dispose();
    await settle();
  });
  test('静音和停止使排队的音效失效', () async {
    final audio = GameAudioController.silent();
    final pending = audio.play(GameSound.bell);
    await audio.stopEffects();
    await pending;
    expect(audio.lastSound, isNull);
    audio.dispose();
  });
}
