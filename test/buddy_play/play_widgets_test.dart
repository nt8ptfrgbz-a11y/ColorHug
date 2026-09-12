import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:color_hug/buddy_home_screen.dart';
import 'package:color_hug/buddy_play/buddy_play_catalog.dart';
import 'package:color_hug/buddy_play/buddy_play_routes.dart';
import 'package:color_hug/game_audio.dart';
import 'package:color_hug/island_progress.dart';
import '../buddy_games_test.dart' show pumpGame, tapKey;

Future<void> advance(WidgetTester tester, double seconds) async {
  for (var i = 0; i < (seconds * 20).ceil(); i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> canvasTap(WidgetTester tester, String key, Offset at) async {
  final f = find.byKey(ValueKey(key));
  final r = tester.getRect(f);
  await tester.tapAt(r.topLeft + Offset(r.width * at.dx, r.height * at.dy));
  await tester.pump();
}

Future<void> canvasDrag(
  WidgetTester tester,
  String key,
  Offset a,
  Offset b,
) async {
  final r = tester.getRect(find.byKey(ValueKey(key)));
  final start = r.topLeft + Offset(r.width * a.dx, r.height * a.dy);
  final end = r.topLeft + Offset(r.width * b.dx, r.height * b.dy);
  await tester.dragFrom(start, end - start);
  await tester.pump();
}

void main() {
  for (final size in [
    const Size(390, 844),
    const Size(844, 390),
    const Size(768, 1024),
    const Size(1200, 800),
  ]) {
    testWidgets('八款在 ${size.width}×${size.height} 可操作、收藏、退出', (tester) async {
      for (final game in BuddyPlay.values) {
        final p = IslandProgress();
        final audio = GameAudioController.silent();
        await pumpGame(tester, buddyPlayScreen(game, p, audio), size: size);
        expect(find.text(playCatalog[game]!.title), findsOneWidget);
        expect(tester.takeException(), isNull, reason: game.name);
        await tapKey(tester, 'play-collect');
        expect(p.playJournal.album(game).length, 1, reason: game.name);
        await tapKey(tester, 'play-album');
        expect(find.text('我的作品盒'), findsOneWidget);
        await tester.tap(find.text('小创作 1'));
        await advance(tester, .4);
        expect(tester.takeException(), isNull, reason: game.name);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        p.dispose();
        audio.dispose();
      }
    });
  }
  testWidgets('小家可以进入八款并返回，旧九款入口保留', (tester) async {
    final p = IslandProgress();
    final audio = GameAudioController.silent();
    await pumpGame(tester, BuddyHomeScreen(progress: p, audio: audio));
    for (final game in BuddyPlay.values) {
      await tapKey(tester, 'buddy-play-${game.name}');
      await advance(tester, .5);
      expect(find.text(playCatalog[game]!.title), findsOneWidget);
      await tapKey(tester, 'play-back');
      await advance(tester, .5);
    }
    await tester.ensureVisible(find.byKey(const ValueKey('buddy-game-juice')));
    await tester.pump();
    expect(find.byKey(const ValueKey('buddy-game-juice')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    p.dispose();
    audio.dispose();
  });
  testWidgets('八款真实手势改变作品与反馈，离开后不残留任务', (tester) async {
    final p = IslandProgress();
    final audio = GameAudioController.silent();
    Future<void> open(BuddyPlay g) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await pumpGame(tester, buddyPlayScreen(g, p, audio));
    }

    await open(BuddyPlay.rolling);
    await tapKey(tester, 'rolling-part-1');
    await canvasTap(tester, 'rolling-canvas', const Offset(.79, .29));
    await tapKey(tester, 'rolling-launch');
    await advance(tester, 5.5);
    await tapKey(tester, 'rolling-rescue');
    await advance(tester, 2);
    expect(p.playDiscoveries(BuddyPlay.rolling), greaterThan(0));
    await open(BuddyPlay.salon);
    await canvasDrag(
      tester,
      'salon-canvas',
      const Offset(.25, .31),
      const Offset(.75, .31),
    );
    await tapKey(tester, 'salon-mirror');
    await advance(tester, .5);
    expect(
      p.playJournal.draft(BuddyPlay.salon)!['looks'][0]['lengths'],
      isNot(List.filled(11, .26)),
    );
    await open(BuddyPlay.water);
    await tapKey(tester, 'water-pipe-1');
    await tapKey(tester, 'water-pipe-2');
    await tapKey(tester, 'water-pipe-2');
    await tapKey(tester, 'water-tap');
    await advance(tester, 6);
    await tapKey(tester, 'water-plug');
    await tapKey(tester, 'water-duck');
    await advance(tester, 11);
    expect(p.playDiscoveries(BuddyPlay.water), greaterThan(1));
    await open(BuddyPlay.delivery);
    await tapKey(tester, 'delivery-box-0');
    await tapKey(tester, 'delivery-drive');
    await advance(tester, 3);
    for (var i = 0; i < 4; i++) {
      await tapKey(tester, 'delivery-wash');
    }
    await advance(tester, 3);
    await tapKey(tester, 'delivery-boat');
    await advance(tester, 6);
    await tapKey(tester, 'delivery-bridge');
    await advance(tester, 8);
    await tapKey(tester, 'delivery-deliver');
    await advance(tester, 3);
    expect(p.playJournal.draft(BuddyPlay.delivery)!['gifts'][0], true);
    await open(BuddyPlay.squishy);
    await canvasDrag(
      tester,
      'squishy-canvas',
      const Offset(.78, .54),
      const Offset(.91, .28),
    );
    await advance(tester, 2);
    await tapKey(tester, 'squishy-stamp');
    await advance(tester, .5);
    expect(p.playJournal.draft(BuddyPlay.squishy)!['mood'], 1);
    await open(BuddyPlay.soundTrain);
    await canvasDrag(
      tester,
      'train-canvas',
      const Offset(.13, .62),
      const Offset(.88, .62),
    );
    await tapKey(tester, 'train-start');
    await advance(tester, 8);
    expect(p.playDiscoveries(BuddyPlay.soundTrain), 1);
    await open(BuddyPlay.shadows);
    await canvasDrag(
      tester,
      'shadows-canvas',
      const Offset(.5, .94),
      const Offset(.2, .84),
    );
    await advance(tester, .5);
    expect(p.playJournal.draft(BuddyPlay.shadows)!['light'][0], lessThan(.3));
    await open(BuddyPlay.tinyWorld);
    await tapKey(tester, 'world-tool-3');
    await canvasTap(tester, 'world-canvas', const Offset(.45, .56));
    await advance(tester, 20);
    expect(
      p.playJournal.draft(BuddyPlay.tinyWorld)!['objects'],
      contains(containsPair('kind', 1)),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    p.dispose();
    audio.dispose();
  });
}
