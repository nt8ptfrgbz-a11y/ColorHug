import AppKit
import SceneKit
import Metal

@main
struct ShanhaiRenderQA {
    static func main() throws {
        guard let device=MTLCreateSystemDefaultDevice() else {fatalError("Metal device required")}
        let root=CommandLine.arguments.count>1 ? CommandLine.arguments[1] : "docs/shanhai"
        try FileManager.default.createDirectory(atPath:root,withIntermediateDirectories:true)
        let game=ShanhaiScene(), renderer=SCNRenderer(device:device,options:nil)
        renderer.scene=game.scene;renderer.pointOfView=game.cameraNode
        func capture(_ name:String,_ phase:String,_ time:Double,_ values:[String:Any]=[:],size:CGSize=CGSize(width:1440,height:900)) throws {
            var args=values;args["phase"]=phase
            game.update(args);game.resize(size)
            for frame in 0..<80 {game.frame(time+Double(frame)/60)}
            renderer.prepare(game.scene,shouldAbortBlock:nil)
            let image=renderer.snapshot(atTime:time,with:size,antialiasingMode:.multisampling4X)
            let png=NSBitmapImageRep(data:image.tiffRepresentation!)!.representation(using:.png,properties:[:])!
            try png.write(to:URL(fileURLWithPath:root).appendingPathComponent("\(name).png"))
            print("Rendered \(name), nodes: \(game.nodeCount)")
        }
        try capture("lake","companion",2)
        try capture("sleeping","sleeping",0)
        try capture("awakening","awakening",1,["awaken":0.6])
        try capture("flight","flying",4,["flight":0.2,"steering":0.2])
        try capture("portrait","companion",3,["orbit":0.0],size:CGSize(width:780,height:1000))
        try capture("side","companion",3,["orbit":0.8])
        try capture("stars","companion",4,["realm":"stars","orbit":0.0])
        try capture("dawn","companion",4,["realm":"dawn","orbit":0.0])
        let count=game.nodeCount
        for i in 0..<90 {
            game.update(["phase":i%3==0 ? "flying" : "companion","flight":Double(i%30)/30,"steering":sin(Double(i))])
            game.frame(Double(i));game.burst(i%2==0 ? "pet" : "feed")
            game.active(false);game.frame(Double(i)+1);game.active(true)
            precondition(game.nodeCount<count+30,"Transient nodes accumulated")
        }
        print("PASS: 90 phase / reaction / pause-resume transitions; no node accumulation.")
    }
}
