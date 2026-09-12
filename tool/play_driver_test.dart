import 'dart:io';
import 'package:flutter_driver/flutter_driver.dart';

Future<void> main() async {
  final driver = await FlutterDriver.connect();
  final directory = Directory(
    Platform.environment['PLAY_SMOKE_DIR'] ?? 'build/play-native-smoke',
  )..createSync(recursive: true);
  Future<void> tap(String key) async {
    await driver.scrollIntoView(find.byValueKey(key));
    stdout.writeln('NATIVE TAP $key');
    await driver.tap(
      find.byValueKey(key),
      timeout: const Duration(seconds: 20),
    );
    await Future<void>.delayed(const Duration(milliseconds: 700));
  }

  try {
    await driver.runUnsynchronized(() async {
      await tap('island-map');
      await tap('activity-buddy');
      for (final entry in {
        'rolling': ['rolling-launch', 'rolling-part-1', 'rolling-launch'],
        'salon': ['salon-color', 'salon-decor', 'salon-mirror'],
        'water': [
          'water-pipe-1',
          'water-pipe-2',
          'water-pipe-2',
          'water-tap',
          'water-plug',
        ],
        'delivery': ['delivery-box-0', 'delivery-drive', 'delivery-horn'],
        'squishy': ['squishy-stamp', 'squishy-color'],
        'soundTrain': ['train-speed', 'train-start'],
        'shadows': ['shadows-hat', 'shadows-near', 'shadows-peek'],
        'tinyWorld': ['world-rain'],
      }.entries) {
        await tap('buddy-play-${entry.key}');
        for (final action in entry.value) {
          await tap(action);
        }
        await Future<void>.delayed(const Duration(seconds: 2));
        await File(
          '${directory.path}/${entry.key}.png',
        ).writeAsBytes(await driver.screenshot());
        await tap('play-collect');
        await tap('play-album');
        await driver.tap(find.text('小创作 1'));
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await tap('play-back');
        stdout.writeln(
          'NATIVE PASS ${entry.key}: navigation, interaction, screenshot, collection and return',
        );
      }
    });
  } finally {
    await driver.close();
  }
}
