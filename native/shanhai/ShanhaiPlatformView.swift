import Foundation
import SceneKit
#if os(macOS)
import FlutterMacOS
#else
import Flutter
#endif

final class ShanhaiPlatformFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger
    init(messenger:FlutterBinaryMessenger) {self.messenger=messenger;super.init()}
    #if os(macOS)
    func createArgsCodec()->(FlutterMessageCodec & NSObjectProtocol)? {FlutterStandardMessageCodec.sharedInstance()}
    func create(withViewIdentifier id:Int64,arguments:Any?)->NSView {
        ShanhaiNativeView(frame:.zero,id:id,messenger:messenger,values:arguments as? [String:Any] ?? [:])
    }
    #else
    func createArgsCodec()->FlutterMessageCodec & NSObjectProtocol {FlutterStandardMessageCodec.sharedInstance()}
    func create(withFrame frame:CGRect,viewIdentifier id:Int64,arguments:Any?)->FlutterPlatformView {
        ShanhaiNativeView(frame:frame,id:id,messenger:messenger,values:arguments as? [String:Any] ?? [:])
    }
    #endif
}

final class ShanhaiNativeView: SCNView, SCNSceneRendererDelegate {
    let world=ShanhaiScene()
    private var channel:FlutterMethodChannel!
    private let lock=NSRecursiveLock()
    private var closed=false, running=true
    private var previous:TimeInterval?, elapsed:TimeInterval=0

    init(frame:CGRect,id:Int64,messenger:FlutterBinaryMessenger,values:[String:Any]) {
        super.init(frame:frame,options:["preferredRenderingAPI":SCNRenderingAPI.metal.rawValue])
        scene=world.scene;pointOfView=world.cameraNode
        antialiasingMode = .multisampling4X;preferredFramesPerSecond=60
        allowsCameraControl=false;autoenablesDefaultLighting=false
        world.update(values);delegate=self;isPlaying=true;rendersContinuously=true
        channel=FlutterMethodChannel(name:"colorhug/shanhai3d/\(id)",binaryMessenger:messenger)
        channel.setMethodCallHandler { [weak self] call,result in
            guard let self=self else {result(nil);return}
            self.lock.lock();defer{self.lock.unlock()}
            guard !self.closed else {result(FlutterError(code:"disposed",message:"Scene closed",details:nil));return}
            switch call.method {
            case "update": self.world.update(call.arguments as? [String:Any] ?? [:]);result(nil)
            case "active":
                let active=call.arguments as? Bool ?? true
                self.running=active;self.previous=nil;self.world.active(active)
                self.isPlaying=active;self.rendersContinuously=active;result(nil)
            case "burst": self.world.burst(call.arguments as? String ?? "pet");result(nil)
            case "stats":result(["nodes":self.world.nodeCount,"phase":self.world.phase,"active":self.running])
            case "dispose":
                self.closed=true;self.running=false;self.delegate=nil
                self.isPlaying=false;self.rendersContinuously=false;self.scene=nil
                self.channel.setMethodCallHandler(nil);result(nil)
            default:result(FlutterMethodNotImplemented)
            }
        }
    }
    required init?(coder:NSCoder) {fatalError("Use platform factory")}
    func renderer(_ renderer:SCNSceneRenderer,updateAtTime time:TimeInterval) {
        lock.lock();defer{lock.unlock()}
        guard running && !closed else {previous=nil;return}
        if let p=previous {elapsed+=min(0.05,max(0,time-p))}
        previous=time;world.frame(elapsed)
    }
    #if os(macOS)
    override func layout() {super.layout();lock.lock();world.resize(bounds.size);lock.unlock()}
    #else
    override func layoutSubviews() {super.layoutSubviews();lock.lock();world.resize(bounds.size);lock.unlock()}
    #endif
    deinit {channel?.setMethodCallHandler(nil)}
}
#if os(iOS)
extension ShanhaiNativeView:FlutterPlatformView {
    func view()->UIView {self}
}
#endif
