# Optional Unity runtime

Based on `flutter_embed_unity_2022_3_ios` 2.0.0; upstream license is retained.

The upstream Swift sources are compiled only when `COLORHUG_UNITY_RUNTIME` is
defined and the target is a physical device. Otherwise a small channel-only
implementation reports that the optional runtime is unavailable. This fixes an
undefined `UnityFramework` symbol in ordinary Flutter builds and allows SceneKit
to run without installing or exporting Unity.

`ios/Podfile` enables the real implementation when the Runner project links
`UnityFramework.framework`. After running `scripts/export_unity_ios.sh`, run
`pod install` in `ios`, then build with `--dart-define=COLORHUG_ENABLE_UNITY=true`.
The existing Flame battle remains the default. Unity itself is not supported in
the iOS Simulator; the wardrobe is.
