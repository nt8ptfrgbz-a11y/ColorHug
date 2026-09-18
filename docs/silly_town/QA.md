# 验证记录 · 2026-09-18

- `flutter analyze --no-pub`：无问题。
- `flutter test --no-pub --reporter expanded`：138 项全部通过，包含新增 12 项小镇测试。
- `flutter test --update-goldens tool/town_capture_test.dart --no-pub`：8 张画面输出成功；已检查手机首页、桌面首页、水果头发、泡泡胡子及原生通关画面。
- 30 关都通过命中测试派发操作完成；13 类机制在小屏和大屏运行，30 关 widget 流程逐关出现下一关入口。
- macOS 原生 Flutter Driver：太阳点击、3 次水果拖拽、泡泡长按均完成；英语语音语言为 `english`；保存 `[0, 5, 11]` 三关；收藏册成功打开。
- 音频检测：14 个 WAV 文件均为有效非静音双声道 PCM，峰值低于 0.7，无削波。详见 `audio-check.json`。
- `flutter build macos --release --no-pub`：成功，73.4 MB。
- `git diff --check`：通过。

试玩程序：`build/macos/Build/Products/Release/ColorHug.app`。正常主入口是 `lib/main.dart`，原生验证专用入口不随正式程序启动。

原生截图位于 `build/town-native/`；可重现的截图脚本和静态预览位于本目录及 `tool/town_capture_test.dart`。

未验证：iPhone/iPad 真机扬声器效果、具体设备的英语 TTS 音色和真实儿童使用体验。构建提示来自已有的 `flutter_tts` Swift Package Manager 支持以及 `objective_c` 双架构框架命名；未阻止 macOS 构建。
