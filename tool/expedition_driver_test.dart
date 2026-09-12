import 'dart:convert';
import 'dart:io';
import 'package:flutter_driver/flutter_driver.dart';

Future<void> main() async {
  final d = await FlutterDriver.connect();
  final output = Directory('build/expedition-native')
    ..createSync(recursive: true);
  Future<void> tap(String key) async {
    await d.tap(find.byValueKey(key), timeout: const Duration(seconds: 20));
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  Future<Map> state() async => jsonDecode(await d.requestData('state')) as Map;
  Future<void> shot(String name) async {
    await File('${output.path}/$name.png').writeAsBytes(await d.screenshot());
    stdout.writeln('NATIVE SHOT $name ${await state()}');
  }

  Future<void> touch(String target, int ms) async {
    stdout.writeln(
      'NATIVE POINTER $target: ${await d.requestData(jsonEncode({'target': target, 'ms': ms}), timeout: Duration(milliseconds: ms + 15000))}',
    );
  }

  void require(bool condition, String message) {
    if (!condition) throw StateError(message);
  }

  try {
    await d.runUnsynchronized(() async {
      await tap('island-map');
      await d.scrollIntoView(find.byValueKey('activity-buddy'));
      await tap('activity-buddy');
      await d.scrollIntoView(find.byValueKey('buddy-expedition'));
      await tap('buddy-expedition');
      await d.waitFor(find.byValueKey('expedition-world'));
      await Future<void>.delayed(const Duration(seconds: 2));
      await shot('01-camp');
      await touch('right', 3000);
      await shot('02-puddle');
      await touch('right', 12000);
      require((await state())['car'] == 1130.0, 'River stop not reached');
      await shot('03-river');
      await touch('log', 80);
      require((await state())['log'] == 'hook', 'Log was not picked up');
      await shot('04-pick');
      await touch('bridge', 80);
      await Future<void>.delayed(const Duration(seconds: 10));
      require((await state())['bridge'] == true, 'Bridge not placed');
      await shot('05-bridge');
      await touch('dino', 80);
      await Future<void>.delayed(const Duration(seconds: 2));
      require((await state())['joined'] == true, 'Companion not invited');
      await shot('06-riding');
      await touch('left', 16000);
      await Future<void>.delayed(const Duration(seconds: 3));
      require((await state())['home'] == true, 'Home outcome not reached');
      await shot('07-home');
      await d.requestData(jsonEncode({'target': 'finish'}));
      await tap('expedition-back');
      await d.scrollIntoView(find.byValueKey('buddy-expedition'));
      await tap('buddy-expedition');
      await d.waitFor(find.byValueKey('expedition-world'));
      await Future<void>.delayed(const Duration(seconds: 2));
      require((await state())['home'] == true, 'Checkpoint not restored');
      await shot('08-restored');
      stdout.writeln(
        'NATIVE PASS: raw-pointer driving, grab, bridge, invite, return home and restore',
      );
    });
  } finally {
    await d.close();
  }
}
