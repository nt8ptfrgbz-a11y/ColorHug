import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DressUp3D") {
      registrar.register(DressPlatformFactory(messenger: registrar.messenger()), withId: "colorhug/dress3d")
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "Shanhai3D") {
      registrar.register(ShanhaiPlatformFactory(messenger: registrar.messenger()), withId: "colorhug/shanhai3d")
    }
  }
}
