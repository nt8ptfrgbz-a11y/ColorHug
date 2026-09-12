// Actual application plus raw-pointer transport and read-only diagnostics.
// Commands dispatch platform-style input, never modify game state directly.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import 'package:flutter_driver/driver_extension.dart';
import 'package:color_hug/main.dart';
import 'package:color_hug/island_progress.dart';
import 'package:color_hug/buddy_expedition/expedition_scene.dart';
import 'package:color_hug/buddy_expedition/expedition_controller.dart';
import 'package:color_hug/buddy_expedition/expedition_models.dart';

void main() {
  bool exclusive = true;
  var pointer = 800;
  enableFlutterDriverExtension(
    handler: (request) async {
      ExpeditionScene? scene;
      RenderBox? box;
      void visit(Element e) {
        final widget = e.widget;
        if (widget is CustomPaint && widget.painter is ExpeditionScene) {
          scene = widget.painter as ExpeditionScene;
          box = e.findRenderObject() as RenderBox?;
        }
        e.visitChildren(visit);
      }

      final root = WidgetsBinding.instance.rootElement;
      if (root != null) visit(root);
      final m = scene?.model;
      if (m == null) return 'no-scene';
      if (request != null && request.startsWith('{')) {
        final command = jsonDecode(request) as Map;
        // Dedicated smoke run: deterministic foreground event, then real hit-tested
        // pointer input. Ignore unrelated desktop clicks until returning to the hub.
        exclusive = true;
        if (m.paused) {
          WidgetsBinding.instance.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
        }
        if (command['target'] == 'finish') {
          exclusive = false;
          return 'released';
        }
        final view = ValleyView(box!.size, m.cameraX, region: m.region);
        final local = switch (command['target']) {
          'right' => Offset(
            box!.size.width * .9,
            view.horizon + 55 * view.scale,
          ),
          'left' => Offset(
            box!.size.width * .08,
            view.horizon + 55 * view.scale,
          ),
          'log' => view.toScreen(m.logPosition),
          'bridge' => view.toScreen(const Offset(bridgeCenter, -20)),
          'dino' => view.toScreen(Offset(m.dinoX, roadHeight(m.dinoX) - 65)),
          _ => view.toScreen(
            m.chapterTargets.firstWhere((v) => v.id == command['target']).at,
          ),
        };
        final point = box!.localToGlobal(local);
        final id = ++pointer;
        GestureBinding.instance.handlePointerEvent(
          PointerAddedEvent(pointer: id, position: point),
        );
        GestureBinding.instance.handlePointerEvent(
          PointerDownEvent(pointer: id, position: point),
        );
        await Future<void>.delayed(
          Duration(milliseconds: command['ms'] as int? ?? 100),
        );
        GestureBinding.instance.handlePointerEvent(
          PointerUpEvent(pointer: id, position: point),
        );
        GestureBinding.instance.handlePointerEvent(
          PointerRemovedEvent(pointer: id, position: point),
        );
        await Future<void>.delayed(const Duration(milliseconds: 800));
      }
      return jsonEncode({
        'region': m.region.name,
        'story': m.story.toJson(),
        'basket': m.orchard.count,
        'ferry': m.bay.ferry.name,
        'car': m.carX,
        'bridge': m.bridge,
        'log': m.logPlace.name,
        'dino': m.dino.name,
        'joined': m.joined,
        'home': m.home,
        'paused': m.paused,
        'input': m.input.name,
      });
    },
  );
  final originalPackets =
      WidgetsBinding.instance.platformDispatcher.onPointerDataPacket;
  WidgetsBinding.instance.platformDispatcher.onPointerDataPacket = (packet) {
    if (!exclusive) originalPackets?.call(packet);
  };
  SystemChannels.lifecycle.setMessageHandler((message) async {
    if (!exclusive && message != null) {
      for (final state in AppLifecycleState.values) {
        if (message == state.toString()) {
          WidgetsBinding.instance.handleAppLifecycleStateChanged(state);
        }
      }
    }
    return null;
  });
  runApp(ColorHugApp(progress: IslandProgress()));
}
