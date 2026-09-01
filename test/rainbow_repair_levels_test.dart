import 'package:color_hug/island_progress.dart';
import 'package:color_hug/rainbow_repair_levels.dart';
import 'package:color_hug/rainbow_repair_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('彩虹修复师包含二十张地图和一百个关卡', () {
    expect(repairMaps, hasLength(20));
    expect(repairLevelTotal, 100);
    expect(repairTasks, hasLength(100));
    expect(
      repairMaps.every((map) => map.tasks.length == repairStagesPerMap),
      isTrue,
    );
    expect(repairMaps.map((map) => map.name).toSet(), hasLength(20));
  });

  test('每一关都有可选择的目标颜色且能累计至一百关', () {
    const availableColors = {
      '红色',
      '橙色',
      '黄色',
      '黄绿色',
      '绿色',
      '薄荷色',
      '青色',
      '湖蓝色',
      '蓝色',
      '靛蓝色',
      '紫色',
      '粉色',
      '棕色',
      '白色',
      '灰色',
      '黑色',
    };
    final progress = IslandProgress();

    for (var index = 0; index < repairTasks.length; index++) {
      final task = repairTasks[index];
      expect(availableColors, contains(task.colorName));
      progress.repairPart(index + 1, task.colorName);
    }

    expect(progress.repairedParts, 100);
    expect(progress.stars, 100);

    progress.repairPart(100, repairTasks.last.colorName);
    expect(progress.stars, 100);
  });

  test('地图会改变任务顺序并使用扩展颜色池', () {
    final firstMap = repairTasksForMap(0);
    final secondMap = repairTasksForMap(1);
    final usedColors = repairTasks.map((task) => task.colorName).toSet();

    expect(firstMap.map((task) => task.colorName), [
      '黄色',
      '蓝色',
      '绿色',
      '红色',
      '紫色',
    ]);
    expect(secondMap.map((task) => task.colorName), [
      '绿色',
      '黄色',
      '粉色',
      '青色',
      '橙色',
    ]);
    expect(usedColors, hasLength(16));
    expect(
      repairTasksForMap(2).any((task) => task.emoji.contains('🪲')),
      isTrue,
    );
  });

  testWidgets('二十张主题地图的完整状态都可以正常绘制', (tester) async {
    tester.view.physicalSize = const Size(800, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final map in repairMaps) {
      await tester.pumpWidget(
        MaterialApp(
          home: CustomPaint(
            painter: GardenRepairPainter(
              map: map,
              restoredSteps: repairStagesPerMap,
              sparkle: 0.5,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: map.name);
    }
  });
}
