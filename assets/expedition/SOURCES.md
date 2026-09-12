# 河谷样章原创素材

本目录的 PNG 是为颜色抱抱样章编写的原创分层矢量插画，经 Flutter Canvas 离线栅格化生成；没有使用外部图像、角色或品牌素材，也没有调用图片生成服务。

可编辑源稿：`tool/expedition_art/art_source.dart`。
导出：`flutter test tool/expedition_art/export_test.dart`。
图片按源坐标 2 倍导出，透明背景；部件锚点由 `expedition_scene.dart` 中的拼装坐标定义。

相关原创音效：`tool/expedition_art/audio.py`，输出 `assets/audio/expedition_*.wav`；恐龙声音为玩具式合成拟声，不是动物录音。

资源与项目其他原创代码一同按根目录 LICENSE 授权。
