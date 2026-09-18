import Foundation
import SceneKit
import QuartzCore
import simd
#if os(macOS)
import AppKit
typealias DressColor = NSColor
typealias DressScalar = CGFloat
#else
import UIKit
typealias DressColor = UIColor
typealias DressScalar = Float
#endif

// Original, fully volumetric toy-doll art. Every garment is built all the way
// around the body, using a shared metric rig and smooth custom lathe meshes.
final class DressScene {
    let scene = SCNScene()
    let cameraNode = SCNNode()
    let doll = SCNNode()
    let body = SCNNode()
    let room = SCNNode()
    let effects = SCNNode()
    private var materials: [String: SCNMaterial] = [:]
    private var look: [String: Any] = [:]
    private var place = "studio"
    private var yaw: DressScalar = 0
    private var reduce = false
    private var leftArm = SCNNode(), rightArm = SCNNode(), head = SCNNode()
    private var eyes: [SCNNode] = []
    private var interactionStep = 0
    private var lastInteraction = -Double.infinity
    private var poseIndex = 0

    init() {
        scene.rootNode.addChildNode(room)
        scene.rootNode.addChildNode(doll)
        scene.rootNode.addChildNode(effects)
        doll.addChildNode(body)
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.camera?.orthographicScale = 1.95
        cameraNode.camera?.zNear = 0.1
        cameraNode.camera?.zFar = 70
        cameraNode.camera?.wantsHDR = true
        cameraNode.camera?.exposureOffset = -0.35
        cameraNode.camera?.wantsExposureAdaptation = false
        cameraNode.camera?.bloomIntensity = 0.13
        cameraNode.camera?.bloomThreshold = 1.3
        cameraNode.camera?.screenSpaceAmbientOcclusionIntensity = 0.55
        cameraNode.camera?.screenSpaceAmbientOcclusionRadius = 0.12
        cameraNode.position = SCNVector3(0, 2.9, 8)
        cameraNode.look(at: SCNVector3(0, 1.5, 0))
        scene.rootNode.addChildNode(cameraNode)
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.color = color(0xFFF1DC)
        ambient.light?.intensity = 95
        scene.rootNode.addChildNode(ambient)
        light(at: SCNVector3(-3, 6, 5), intensity: 170, hex: 0xFFF1DE, shadow: true)
        light(at: SCNVector3(4, 3, 1), intensity: 65, hex: 0xDEE7F5, shadow: false)
        light(at: SCNVector3(1, 4, -3), intensity: 75, hex: 0xFFDBB3, shadow: false)
        update(["outfit": "petal", "hair": "pigtails", "shoes": "maryjane", "accessory": "bow", "character": 0, "place": "studio"])
    }

    func color(_ hex: Int, alpha: CGFloat = 1) -> DressColor {
        DressColor(red: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: alpha)
    }

    func material(_ hex: Int, rough: CGFloat = 0.72, metal: CGFloat = 0, glow: Bool = false) -> SCNMaterial {
        let key = "\(hex)-\(rough)-\(metal)-\(glow)"
        if let existing = materials[key] { return existing }
        let m = SCNMaterial()
        m.lightingModel = .physicallyBased
        m.diffuse.contents = color(hex)
        m.roughness.contents = rough
        m.metalness.contents = metal
        if glow { m.emission.contents = color(hex) }
        materials[key] = m
        return m
    }

    @discardableResult
    func node(_ geometry: SCNGeometry, _ hex: Int, _ x: DressScalar, _ y: DressScalar, _ z: DressScalar, parent: SCNNode, rough: CGFloat = 0.72) -> SCNNode {
        if let capsule = geometry as? SCNCapsule { capsule.radialSegmentCount = 16; capsule.capSegmentCount = 6; capsule.heightSegmentCount = 1 }
        if let cylinder = geometry as? SCNCylinder { cylinder.radialSegmentCount = 32; cylinder.heightSegmentCount = 1 }
        if let cone = geometry as? SCNCone { cone.radialSegmentCount = 32; cone.heightSegmentCount = 1 }
        geometry.firstMaterial = material(hex, rough: rough)
        let n = SCNNode(geometry: geometry)
        n.position = SCNVector3(x, y, z)
        parent.addChildNode(n)
        return n
    }

    @discardableResult
    func ball(_ x: DressScalar, _ y: DressScalar, _ z: DressScalar, _ sx: DressScalar, _ sy: DressScalar, _ sz: DressScalar, _ hex: Int, _ parent: SCNNode, rough: CGFloat = 0.72) -> SCNNode {
        let g = SCNSphere(radius: 1)
        g.segmentCount = 24
        let n = node(g, hex, x, y, z, parent: parent, rough: rough)
        n.scale = SCNVector3(sx, sy, sz)
        return n
    }

    @discardableResult
    func box(_ x: DressScalar, _ y: DressScalar, _ z: DressScalar, _ w: CGFloat, _ h: CGFloat, _ d: CGFloat, _ hex: Int, _ parent: SCNNode, bevel: CGFloat = 0.04) -> SCNNode {
        let g = SCNBox(width: w, height: h, length: d, chamferRadius: min(bevel, min(w, min(h, d)) / 2))
        g.chamferSegmentCount = 5
        return node(g, hex, x, y, z, parent: parent)
    }

    @discardableResult
    func rod(_ a: SCNVector3, _ b: SCNVector3, radius: CGFloat, hex: Int, parent: SCNNode) -> SCNNode {
        let dx = b.x - a.x, dy = b.y - a.y, dz = b.z - a.z
        let length = CGFloat(sqrt(dx*dx + dy*dy + dz*dz))
        let g = SCNCapsule(capRadius: radius, height: max(radius * 2, length))
        g.radialSegmentCount = 12
        g.capSegmentCount = 6
        let n = node(g, hex, (a.x+b.x)/2, (a.y+b.y)/2, (a.z+b.z)/2, parent: parent)
        // Endpoints are parent-local. look(at:) expects a world-space target,
        // which bends rods incorrectly inside translated or rotated furniture.
        if length > 0.000001 {
            let direction = simd_normalize(SIMD3<Float>(Float(dx), Float(dy), Float(dz)))
            n.simdOrientation = simd_quatf(from: SIMD3<Float>(0, 1, 0), to: direction)
        }
        return n
    }

    func tube(_ points: [SCNVector3], radius: CGFloat, hex: Int, parent: SCNNode) {
        for i in 0..<(points.count - 1) { rod(points[i], points[i+1], radius: radius, hex: hex, parent: parent) }
    }

    @discardableResult
    func torus(_ x: DressScalar, _ y: DressScalar, _ z: DressScalar, ring: CGFloat, pipe: CGFloat, hex: Int, parent: SCNNode) -> SCNNode {
        let g = SCNTorus(ringRadius: ring, pipeRadius: pipe)
        g.ringSegmentCount = 72
        g.pipeSegmentCount = 12
        return node(g, hex, x, y, z, parent: parent)
    }

    // Closed, smooth lathe surface: profile entries are (height, radius).
    @discardableResult
    func lathe(_ profile: [(DressScalar, DressScalar)], depth: DressScalar = 0.72, pleats: DressScalar = 0, hex: Int, parent: SCNNode) -> SCNNode {
        let segments = 96
        var vertices: [SCNVector3] = [], normals: [SCNVector3] = [], uv: [CGPoint] = [], indices: [Int32] = []
        for j in 0..<profile.count {
            let (y, r) = profile[j]
            let lo = profile[max(0, j-1)], hi = profile[min(profile.count-1, j+1)]
            let slope = (hi.1 - lo.1) / max(0.0001, hi.0 - lo.0)
            for i in 0...segments {
                let a = DressScalar(i) / DressScalar(segments) * .pi * 2
                let ripple = pleats * cos(a * 16) * r
                let rr = max(0.001, r + ripple)
                vertices.append(SCNVector3(sin(a)*rr, y, cos(a)*rr*depth))
                let nx = sin(a), ny = -slope, nz = cos(a)/depth
                let length = sqrt(nx*nx+ny*ny+nz*nz)
                normals.append(SCNVector3(nx/length, ny/length, nz/length))
                uv.append(CGPoint(x: Double(i)/Double(segments), y: Double(j)/Double(profile.count-1)))
                if j > 0 && i > 0 {
                    let k = Int32(j*(segments+1)+i), step = Int32(segments+1)
                    indices += [k-step-1, k-step, k, k-step-1, k, k-1]
                }
            }
        }
        let sources = [SCNGeometrySource(vertices: vertices), SCNGeometrySource(normals: normals), SCNGeometrySource(textureCoordinates: uv)]
        let g = SCNGeometry(sources: sources, elements: [SCNGeometryElement(indices: indices, primitiveType: .triangles)])
        let n = node(g, hex, 0, 0, 0, parent: parent)
        g.firstMaterial?.isDoubleSided = true
        return n
    }

    private func light(at position: SCNVector3, intensity: CGFloat, hex: Int, shadow: Bool) {
        let n = SCNNode()
        let l = SCNLight()
        l.type = .omni
        l.intensity = intensity
        l.color = color(hex)
        l.castsShadow = shadow
        l.shadowMode = .deferred
        l.shadowRadius = 6
        l.shadowSampleCount = 16
        l.shadowMapSize = CGSize(width: 2048, height: 2048)
        l.shadowColor = color(0x6C5444, alpha: 0.18)
        n.light = l
        n.position = position
        scene.rootNode.addChildNode(n)
    }

    func update(_ values: [String: Any]) {
        let newPlace = values["place"] as? String ?? "studio"
        let nextReduce = values["reducedMotion"] as? Bool ?? false
        let appearanceKeys = ["character", "outfit", "top", "bottom", "shoes", "hair", "accessory", "tint"]
        let changed = appearanceKeys.contains { String(describing: values[$0]) != String(describing: look[$0]) }
        let motionChanged = reduce != nextReduce
        reduce = nextReduce
        look = values
        if changed || body.childNodes.isEmpty || motionChanged {
            buildDoll()
            if !reduce { celebrate() }
        }
        if newPlace != place || room.childNodes.isEmpty {
            place = newPlace
            interactionStep = 0
            buildRoom()
        }
        if motionChanged && reduce {
            effects.childNodes.forEach { $0.removeFromParentNode() }
        }
    }

    func turn(_ value: Double, animated: Bool = false) {
        yaw = DressScalar(value.truncatingRemainder(dividingBy: Double.pi * 2))
        SCNTransaction.begin()
        SCNTransaction.animationDuration = animated && !reduce ? 0.28 : 0
        doll.eulerAngles.y = yaw
        SCNTransaction.commit()
    }

    func resize(_ size: CGSize) {
        guard size.height > 0, size.width > 0 else { return }
        let aspect = size.width / size.height
        let fittingScale: CGFloat = size.height < 380 ? 2.25 : 1.95
        cameraNode.camera?.orthographicScale = Double(max(fittingScale, aspect < 0.6 ? 1.16 / aspect : fittingScale))
    }

    func active(_ enabled: Bool) { scene.isPaused = !enabled }

    func pose(_ index: Int) {
        poseIndex = max(0, min(2, index))
        rightArm.removeAction(forKey: "wave")
        SCNTransaction.begin()
        SCNTransaction.animationDuration = reduce ? 0 : 0.3
        rightArm.eulerAngles.z = poseIndex == 2 ? 1.35 : 0.16
        leftArm.eulerAngles.z = poseIndex == 1 ? -0.32 : -0.16
        head.eulerAngles.z = poseIndex == 1 ? -0.12 : poseIndex == 2 ? 0.07 : 0
        SCNTransaction.commit()
    }

    func action() {
        let now = Date.timeIntervalSinceReferenceDate
        guard now - lastInteraction > 0.9 else { return }
        lastInteraction = now
        guard !reduce else { interactionStep += 1; stillInteraction(); return }
        interactionStep += 1
        body.removeAction(forKey: "celebrate")
        if place == "garden" {
            let jump = SCNAction.sequence([.moveBy(x: 0, y: 0.25, z: 0, duration: 0.2), .moveBy(x: 0, y: -0.25, z: 0, duration: 0.2)])
            jump.timingMode = .easeInEaseOut
            body.runAction(jump, forKey: "jump")
            for i in 0..<20 {
                let a = DressScalar(i) * 2 * .pi / 20
                let n = ball(sin(a)*0.45, 0.08, cos(a)*0.4, 0.025, 0.06, 0.025, 0xB3D5DA, effects)
                let fly = SCNAction.moveBy(x: CGFloat(sin(a)*0.55), y: 0.35, z: CGFloat(cos(a)*0.55), duration: 0.35)
                n.runAction(.sequence([.group([fly, .fadeOut(duration: 0.65)]), .removeFromParentNode()]))
            }
            let ripple = torus(0, 0.025, 0, ring: 0.4, pipe: 0.013, hex: 0xCEE5E6, parent: effects)
            ripple.scale.z = 0.8
            ripple.runAction(.sequence([.group([.scale(to: 3, duration: 0.9), .fadeOut(duration: 0.9)]), .removeFromParentNode()]))
        } else if place == "tea" {
            room.childNode(withName: "tea", recursively: true)?.isHidden = false
            wave()
            if let pot = room.childNode(withName: "teapot", recursively: true) {
                pot.runAction(.sequence([.rotateBy(x: 0, y: 0, z: -0.4, duration: 0.35), .wait(duration: 0.45), .rotateBy(x: 0, y: 0, z: 0.4, duration: 0.35)]), forKey: "pour")
            }
            for i in 0..<7 {
                let steam = ball(1.12, 0.94, 0.65, 0.035, 0.035, 0.035, 0xFFF1DC, effects)
                steam.opacity = 0
                steam.runAction(.sequence([.wait(duration: Double(i)*0.1), .fadeIn(duration: 0.15), .group([.moveBy(x: -0.12, y: 0.5, z: 0, duration: 1), .fadeOut(duration: 1)]), .removeFromParentNode()]))
            }
        } else if place == "night" {
            wave()
            if let star = room.childNode(withName: "star\(interactionStep % 7)", recursively: true) {
                star.geometry?.firstMaterial = material(0xFFEAB3, rough: 0.5, glow: true)
                star.runAction(.sequence([.scale(to: 1.35, duration: 0.25), .scale(to: 1, duration: 0.35)]))
            }
            sparkles(hex: 0xFFE6A1)
        } else {
            let sway = SCNAction.sequence([.rotateBy(x: 0, y: 0, z: 0.06, duration: 0.2), .rotateBy(x: 0, y: 0, z: -0.12, duration: 0.4), .rotateBy(x: 0, y: 0, z: 0.06, duration: 0.2)])
            body.runAction(sway, forKey: "sway")
            wave()
            sparkles(hex: 0xEBC69A)
        }
    }

    private func stillInteraction() {
        if place == "night", let star = room.childNode(withName: "star\(interactionStep % 7)", recursively: true) {
            star.geometry?.firstMaterial = material(0xFFEAB3, glow: true)
        } else if place == "garden" {
            if effects.childNodes.count > 8 { effects.childNodes.first?.removeFromParentNode() }
            let ripple = torus(DressScalar(interactionStep % 3) * 0.15 - 0.15, 0.02, 0, ring: 0.25, pipe: 0.012, hex: 0xD2E7E6, parent: effects)
            ripple.scale.z = 0.65
        } else if place == "tea", let cup = room.childNode(withName: "tea", recursively: true) {
            cup.isHidden = false
        }
    }

    private func celebrate() {
        body.removeAction(forKey: "celebrate")
        body.scale = SCNVector3(1, 1, 1)
        body.runAction(.sequence([.scale(to: 1.018, duration: 0.13), .scale(to: 1, duration: 0.22)]), forKey: "celebrate")
    }
    private func wave() {
        rightArm.removeAction(forKey: "wave")
        rightArm.eulerAngles.z = 0.16
        rightArm.runAction(.sequence([.rotateBy(x: 0, y: 0, z: 1.1, duration: 0.25), .rotateBy(x: 0, y: 0, z: -0.2, duration: 0.16), .rotateBy(x: 0, y: 0, z: 0.2, duration: 0.16), .rotateBy(x: 0, y: 0, z: -1.1, duration: 0.3)]), forKey: "wave")
    }
    private func sparkles(hex: Int) {
        guard effects.childNodes.count < 50 else { return }
        for i in 0..<10 {
            let a = DressScalar(i) * .pi * 0.2
            let n = star(sin(a)*0.85, 1.4 + DressScalar(i % 3)*0.35, cos(a)*0.65, size: 0.06, hex: hex, parent: effects)
            n.runAction(.sequence([.group([.moveBy(x: 0, y: 0.35, z: 0, duration: 0.8), .fadeOut(duration: 0.8)]), .removeFromParentNode()]))
        }
    }

    @discardableResult
    func star(_ x: DressScalar, _ y: DressScalar, _ z: DressScalar, size: DressScalar, hex: Int, parent: SCNNode) -> SCNNode {
        var v = [SCNVector3(0, 0, 0.018)], idx: [Int32] = []
        for i in 0..<10 {
            let a = DressScalar(i) * .pi / 5
            let r = i % 2 == 0 ? size : size*0.48
            v.append(SCNVector3(sin(a)*r, cos(a)*r, 0))
        }
        for i in 0..<10 { idx += [0, Int32(i+1), Int32((i+1)%10+1)] }
        let g = SCNGeometry(sources: [SCNGeometrySource(vertices: v)], elements: [SCNGeometryElement(indices: idx, primitiveType: .triangles)])
        let n = node(g, hex, x, y, z, parent: parent)
        g.firstMaterial = material(hex, rough: 0.45, metal: 0.12)
        g.firstMaterial?.isDoubleSided = true
        return n
    }

    func flower(_ x: DressScalar, _ y: DressScalar, _ z: DressScalar, size: DressScalar, hex: Int, parent: SCNNode) {
        for i in 0..<5 {
            let a = DressScalar(i)*2 * .pi / 5
            let p = ball(x + sin(a)*size*0.55, y + cos(a)*size*0.55, z, size*0.4, size*0.55, size*0.14, hex, parent)
            p.eulerAngles.z = -a
        }
        ball(x, y, z+size*0.16, size*0.25, size*0.25, size*0.18, 0xDAB665, parent)
    }

    private func value(_ key: String, _ fallback: String) -> String { look[key] as? String ?? fallback }

    private func buildDoll() {
        body.removeAllActions()
        body.childNodes.forEach { $0.removeFromParentNode() }
        body.position = SCNVector3Zero
        body.eulerAngles = SCNVector3Zero
        body.scale = SCNVector3(1, 1, 1)
        eyes.removeAll()
        let skin = (look["character"] as? Int ?? 0) == 0 ? 0xEBC3A5 : 0xB87F5F
        let blush = (look["character"] as? Int ?? 0) == 0 ? 0xDF9B93 : 0xAD6659
        // The base body is always covered by a cream romper.
        lathe([(0.78,0.03),(0.82,0.25),(1.1,0.27),(1.4,0.29),(1.55,0.33),(1.65,0.19),(1.67,0.02)], hex: 0xF4E2CA, parent: body)
        node(SCNCapsule(capRadius: 0.105, height: 0.25), skin, 0, 1.73, 0, parent: body)
        for side: DressScalar in [-1, 1] {
            node(SCNCapsule(capRadius: 0.115, height: 0.7), skin, side*0.155, 0.55, 0, parent: body)
            let arm = SCNNode()
            arm.position = SCNVector3(side*0.325,1.55,0)
            arm.eulerAngles.z = side*0.16
            body.addChildNode(arm)
            node(SCNCapsule(capRadius: 0.092, height: 0.57), skin, 0, -0.22, 0, parent: arm)
            ball(0,-0.51,0.015,0.097,0.115,0.085,skin,arm)
            ball(-side*0.065,-0.49,0.06,0.04,0.06,0.04,skin,arm)
            if side < 0 { leftArm = arm } else { rightArm = arm }
        }
        head = SCNNode()
        body.addChildNode(head)
        ball(0,2.19,0,0.465,0.535,0.43,skin,head,rough:0.58)
        for side: DressScalar in [-1,1] {
            ball(side*0.455,2.17,-0.005,0.095,0.125,0.068,skin,head)
            ball(side*0.485,2.17,0.04,0.039,0.069,0.025,blush,head)
            ball(side*0.286,2.08,0.334,0.083,0.039,0.021,blush,head)
            let eye = SCNNode()
            eye.position = SCNVector3(side*0.17,2.23,0.395)
            eye.eulerAngles.y = side*0.17
            head.addChildNode(eye)
            ball(0,0,0,0.09,0.115,0.046,0xFFF6E7,eye,rough:0.22)
            ball(0.003,-0.004,0.041,0.063,0.085,0.017,0x513C34,eye,rough:0.18)
            ball(0.004,-0.004,0.054,0.034,0.058,0.01,0x2D2729,eye,rough:0.18)
            ball(-0.018,0.031,0.064,0.022,0.026,0.008,0xFFFFFF,eye,rough:0.1)
            ball(0.024,-0.041,0.062,0.009,0.012,0.006,0xFCE5CC,eye)
            eyes.append(eye)
            tube((0...8).map { i in let a = DressScalar(i)/8 * .pi; return SCNVector3(side*0.17 + cos(a)*0.086,2.246+sin(a)*0.103,0.432-abs(cos(a))*0.012) }, radius:0.009, hex:0x513D35, parent:head)
            tube((0...6).map { i in let xx = DressScalar(i)/6; return SCNVector3(side*0.17+(xx-0.5)*0.16,2.418+sin(xx * .pi)*0.016,0.346) }, radius:0.012, hex:0x6C4C3B, parent:head)
        }
        ball(0,2.12,0.421,0.054,0.06,0.055,skin,head)
        tube((0...10).map { i in let x = DressScalar(i)/10-0.5; return SCNVector3(x*0.14,2.007+x*x*0.16,0.4-abs(x)*0.006) }, radius:0.012, hex:0xAF6C65, parent:head)
        buildHair(value("hair", "pigtails"))
        buildClothes()
        buildShoes(value("shoes", "maryjane"))
        buildAccessory(value("accessory", "bow"))
        pose(poseIndex)
        if !reduce {
            head.runAction(.repeatForever(.sequence([.moveBy(x:0,y:0.006,z:0,duration:1.9),.moveBy(x:0,y:-0.006,z:0,duration:1.9)])), forKey:"breath")
            for eye in eyes {
                eye.runAction(.repeatForever(.sequence([.wait(duration:3.8),.scaleY(to:0.09,duration:0.07),.scaleY(to:1,duration:0.1),.wait(duration:1.7)])), forKey:"blink")
            }
        }
    }

    private func buildHair(_ style: String) {
        let colors = ["bob":0x715044,"pigtails":0x6C493C,"waves":0x8A6248,"buns":0x493A38,"braids":0x956F48,"pixie":0x503D35]
        let hex = colors[style] ?? 0x715044
        var vertices: [SCNVector3] = [], normals: [SCNVector3] = [], indices: [Int32] = []
        let rings = 28, slices = 72
        for j in 0...rings {
            for i in 0...slices {
                let a = DressScalar(i)/DressScalar(slices)*2 * .pi
                let front = max(0,cos(a))
                let maxAngle: DressScalar = 2.32 - front*1.1
                let t = DressScalar(j)/DressScalar(rings)*maxAngle
                let r = 1 + 0.012*sin(a*18+t*2)
                vertices.append(SCNVector3(sin(a)*sin(t)*0.49*r,2.22+cos(t)*0.56,cos(a)*sin(t)*0.465*r))
                normals.append(SCNVector3(sin(a)*sin(t),cos(t),cos(a)*sin(t)))
                if j > 0 && i > 0 { let k = Int32(j*(slices+1)+i), s = Int32(slices+1); indices += [k-s-1,k,k-s,k-s-1,k-1,k] }
            }
        }
        let g = SCNGeometry(sources:[SCNGeometrySource(vertices:vertices),SCNGeometrySource(normals:normals)],elements:[SCNGeometryElement(indices:indices,primitiveType:.triangles)])
        node(g,hex,0,0,0,parent:head,rough:0.48)
        g.firstMaterial?.isDoubleSided = true
        // Swept fringe locks follow the forehead rather than obscuring the eyes.
        for i in 0..<7 {
            let x = DressScalar(i-3)*0.103
            let bang = ball(x,2.535-abs(x)*0.2,0.315,0.10,0.2,0.095,hex,head,rough:0.5)
            bang.eulerAngles.z = -0.28-DressScalar(i)*0.025
        }
        for side: DressScalar in [-1,1] {
            if style == "buns" {
                let bun = ball(side*0.46,2.67,-0.04,0.205,0.21,0.20,hex,head,rough:0.5)
                for i in 0..<5 { let t = DressScalar(i)*0.04; ball(side*0.46-0.08+t,2.79,-0.02,0.026,0.07,0.13,hex,head) }
                bun.eulerAngles.z = side*0.2
            } else if style == "pigtails" {
                for i in 0..<3 {
                    let p = ball(side*(0.47+DressScalar(i)*0.02),2.21-DressScalar(i)*0.18,-0.12,0.13-DressScalar(i)*0.015,0.19,0.135,hex,head,rough:0.5)
                    p.eulerAngles.z = side*0.3
                }
                bow(side*0.48,2.39,0,scale:0.5,hex:0xD79895,parent:head)
            } else if style == "braids" {
                for i in 0..<7 {
                    ball(side*(0.43 + (i%2 == 0 ? 0.025 : -0.025)),2.25-DressScalar(i)*0.097,-0.09,0.095-DressScalar(i)*0.005,0.081,0.086,hex,head)
                }
                bow(side*0.43,1.62,-0.06,scale:0.36,hex:0xBD9C69,parent:head)
            } else if style == "waves" {
                for i in 0..<5 { let t = DressScalar(i); ball(side*(0.41+sin(t)*0.04),2.23-t*0.12,-0.12,0.145,0.16,0.18,hex,head,rough:0.5) }
            } else if style == "bob" {
                ball(side*0.412,2.15,-0.09,0.135,0.3,0.23,hex,head,rough:0.5)
            } else {
                ball(side*0.43,2.32,-0.06,0.075,0.16,0.14,hex,head)
            }
        }
    }

    private func bow(_ x: DressScalar, _ y: DressScalar, _ z: DressScalar, scale: DressScalar, hex: Int, parent: SCNNode) {
        let root = SCNNode(); root.position = SCNVector3(x,y,z); root.scale = SCNVector3(scale,scale,scale); parent.addChildNode(root)
        for side: DressScalar in [-1,1] {
            let l = ball(side*0.13,0,0,0.15,0.1,0.045,hex,root)
            l.eulerAngles.z = side*0.35
            let tail = box(side*0.09,-0.11,-0.008,0.085,0.16,0.035,hex,root,bevel:0.02)
            tail.eulerAngles.z = -side*0.2
        }
        ball(0,0,0.025,0.055,0.065,0.045,hex,root)
    }

    private func buildClothes() {
        let outfit = value("outfit", "petal"), top = value("top", "blouse"), bottom = value("bottom", "pleats")
        let palette = ["petal":0xE7A6B1,"pinafore":0x95ADA0,"starlight":0xAAA5CC,"raincoat":0xF3CA69,"sleepy":0x9BBFD0,"explorer":0xC5B292,"tee":0x9DBDC5,"cardigan":0xDFA4A1,"blouse":0xF0DBB6,"knit":0x98B5A3,"hoodie":0xA4A3C6,"sailor":0xEFDFC8]
        let tints = [0xE7A6B1,0xA7BCA8,0xA1BDCD,0xC0AED2,0xEBC774,0xF0DDC3]
        let tint = look["tint"] as? Int ?? -1
        let id = outfit.isEmpty ? top : outfit
        let hex = tint >= 0 && tint < tints.count ? tints[tint] : (palette[id] ?? 0xE7A6B1)
        let cream = 0xFFF0D8
        let garment = SCNNode(); body.addChildNode(garment)
        lathe([(1.06,0.29),(1.12,0.294),(1.3,0.285),(1.48,0.322),(1.58,0.34),(1.65,0.22),(1.66,0.12)], depth:0.76, hex:hex, parent:garment)
        let longSleeves = ["raincoat","sleepy","cardigan","knit","hoodie"].contains(id)
        for arm in [leftArm,rightArm] {
            node(SCNCapsule(capRadius:longSleeves ? 0.107 : 0.126,height:longSleeves ? 0.55 : 0.25), id == "pinafore" ? cream : hex,0,longSleeves ? -0.19 : -0.05,0,parent:arm)
            if longSleeves { let cuff = torus(0,-0.405,0,ring:0.1,pipe:0.018,hex:cream,parent:arm); cuff.scale.z = 0.9 }
        }
        if ["petal","pinafore","starlight"].contains(outfit) {
            let tutu = outfit == "starlight"
            lathe([(0.66,tutu ? 0.61 : 0.52),(0.70,tutu ? 0.61 : 0.52),(0.82,0.47),(1.0,0.36),(1.16,0.29)],depth:0.8,pleats:0.048,hex:hex,parent:garment)
            let hem = torus(0,0.695,0,ring:tutu ? 0.603 : 0.516,pipe:0.023,hex:outfit == "pinafore" ? 0xC9D6BC : 0xF5D7CE,parent:garment); hem.scale.z = 0.8
            let belt = torus(0,1.14,0,ring:0.292,pipe:0.022,hex:cream,parent:garment); belt.scale.z = 0.76
            if tutu {
                lathe([(0.84,0.53),(0.88,0.52),(1.13,0.29)],depth:0.8,pleats:0.06,hex:0xC6BEDC,parent:garment)
                for i in 0..<10 { let a = DressScalar(i)*2 * .pi / 10; let s = star(sin(a)*0.445,0.86,cos(a)*0.367,size:0.035,hex:0xEACD85,parent:garment); s.eulerAngles.y = a }
            } else if outfit == "petal" {
                for i in 0..<12 { let a = DressScalar(i)*2 * .pi / 12; let root=SCNNode();root.position=SCNVector3(sin(a)*0.47,0.79,cos(a)*0.384);root.eulerAngles.y=a;garment.addChildNode(root);flower(0,0,0,size:0.039,hex:cream,parent:root) }
                bow(0,1.14,0.25,scale:0.55,hex:cream,parent:garment)
            } else {
                box(0,1.33,0.242,0.34,0.35,0.06,hex,garment)
                for side: DressScalar in [-1,1] { box(side*0.16,1.54,0.22,0.066,0.3,0.035,hex,garment);ball(side*0.15,1.41,0.293,0.023,0.023,0.012,0xD5B777,garment) }
                box(0,0.92,0.337,0.20,0.16,0.045,0xB3C4AB,garment)
                flower(0,0.95,0.367,size:0.043,hex:cream,parent:garment)
            }
        } else if outfit == "raincoat" {
            lathe([(0.77,0.40),(0.81,0.4),(1.10,0.31),(1.5,0.335),(1.64,0.2)],depth:0.8,hex:hex,parent:garment)
            box(0,1.15,0.277,0.025,0.75,0.025,0xD4A743,garment,bevel:0.01)
            for i in 0..<4 { ball(0.06,1.4-DressScalar(i)*0.15,0.29,0.027,0.027,0.018,cream,garment) }
            for s: DressScalar in [-1,1] { box(s*0.21,0.98,0.267,0.15,0.15,0.038,0xF8DC91,garment) }
            let hood=torus(0,1.60,-0.065,ring:0.215,pipe:0.065,hex:hex,parent:garment);hood.eulerAngles.x=0.6
        } else {
            let bottomId = outfit == "sleepy" ? "sleepypants" : outfit == "explorer" ? "shorts" : bottom
            buildBottom(bottomId,override:outfit == "sleepy" ? hex : nil,parent:garment)
        }
        // Collars, knit stitches, seams and pockets distinguish the silhouettes.
        if ["petal","blouse","pinafore","sleepy"].contains(id) {
            for s: DressScalar in [-1,1] { let c=ball(s*0.105,1.597,0.205,0.113,0.052,0.065,cream,garment); c.eulerAngles.z=s*0.25 }
        }
        if ["cardigan","blouse","sleepy","explorer"].contains(id) {
            box(0,1.36,0.24,0.024,0.43,0.027,cream,garment,bevel:0.008)
            for i in 0..<3 { ball(0,1.47-DressScalar(i)*0.12,0.269,0.018,0.018,0.012,0xAF8964,garment) }
        }
        if id == "tee" {
            for i in 0..<4 { let y = DressScalar(1.13)+DressScalar(i)*0.108;let r:DressScalar=0.296+DressScalar(i)*0.008;lathe([(y,r),(y+0.037,r)],depth:0.78,hex:cream,parent:garment) }
        }
        if id == "knit" {
            for i in -3...3 { for j in 0..<5 { let x=DressScalar(i)*0.066,y=1.18+DressScalar(j)*0.071; tube([SCNVector3(x-0.012,y+0.015,0.222),SCNVector3(x,y,0.232),SCNVector3(x+0.012,y+0.015,0.222)],radius:0.005,hex:0xC4D3BA,parent:garment) } }
        }
        if id == "hoodie" {
            let hood=torus(0,1.60,-0.07,ring:0.19,pipe:0.075,hex:hex,parent:garment);hood.eulerAngles.x=0.4
            box(0,1.23,0.24,0.26,0.13,0.05,0xC0B9D8,garment)
        }
        if id == "sailor" {
            for s:DressScalar in [-1,1] { let flap=box(s*0.105,1.53,0.241,0.15,0.2,0.035,0x7398AC,garment);flap.eulerAngles.z = -s*0.43 }
            bow(0,1.4,0.285,scale:0.45,hex:0x7398AC,parent:garment)
        }
        if id == "explorer" { for s:DressScalar in [-1,1] {box(s*0.16,1.4,0.222,0.12,0.13,0.04,0xAE9977,garment)} }
        if id == "sleepy" { for i in 0..<5 {let x=DressScalar(i%2)*0.22-0.11,y=1.23+DressScalar(i/2)*0.14;ball(x,y,0.247,0.042,0.018,0.011,cream,garment)} }
    }

    private func buildBottom(_ id: String, override: Int?, parent: SCNNode) {
        let palette = ["shorts":0xD5B893,"pleats":0xD9A19B,"jeans":0x88A8B9,"bloomers":0xDCB569,"cloudskirt":0xC0B5CD,"dungarees":0x9AAF96]
        let hex = override ?? palette[id] ?? 0x9BBFD0
        if ["pleats","cloudskirt"].contains(id) {
            let wide = id == "cloudskirt"
            lathe([(0.72,wide ? 0.5 : 0.44),(0.77,wide ? 0.5 : 0.44),(1.13,0.292)],depth:0.79,pleats:wide ? 0.03 : 0.09,hex:hex,parent:parent)
            let h=torus(0,0.75,0,ring:wide ? 0.5 : 0.44,pipe:0.02,hex:0xF1DACA,parent:parent);h.scale.z=0.79
        } else {
            lathe([(0.79,0.06),(0.84,0.275),(0.99,0.305),(1.14,0.294)],depth:0.8,hex:hex,parent:parent)
            let long = ["jeans","sleepypants","dungarees"].contains(id)
            for s: DressScalar in [-1,1] {
                let leg=SCNNode();leg.position.x=s*0.16;parent.addChildNode(leg)
                lathe([(long ? 0.28 : 0.69,0.13),(long ? 0.32 : 0.73,id == "bloomers" ? 0.18 : 0.14),(0.92,id == "bloomers" ? 0.19 : 0.16),(1.12,0.145)],depth:0.95,hex:hex,parent:leg)
                let cuff=torus(0,long ? 0.30 : 0.71,0,ring:0.128,pipe:0.017,hex:0xEBDAC0,parent:leg);cuff.scale.z=0.95
            }
            if id == "dungarees" {
                box(0,1.28,0.257,0.37,0.3,0.06,hex,parent)
                for s:DressScalar in [-1,1] {box(s*0.15,1.48,0.245,0.065,0.31,0.04,hex,parent);ball(s*0.14,1.34,0.299,0.023,0.023,0.014,0xD9BD75,parent)}
                box(0,1.24,0.3,0.18,0.11,0.03,0xC3CEAF,parent)
            }
        }
    }

    private func buildShoes(_ id: String) {
        let colors=["maryjane":0xAD686F,"wellies":0xE8BD59,"sneakers":0x91AFA5,"ballet":0xDEAFA9,"bunny":0xE2CCBA,"hiking":0xAA886C]
        let hex=colors[id] ?? 0xAD686F
        for s:DressScalar in [-1,1] {
            let root=SCNNode();root.position=SCNVector3(s*0.16,0,0);body.addChildNode(root)
            ball(0,0.115,0.077,0.147,0.093,0.235,0xDEC9AA,root)
            ball(0,0.16,0.083,0.14,0.11,0.222,hex,root,rough:id == "wellies" ? 0.26 : 0.55)
            if ["wellies","hiking"].contains(id) {
                node(SCNCylinder(radius:0.135,height:id == "wellies" ? 0.36 : 0.22),hex,0,id == "wellies" ? 0.34 : 0.27,0,parent:root,rough:0.35)
                torus(0,id == "wellies" ? 0.52 : 0.38,0,ring:0.129,pipe:0.014,hex:0xF3D998,parent:root)
            } else {
                node(SCNCylinder(radius:0.112,height:0.17),0xFFF0DA,0,0.3,0,parent:root)
                torus(0,0.39,0,ring:0.108,pipe:0.016,hex:0xE7D3B8,parent:root)
            }
            if id == "maryjane" { box(0,0.25,0.12,0.25,0.035,0.058,hex,root);ball(s*0.105,0.25,0.145,0.021,0.021,0.015,0xEAD5A7,root) }
            if ["sneakers","hiking"].contains(id) { for i in 0..<3 {box(0,0.25-DressScalar(i)*0.01,0.075+DressScalar(i)*0.04,0.14,0.018,0.018,0xFFEFDB,root,bevel:0.008)} }
            if id == "ballet" { bow(0,0.24,0.17,scale:0.27,hex:0xF7DACC,parent:root) }
            if id == "bunny" { for t:DressScalar in [-1,1] {ball(t*0.053,0.33,0.19,0.037,0.095,0.031,hex,root);ball(t*0.053,0.34,0.217,0.017,0.058,0.009,0xD7A7A5,root);ball(t*0.04,0.21,0.29,0.01,0.012,0.008,0x59463C,root)} }
        }
    }

    private func buildAccessory(_ id: String) {
        if id == "bow" { bow(0.30,2.65,0.28,scale:0.8,hex:0xD58F97,parent:head) }
        if id == "flower" {
            let ring=torus(0,2.57,0,ring:0.433,pipe:0.019,hex:0x90A67E,parent:head);ring.scale.z=0.91
            for i in 0..<9 {let a=DressScalar(i)*2 * .pi/9;let r=SCNNode();r.position=SCNVector3(sin(a)*0.44,2.59,cos(a)*0.4);r.eulerAngles.y=a;head.addChildNode(r);flower(0,0,0,size:0.073,hex:0xFFF0CB,parent:r)}
        }
        if id == "beret" {
            let hat=SCNNode();hat.position=SCNVector3(-0.035,2.7,-0.018);hat.eulerAngles.z=0.12;head.addChildNode(hat)
            ball(0,0,0,0.49,0.13,0.455,0xBC9982,hat)
            torus(0,-0.047,0,ring:0.403,pipe:0.024,hex:0x96745C,parent:hat)
            node(SCNCapsule(capRadius:0.025,height:0.095),0x96745C,0,0.14,0,parent:hat)
        }
        if id == "crown" {
            torus(0,2.71,0,ring:0.28,pipe:0.024,hex:0xE0BA6B,parent:head)
            for i in 0..<7 {let a=DressScalar(i)*2 * .pi/7;let n=node(SCNCone(topRadius:0.01,bottomRadius:0.072,height:0.20),0xE0BA6B,sin(a)*0.255,2.79,cos(a)*0.255,parent:head,rough:0.35);n.eulerAngles.x=0;ball(sin(a)*0.255,2.89,cos(a)*0.255,0.028,0.028,0.028,0xF7DB97,head)}
        }
        if id == "bunnyears" {
            for s:DressScalar in [-1,1] {let ear=ball(s*0.24,2.98,-0.02,0.10,0.31,0.075,0xEBD8C2,head);ear.eulerAngles.z = -s*0.14;let inner=ball(s*0.24,3,0.047,0.045,0.21,0.018,0xD7A7A5,head);inner.eulerAngles.z = -s*0.14}
        }
        if id == "satchel" {
            tube([SCNVector3(-0.27,1.64,0.13),SCNVector3(-0.06,1.33,0.27),SCNVector3(0.3,0.92,0.26)],radius:0.021,hex:0xAA7E62,parent:body)
            tube([SCNVector3(-0.27,1.64,-0.13),SCNVector3(-0.06,1.33,-0.25),SCNVector3(0.3,0.92,-0.08)],radius:0.021,hex:0xAA7E62,parent:body)
            box(0.32,0.92,0.19,0.29,0.27,0.16,0xAA7E62,body,bevel:0.08)
            box(0.32,0.99,0.279,0.26,0.12,0.025,0xC39A77,body)
            flower(0.32,0.92,0.29,size:0.048,hex:0xF1D394,parent:body)
        }
    }

    // MARK: Dioramas
    private func buildRoom() {
        room.childNodes.forEach { $0.removeFromParentNode() }
        effects.childNodes.forEach { $0.removeFromParentNode() }
        let isNight = place == "night"
        scene.background.contents = color(isNight ? 0x797C9D : 0xF1E4D3)
        scene.fogColor = color(isNight ? 0x797C9D : 0xF1E4D3)
        scene.fogStartDistance = 13
        scene.fogEndDistance = 28
        let floor=SCNFloor();floor.reflectivity=0
        node(floor,isNight ? 0xA19AAA : 0xE5D4BD,0,-0.025,0,parent:room)
        let rug=node(SCNCylinder(radius:1.12,height:0.035),place == "garden" ? 0x9BBFC1 : isNight ? 0xD7C3B7 : 0xE8C9B7,0,-0.003,0,parent:room)
        rug.scale.z=0.86
        if place != "garden" {
            for i in 0..<4 {let ring=torus(0,0.017,0,ring:CGFloat(0.9+DressScalar(i)*0.046),pipe:0.008,hex:isNight ? 0xE5D4C4 : 0xF2DCC7,parent:room);ring.scale.z=0.86}
        }
        contactShadow()
        if place == "studio" { studio() }
        if place == "garden" { garden() }
        if place == "tea" { tea() }
        if place == "night" { night() }
    }

    private func contactShadow() {
        let space = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: nil, width: 128, height: 128, bitsPerComponent: 8, bytesPerRow: 512, space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
              let gradient = CGGradient(colorsSpace: space, colors: [CGColor(red: 0.32, green: 0.22, blue: 0.17, alpha: 0.25), CGColor(red: 0.32, green: 0.22, blue: 0.17, alpha: 0)] as CFArray, locations: [0, 1]) else { return }
        context.drawRadialGradient(gradient, startCenter: CGPoint(x: 64, y: 64), startRadius: 8, endCenter: CGPoint(x: 64, y: 64), endRadius: 64, options: [])
        let m = SCNMaterial(); m.lightingModel = .constant; m.diffuse.contents = context.makeImage(); m.writesToDepthBuffer = false
        let plane = SCNPlane(width: 1.18, height: 0.76); plane.firstMaterial = m
        let shadow = SCNNode(geometry: plane); shadow.position = SCNVector3(0, 0.029, 0.07); shadow.eulerAngles.x = -.pi / 2; shadow.castsShadow = false
        room.addChildNode(shadow)
    }

    private func studio() {
        box(0,2,-2.1,9,4,0.16,0xF3E7D6,room)
        box(0,0.85,-1.99,9,1.7,0.075,0xEADAC5,room)
        box(0,1.70,-1.92,9,0.05,0.1,0xD9C4A8,room)
        for i in -9...9 {box(DressScalar(i)*0.42,0.85,-1.94,0.018,1.65,0.018,0xE0CBB0,room,bevel:0.004)}
        // An arched mirror, a real miniature clothes rail and a quiet reading corner.
        box(-1.55,1.18,-1.64,0.88,1.90,0.12,0xC1AA8B,room,bevel:0.35)
        box(-1.55,1.2,-1.56,0.77,1.77,0.06,0xCEDBDC,room,bevel:0.33)
        box(-1.74,1.35,-1.517,0.025,1.23,0.012,0xEFF2E7,room,bevel:0.006).eulerAngles.z = -0.22
        let rail=SCNNode();rail.position=SCNVector3(1.7,0,-1.10);room.addChildNode(rail)
        for s:DressScalar in [-1,1] {rod(SCNVector3(s*0.48,0.05,0),SCNVector3(s*0.48,1.86,0),radius:0.027,hex:0xB99C78,parent:rail);rod(SCNVector3(s*0.48,0.04,-0.20),SCNVector3(s*0.48,0.04,0.20),radius:0.035,hex:0xB99C78,parent:rail)}
        rod(SCNVector3(-0.48,1.84,0),SCNVector3(0.48,1.84,0),radius:0.028,hex:0xB99C78,parent:rail)
        for i in 0..<3 {
            let x=DressScalar(i-1)*0.28
            tube([SCNVector3(x,1.83,0),SCNVector3(x,1.71,0),SCNVector3(x-0.14,1.58,0),SCNVector3(x+0.14,1.58,0),SCNVector3(x,1.71,0)],radius:0.012,hex:0xA88766,parent:rail)
            let garment=SCNNode();garment.position=SCNVector3(x,0.98,0);garment.scale=SCNVector3(0.6,0.6,0.6);rail.addChildNode(garment)
            lathe([(0,0.23),(0.06,0.23),(0.65,0.14),(1,0.22)],depth:0.6,hex:[0xA5BBA6,0xE1B2A5,0xBCC0D5][i],parent:garment)
        }
        plant(-2.2,0,-0.8,scale:0.9)
        box(1.6,0.25,0.1,0.66,0.42,0.52,0xBC9B7C,room,bevel:0.10)
        box(1.6,0.5,0.1,0.73,0.17,0.59,0xE9C5AC,room,bevel:0.08)
        for i in 0..<3 {box(1.64,0.61+DressScalar(i)*0.065,0.09,0.35,0.06,0.26,[0xA3B7AA,0xDDD0B9,0xC3AAB7][i],room,bevel:0.018)}
        // Round window with a warm sky.
        let window=ball(0.1,2.8,-1.97,0.62,0.62,0.04,0xD7E2DB,room)
        window.geometry?.firstMaterial?.lightingModel = .constant
        let frame=torus(0.1,2.8,-1.89,ring:0.62,pipe:0.045,hex:0xCFB89A,parent:room);frame.eulerAngles.x = .pi/2
        box(0.1,2.8,-1.85,0.033,1.18,0.04,0xCFB89A,room)
        box(0.1,2.8,-1.85,1.18,0.033,0.04,0xCFB89A,room)
        ball(-0.08,3.01,-1.9,0.16,0.16,0.015,0xF5D593,room)
    }

    private func plant(_ x:DressScalar,_ y:DressScalar,_ z:DressScalar,scale:DressScalar) {
        let root=SCNNode();root.position=SCNVector3(x,y,z);root.scale=SCNVector3(scale,scale,scale);room.addChildNode(root)
        lathe([(0,0.17),(0.04,0.18),(0.4,0.25),(0.43,0.26)],depth:1,hex:0xC49174,parent:root)
        for i in 0..<7 {let a=DressScalar(i)*2 * .pi/7;let end=SCNVector3(sin(a)*0.31,0.85+DressScalar(i%3)*0.16,cos(a)*0.26);rod(SCNVector3(0,0.4,0),end,radius:0.012,hex:0x7D9471,parent:root);let leaf=ball(end.x,end.y,end.z,0.10,0.23,0.035,[0x8B9F7B,0xA6B68D,0x718C72][i%3],root);leaf.eulerAngles=SCNVector3(0,a,-sin(a)*0.5)}
    }

    private func garden() {
        scene.background.contents=color(0xDCE4D8)
        box(0,0.02,-2.1,10,0.07,3,0xB5C5A0,room)
        for i in -7...7 {box(DressScalar(i)*0.38,0.60,-1.8,0.22,1.1,0.09,0xEBDFC9,room,bevel:0.10)}
        for y:DressScalar in [0.25,0.8] {box(0,y,-1.88,6.4,0.11,0.08,0xD8CAAF,room)}
        for i in 0..<5 {plant(DressScalar(i)*1.05-2.3,0,-2.45,scale:1.25)}
        for i in 0..<9 {let x=DressScalar(i%3)*0.2-1.8,z=DressScalar(i/3)*0.19-0.3;rod(SCNVector3(x,0,z),SCNVector3(x,0.32,z),radius:0.014,hex:0x799667,parent:room);flower(x,0.36,z,size:0.07,hex:i%2 == 0 ? 0xF8E4AC : 0xD5A6AF,parent:room)}
        for i in 0..<4 {let puddle=ball(DressScalar(i%2)*2.6-1.35,0.02,DressScalar(i/2)*0.8+0.2,0.33,0.015,0.22,0xB2CDCD,room,rough:0.18);puddle.eulerAngles.y=DressScalar(i)}
        let umbrella=SCNNode();umbrella.position=SCNVector3(1.55,0.12,-0.65);umbrella.eulerAngles.z = -0.2;room.addChildNode(umbrella)
        rod(SCNVector3Zero,SCNVector3(0,1.5,0),radius:0.025,hex:0xBD9A75,parent:umbrella)
        lathe([(1.25,0.67),(1.36,0.60),(1.52,0.36),(1.6,0.01)],depth:1,hex:0xCDA4AC,parent:umbrella)
        for i in 0..<8 {let a=DressScalar(i)*2 * .pi/8;rod(SCNVector3(0,1.6,0),SCNVector3(sin(a)*0.67,1.25,cos(a)*0.67),radius:0.008,hex:0xEED7D0,parent:umbrella)}
        bunny(-1.5,0.08,-0.7,scale:0.52)
    }

    private func bunny(_ x:DressScalar,_ y:DressScalar,_ z:DressScalar,scale:DressScalar) {
        let root=SCNNode();root.position=SCNVector3(x,y,z);root.scale=SCNVector3(scale,scale,scale);room.addChildNode(root)
        ball(0,0.28,0,0.25,0.30,0.22,0xDCC5AB,root)
        ball(0,0.67,0.03,0.26,0.25,0.24,0xEAD8BF,root)
        for s:DressScalar in [-1,1] {ball(s*0.12,1,0.015,0.07,0.26,0.062,0xEAD8BF,root);ball(s*0.12,1,0.07,0.032,0.17,0.017,0xCDA3A0,root);ball(s*0.09,0.7,0.249,0.019,0.027,0.012,0x53473D,root);ball(s*0.13,0.08,0.13,0.11,0.09,0.17,0xEAD8BF,root)}
        ball(0,0.63,0.275,0.025,0.018,0.015,0xB3857B,root)
        bow(0,0.42,0.20,scale:0.4,hex:0xA3B5A5,parent:root)
    }

    private func tea() {
        box(0,1.8,-2.3,9,4,0.15,0xE8DCCC,room)
        for i in -7...7 {box(DressScalar(i)*0.45,1.8,-2.20,0.022,3.5,0.012,0xDBCABA,room,bevel:0.003)}
        box(0,2.35,-2.11,2.3,0.035,0.10,0xD0B492,room)
        for i in -3...3 {let n=star(DressScalar(i)*0.34,2.7-abs(DressScalar(i))*0.06,-2.06,size:0.09,hex:i%2 == 0 ? 0xCF9E96 : 0xA6B59B,parent:room);n.eulerAngles.z=DressScalar(i)*0.13}
        let table=SCNNode();table.position=SCNVector3(1.22,0,0.38);room.addChildNode(table)
        node(SCNCylinder(radius:0.57,height:0.075),0xE8CAA7,0,0.77,0,parent:table)
        for x:DressScalar in [-0.32,0.32] {for z:DressScalar in [-0.25,0.25] {rod(SCNVector3(x,0.04,z),SCNVector3(x*0.8,0.75,z*0.8),radius:0.043,hex:0xBB9572,parent:table)}}
        let cloth=box(0,0.815,0,0.72,0.025,0.68,0xF2DCD0,table,bevel:0.01);cloth.eulerAngles.y=0.16
        let pot=SCNNode();pot.name="teapot";pot.position=SCNVector3(0.13,0.87,-0.06);table.addChildNode(pot)
        ball(0,0.09,0,0.14,0.12,0.13,0xA6B9A5,pot,rough:0.28)
        ball(0,0.205,0,0.105,0.025,0.10,0xA6B9A5,pot)
        ball(0,0.25,0,0.028,0.028,0.028,0xCBB187,pot)
        rod(SCNVector3(-0.1,0.1,0),SCNVector3(-0.23,0.21,0),radius:0.043,hex:0xA6B9A5,parent:pot)
        let handle=torus(0.16,0.11,0,ring:0.075,pipe:0.022,hex:0xA6B9A5,parent:pot);handle.eulerAngles.x = .pi/2
        node(SCNCylinder(radius:0.105,height:0.025),0xF3E8D5,-0.23,0.84,0.15,parent:table)
        node(SCNCylinder(radius:0.071,height:0.095),0xC79792,-0.23,0.9,0.15,parent:table)
        let drink=node(SCNCylinder(radius:0.059,height:0.009),0xA7774C,-0.23,0.95,0.15,parent:table);drink.name="tea";drink.isHidden=true
        for i in 0..<3 {ball(DressScalar(i)*0.10-0.1,0.87,-0.24,0.075,0.035,0.055,[0xD6AA79,0xE5C295,0xB98964][i],table)}
        bunny(-1.25,0.08,-0.1,scale:0.85)
        box(-1.25,0.07,-0.1,0.72,0.13,0.6,0xB9C1AA,room,bevel:0.06)
        plant(1.9,0,-1.2,scale:1.1)
        plant(-2.1,0,-1.1,scale:0.8)
    }

    private func night() {
        box(0,2,-2.2,9,4,0.15,0x9294B0,room)
        let ring=torus(-1.25,2.5,-2.02,ring:0.55,pipe:0.036,hex:0xC5BBD1,parent:room);ring.eulerAngles.x = .pi/2
        ball(-1.25,2.5,-2.12,0.54,0.54,0.035,0x68738F,room)
        ball(-1.35,2.55,-2.06,0.27,0.27,0.025,0xF1D79B,room)
        ball(-1.23,2.63,-2.03,0.245,0.245,0.028,0x68738F,room)
        for i in 0..<7 {let x=DressScalar(i)*0.47-1.4,y=2.93+sin(DressScalar(i)*1.9)*0.35;let n=star(x,y,-1.95,size:0.065+DressScalar(i%2)*0.018,hex:0xC7BBD0,parent:room);n.name="star\(i)"}
        box(1.65,0.3,-0.77,1.0,0.45,1.52,0xBAA5AB,room,bevel:0.12)
        box(1.65,0.56,-0.77,1.06,0.15,1.6,0xDDD0C7,room,bevel:0.08)
        box(1.65,0.67,-0.46,1.04,0.17,0.92,0xAAB7C4,room,bevel:0.08)
        box(1.65,0.69,-1.30,0.71,0.18,0.38,0xEBDACA,room,bevel:0.09)
        box(1.65,0.62,-1.60,1.06,1.15,0.10,0xC3ACAB,room,bevel:0.05)
        for i in 0..<5 {flower(1.32+DressScalar(i%3)*0.24,0.777,-0.66+DressScalar(i/3)*0.34,size:0.035,hex:0xE7D9C5,parent:room)}
        bunny(-1.22,0.05,0.02,scale:0.68)
        node(SCNCylinder(radius:0.25,height:0.4),0xB0A69F,-1.75,0.2,-0.8,parent:room)
        node(SCNCylinder(radius:0.025,height:0.36),0xD1B895,-1.75,0.58,-0.8,parent:room)
        let shade=node(SCNCone(topRadius:0.18,bottomRadius:0.3,height:0.35),0xE5CAA0,-1.75,0.87,-0.8,parent:room)
        shade.geometry?.firstMaterial=material(0xE5CAA0,glow:true)
    }
}

private extension SCNAction {
    static func scaleY(to value: CGFloat, duration: TimeInterval) -> SCNAction {
        let start: CGFloat = value < 1 ? 1 : 0.09
        return .customAction(duration: duration) { node, elapsed in
            node.scale.y = DressScalar(start + (value - start) * min(1, elapsed / CGFloat(duration)))
        }
    }
}
