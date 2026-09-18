#if !COLORHUG_UNITY_RUNTIME || targetEnvironment(simulator)
import Flutter
import UIKit

// The upstream plugin directly references UnityFramework even when its runtime
// was not exported. Keep the plugin channel registered in normal builds, while
// avoiding unresolved Objective-C symbols. The existing Dart game uses its
// Flame implementation unless COLORHUG_ENABLE_UNITY is explicitly enabled.
public final class FlutterEmbedUnityIosPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.learntoflutter/flutter_embed_unity", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(FlutterEmbedUnityIosPlugin(), channel: channel)
    }
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(FlutterError(code: "unity_not_exported", message: "Export and link Unity to use the optional Unity game.", details: nil))
    }
}
#endif
