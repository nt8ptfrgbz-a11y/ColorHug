import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:color_hug/game_audio.dart';
import 'package:color_hug/shanhai/shanhai_model.dart';
import 'package:color_hug/shanhai/shanhai_screen.dart';

void main() {
  final model = ShanhaiModel();
  final history = <String>[];
  var lastPhase = model.phase;
  model.addListener(() {
    if (model.phase != lastPhase) {
      history.add(
        '${lastPhase.name}->${model.phase.name} @${model.flight.toStringAsFixed(3)}',
      );
      lastPhase = model.phase;
    }
  });
  var pointer = 200;
  enableFlutterDriverExtension(
    handler: (request) async {
      RenderBox? box;
      void visit(Element e) {
        if (e.widget.key == const ValueKey('shan-stage-touch')) {
          box = e.findRenderObject() as RenderBox?;
        }
        e.visitChildren(visit);
      }

      WidgetsBinding.instance.rootElement?.visitChildren(visit);
      if (request != null && request.startsWith('{') && box != null) {
        final command = jsonDecode(request) as Map;
        final local = Offset(
          (command['x'] as num).toDouble() * box!.size.width,
          (command['y'] as num).toDouble() * box!.size.height,
        );
        final at = box!.localToGlobal(local), id = pointer++;
        GestureBinding.instance.handlePointerEvent(
          PointerAddedEvent(pointer: id, position: at),
        );
        GestureBinding.instance.handlePointerEvent(
          PointerDownEvent(pointer: id, position: at),
        );
        await Future<void>.delayed(const Duration(milliseconds: 60));
        GestureBinding.instance.handlePointerEvent(
          PointerUpEvent(pointer: id, position: at),
        );
        GestureBinding.instance.handlePointerEvent(
          PointerRemovedEvent(pointer: id, position: at),
        );
      }
      return jsonEncode({
        'phase': model.phase.name,
        'seals': model.seals.length,
        'feeds': model.feeds,
        'affection': model.affection,
        'flight': model.flight,
        'stars': model.flightStars,
        'flights': model.flights,
        'realm': model.realm.name,
        'history': history,
      });
    },
  );
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamilyFallback: const ['PingFang SC', 'Hiragino Sans GB'],
      ),
      home: ShanhaiScreen(
        audio: GameAudioController.silent(),
        model: model,
        nativeAudio: false,
      ),
    ),
  );
}
