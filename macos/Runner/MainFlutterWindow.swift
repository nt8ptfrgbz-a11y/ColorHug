import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.title = "绒绒衣橱 · ColorHug"
    self.minSize = NSSize(width: 640, height: 520)

    RegisterGeneratedPlugins(registry: flutterViewController)
    let dressRegistrar = flutterViewController.registrar(forPlugin: "DressUp3D")
    dressRegistrar.register(DressPlatformFactory(messenger: dressRegistrar.messenger), withId: "colorhug/dress3d")

    super.awakeFromNib()
  }
}
