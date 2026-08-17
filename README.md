<div align="center">

# 🌈 颜色抱抱

**拖一拖、抱一抱，在游戏里发现颜色的秘密。**

一个为孩子设计的互动混色小游戏。使用同一套 Flutter 代码，支持 macOS、iPad 和 iPhone。

<p>
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white">
  <img alt="Dart" src="https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white">
  <img alt="macOS 10.15+" src="https://img.shields.io/badge/macOS-10.15%2B-000000?logo=apple&logoColor=white">
  <img alt="iOS 13+" src="https://img.shields.io/badge/iOS-13%2B-000000?logo=apple&logoColor=white">
  <a href="LICENSE"><img alt="MIT License" src="https://img.shields.io/badge/License-MIT-4C1"></a>
</p>

[玩法亮点](#-玩法亮点) · [界面预览](#-界面预览) · [快速开始](#-快速开始) · [项目结构](#-项目结构)

<img width="860" alt="颜色抱抱 macOS 光模式主界面" src="./docs/images/color-hug-home.png">

<sub>macOS · 光模式自由混色</sub>

</div>

## ✨ 玩法亮点

- **拖动即可混色**：把一只颜色精灵拖到另一只身边，松手后它们会“抱抱”并变成新颜色。
- **两套混色规则**：在“光”的加色混合与适合儿童理解的“颜料”混色之间随时切换。
- **颜色小任务**：按照目标混出指定颜色，收集星星并解锁彩纸和颜色物品惊喜。
- **可拆分、可探索**：点击混合后的精灵即可拆回原色，也可以从底部颜色盘叫来更多朋友。
- **充满即时反馈**：磁吸靠近、呼吸动画、表情、音效和庆祝效果，让每次探索都有回应。
- **一套代码，多种屏幕**：界面会适配 macOS、iPad 与 iPhone 的不同尺寸。

## 🖼️ 界面预览

<table>
  <tr>
    <td width="50%" align="center">
      <img alt="颜色抱抱 macOS 颜料模式" src="./docs/images/color-hug-paint.png">
    </td>
    <td width="50%" align="center">
      <img alt="颜色抱抱 macOS 颜色小任务" src="./docs/images/color-hug-challenge.png">
    </td>
  </tr>
  <tr>
    <td align="center"><strong>🎨 颜料模式</strong><br><sub>在温暖的画布上探索颜料混色</sub></td>
    <td align="center"><strong>🎯 颜色小任务</strong><br><sub>根据目标颜色完成挑战并收集星星</sub></td>
  </tr>
</table>

## 🧪 两种混色模式

| 模式 | 混色方式 | 示例 |
| --- | --- | --- |
| ☀️ 光 | 加色混合，颜色相遇后变得更亮 | 红光 + 绿光 → 黄光 |
| 🖌️ 颜料 | 面向儿童认知的颜料混色规则 | 红色 + 黄色 → 橙色 |

## 🎮 怎么玩

1. 拖动一只颜色精灵，靠近另一只精灵。
2. 出现磁吸提示后松手，看它们抱抱并混出新颜色。
3. 点击混合后的精灵，可以把它拆回原来的颜色。
4. 点击右上角的小旗子进入颜色任务，完成目标并收集星星。

## 🚀 快速开始

### 环境要求

- Flutter SDK（Dart `>= 3.12.2`）
- 构建 macOS 或 iOS 版本时需要 Xcode

### 在 macOS 上运行

```bash
flutter pub get
flutter run -d macos
```

### 在 iPhone 或 iPad 上运行

先启动相应的模拟器，再选择设备运行：

```bash
flutter devices
flutter run -d <device-id>
```

## ✅ 验证

```bash
flutter analyze
flutter test
flutter build macos
flutter build ios --simulator
```

## 🗂️ 项目结构

```text
lib/
├── main.dart                  # 应用入口与主题
├── color_lab_screen.dart      # 主界面、交互与动画
├── color_mixer.dart           # 光与颜料的混色规则
└── color_challenges.dart      # 颜色任务与目标

test/
├── widget_test.dart           # 界面交互与响应式布局
├── color_mixer_test.dart      # 混色规则
└── color_challenges_test.dart # 任务题库
```

## 📄 许可证

本项目基于 [MIT License](LICENSE) 开源。
