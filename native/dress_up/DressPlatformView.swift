import Foundation
import SceneKit
#if os(macOS)
import FlutterMacOS
#else
import Flutter
#endif

final class DressPlatformFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger
    init(messenger: FlutterBinaryMessenger) { self.messenger = messenger; super.init() }
    #if os(macOS)
    func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol)? { FlutterStandardMessageCodec.sharedInstance() }
    func create(withViewIdentifier id: Int64, arguments: Any?) -> NSView {
        DressNativeView(frame: .zero, id: id, messenger: messenger, values: arguments as? [String: Any] ?? [:])
    }
    #else
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol { FlutterStandardMessageCodec.sharedInstance() }
    func create(withFrame frame: CGRect, viewIdentifier id: Int64, arguments: Any?) -> FlutterPlatformView {
        DressNativeView(frame: frame, id: id, messenger: messenger, values: arguments as? [String: Any] ?? [:])
    }
    #endif
}

final class DressNativeView: SCNView {
    let studio = DressScene()
    private var channel: FlutterMethodChannel!
    private var captureBusy = false
    private var isDisposed = false

    init(frame: CGRect, id: Int64, messenger: FlutterBinaryMessenger, values: [String: Any]) {
        super.init(frame: frame, options: ["preferredRenderingAPI": SCNRenderingAPI.metal.rawValue])
        scene = studio.scene
        pointOfView = studio.cameraNode
        antialiasingMode = .multisampling4X
        preferredFramesPerSecond = 60
        autoenablesDefaultLighting = false
        allowsCameraControl = false
        isPlaying = true
        rendersContinuously = true
        studio.update(values)
        channel = FlutterMethodChannel(name: "colorhug/dress3d/\(id)", binaryMessenger: messenger)
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self = self, !self.isDisposed else { result(FlutterError(code:"disposed", message:"Scene closed", details:nil)); return }
            switch call.method {
            case "update": self.studio.update(call.arguments as? [String: Any] ?? [:]); result(nil)
            case "turn":
                let args = call.arguments as? [String: Any] ?? [:]
                let angle = args["angle"] as? Double ?? 0
                if angle.isFinite { self.studio.turn(angle, animated: args["animated"] as? Bool ?? false) }
                result(nil)
            case "action": self.studio.action(); result(nil)
            case "pose": self.studio.pose(call.arguments as? Int ?? 0); result(nil)
            case "active":
                let active = call.arguments as? Bool ?? true
                self.studio.active(active); self.isPlaying = active; self.rendersContinuously = active; result(nil)
            case "capture": self.capture(call.arguments as? String ?? "", result: result)
            case "readPhoto":
                guard let name = call.arguments as? String, let url = self.photoURL(name), let data = try? Data(contentsOf: url) else { result(nil); return }
                result(FlutterStandardTypedData(bytes:data))
            case "removePhotos":
                for name in call.arguments as? [String] ?? [] { if let url = self.photoURL(name) { try? FileManager.default.removeItem(at: url) } }
                result(nil)
            case "dispose":
                self.isDisposed = true; self.isPlaying = false; self.rendersContinuously = false
                self.scene = nil; self.channel.setMethodCallHandler(nil); result(nil)
            default: result(FlutterMethodNotImplemented)
            }
        }
    }
    required init?(coder: NSCoder) { fatalError("Use platform factory") }
    #if os(macOS)
    override func layout() { super.layout(); studio.resize(bounds.size) }
    #else
    override func layoutSubviews() { super.layoutSubviews(); studio.resize(bounds.size) }
    #endif

    private func photoURL(_ name: String) -> URL? {
        guard name.range(of: "^look_[0-9]{10,20}\\.png$", options: .regularExpression) != nil,
              let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let directory = root.appendingPathComponent("ColorHug/DressPhotos", isDirectory: true)
        do { try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true) } catch { return nil }
        return directory.appendingPathComponent(name)
    }

    private func capture(_ name: String, result: @escaping FlutterResult) {
        guard !captureBusy, let url = photoURL(name), bounds.width > 0, bounds.height > 0 else {
            result(FlutterError(code:"capture_unavailable", message:"Please try the photo again", details:nil)); return
        }
        captureBusy = true
        let image = snapshot()
        #if os(macOS)
        let data = image.tiffRepresentation.flatMap { NSBitmapImageRep(data:$0)?.representation(using:.png,properties:[:]) }
        #else
        let data = image.pngData()
        #endif
        guard let data = data else { captureBusy = false; result(FlutterError(code:"capture_failed", message:"Photo unavailable", details:nil)); return }
        DispatchQueue.global(qos:.userInitiated).async { [weak self] in
            do {
                try data.write(to:url,options:.atomic)
                DispatchQueue.main.async { self?.captureBusy = false; result(FlutterStandardTypedData(bytes:data)) }
            } catch {
                DispatchQueue.main.async { self?.captureBusy = false; result(FlutterError(code:"photo_save_failed", message:"Could not save photo", details:nil)) }
            }
        }
    }
    deinit { channel?.setMethodCallHandler(nil) }
}

#if os(iOS)
extension DressNativeView: FlutterPlatformView {
    func view() -> UIView { self }
}
#endif
