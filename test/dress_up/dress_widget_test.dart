import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:color_hug/dress_up/dress_catalog.dart';
import 'package:color_hug/dress_up/dress_model.dart';
import 'package:color_hug/dress_up/dress_screen.dart';
import 'package:color_hug/dress_up/dress_native.dart';
import 'package:color_hug/game_audio.dart';
import 'package:color_hug/silly_town/town_progress.dart';
import 'package:color_hug/silly_town/town_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'more games pauses the native stage and has an explicit way back',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final calls = <MethodCall>[];
      const channel = MethodChannel('colorhug/dress3d/98');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call);
        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      final model = DressModel(),
          audio = GameAudioController.silent(),
          town = TownProgress();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => DressUpScreen(
              audio: audio,
              model: model,
              nativeController: DressNativeController(98),
              stageBuilder: (_, values) =>
                  const ColoredBox(color: Colors.brown),
              onOpenTown: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (context) => TownHomeScreen(
                    audio: audio,
                    progress: town,
                    nativeAudio: false,
                    onBack: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('更多游戏'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.byKey(const ValueKey('town-back-to-wardrobe')),
        findsOneWidget,
      );
      expect(calls.lastWhere((c) => c.method == 'active').arguments, isFalse);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('town-back-to-wardrobe')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('dress-stage')), findsOneWidget);
      expect(calls.lastWhere((c) => c.method == 'active').arguments, isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      model.dispose();
      audio.dispose();
      town.dispose();
    },
  );

  testWidgets('native photo, sticker, restore, rotation and lifecycle bridge', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final calls = <MethodCall>[];
    const channel = MethodChannel('colorhug/dress3d/99');
    final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a7xkAAAAASUVORK5CYII=',
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      return call.method == 'capture' || call.method == 'readPhoto'
          ? png
          : null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    final model = DressModel(), audio = GameAudioController.silent();
    await tester.pumpWidget(
      MaterialApp(
        home: DressUpScreen(
          audio: audio,
          model: model,
          nativeController: DressNativeController(99),
          stageBuilder: (_, values) => const ColoredBox(color: Colors.brown),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('dress-pose')));
    await tester.tap(find.byKey(const ValueKey('dress-turn-right')));
    await tester.pumpAndSettle();
    expect(calls.any((c) => c.method == 'pose' && c.arguments == 1), isTrue);
    expect(
      calls.any((c) => c.method == 'turn' && (c.arguments as Map)['angle'] > 0),
      isTrue,
    );
    await tester.tap(find.byKey(const ValueKey('dress-camera')));
    await tester.pumpAndSettle();
    expect(model.memories.length, 1);
    await tester.tap(find.byKey(const ValueKey('dress-sticker-2')));
    await tester.pumpAndSettle();
    expect(model.memories.single.sticker, 2);
    await tester.tap(find.byTooltip('收好照片'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('dress-item-raincoat')));
    await tester.pumpAndSettle();
    expect(model.look.outfit, 'raincoat');
    await tester.tap(find.byKey(const ValueKey('dress-album')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ValueKey('dress-memory-${model.memories.single.id}')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('dress-restore-memory')));
    await tester.pumpAndSettle();
    expect(model.look.outfit, 'petal');
    final restored = DressModel()..restore(model.encode());
    expect(restored.memories.single.sticker, 2);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(calls.lastWhere((c) => c.method == 'active').arguments, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(calls.lastWhere((c) => c.method == 'active').arguments, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(calls.any((c) => c.method == 'dispose'), isTrue);
    model.dispose();
    restored.dispose();
    audio.dispose();
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
    const Size(1024, 768),
    const Size(1280, 800),
  ]) {
    testWidgets(
      'wardrobe, turning, travel, album and settings remain usable at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final model = DressModel(), audio = GameAudioController.silent();
        await tester.pumpWidget(
          MaterialApp(
            home: DressUpScreen(
              audio: audio,
              model: model,
              stageBuilder: (_, values) =>
                  const ColoredBox(color: Color(0xFFE7D6C1)),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (final category in DressCategory.values) {
          await tester.tap(
            find.byKey(ValueKey('dress-category-${category.name}')),
          );
          await tester.pumpAndSettle();
          for (final item in dressCatalog.where(
            (item) => item.category == category,
          )) {
            final finder = find.byKey(ValueKey('dress-item-${item.id}'));
            await tester.ensureVisible(finder);
            await tester.pumpAndSettle();
            await tester.tap(finder);
            await tester.pumpAndSettle();
            expect(model.look.itemFor(category), item.id);
            expect(tester.takeException(), isNull, reason: item.id);
          }
        }
        await tester.tap(find.byKey(const ValueKey('dress-remove-accessory')));
        await tester.pump();
        expect(model.look.accessory, isEmpty);
        await tester.tap(find.byKey(const ValueKey('dress-undo')));
        await tester.pump();
        expect(model.look.accessory, 'satchel');
        await tester.tap(find.byKey(const ValueKey('dress-character-1')));
        await tester.tap(find.byKey(const ValueKey('dress-turn-left')));
        await tester.tap(find.byKey(const ValueKey('dress-turn-right')));
        await tester.tap(find.byKey(const ValueKey('dress-front')));
        await tester.drag(
          find.byKey(const ValueKey('dress-stage')),
          const Offset(90, 0),
        );
        await tester.pumpAndSettle();
        expect(model.look.character, 1);
        for (final place in [
          DressPlace.garden,
          DressPlace.tea,
          DressPlace.night,
        ]) {
          await tester.tap(find.byKey(const ValueKey('dress-travel')));
          await tester.pumpAndSettle();
          await tester.ensureVisible(
            find.byKey(ValueKey('dress-place-${place.name}')),
          );
          await tester.tap(find.byKey(ValueKey('dress-place-${place.name}')));
          await tester.pumpAndSettle();
          expect(model.place, place);
          await tester.tap(find.byKey(const ValueKey('dress-action')));
          await tester.pumpAndSettle();
          expect(model.discoveries, contains(place));
        }
        await tester.tap(find.byKey(const ValueKey('dress-album')));
        await tester.pumpAndSettle();
        expect(find.text('给今天的搭配拍张照吧'), findsOneWidget);
        await tester.tap(find.byTooltip('关闭相册'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('dress-settings')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('安静的小动作'));
        await tester.pumpAndSettle();
        expect(model.reducedMotion, isTrue);
        await tester.ensureVisible(find.text('继续玩'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('继续玩'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        model.dispose();
        audio.dispose();
      },
    );
  }
  testWidgets(
    'dragging clothing onto the stage equips it without precise targeting',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final model = DressModel(), audio = GameAudioController.silent();
      await tester.pumpWidget(
        MaterialApp(
          home: DressUpScreen(
            audio: audio,
            model: model,
            stageBuilder: (_, values) => const ColoredBox(color: Colors.brown),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final start = tester.getCenter(
        find.byKey(const ValueKey('dress-item-pinafore')),
      );
      final end = tester.getCenter(find.byKey(const ValueKey('dress-stage')));
      await tester.dragFrom(start, end - start);
      await tester.pumpAndSettle();
      expect(model.look.outfit, 'pinafore');
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      model.dispose();
      audio.dispose();
    },
  );
}
