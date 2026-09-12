import 'dart:convert';
import 'dart:io';
import 'package:flutter_driver/flutter_driver.dart';

Future<void> main() async {
  final d = await FlutterDriver.connect();
  final output = Directory('build/island-native')..createSync(recursive: true);
  Future<void> tap(String key) async {
    await d.tap(find.byValueKey(key), timeout: const Duration(seconds: 20));
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  Future<Map> state() async {
    for (var i = 0; i < 20; i++) {
      final raw = await d.requestData('state');
      if (raw != 'no-scene') return jsonDecode(raw) as Map;
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    throw StateError('The gameplay scene is not mounted');
  }

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
      await touch('right', 15000);
      require((await state())['region'] == 'orchard', 'Orchard not reached');
      await touch('right', 5000);
      await shot('07-orchard');
      await touch('stone', 4000);
      await touch('right', 4800);
      await touch('tree', 80);
      await Future<void>.delayed(const Duration(seconds: 2));
      for (var i = 0; i < 4; i++) {
        await touch('apple-$i', 80);
      }
      require((await state())['basket'] == 4, 'Apples not collected');
      await touch('share', 80);
      await touch('basket', 80);
      await shot('08-picnic');
      await touch('right', 10000);
      require((await state())['region'] == 'cave', 'Cave not reached');
      await touch('right', 9000);
      await touch('mural', 80);
      await Future<void>.delayed(const Duration(seconds: 2));
      await shot('09-cave');
      await touch('lever', 80);
      await Future<void>.delayed(const Duration(seconds: 2));
      await touch('lamp', 80);
      await touch('right', 9000);
      require((await state())['region'] == 'bay', 'Bay not reached');
      await touch('right', 7000);
      await touch('perch', 80);
      await Future<void>.delayed(const Duration(seconds: 2));
      await shot('10-rescue');
      await touch('landing', 80);
      await Future<void>.delayed(const Duration(seconds: 2));
      await touch('right', 9000);
      await touch('rope', 80);
      await Future<void>.delayed(const Duration(seconds: 4));
      await touch('right', 3000);
      await touch('rope', 80);
      await Future<void>.delayed(const Duration(seconds: 3));
      await shot('11-sailing');
      await Future<void>.delayed(const Duration(seconds: 9));
      require((await state())['region'] == 'valley', 'Ferry did not return');
      await touch('left', 4000);
      await Future<void>.delayed(const Duration(seconds: 3));
      require(
        (await state())['story']['celebrated'] == true,
        'Reunion not complete',
      );
      await shot('12-reunion');
      await tap('expedition-back');
      await d.scrollIntoView(find.byValueKey('buddy-expedition'));
      await tap('buddy-expedition');
      await d.waitFor(find.byValueKey('expedition-world'));
      await Future<void>.delayed(const Duration(seconds: 2));
      require(
        (await state())['story']['celebrated'] == true,
        'Story checkpoint not restored',
      );
      await shot('08-restored');
      stdout.writeln(
        'NATIVE PASS: complete four-region adventure, ferry, reunion and restore',
      );
    });
  } finally {
    await d.close();
  }
}
