import 'dart:convert';
import 'dart:io';
import 'package:flutter_driver/flutter_driver.dart';

Future<void> main() async {
  final driver = await FlutterDriver.connect();
  Future<Map> state() async =>
      jsonDecode(await driver.requestData('state')) as Map;
  Future<void> tap(String key) async {
    await driver.tap(find.byValueKey(key));
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  Future<void> waitPhase(String phase, {int seconds = 12}) async {
    for (var i = 0; i < seconds * 2; i++) {
      if ((await state())['phase'] == phase) return;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    throw StateError('Phase $phase not reached: ${await state()}');
  }

  try {
    await driver.runUnsynchronized(() async {
      await driver.waitFor(find.byValueKey('shan-stage-touch'));
      for (final point in [
        [.28, .68],
        [.5, .77],
        [.73, .65],
      ]) {
        await driver.requestData(jsonEncode({'x': point[0], 'y': point[1]}));
      }
      await waitPhase('companion');
      await tap('shan-feed');
      await tap('shan-pet');
      if ((await state())['feeds'] != 1) {
        throw StateError('Native UI did not accept feeding');
      }
      await tap('shan-realm-stars');
      await tap('shan-fly');
      await waitPhase('flying');
      await tap('shan-right');
      await tap('shan-left');
      await tap('shan-journal');
      final paused = (await state())['flight'];
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if ((await state())['flight'] != paused) {
        throw StateError('Flight moved behind journal');
      }
      await tap('shan-close-journal');
      stdout.writeln('AFTER JOURNAL ${await state()}');
      await waitPhase('arrival', seconds: 65);
      await tap('shan-return');
      await waitPhase('companion');
      final result = await state();
      if (result['flights'] != 1) {
        throw StateError('Flight completion was not recorded');
      }
      final out = Directory('build/shanhai-native')
        ..createSync(recursive: true);
      await File('${out.path}/result.json').writeAsString(jsonEncode(result));
      stdout.writeln(
        'NATIVE PASS: wake through real pointers, feed, pet, realm, flight, journal pause and arrival: $result',
      );
    });
  } finally {
    await driver.close();
  }
}
