import AppKit
import SceneKit
import Metal

// Standalone real-render QA uses exactly the scene implementation embedded in
// the app. Outputs are never substituted for the interactive 3D viewport.
@main
struct DressRenderQA {
    static func main() throws {
        guard let device = MTLCreateSystemDefaultDevice() else { fatalError("A Metal device is required") }
        let path = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "build/dress-up-qa"
        try FileManager.default.createDirectory(atPath:path,withIntermediateDirectories:true)
        let game = DressScene()
        // Verify actual capsule endpoints under a transformed parent. This
        // catches accidental use of world-space look-at for local geometry.
        let probe = SCNNode()
        probe.position = SCNVector3(1.7, 0.3, -1.1)
        probe.eulerAngles = SCNVector3(0.2, 0.4, -0.3)
        game.scene.rootNode.addChildNode(probe)
        for (a, b) in [
            (SCNVector3(0, 0, 0), SCNVector3(0, 1.8, 0)),
            (SCNVector3(0.3, 0.04, 0.25), SCNVector3(0.24, 0.75, 0.2)),
            (SCNVector3(-0.4, 1.8, 0), SCNVector3(0.4, 1.8, 0)),
            (SCNVector3(0, 1, 0), SCNVector3(0, -1, 0)),
            (SCNVector3(0, 0, -0.2), SCNVector3(0, 0, 0.2))
        ] {
            let rod = game.rod(a, b, radius: 0.02, hex: 0xFFFFFF, parent: probe)
            let height = (rod.geometry as! SCNCapsule).height
            for (local, expected) in [(SCNVector3(0, -height / 2, 0), a), (SCNVector3(0, height / 2, 0), b)] {
                let actual = rod.convertPosition(local, to: probe)
                let distance = sqrt(pow(actual.x - expected.x, 2) + pow(actual.y - expected.y, 2) + pow(actual.z - expected.z, 2))
                precondition(distance < 0.0001, "Rod endpoint differs from intended furniture joint: \(distance)")
            }
        }
        probe.removeFromParentNode()
        print("GEOMETRY PASS: rods meet both joints in transformed parent space")
        let renderer = SCNRenderer(device:device,options:nil)
        renderer.scene = game.scene
        renderer.pointOfView = game.cameraNode
        var look: [String:Any] = ["character":0,"outfit":"petal","top":"blouse","bottom":"pleats","shoes":"maryjane","hair":"pigtails","accessory":"bow","tint":-1,"place":"studio","reducedMotion":true]
        func capture(_ name: String, angle:Double = 0) throws {
            game.update(look)
            game.turn(angle)
            game.resize(CGSize(width:900,height:1000))
            renderer.prepare(game.scene,shouldAbortBlock:nil)
            let image=renderer.snapshot(atTime:0,with:CGSize(width:900,height:1000),antialiasingMode:.multisampling4X)
            guard let tiff=image.tiffRepresentation,let bitmap=NSBitmapImageRep(data:tiff),let png=bitmap.representation(using:.png,properties:[:]) else {fatalError("PNG failed")}
            try png.write(to:URL(fileURLWithPath:path).appendingPathComponent(name+".png"))
            print("Rendered \(name)")
        }
        try capture("studio-front")
        try capture("studio-back",angle:.pi)
        if CommandLine.arguments.contains("--stress") {
            let started = Date.timeIntervalSinceReferenceDate
            let outfits=["petal","pinafore","starlight","raincoat","sleepy","explorer"]
            let hair=["pigtails","bob","waves","buns","braids","pixie"]
            let accessories=["bow","flower","crown","bunnyears","beret","satchel"]
            for i in 0..<120 {
                look["character"]=i%2; look["outfit"]=outfits[i%6]; look["hair"]=hair[(i/6)%6]; look["accessory"]=accessories[(i/3)%6]
                look["place"]=["studio","garden","tea","night"][(i/12)%4]
                look["reducedMotion"]=i%2 == 0
                game.update(look); game.turn(Double(i)*0.4); game.pose(i%3)
                game.action(); game.active(false); game.active(true)
                var count=0
                game.scene.rootNode.enumerateChildNodes { _,_ in count += 1 }
                precondition(count < 1000, "Scene retained stale nodes: \(count)")
                if i%12 == 0 { _=renderer.snapshot(atTime:Double(i),with:CGSize(width:256,height:320),antialiasingMode:.multisampling4X) }
            }
            look["reducedMotion"]=true
            try capture("stress-final")
            print("STRESS PASS: 120 appearance / scene / pose / lifecycle transitions in \(String(format: "%.2f", Date.timeIntervalSinceReferenceDate-started))s. This is not a device FPS benchmark.")
        }
        if CommandLine.arguments.contains("--all") {
            game.pose(0)
            let outfits=["petal","pinafore","starlight","raincoat","sleepy","explorer"]
            let hair=["pigtails","bob","waves","buns","braids","pixie"]
            let accessories=["bow","flower","crown","bunnyears","beret","satchel"]
            let shoes=["maryjane","sneakers","ballet","wellies","bunny","hiking"]
            for i in 0..<6 {
                look["character"]=i%2;look["outfit"]=outfits[i];look["hair"]=hair[i];look["accessory"]=accessories[i];look["shoes"]=shoes[i]
                try capture("outfit-\(i)",angle:0.25)
                try capture("outfit-\(i)-back",angle:.pi+0.25)
            }
            for (i,place) in ["garden","tea","night"].enumerated() {
                look["place"]=place;look["outfit"]=["raincoat","petal","sleepy"][i];look["hair"]="bob";look["accessory"]=["bow","flower","bunnyears"][i];look["shoes"]=["wellies","maryjane","bunny"][i]
                try capture(place)
            }
            look["place"]="studio";look["outfit"]="";look["accessory"]=""
            let tops=["tee","cardigan","blouse","knit","hoodie","sailor"]
            let bottoms=["shorts","pleats","jeans","bloomers","cloudskirt","dungarees"]
            for i in 0..<6 {look["top"]=tops[i];look["bottom"]=bottoms[i];try capture("separates-\(i)",angle:0.35)}
            look["outfit"]="petal";look["hair"]="pigtails";look["accessory"]="flower"
            game.pose(1);try capture("pose-tilt")
            game.pose(2);try capture("pose-wave")
        }
        var nodes=0,triangles=0
        game.scene.rootNode.enumerateChildNodes { n,_ in nodes+=1;if let g=n.geometry {for e in g.elements {if e.primitiveType == .triangles {triangles+=e.primitiveCount}}} }
        print("Scene nodes: \(nodes); triangles: \(triangles)")
    }
}
