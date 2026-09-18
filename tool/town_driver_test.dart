import 'dart:convert';
import 'dart:io';
import 'package:flutter_driver/flutter_driver.dart';

Future<void> main() async {
  final d = await FlutterDriver.connect();
  final out = Directory('build/town-native')..createSync(recursive: true);
  Future<Map> state() async => jsonDecode(await d.requestData('state')) as Map;
  Future<void> tap(String key) async {
    await d.tap(find.byValueKey(key));
    await Future<void>.delayed(const Duration(milliseconds: 550));
  }

  Future<void> shot(String name) async {
    await File('${out.path}/$name.png').writeAsBytes(await d.screenshot());
  }

  try {
    await d.runUnsynchronized(() async {
      await tap('town-start');
      await Future<void>.delayed(const Duration(seconds: 3));
      await shot('01-sun');
      for (var i = 0; i < 8; i++) {
        await d.requestData(jsonEncode({'from': 'actor'}));
      }
      if ((await state())['finished'] != true) {
        throw StateError('Sun was not awakened by pointer events');
      }
      await Future<void>.delayed(const Duration(seconds: 5));
      await shot('02-rainbow');
      await tap('town-repeat-english');
      await Future<void>.delayed(const Duration(seconds: 3));
      if ((await state())['language'] != 'english') {
        throw StateError('English voice not selected');
      }
      await tap('town-back');
      await d.scrollIntoView(find.byValueKey('town-district-1'));
      await tap('town-district-1');
      await tap('town-level-5');
      for (var i = 0; i < 3; i++) {
        await d.requestData(jsonEncode({'from': 'slot$i', 'to': 'actor'}));
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      if ((await state())['finished'] != true) {
        throw StateError('Fruit dragging did not complete');
      }
      await shot('03-fruit');
      await tap('town-back');
      await d.scrollIntoView(find.byValueKey('town-district-2'));
      await tap('town-district-2');
      await tap('town-level-11');
      await d.requestData(jsonEncode({'hold': 2300}));
      await shot('04-bubbles');
      await d.requestData(jsonEncode({'hold': 2000}));
      await Future<void>.delayed(const Duration(seconds: 5));
      final finalState = await state();
      if (finalState['finished'] != true) {
        throw StateError('Bubble hold did not complete');
      }
      if ((finalState['completed'] as List).length != 3) {
        throw StateError('Native journal did not record all scenes');
      }
      stdout.writeln('NATIVE PASS $finalState');
      await tap('town-back');
      await d.scroll(
        find.byValueKey('town-home-scroll'),
        0,
        1500,
        const Duration(milliseconds: 600),
      );
      await tap('town-album');
      await shot('05-words');
      stdout.writeln('NATIVE ALBUM PASS');
    });
  } finally {
    await d.close();
  }
}
