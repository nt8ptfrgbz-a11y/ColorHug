import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:color_hug/game_audio.dart';
import 'package:color_hug/silly_town/town_art.dart';
import 'package:color_hug/silly_town/town_model.dart';
import 'package:color_hug/silly_town/town_progress.dart';
import 'package:color_hug/silly_town/town_screen.dart';

void main() {
  late final GameAudioController audio;
  late final TownProgress progress;
  var pointer = 600;
  enableFlutterDriverExtension(
    handler: (request) async {
      TownScenePainter? scene;
      RenderBox? box;
      void visit(Element e) {
        if (e.widget case CustomPaint(
          painter: final TownScenePainter painter,
        )) {
          scene = painter;
          box = e.findRenderObject() as RenderBox?;
        }
        e.visitChildren(visit);
      }

      WidgetsBinding.instance.rootElement?.visitChildren(visit);
      final m = scene?.model;
      if (m == null) {
        return jsonEncode({
          'scene': false,
          'completed': progress.completed.toList(),
          'words': progress.words.toList(),
        });
      }
      if (request != null && request.startsWith('{')) {
        final command = jsonDecode(request) as Map;
        final l = TownLayout(box!.size);
        Offset point(String key) => key.startsWith('slot')
            ? l.slot(int.parse(key.substring(4)))
            : l.actor;
        final from = box!.localToGlobal(
          point(command['from'] as String? ?? 'actor'),
        );
        final to = box!.localToGlobal(
          point(
            command['to'] as String? ?? command['from'] as String? ?? 'actor',
          ),
        );
        final id = pointer++;
        GestureBinding.instance.handlePointerEvent(
          PointerAddedEvent(pointer: id, position: from),
        );
        GestureBinding.instance.handlePointerEvent(
          PointerDownEvent(pointer: id, position: from),
        );
        final ms = command['hold'] as int? ?? 100;
        await Future<void>.delayed(Duration(milliseconds: ms));
        if (from != to) {
          for (var i = 1; i <= 12; i++) {
            final at = Offset.lerp(from, to, i / 12)!;
            GestureBinding.instance.handlePointerEvent(
              PointerMoveEvent(
                pointer: id,
                position: at,
                delta: (to - from) / 12,
              ),
            );
            await Future<void>.delayed(const Duration(milliseconds: 18));
          }
        }
        GestureBinding.instance.handlePointerEvent(
          PointerUpEvent(pointer: id, position: to),
        );
        GestureBinding.instance.handlePointerEvent(
          PointerRemovedEvent(pointer: id, position: to),
        );
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      return jsonEncode({
        'scene': true,
        'level': m.level.id,
        'actions': m.actionCount,
        'finished': m.finished,
        'next': m.showNext,
        'words': progress.words.toList(),
        'completed': progress.completed.toList(),
        // This is a driver-only test entrypoint outside test/.
        // ignore: invalid_use_of_visible_for_testing_member
        'language': audio.lastLanguage?.name,
        // ignore: invalid_use_of_visible_for_testing_member
        'speech': audio.lastSpokenText,
      });
    },
  );
  audio = GameAudioController.live();
  progress = TownProgress(); // Native QA uses an isolated in-memory journal.
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        splashFactory: InkRipple.splashFactory,
        fontFamilyFallback: const ['PingFang SC', 'Hiragino Sans GB'],
      ),
      home: TownHomeScreen(audio: audio, progress: progress),
    ),
  );
}
