import 'package:color_hug/game_audio.dart';
import 'package:color_hug/island_progress.dart';
import 'package:color_hug/main.dart';
import 'package:color_hug/shanhai/shanhai_screen.dart';
import 'package:color_hug/seed_lab/seed_screen.dart';
import 'package:color_hug/dress_up/dress_screen.dart';
import 'package:color_hug/silly_town/town_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Future<void> mountCatalog(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ColorHugApp(
      progress: IslandProgress(),
      audio: GameAudioController.silent(),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    final previous = SharedPreferencesAsyncPlatform.instance;
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    addTearDown(() => SharedPreferencesAsyncPlatform.instance = previous);
  });
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(1024, 768),
  ]) {
    testWidgets('游戏目录在 $size 展示分类且不溢出', (tester) async {
      await mountCatalog(tester, size);
      expect(find.text('游戏乐园'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('catalog-game-shanhai')),
        findsOneWidget,
      );
      await tester.drag(find.byType(ListView), const Offset(-330, 0));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('catalog-category-buddy')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('catalog-category-buddy')));
      await tester.pump();
      expect(find.text('抱抱的小世界'), findsWidgets);
      expect(find.byKey(const ValueKey('catalog-game-shanhai')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('搜索可以直达嵌套玩法并返回目录', (tester) async {
    await mountCatalog(tester, const Size(390, 844));
    await tester.enterText(
      find.byKey(const ValueKey('catalog-search')),
      '怪兽理发店',
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('catalog-game-play-salon')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('catalog-game-shanhai')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('catalog-game-play-salon')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('怪兽理发店'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('返回游戏目录'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('catalog-search')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('catalog-game-play-salon')),
      findsOneWidget,
    );
  });

  testWidgets('颜色实验室可从首页进入并返回', (tester) async {
    await mountCatalog(tester, const Size(390, 844));
    await tester.drag(find.byType(ListView), const Offset(-220, 0));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('catalog-category-colors')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('catalog-game-lab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('color-playground')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('island-map')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final labOnIsland = find.byKey(const ValueKey('activity-lab'));
    await tester.ensureVisible(labOnIsland);
    await tester.tap(labOnIsland);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byTooltip('返回游戏目录'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('lab-back-to-town')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('catalog-game-lab')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final entry in [
    ('山海唤灵师', 'shanhai', ShanhaiScreen),
    ('奇怪种子实验室', 'seed', SeedLabScreen),
    ('绒绒衣橱', 'dress', DressUpScreen),
    ('小怪兽的胡闹小镇', 'town', TownHomeScreen),
  ]) {
    testWidgets('${entry.$1}可从目录直达并返回', (tester) async {
      await mountCatalog(tester, const Size(390, 844));
      await tester.enterText(
        find.byKey(const ValueKey('catalog-search')),
        entry.$1,
      );
      await tester.pump();
      await tester.tap(find.byKey(ValueKey('catalog-game-${entry.$2}')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(entry.$3), findsOneWidget);
      expect(find.byTooltip('返回游戏目录'), findsWidgets);
      await tester.tap(find.byTooltip('返回游戏目录').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const ValueKey('catalog-search')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
