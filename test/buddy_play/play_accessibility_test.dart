import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:color_hug/buddy_play/buddy_play_catalog.dart';
import 'package:color_hug/buddy_play/buddy_play_routes.dart';
import 'package:color_hug/game_audio.dart';
import 'package:color_hug/island_progress.dart';
import '../buddy_games_test.dart' show tapKey, pumpGame;
import 'play_widgets_test.dart' show advance;

void main() {
  for (final size in [const Size(320, 568), const Size(740, 360)]) {
    testWidgets('放大字体与减少动画 ${size.width}×${size.height}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final game in BuddyPlay.values) {
        final p = IslandProgress();
        final audio = GameAudioController.silent();
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: const TextScaler.linear(1.6),
                disableAnimations: true,
              ),
              child: buddyPlayScreen(game, p, audio),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull, reason: game.name);
        await tapKey(tester, 'play-collect');
        expect(p.playJournal.album(game).length, 1);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        p.dispose();
        audio.dispose();
      }
    });
  }
  testWidgets('后台暂停实际模拟，恢复后由孩子继续，静音仍能玩', (tester) async {
    final p = IslandProgress();
    final audio = GameAudioController.silent();
    await pumpGame(tester, buddyPlayScreen(BuddyPlay.rolling, p, audio));
    await tapKey(tester, 'rolling-launch');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await advance(tester, 8);
    expect(p.playDiscoveries(BuddyPlay.rolling), 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tapKey(tester, 'rolling-pause');
    await audio.toggle();
    final last = audio.lastSpokenText;
    await advance(tester, 7);
    expect(p.playDiscoveries(BuddyPlay.rolling), greaterThan(0));
    expect(audio.lastSpokenText, last);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    p.dispose();
    audio.dispose();
  });
}
