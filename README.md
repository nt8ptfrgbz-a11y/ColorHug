<div align="center">

# 🌈 颜色抱抱

**探索、观察、创作，在彩虹小岛发现颜色的秘密。**

一个为孩子设计的互动色彩游戏。孩子可以混合颜色、破解线索、修复花园、自由绘画并收藏自己的色彩发现。

<p>
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white">
  <img alt="Dart" src="https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white">
  <img alt="macOS 10.15+" src="https://img.shields.io/badge/macOS-10.15%2B-000000?logo=apple&logoColor=white">
  <img alt="iOS 13+" src="https://img.shields.io/badge/iOS-13%2B-000000?logo=apple&logoColor=white">
  <a href="LICENSE"><img alt="MIT License" src="https://img.shields.io/badge/License-MIT-4C1"></a>
</p>

[玩法亮点](#-玩法亮点) · [界面预览](#-界面预览) · [快速开始](#-快速开始) · [项目结构](#-项目结构)

<img width="860" alt="颜色抱抱彩虹小岛 macOS 主界面" src="./docs/images/color-hug-island.png">

<sub>macOS · 彩虹小岛活动地图</sub>

</div>

## ✨ 玩法亮点

- **彩虹小岛**：五个活动共享星星、作品和颜色发现，让每次游玩都有积累。
- **颜色实验室**：拖动颜色精灵完成光与颜料混色，也可以挑战指定的目标颜色。
- **色彩侦探**：根据生活化线索观察物品，从不同答案中找出正确颜色。
- **彩虹修复师**：为灰色花园依次找回太阳、河流、草地和花朵。
- **魔法画室**：选择颜色和画笔粗细自由绘画，完成后记录自己的创作次数。
- **色彩图鉴**：发现颜色后点亮收藏卡片，阅读颜色配方和有趣的小秘密。
- **语音陪玩**：进入玩法会主动用中文讲解步骤，关键操作也会说出鼓励或下一步提示，不识字也能独立探索。
- **声音反馈**：点击扬声器可以重复收听；点击、答对、再试、发现和完成都有不同音效，总声音开关会记住设置。
- **自动保存成长**：星星、图鉴、修复进度和作品数量会保存在本机，下次打开可以继续。
- **充满即时反馈**：磁吸、呼吸动画、表情、触觉和庆祝效果，让每次探索都有回应。
- **一套代码，多种屏幕**：界面会适配 macOS、iPad 与 iPhone 的不同尺寸。

## 🖼️ 界面预览

<table>
  <tr>
    <td width="50%" align="center">
      <img alt="颜色抱抱 macOS 光模式" src="./docs/images/color-hug-home.png">
    </td>
    <td width="50%" align="center">
      <img alt="颜色抱抱 macOS 颜料模式" src="./docs/images/color-hug-paint.png">
    </td>
  </tr>
  <tr>
    <td align="center"><strong>☀️ 光模式</strong><br><sub>拖动颜色精灵探索加色混合</sub></td>
    <td align="center"><strong>🎨 颜料模式</strong><br><sub>在温暖的画布上探索颜料混色</sub></td>
  </tr>
</table>

## 🧪 两种混色模式

| 模式 | 混色方式 | 示例 |
| --- | --- | --- |
| ☀️ 光 | 加色混合，颜色相遇后变得更亮 | 红光 + 绿光 → 黄光 |
| 🖌️ 颜料 | 面向儿童认知的颜料混色规则 | 红色 + 黄色 → 橙色 |

## 🎮 怎么玩

1. 点击实验室顶部的地图按钮进入彩虹小岛。
2. 在实验室、色彩侦探、彩虹修复师和魔法画室之间自由选择。
3. 跟着彩虹精灵的语音提示操作；没听清时，点击带有人物声波的按钮再听一次。
4. 完成线索与修复任务收集星星，混色和绘画则会解锁更多颜色。
5. 打开色彩图鉴，点击卡片听一听已经发现的颜色和它们的小秘密。

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
├── main.dart                    # 应用入口、主题与共享进度
├── rainbow_island_screen.dart   # 彩虹小岛活动地图
├── color_lab_screen.dart        # 混色实验室、交互与动画
├── color_detective_screen.dart  # 色彩侦探线索游戏
├── rainbow_repair_screen.dart   # 彩虹花园修复关卡
├── magic_studio_screen.dart     # 自由绘画画室
├── color_gallery_screen.dart    # 色彩图鉴
├── game_audio.dart              # 中文语音、音效与声音开关
├── island_progress.dart         # 星星、作品与颜色发现
├── color_mixer.dart             # 光与颜料的混色规则
└── color_challenges.dart        # 颜色任务与目标

test/
├── widget_test.dart             # 实验室交互与响应式布局
├── island_features_test.dart    # 彩虹小岛与新玩法流程
├── game_audio_test.dart         # 语音与音效控制逻辑
├── island_progress_test.dart    # 共享奖励与发现进度
├── color_mixer_test.dart        # 混色规则
└── color_challenges_test.dart   # 任务题库

assets/audio/                    # 五种轻量游戏提示音
```

## 📄 许可证

本项目基于 [MIT License](LICENSE) 开源。
