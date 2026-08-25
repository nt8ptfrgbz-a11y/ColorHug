import 'package:color_hug/game_audio.dart';
import 'package:color_hug/island_progress.dart';
import 'package:color_hug/monster_planet_game.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('三位英雄拥有不同属性和战斗伤害', () {
    expect(ultraFighters, hasLength(3));
    expect(ultraFighters[1].speed, greaterThan(ultraFighters[0].speed));
    expect(
      MonsterBattleRules.punchDamage(ultraFighters[2]),
      greaterThan(MonsterBattleRules.punchDamage(ultraFighters[0])),
    );
    expect(
      MonsterBattleRules.specialDamage(ultraFighters[2]),
      greaterThan(MonsterBattleRules.specialDamage(ultraFighters[1])),
    );
  });

  testWidgets('摇杆可以移动角色，拳击蓄能后可以释放必杀', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final progress = IslandProgress();
    final audio = GameAudioController.silent();
    await audio.toggle();
    final game = MonsterPlanetGame(
      fighter: ultraFighters[2],
      progress: progress,
      audio: audio,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GameWidget<MonsterPlanetGame>(game: game)),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      await game.toBeLoaded();
    });
    await tester.pump(const Duration(milliseconds: 100));

    final startX = game.player.position.x;
    game.player.applyHorizontalInput(1, 0.5);
    expect(game.player.position.x, greaterThan(startX));

    game.player.position.x = game.monster.position.x - 180;
    for (var hit = 0; hit < 4; hit++) {
      game.punch();
      await tester.pump(const Duration(milliseconds: 460));
    }
    expect(game.battleState.value.energy, 100);

    game.special();
    await tester.pump(const Duration(milliseconds: 100));
    expect(game.battleState.value.status, BattleStatus.won);
    expect(progress.monsterPlanetWins, 1);
    expect(progress.stars, 1);

    final defeatedVariant = game.monster.variantIndex;
    game.resetBattle();
    expect(game.monster.variantIndex, isNot(defeatedVariant));
    expect(game.battleState.value.status, BattleStatus.playing);
    expect(tester.takeException(), isNull);
  });
}
