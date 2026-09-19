import Foundation
import SceneKit
import QuartzCore
import simd
#if os(macOS)
import AppKit
typealias ShanColor = NSColor
typealias ShanScalar = CGFloat
#else
import UIKit
typealias ShanColor = UIColor
typealias ShanScalar = Float
#endif

// All visible geometry is rendered by SceneKit/Metal, including the swept
// dragon mesh, separate overlapping scales, water and the mountain silhouettes.
final class ShanhaiScene {
    let scene = SCNScene()
    let cameraNode = SCNNode()
    let dragon = SCNNode(), head = SCNNode(), world = SCNNode(), effects = SCNNode()
    private let body = SCNNode(), scales = SCNNode(), fins = SCNNode(), halo = SCNNode()
    private var limbs: [SCNNode] = [], eyes: [SCNNode] = [], whiskers: [SCNNode] = []
    private var rings: [SCNNode] = [], motes: [SCNNode] = []
    private var cache: [String: SCNMaterial] = [:]
    private(set) var phase = "sleeping"
    private(set) var paused = false
    private var reduce = false, awake = 0.0, steering = 0.0, flight = 0.0, orbit = 0.0
    private var mood = "moon", reaction = 0.0, lastPose = -1.0, aspect: Double = 1.5
    private var liveTime = 0.0
    private var cameraPosition = SIMD3<Float>(9, 6.8, 17)
    private var flightRings: [SCNNode] = []
    private var skyTexture: CGImage?
    private var appliedMood = ""
    private let scenery = SCNNode()
    private let dorsal = SCNNode(), summon = SCNNode(), constellation = SCNNode()
    private var moonNode=SCNNode(), mistNodes:[SCNNode]=[]
    private var realmSkies:[String:CGImage]=[:]
    private var flyBlend:Float=0
    private let jadeHex = 0x267E78, goldHex = 0xE8C47B

    init() {
        scene.rootNode.addChildNode(world); scene.rootNode.addChildNode(dragon)
        scene.rootNode.addChildNode(effects); scene.rootNode.addChildNode(cameraNode)
        dragon.addChildNode(body); dragon.addChildNode(scales); dragon.addChildNode(fins)
        dragon.addChildNode(dorsal);world.addChildNode(summon);world.addChildNode(constellation)
        dragon.addChildNode(head)
        let camera = SCNCamera(); cameraNode.camera = camera
        camera.fieldOfView = 44; camera.zNear = 0.1; camera.zFar = 250
        camera.wantsHDR = true; camera.wantsExposureAdaptation = false
        camera.exposureOffset = -0.3; camera.bloomIntensity = 0.8
        camera.bloomThreshold = 1.15; camera.bloomBlurRadius = 9
        camera.screenSpaceAmbientOcclusionIntensity = 0.6
        camera.screenSpaceAmbientOcclusionRadius = 0.7
        skyTexture=sky();scene.background.contents = skyTexture
        scene.fogColor = color(0x172E43); scene.fogStartDistance = 36; scene.fogEndDistance = 115
        scene.lightingEnvironment.contents = sky(environment: true)
        scene.lightingEnvironment.intensity = 0.5
        light(.ambient, at: SIMD3(0, 0, 0), color: 0x8EDBDF, intensity: 140)
        light(.omni, at: SIMD3(-6, 10, 9), color: 0xE0FFF1, intensity: 680)
        light(.omni, at: SIMD3(7, 5, -5), color: 0x65DCF3, intensity: 850)
        light(.omni, at: SIMD3(-3, 7, -8), color: 0xF8D9A2, intensity: 750)
        buildWorld(); buildHead(); buildLimbs(); buildFlightRings()
        buildMagic()
        realmSkies=["moon":sky(),"stars":sky(mode:"stars"),"dawn":sky(mode:"dawn")]
        update(["phase":"sleeping", "awaken":0.0]); frame(0)
    }

    func color(_ hex: Int, alpha: CGFloat = 1) -> ShanColor {
        ShanColor(red: CGFloat((hex >> 16) & 255)/255, green: CGFloat((hex >> 8) & 255)/255,
                  blue: CGFloat(hex & 255)/255, alpha: alpha)
    }

    func material(_ hex: Int, metal: CGFloat = 0.35, rough: CGFloat = 0.28,
                  glow: CGFloat = 0, alpha: CGFloat = 1) -> SCNMaterial {
        let key = "\(hex)-\(metal)-\(rough)-\(glow)-\(alpha)"
        if let m = cache[key] { return m }
        let m = SCNMaterial(); m.lightingModel = .physicallyBased
        m.diffuse.contents = color(hex); m.metalness.contents = metal; m.roughness.contents = rough
        if glow > 0 { m.emission.contents = color(hex); m.emission.intensity = glow }
        m.transparency = alpha
        cache[key] = m; return m
    }

    @discardableResult
    private func add(_ geometry: SCNGeometry, _ mat: SCNMaterial, _ position: SIMD3<Float>,
                     _ parent: SCNNode) -> SCNNode {
        geometry.firstMaterial = mat
        let n = SCNNode(geometry: geometry); n.simdPosition = position; parent.addChildNode(n); return n
    }

    @discardableResult
    private func ellipsoid(_ at: SIMD3<Float>, _ scale: SIMD3<Float>, _ mat: SCNMaterial, _ parent: SCNNode) -> SCNNode {
        let g = SCNSphere(radius: 1); g.segmentCount = 24
        let n = add(g, mat, at, parent); n.simdScale = scale; return n
    }

    private func light(_ type: SCNLight.LightType, at: SIMD3<Float>, color hex: Int, intensity: CGFloat) {
        let n = SCNNode(); n.light = SCNLight(); n.light!.type = type
        n.light!.color = color(hex); n.light!.intensity = intensity
        n.simdPosition = at; scene.rootNode.addChildNode(n)
    }

    private func sky(environment: Bool = false, mode:String="moon") -> CGImage {
        let width = 1024, height = 512
        let cs = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data:nil,width:width,height:height,bitsPerComponent:8,bytesPerRow:width*4,
                                space:cs,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
        let palette:[Int]=mode=="dawn" ? [0x735064,0x372D4C,0x111C38] : mode=="stars" ? [0x282D53,0x171B39,0x040920] : [0x233D4D,0x10223A,0x060C21]
        let colors = environment ? [color(0x172334).cgColor, color(0x88A9B5).cgColor, color(0xEBDAC1).cgColor] : palette.map{color($0).cgColor}
        let gradient = CGGradient(colorsSpace:cs,colors:colors as CFArray,locations:[0,0.45,1])!
        context.drawLinearGradient(gradient,start:CGPoint(x:0,y:0),end:CGPoint(x:0,y:height),options:[])
        if !environment {
            for i in 0..<360 {
                let x = Double((i*733+17)%1024), y = Double((i*317+91)%480)
                let r: Double = i%7 == 0 ? 1.3 : 0.6
                context.setFillColor(color(i%5 == 0 ? 0xE8D7B2 : 0xBBDEEC,alpha:CGFloat(0.25+Double(i%6)*0.1)).cgColor)
                context.fillEllipse(in:CGRect(x:x,y:y,width:r*2,height:r*2))
            }
        }
        return context.makeImage()!
    }

    // Smooth, closed, continuous tube with normals and texture coordinates.
    private func tube(_ points: [SIMD3<Float>], radii: [Float], material: SCNMaterial,
                      sides: Int = 12) -> SCNGeometry {
        var v: [SCNVector3] = [], n: [SCNVector3] = [], uv: [CGPoint] = [], idx: [Int32] = []
        for i in points.indices {
            let tangent = simd_normalize(points[min(i+1,points.count-1)]-points[max(0,i-1)])
            let axis: SIMD3<Float> = abs(tangent.y) > 0.96 ? SIMD3(1,0,0) : SIMD3(0,1,0)
            let u = simd_normalize(simd_cross(tangent,axis)), w = simd_cross(tangent,u)
            for j in 0...sides {
                let a = Float(j)/Float(sides)*Float.pi*2
                let normal = u*cos(a)+w*sin(a)
                v.append(SCNVector3(points[i]+normal*radii[i])); n.append(SCNVector3(normal))
                uv.append(CGPoint(x:Double(j)/Double(sides),y:Double(i)/Double(points.count-1)))
                if i<points.count-1 && j<sides {
                    let a=Int32(i*(sides+1)+j), b=a+Int32(sides+1)
                    idx += [a,a+1,b,a+1,b+1,b]
                }
            }
        }
        // Endpoints are pinched to tiny radii by callers, avoiding open ends.
        let g=SCNGeometry(sources:[SCNGeometrySource(vertices:v),SCNGeometrySource(normals:n),SCNGeometrySource(textureCoordinates:uv)],
                          elements:[SCNGeometryElement(indices:idx,primitiveType:.triangles)])
        g.firstMaterial=material;return g
    }

    private func curve(_ control: [SIMD3<Float>], samples: Int) -> [SIMD3<Float>] {
        (0..<samples).map { i in
            let f=Float(i)/Float(samples-1)*Float(control.count-1), k=min(control.count-2,Int(f)), t=f-Float(k)
            let p0=control[max(0,k-1)],p1=control[k],p2=control[k+1],p3=control[min(control.count-1,k+2)]
            let a:SIMD3<Float> = p1*2
            let b:SIMD3<Float> = (p2-p0)*t
            let c:SIMD3<Float> = (p0*2-p1*5+p2*4-p3)*(t*t)
            let d:SIMD3<Float> = (-p0+p1*3-p2*3+p3)*(t*t*t)
            return (a+b+c+d)*0.5
        }
    }

    @discardableResult
    private func tendril(_ control:[SIMD3<Float>], radius:Float, _ mat:SCNMaterial, parent:SCNNode) -> SCNNode {
        let p=curve(control,samples:28)
        let r=(0..<p.count).map{radius*pow(1-Float($0)/Float(p.count),0.7)+0.002}
        let node=SCNNode(geometry:tube(p,radii:r,material:mat,sides:8));parent.addChildNode(node);return node
    }

    private func buildHead() {
        let jade=material(0x62B3A4,metal:0.28,rough:0.22)
        let dark=material(0x19584F,metal:0.2,rough:0.27)
        let gold=material(goldHex,metal:0.78,rough:0.22)
        let ivory=material(0xDBE4BF,metal:0.2,rough:0.3)
        ellipsoid(SIMD3(0,0,0),SIMD3(0.69,0.55,0.78),jade,head)
        ellipsoid(SIMD3(0,-0.13,0.66),SIMD3(0.48,0.28,0.76),jade,head)
        ellipsoid(SIMD3(0,-0.31,0.75),SIMD3(0.43,0.13,0.67),ivory,head)
        ellipsoid(SIMD3(0,-0.035,1.18),SIMD3(0.46,0.22,0.30),dark,head)
        for side:Float in [-1,1] {
            ellipsoid(SIMD3(side*0.24,0.12,1.24),SIMD3(0.10,0.047,0.07),material(0x062D2C),head)
            let socket=ellipsoid(SIMD3(side*0.49,0.13,0.44),SIMD3(0.24,0.19,0.31),dark,head)
            socket.eulerAngles.z = ShanScalar(side)*(-0.14)
            let eye=ellipsoid(SIMD3(side*0.59,0.18,0.58),SIMD3(0.145,0.13,0.18),material(0xF2D69A,metal:0.2,rough:0.13,glow:0.5),head)
            eyes.append(eye)
            ellipsoid(SIMD3(side*0.632,0.18,0.71),SIMD3(0.058,0.088,0.043),material(0x102623,rough:0.1),head)
            ellipsoid(SIMD3(side*0.625,0.222,0.738),SIMD3(0.024,0.028,0.02),material(0xFFFFFF,glow:1),head)
            tendril([SIMD3(side*0.35,0.32,0.72),SIMD3(side*0.58,0.40,0.40),SIMD3(side*0.74,0.36,0.08)],radius:0.105,gold,parent:head)
            // Branching antler horns, not a crown or a pair of cones.
            tendril([SIMD3(side*0.42,0.39,-0.19),SIMD3(side*0.61,0.91,-0.40),SIMD3(side*0.49,1.43,-0.68),SIMD3(side*0.73,1.74,-0.81)],radius:0.145,gold,parent:head)
            tendril([SIMD3(side*0.58,0.90,-0.43),SIMD3(side*0.93,1.08,-0.52),SIMD3(side*1.04,1.35,-0.62)],radius:0.075,gold,parent:head)
            tendril([SIMD3(side*0.51,1.35,-0.64),SIMD3(side*0.25,1.60,-0.78)],radius:0.05,gold,parent:head)
            let ear=ellipsoid(SIMD3(side*0.76,0.13,-0.28),SIMD3(0.34,0.15,0.44),jade,head)
            ear.eulerAngles.z=ShanScalar(side)*0.5
            // Layered cheek mane in ivory jade and gilt edges.
            for j in 0..<6 {
                let f=Float(j)
                tendril([SIMD3(side*0.51,0.06-f*0.09,-0.27),SIMD3(side*(0.86+f*0.035),-0.05-f*0.08,-0.56),
                         SIMD3(side*(0.81+f*0.07),0.05-f*0.08,-1.12-f*0.03)],radius:0.10, j%2==0 ? gold : ivory,parent:head)
            }
            let whisker=tendril([SIMD3(side*0.35,-0.02,1.27),SIMD3(side*1.04,0.14,1.50),SIMD3(side*1.7,0.39,1.04),
                                SIMD3(side*1.99,0.72,0.75),SIMD3(side*1.70,0.96,0.60)],radius:0.038,
                               material(0xEED79C,metal:0.55,rough:0.25,glow:0.35),parent:head)
            whiskers.append(whisker)
            tendril([SIMD3(side*0.3,-0.38,0.70),SIMD3(side*0.29,-0.67,0.48),SIMD3(side*0.12,-0.85,0.32)],radius:0.065,ivory,parent:head)
        }
        // Forehead inlay, a pearl clasp, and a small articulated saddle.
        let jewel=ellipsoid(SIMD3(0,0.50,0.30),SIMD3(0.14,0.065,0.24),material(0xBCEFE4,metal:0.25,rough:0.12,glow:0.6),head)
        jewel.eulerAngles.x = -0.25
        for i in 0..<4 {
            ellipsoid(SIMD3(0,0.51-Float(i)*0.02,-Float(i)*0.15),SIMD3(0.15-Float(i)*0.022,0.055,0.11),gold,head)
        }
    }

    private func buildLimbs() {
        for side:Float in [-1,1] {
            for rear in [false,true] {
                let limb=SCNNode();dragon.addChildNode(limb);limbs.append(limb)
                let jade=material(0x408F80,metal:0.3,rough:0.26)
                tendril([SIMD3(0,0,0),SIMD3(side*0.48,-0.32,0.18),SIMD3(side*0.67,-0.68,0.36),SIMD3(side*0.52,-0.92,0.62)],radius:rear ? 0.20 : 0.24,jade,parent:limb)
                ellipsoid(SIMD3(side*0.55,-0.89,0.65),SIMD3(0.25,0.12,0.26),jade,limb)
                for j in 0..<3 {
                    let x=side*0.55+Float(j-1)*0.17
                    tendril([SIMD3(x,-0.9,0.65),SIMD3(x,-0.95,0.92),SIMD3(x,-0.89,1.06)],radius:0.07,material(0xE4D4A3,metal:0.6),parent:limb)
                }
            }
        }
    }

    private func spine(_ time:Double) -> [SIMD3<Float>] {
        let flightControl:[SIMD3<Float>]=[SIMD3(0,2.5,-3.2),SIMD3(-0.3,2.3,-1.8),SIMD3(0.3,2.1,0.3),SIMD3(-0.3,2.0,2.3),
                     SIMD3(0.4,2.3,4.0),SIMD3(-0.4,2.6,5.8),SIMD3(0.5,2.8,7.6),SIMD3(0.2,3.3,9)]
        let lakeControl:[SIMD3<Float>]=[SIMD3(-2.5,2.7,1.2),SIMD3(-1.95,2.2,0.2),SIMD3(0.0,1.75,0),SIMD3(2.75,2.0,-0.4),
                     SIMD3(3.1,3.3,-1.9),SIMD3(0.4,4.0,-2.8),SIMD3(-1.5,3.5,-3.5),SIMD3(0.9,2.6,-4.0),SIMD3(4.2,3.4,-3.7)]
        let lake=curve(lakeControl,samples:89),fly=curve(flightControl,samples:89)
        return lake.enumerated().map { i,point in
            let p=simd_mix(point,fly[i],SIMD3(repeating:flyBlend))
            let f=Float(i)/88, t=Float(time)
            return p+SIMD3(sin(f*10-t*1.7)*0.12*f,sin(f*11-t*1.6)*0.14,cos(f*8-t)*0.10*f)
        }
    }

    private func dragonPose(_ time: Double) {
        let points=spine(time), count=points.count
        let radii=(0..<count).map{ i -> Float in
            let t=Float(i)/Float(count-1)
            return max(0.014,0.50*pow(1-t,0.64)*(1+0.07*sin(t*8)))
        }
        body.geometry=tube(points,radii:radii,material:material(jadeHex,metal:0.45,rough:0.25),sides:20)
        // Each scale is its own curved, overlapping lozenge, combined into a
        // single mesh to keep draw-call count bounded as the spine undulates.
        var vertices:[SCNVector3]=[],normals:[SCNVector3]=[],indices:[Int32]=[]
        var goldVertices:[SCNVector3]=[],goldNormals:[SCNVector3]=[],goldIndices:[Int32]=[]
        for i in stride(from:1,to:count-2,by:2) {
            let tangent=simd_normalize(points[i+1]-points[i-1])
            let u=simd_normalize(simd_cross(tangent,SIMD3<Float>(0,1,0))),w=simd_cross(tangent,u)
            let r=radii[i]
            for j in 0..<11 {
                let angle=(Float(j)+Float((i/2)%2)*0.5)/11*Float.pi*2
                let normal=u*cos(angle)+w*sin(angle), across = -u*sin(angle)+w*cos(angle)
                let center=points[i]+normal*(r+0.012), length:Float=0.17*(0.5+r),width=r*0.30
                let local=[center-tangent*length,center+across*width,center+normal*0.025,
                           center-across*width,center+tangent*length*1.35]
                let gold = j == 2 || j == 3
                let base=Int32(gold ? goldVertices.count : vertices.count)
                let tris:[Int32]=[0,1,2,0,2,3,1,4,2,2,4,3].map{$0+base}
                if gold {goldVertices+=local.map(SCNVector3.init);goldNormals+=Array(repeating:SCNVector3(normal),count:5);goldIndices+=tris}
                else {vertices+=local.map(SCNVector3.init);normals+=Array(repeating:SCNVector3(normal),count:5);indices+=tris}
            }
        }
        func mesh(_ v:[SCNVector3],_ n:[SCNVector3],_ i:[Int32],_ m:SCNMaterial)->SCNGeometry {
            let g=SCNGeometry(sources:[SCNGeometrySource(vertices:v),SCNGeometrySource(normals:n)],elements:[SCNGeometryElement(indices:i,primitiveType:.triangles)])
            m.isDoubleSided=true;g.firstMaterial=m;return g
        }
        scales.geometry=mesh(vertices,normals,indices,material(0x438F82,metal:0.32,rough:0.35))
        fins.geometry=mesh(goldVertices,goldNormals,goldIndices,material(0xE4CA8C,metal:0.68,rough:0.26))
        var dv:[SCNVector3]=[],dn:[SCNVector3]=[],di:[Int32]=[]
        for i in stride(from:7,to:count-5,by:4) {
            let tangent=simd_normalize(points[i+1]-points[i-1])
            let up=simd_normalize(SIMD3<Float>(0,1,0)-tangent*tangent.y)
            let base=points[i]+up*radii[i]*0.9, height=radii[i]*0.95
            let ridge=[base-tangent*0.17,base+up*height*1.1-tangent*0.11,base+up*height*0.38+tangent*0.07,base+tangent*0.23]
            let j=Int32(dv.count);dv+=ridge.map(SCNVector3.init)
            dn+=Array(repeating:SCNVector3(simd_cross(tangent,up)),count:4);di += [j,j+1,j+2,j,j+2,j+3]
        }
        dorsal.geometry=mesh(dv,dn,di,material(0xA99565,metal:0.45,rough:0.45))
        head.simdPosition=points[0]
        head.simdOrientation=simd_quatf(from:SIMD3<Float>(0,0,1),to:simd_normalize(points[0]-points[3]))
        let moodNod=Float(reaction>0 ? sin(reaction*Double.pi)*0.18 : sin(time*0.65)*0.025)
        head.simdOrientation=head.simdOrientation*simd_quatf(angle:moodNod,axis:SIMD3(1,0,0))
        for (i,limb) in limbs.enumerated() {
            let index = i%2 == 0 ? 11 : 39
            limb.simdPosition=points[index]
            limb.eulerAngles.x = ShanScalar(sin(time*1.5+Double(i))*0.13)
        }
        let blink = time.truncatingRemainder(dividingBy:5.3)>5.1
        for eye in eyes { eye.scale.y = blink ? 0.015 : 0.13 }
        for (i,whisker) in whiskers.enumerated() {whisker.eulerAngles.z=ShanScalar(sin(time*1.2+Double(i))*0.04)}
    }

    private func buildWorld() {
        let water=SCNPlane(width:160,height:160)
        water.widthSegmentCount=1;water.heightSegmentCount=1
        let mat=material(0x082E3B,metal:0.28,rough:0.48)
        mat.shaderModifiers=[.surface:"""
        #pragma arguments
        float shanTime;
        #pragma body
        float2 p = _surface.diffuseTexcoord * 130.0;
        float waves = sin(p.x * 2.8 + sin(p.y * 1.3 + shanTime * 0.4) + shanTime * 0.7);
        waves *= sin(p.y * 5.0 - shanTime * 0.6);
        _surface.normal = normalize(_surface.normal + float3(waves * 0.06, sin(p.x + shanTime) * 0.04, 0));
        float shine = pow(max(0.0, waves), 14.0);
        _surface.emission.rgb += float3(0.07, 0.27, 0.28) * shine * 0.6;
        """]
        mat.setValue(0,forKey:"shanTime")
        let lake=add(water,mat,SIMD3(0,-0.03,0),world);lake.eulerAngles.x = -.pi/2;lake.name="lake"
        // A carved circular summoning dais sits just beneath the water surface.
        let disk=SCNCylinder(radius:4.6,height:0.07);disk.radialSegmentCount=96
        add(disk,material(0x17323C,metal:0.25,rough:0.55),SIMD3(0,-0.03,0),world)
        for (i,radius) in [3.7,4.15,4.48,5.05].enumerated() {
            let g=SCNTorus(ringRadius:radius,pipeRadius:i==1 ? 0.017 : 0.01);g.ringSegmentCount=128;g.pipeSegmentCount=6
            let ring=add(g,material(0x75CCBB,metal:0.5,rough:0.25,glow:0.8),SIMD3(0,0.045,0),world)
            rings.append(ring)
        }
        for i in 0..<48 {
            let a=Float(i)/48*Float.pi*2
            let g=SCNBox(width:i%4==0 ? 0.035 : 0.02,height:0.008,length:i%4==0 ? 0.28 : 0.12,chamferRadius:0)
            let mark=add(g,material(goldHex,glow:0.6),SIMD3(cos(a)*4.30,0.06,sin(a)*4.30),world)
            mark.eulerAngles.y = ShanScalar(-a+Float.pi/2)
        }
        // Multiple depth layers use real ridged meshes rather than backplates.
        world.addChildNode(scenery)
        for layer in 0..<3 {
            for i in 0..<11 {
                let x=Float(i-5)*9+Float(layer)*3,z=Float(-22-layer*20)-Float(i%3)*3
                let height:Float=Float(6+(i*7+layer*3)%10)*(abs(x)<13 ? 0.42 : 1)
                let mountain=mountainMesh(seed:i+layer*17,height:height,radius:Float(5+layer*2))
                let colors=[0x153541,0x234555,0x345264]
                let peak=add(mountain,material(colors[layer],metal:0,rough:1),SIMD3(x,-0.1,z),scenery)
                peak.name="mountain-\(layer)"
            }
        }
        // Distant moon: actual emissive sphere with thin astronomical rings.
        moonNode=ellipsoid(SIMD3(-5,8.2,-22),SIMD3(2.2,2.2,0.6),material(0xD3C6A3,metal:0,rough:1,glow:0.45),scenery)
        for radius in [2.6,2.80] {
            let torus=SCNTorus(ringRadius:radius,pipeRadius:0.018);torus.ringSegmentCount=100
            let n=add(torus,material(0xD2BC86,glow:0.3),SIMD3(-5,8.2,-21.7),scenery);n.eulerAngles.x = .pi/2
        }
        for side:Float in [-1,1] {
            let island=SCNNode(); island.simdPosition=SIMD3(side*11,1,-8);scenery.addChildNode(island)
            add(mountainMesh(seed:3,height:3,radius:3.5),material(0x204C55,rough:0.9),SIMD3(0,-2.5,0),island)
            buildPagoda(island, at: SIMD3(0,0.5,0), scale:0.6)
        }
        for i in 0..<60 {
            let x=Float((i*37)%101)/101*28-14,z=Float((i*61)%103)/103*23-13
            let n=ellipsoid(SIMD3(x,Float(i%7)*0.6+0.5,z),SIMD3(repeating:Float(i%3+1)*0.018),material(i%3==0 ? goldHex : 0x83EFDC,glow:1.5),world)
            n.name="mote";motes.append(n)
        }
        // A ribbon of luminous mist marks the portal during awakening.
        world.addChildNode(halo)
        let path=(0..<100).map { i -> SIMD3<Float> in
            let a=Float(i)/99*Float.pi*2
            return SIMD3(cos(a)*5,0.15,sin(a)*5)
        }
        halo.geometry=tube(path,radii:Array(repeating:0.028,count:path.count),material:material(0xA0F9EA,glow:1.4),sides:6)
    }

    private func mountainMesh(seed:Int,height:Float,radius:Float)->SCNGeometry {
        var v:[SCNVector3]=[],idx:[Int32]=[]
        let sides=32,levels=24
        for level in 0..<levels {
            let f=Float(level)/Float(levels-1)
            for j in 0..<sides {
                let a=Float(j)/Float(sides)*Float.pi*2
                let ridge:Float=0.82+0.13*sin(a*5+Float(seed))+0.05*cos(a*9+f*8)
                let r=max(0.01,radius*pow(1-f,0.60)*ridge)
                v.append(SCNVector3(SIMD3(cos(a)*r+sin(f*3+Float(seed))*0.5,f*height,sin(a)*r)))
                if level<levels-1 {
                    let a=Int32(level*sides+j), b=Int32(level*sides+(j+1)%sides),c=a+Int32(sides),d=b+Int32(sides)
                    idx += [a,c,b,b,c,d]
                }
            }
        }
        var normal=Array(repeating:SIMD3<Float>(0,0,0),count:v.count)
        for i in stride(from:0,to:idx.count,by:3) {
            let a=Int(idx[i]),b=Int(idx[i+1]),c=Int(idx[i+2])
            let av=SIMD3<Float>(Float(v[a].x),Float(v[a].y),Float(v[a].z))
            let bv=SIMD3<Float>(Float(v[b].x),Float(v[b].y),Float(v[b].z))
            let cv=SIMD3<Float>(Float(v[c].x),Float(v[c].y),Float(v[c].z))
            let n=simd_cross(bv-av,cv-av);normal[a]+=n;normal[b]+=n;normal[c]+=n
        }
        let normals=normal.map{SCNVector3(simd_length($0)>0.0001 ? simd_normalize($0) : SIMD3<Float>(0,1,0))}
        return SCNGeometry(sources:[SCNGeometrySource(vertices:v),SCNGeometrySource(normals:normals)],elements:[SCNGeometryElement(indices:idx,primitiveType:.triangles)])
    }

    private func buildPagoda(_ parent:SCNNode,at:SIMD3<Float>,scale:Float) {
        let root=SCNNode();root.simdPosition=at;root.simdScale=SIMD3(repeating:scale);parent.addChildNode(root)
        for level in 0..<3 {
            let y=Float(level)*1.1
            let base=SCNCylinder(radius:CGFloat(1.1-Float(level)*0.18),height:0.8);base.radialSegmentCount=6
            add(base,material(0x324E50,rough:0.7),SIMD3(0,y,0),root)
            let roof=SCNCone(topRadius:0.18,bottomRadius:CGFloat(1.75-Float(level)*0.26),height:0.7);roof.radialSegmentCount=6
            add(roof,material(0x253740,metal:0.4),SIMD3(0,y+0.7,0),root)
            for j in 0..<6 {
                let a=Float(j)/6*Float.pi*2
                let lamp=SCNBox(width:0.13,height:0.33,length:0.12,chamferRadius:0.02)
                add(lamp,material(0xEED291,glow:1.1),SIMD3(cos(a)*(1.1-Float(level)*0.18),y,sin(a)*(1.1-Float(level)*0.18)),root)
            }
        }
    }

    private func buildFlightRings() {
        for i in 0..<7 {
            let root=SCNNode();effects.addChildNode(root);flightRings.append(root)
            for radius in [1.65,1.85] {
                let g=SCNTorus(ringRadius:radius,pipeRadius:radius==1.65 ? 0.038 : 0.015);g.ringSegmentCount=80;g.pipeSegmentCount=6
                let n=add(g,material(i%2==0 ? 0x78E7D8 : goldHex,glow:1.2),SIMD3(0,0,0),root);n.eulerAngles.x = .pi/2
            }
            for j in 0..<8 {
                let a=Float(j)/8*Float.pi*2
                ellipsoid(SIMD3(cos(a)*1.85,sin(a)*1.85,0),SIMD3(repeating:0.065),material(goldHex,glow:1.5),root)
            }
        }
    }

    private func buildMagic() {
        let cs=CGColorSpaceCreateDeviceRGB()
        let ctx=CGContext(data:nil,width:512,height:128,bitsPerComponent:8,bytesPerRow:512*4,space:cs,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
        for i in 0..<28 {
            ctx.saveGState()
            let x=Double((i*89)%470+20), y=Double((i*31)%65+30)
            ctx.translateBy(x:x,y:y);ctx.scaleBy(x:2.8,y:0.65)
            let gradient=CGGradient(colorsSpace:cs,colors:[color(0xB5D5CE,alpha:0.22).cgColor,color(0xB5D5CE,alpha:0).cgColor] as CFArray,locations:[0,1])!
            ctx.drawRadialGradient(gradient,startCenter:.zero,startRadius:0,endCenter:.zero,endRadius:40,options:[])
            ctx.restoreGState()
        }
        let texture=ctx.makeImage()!
        for i in 0..<5 {
            let mat=SCNMaterial();mat.lightingModel = .constant;mat.diffuse.contents=texture
            mat.isDoubleSided=true;mat.writesToDepthBuffer=false;mat.transparency=0.20
            let plane=SCNPlane(width:CGFloat(38+i*7),height:CGFloat(4+i))
            let n=add(plane,mat,SIMD3(Float(i%2)*5-3,1.0+Float(i)*0.65,-9-Float(i)*9),scenery)
            mistNodes.append(n)
        }
        for j in 0..<5 {
            let points=(0..<100).map {i -> SIMD3<Float> in
                let t=Float(i)/99,a=t*Float.pi*3+Float(j)*Float.pi*2/5
                let r:Float=3.7-t*1.7
                return SIMD3(cos(a)*r,t*4.4,sin(a)*r)
            }
            let radii=(0..<100).map{i in Float(0.018+sin(Double(i)/99*Double.pi)*0.024)}
            let n=SCNNode(geometry:tube(points,radii:radii,material:material(j%2==0 ? 0x77EAD8 : 0xD8CB9D,glow:0.7,alpha:0.7),sides:6))
            summon.addChildNode(n)
        }
        for j in 0..<5 {
            let start=SIMD3<Float>(Float(j-2)*4.8,10+Float(j%2)*2,-19-Float(j%3)*3)
            var points:[SIMD3<Float>]=[]
            for i in 0..<5 {
                let p=start+SIMD3<Float>(Float(i)*0.9,sin(Float(i*3+j))*0.9,0)
                points.append(p)
                ellipsoid(p,SIMD3(repeating:0.04),material(0xCBC2FF,glow:1.4),constellation)
            }
            let line=SCNNode(geometry:tube(points,radii:Array(repeating:0.012,count:points.count),material:material(0xAFA4DC,glow:0.6),sides:4))
            constellation.addChildNode(line)
        }
    }

    func resize(_ size:CGSize) {if size.height>0 {aspect=Double(size.width/size.height)}}

    func update(_ values:[String:Any]) {
        if let p=values["phase"] as? String, ["sleeping","awakening","companion","flying","arrival"].contains(p) {phase=p}
        reduce=values["reducedMotion"] as? Bool ?? reduce
        awake=finite(values["awaken"], fallback:awake).clamped(0,1)
        steering=finite(values["steering"],fallback:steering).clamped(-1,1)
        flight=finite(values["flight"],fallback:flight).clamped(0,1)
        orbit=finite(values["orbit"],fallback:orbit).clamped(-0.9,0.9)
        reaction=finite(values["reaction"],fallback:reaction).clamped(0,1)
        if let m=values["realm"] as? String {mood=m}
        lastPose = -1
    }

    private func finite(_ value:Any?,fallback:Double)->Double {
        guard let v=value as? Double,v.isFinite else{return fallback};return v
    }

    func active(_ value:Bool) {paused = !value; scene.isPaused = !value}

    /// Render time is supplied by the platform view's paused-aware clock or QA.
    func frame(_ time:Double) {
        guard !paused else {return}
        liveTime=time
        let t=reduce ? 0 : time
        if lastPose<0 || t-lastPose>1.0/24 {
            dragonPose(t);lastPose=t
        }
        let flying=phase=="flying"
        let desiredBlend:Float=flying ? 1 : 0
        flyBlend=reduce ? desiredBlend : flyBlend+(desiredBlend-flyBlend)*0.045
        let sleeping=phase=="sleeping"
        let rise=phase=="awakening" ? Float(awake) : sleeping ? 0 : 1
        dragon.opacity=sleeping ? 0.30 : phase=="awakening" ? CGFloat(0.3+awake*0.7) : 1
        dragon.simdPosition=SIMD3(flying ? Float(steering)*3 : 0, sleeping ? -1.65 : (1-rise)*(-1.65),0)
        dragon.eulerAngles.z=flying && !reduce ? ShanScalar(-steering*0.14) : 0
        halo.opacity=phase=="awakening" ? CGFloat(sin(awake*Double.pi)*0.8+0.2) : sleeping ? 0.4 : 0.12
        halo.simdScale=SIMD3(repeating:phase=="awakening" ? Float(1+sin(awake*Double.pi)*0.15) : 1)
        summon.isHidden=phase != "awakening"
        summon.opacity=CGFloat(sin(awake*Double.pi))*0.9
        summon.eulerAngles.y=ShanScalar(t*0.8)
        summon.simdScale=SIMD3(1,Float(max(0.01,awake)),1)
        for (i,ring) in rings.enumerated() {ring.opacity=CGFloat(0.45+0.22*sin(t*0.8+Double(i)))}
        for (i,n) in motes.enumerated() {
            n.position.y=ShanScalar(Double(i%7)*0.6+0.5+sin(t*0.7+Double(i))*0.18)
            n.opacity=CGFloat(0.45+0.4*sin(t+Double(i)))
        }
        world.childNode(withName:"lake",recursively:false)?.geometry?.firstMaterial?.setValue(Float(t),forKey:"shanTime")
        let cameraBase:SIMD3<Float>, target:SIMD3<Float>
        do {
            let distance:Float=aspect<0.85 ? 22 : 14
            let angle=Float(orbit)+(phase=="awakening" && !reduce ? Float((1-awake)*0.18) : 0)
            let lakeCamera=SIMD3<Float>(6*cos(angle)+distance*sin(angle),aspect<0.85 ? 7.8 : 5.8,distance*cos(angle)-6*sin(angle))
            let flightCamera=SIMD3<Float>(Float(steering)*2.3,5.7,12.8)
            cameraBase=simd_mix(lakeCamera,flightCamera,SIMD3(repeating:flyBlend))
            target=simd_mix(SIMD3<Float>(0,2,-0.7),SIMD3<Float>(Float(steering)*2,2.5,-9),SIMD3(repeating:flyBlend))
            cameraNode.camera?.fieldOfView=CGFloat(44+flyBlend*13)
        }
        cameraPosition=cameraBase
        cameraNode.simdPosition=cameraPosition;cameraNode.look(at:SCNVector3(target))
        for (i,ring) in flightRings.enumerated() {
            ring.isHidden = !flying
            let z = Float(i)*(-16)-8+Float(flight)*112
            ring.simdPosition=SIMD3(Float(sin(Double(i)*1.7))*3,2.5,z)
            ring.opacity=z>5 ? 0 : 1
        }
        scenery.simdPosition=SIMD3(0,0,flying ? Float(flight)*8 : 0)
        for (i,mist) in mistNodes.enumerated() {mist.position.x=ShanScalar(sin(t*0.08+Double(i))*2)}
        if mood != appliedMood {
          appliedMood=mood
          constellation.isHidden=mood != "stars"
          scene.background.contents=realmSkies[mood] ?? skyTexture
          let palette:[Int]=mood=="dawn" ? [0x493847,0x514154,0x605369] : mood=="stars" ? [0x1B2C46,0x273550,0x394665] : [0x153541,0x234555,0x345264]
          for peak in scenery.childNodes {
            if let name=peak.name,name.hasPrefix("mountain-"),let layer=Int(name.suffix(1)) {
                peak.geometry?.firstMaterial=material(palette[layer],metal:0,rough:1)
            }
          }
          moonNode.geometry?.firstMaterial=material(mood=="dawn" ? 0xDFA58C : 0xD3C6A3,metal:0,rough:1,glow:0.45)
          if mood=="dawn" {
            scene.fogColor=color(0x594757)
          } else if mood=="stars" {
            scene.fogColor=color(0x15233F)
          } else {scene.fogColor=color(0x172E43)}
        }
    }

    func burst(_ kind:String) {
        // Bounded transient geometry with lifetime owned by SceneKit actions.
        effects.childNode(withName:"burst",recursively:false)?.removeFromParentNode()
        let group=SCNNode();group.name="burst";effects.addChildNode(group)
        let at=dragon.convertPosition(head.position,to:scene.rootNode)
        group.position=at
        if kind=="feed" {
            let pearl=ellipsoid(SIMD3(1.2,-1.5,2),SIMD3(repeating:0.22),material(0xF1E3AE,metal:0.25,rough:0.15,glow:0.7),group)
            let fly=SCNAction.move(to:SCNVector3(0,0,0.4),duration:reduce ? 0.2 : 0.75);fly.timingMode = .easeInEaseOut
            pearl.runAction(.sequence([fly,.scale(to:0.01,duration:0.2),.removeFromParentNode()]))
        }
        for i in 0..<(reduce ? 6 : 26) {
            let a=Float(i)*2.39996
            let n=ellipsoid(SIMD3(0,0,0),SIMD3(repeating:0.045+Float(i%3)*0.02),
                            material(kind=="feed" ? 0xFFD796 : 0x94F8E4,glow:1.5),group)
            let move=SCNAction.move(to:SCNVector3(SIMD3(cos(a)*2,0.6+Float(i%7)*0.15,sin(a)*2)),duration:reduce ? 0.3 : 1.3)
            move.timingMode = .easeOut
            n.runAction(.group([move,.fadeOut(duration:reduce ? 0.3 : 1.3)]))
        }
        group.runAction(.sequence([.wait(duration:1.5),.removeFromParentNode()]))
    }

    var nodeCount:Int {var n=0;scene.rootNode.enumerateChildNodes{_,_ in n+=1};return n}
}

private extension Double {
    func clamped(_ lower:Double,_ upper:Double)->Double {min(upper,max(lower,self))}
}
