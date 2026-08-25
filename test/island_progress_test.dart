import 'package:color_hug/island_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('初始图鉴点亮四种基础颜色', () {
    final progress = IslandProgress();

    expect(progress.discoveredCount, 4);
    expect(progress.hasDiscovered('红色'), isTrue);
    expect(progress.hasDiscovered('紫色'), isFalse);
  });

  test('同一个侦探线索不会重复奖励星星', () {
    final progress = IslandProgress();

    progress.recordDetectiveWin(0, '黄色');
    progress.recordDetectiveWin(0, '黄色');

    expect(progress.stars, 1);
    expect(progress.detectiveWins, 1);
  });

  test('浅色和深色会点亮对应基础颜色', () {
    final progress = IslandProgress();

    progress.discover('浅紫色');
    progress.discover('深棕色');

    expect(progress.hasDiscovered('紫色'), isTrue);
    expect(progress.hasDiscovered('棕色'), isTrue);
  });

  test('同一颜色关卡和守护任务不会重复奖励星星', () {
    final progress = IslandProgress();

    expect(progress.recordColorChallenge(1, '黄色'), isTrue);
    expect(progress.recordColorChallenge(1, '黄色'), isFalse);
    expect(progress.recordGuardianWin(0, '青色'), isTrue);
    expect(progress.recordGuardianWin(0, '青色'), isFalse);

    expect(progress.completedColorChallenges, 1);
    expect(progress.guardianWins, 1);
    expect(progress.stars, 2);
  });

  test('奥特曼训练的三种进度分别记录且不重复奖励', () {
    final progress = IslandProgress();

    expect(progress.recordUltraTrainingWin('radar', 0), isTrue);
    expect(progress.recordUltraTrainingWin('radar', 0), isFalse);
    expect(progress.recordUltraTrainingWin('beam', 0), isTrue);
    expect(progress.recordUltraTrainingWin('rescue', 0), isTrue);

    expect(progress.monsterRadarWins, 1);
    expect(progress.beamTrainingWins, 1);
    expect(progress.spaceRescueWins, 1);
    expect(progress.stars, 3);
  });

  test('怪兽星球为三位英雄分别记录首次胜利', () {
    final progress = IslandProgress();

    expect(progress.recordMonsterPlanetWin('spark'), isTrue);
    expect(progress.recordMonsterPlanetWin('spark'), isFalse);
    expect(progress.recordMonsterPlanetWin('gale'), isTrue);

    expect(progress.monsterPlanetWins, 2);
    expect(progress.hasMonsterPlanetWin('spark'), isTrue);
    expect(progress.hasMonsterPlanetWin('nova'), isFalse);
    expect(progress.stars, 2);
  });
}
