# 颜色抱抱

一个为孩子设计的互动混色小游戏，同一套 Flutter 代码支持 macOS、iPad 和 iPhone。

## 玩法

- 拖动一只颜色精灵靠近另一只，松手后它们会“抱抱”并混合。
- 点击已混合的颜色精灵，可以把它拆回原来的颜色。
- 使用底部颜色盘可以叫来更多颜色精灵。
- “光”模式使用加色混合，“颜料”模式使用适合儿童学习的颜料混色规则。
- 点击顶部的小旗子可以进入“颜色小任务”，按目标混出颜色并收集星星。
- 任务成功会触发全屏彩纸和颜色物品惊喜；点击精灵或空白区域也会得到不同回应。

## 运行

```bash
flutter pub get
flutter run -d macos
```

运行到 iPhone 或 iPad 模拟器时，先启动相应的模拟器，然后使用 `flutter devices` 查看设备，再执行 `flutter run -d <device-id>`。

## 验证

```bash
flutter analyze
flutter test
flutter build macos
flutter build ios --simulator
```
