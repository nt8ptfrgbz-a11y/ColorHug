import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.minSize = NSSize(width: 640, height: 520)

    RegisterGeneratedPlugins(registry: flutterViewController)
    let dressRegistrar = flutterViewController.registrar(forPlugin: "DressUp3D")
    dressRegistrar.register(DressPlatformFactory(messenger: dressRegistrar.messenger), withId: "colorhug/dress3d")
    let shanRegistrar = flutterViewController.registrar(forPlugin: "Shanhai3D")
    shanRegistrar.register(ShanhaiPlatformFactory(messenger: shanRegistrar.messenger), withId: "colorhug/shanhai3d")

    super.awakeFromNib()
    self.title = "山海唤灵师 · ColorHug"
    if let available = self.screen?.visibleFrame {
      self.setContentSize(NSSize(width: min(1180, available.width - 80),
                                 height: min(820, available.height - 80)))
      self.center()
    }
  }
}
