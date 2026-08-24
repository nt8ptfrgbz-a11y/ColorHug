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
}
