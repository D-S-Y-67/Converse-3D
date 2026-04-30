import SwiftUI
import SceneKit

// =====================================================
// MARK: - DATA MODELS
// =====================================================

enum PowerUpType: CaseIterable {
    case speed, shield, magnet
    var name: String {
        switch self {
        case .speed: return "Turbo"
        case .shield: return "Shield"
        case .magnet: return "Magnet"
        }
    }
    var symbol: String {
        switch self {
        case .speed: return "bolt.fill"
        case .shield: return "shield.lefthalf.filled"
        case .magnet: return "scope"
        }
    }
    var tint: Color {
        switch self {
        case .speed: return Color(red: 1.0, green: 0.85, blue: 0.2)
        case .shield: return Color(red: 0.3, green: 0.85, blue: 1.0)
        case .magnet: return Color(red: 1.0, green: 0.4, blue: 0.7)
        }
    }
    var uiColor: UIColor { UIColor(self.tint) }
    var duration: Double {
        switch self {
        case .speed: return 6
        case .shield: return 10
        case .magnet: return 12
        }
    }
}

struct CarConfig: Identifiable, Equatable {
    let id: Int
    let name: String
    let tagline: String
    let body: UIColor
    let cabin: UIColor
    let topSpeed: Float
    let acceleration: Float
    let handling: Float
    let unlockScore: Int
    
    var bodyColor: Color { Color(body) }
    var cabinColor: Color { Color(cabin) }
    
    static let all: [CarConfig] = [
        CarConfig(id: 0, name: "Ember",   tagline: "Reliable starter, balanced everywhere",
                  body: UIColor(red: 0.86, green: 0.16, blue: 0.18, alpha: 1),
                  cabin: UIColor(red: 0.10, green: 0.16, blue: 0.24, alpha: 1),
                  topSpeed: 20, acceleration: 20, handling: 1.8, unlockScore: 0),
        CarConfig(id: 1, name: "Glacier", tagline: "Cool runner with sharper steering",
                  body: UIColor(red: 0.20, green: 0.55, blue: 0.95, alpha: 1),
                  cabin: UIColor(red: 0.05, green: 0.10, blue: 0.18, alpha: 1),
                  topSpeed: 22, acceleration: 19, handling: 2.0, unlockScore: 25),
        CarConfig(id: 2, name: "Mantis",  tagline: "Quick off the line, eager to corner",
                  body: UIColor(red: 0.40, green: 0.85, blue: 0.30, alpha: 1),
                  cabin: UIColor(red: 0.10, green: 0.20, blue: 0.10, alpha: 1),
                  topSpeed: 23, acceleration: 22, handling: 1.7, unlockScore: 75),
        CarConfig(id: 3, name: "Solar",   tagline: "Big top-end, demands precision",
                  body: UIColor(red: 1.00, green: 0.78, blue: 0.10, alpha: 1),
                  cabin: UIColor(red: 0.18, green: 0.12, blue: 0.05, alpha: 1),
                  topSpeed: 26, acceleration: 24, handling: 1.6, unlockScore: 150),
        CarConfig(id: 4, name: "Phantom", tagline: "Pure speed for veteran drivers",
                  body: UIColor(red: 0.10, green: 0.10, blue: 0.14, alpha: 1),
                  cabin: UIColor(red: 0.55, green: 0.15, blue: 0.85, alpha: 1),
                  topSpeed: 30, acceleration: 28, handling: 1.5, unlockScore: 300)
    ]
}

struct TreadConfig: Identifiable, Equatable {
    let id: Int
    let name: String
    let description: String
    let radius: CGFloat
    let width: CGFloat
    let color: UIColor
    let gripBonus: Float
    
    var swiftColor: Color { Color(color) }
    
    static let all: [TreadConfig] = [
        TreadConfig(id: 0, name: "Street",   description: "Balanced grip and speed",
                    radius: 0.42, width: 0.32,
                    color: UIColor(white: 0.08, alpha: 1), gripBonus: 1.0),
        TreadConfig(id: 1, name: "Off-Road", description: "Better grip, chunky tread",
                    radius: 0.50, width: 0.45,
                    color: UIColor(red: 0.30, green: 0.20, blue: 0.12, alpha: 1), gripBonus: 1.1),
        TreadConfig(id: 2, name: "Slicks",   description: "Maximum grip, less stable",
                    radius: 0.40, width: 0.28,
                    color: UIColor(white: 0.04, alpha: 1), gripBonus: 1.25),
        TreadConfig(id: 3, name: "Monster",  description: "Massive but slow turning",
                    radius: 0.62, width: 0.55,
                    color: UIColor(white: 0.05, alpha: 1), gripBonus: 0.85)
    ]
}

// =====================================================
// MARK: - SHARED GAME STATE
// =====================================================

final class GameState: ObservableObject {
    @Published var score: Int = 0
    @Published var bestScore: Int = 0
    @Published var speed: Float = 0
    @Published var activePowerUp: PowerUpType? = nil
    @Published var powerUpTimeRemaining: Double = 0
    @Published var lap: Int = 0
    @Published var totalLaps: Int = 3
    @Published var lapTime: Double = 0
    @Published var bestLapTime: Double = 0
    @Published var lastLapTime: Double = 0
    @Published var isFinished: Bool = false
    
    @Published var leftHeld: Bool = false
    @Published var rightHeld: Bool = false
    @Published var gasHeld: Bool = false
    @Published var brakeHeld: Bool = false
    @Published var driftHeld: Bool = false
    
    @Published var isPaused: Bool = false
    
    var car: CarConfig = CarConfig.all[0]
    var tread: TreadConfig = TreadConfig.all[0]
    
    var steerInput: Float {
        var s: Float = 0
        if leftHeld { s -= 1 }
        if rightHeld { s += 1 }
        return s
    }
    var throttleInput: Float {
        var t: Float = 0
        if gasHeld { t += 1 }
        if brakeHeld { t -= 1 }
        return t
    }
}

// =====================================================
// MARK: - GAME WORLD (SceneKit)
// =====================================================

final class GameWorld: NSObject, SCNSceneRendererDelegate {
    let scene = SCNScene()
    let cameraNode = SCNNode()
    let carNode = SCNNode()
    
    private weak var state: GameState?
    private let car: CarConfig
    private let tread: TreadConfig
    
    private var coins: [SCNNode] = []
    private var powerUps: [(node: SCNNode, type: PowerUpType)] = []
    
    private var velocity: Float = 0
    private var lastTime: TimeInterval = 0
    private var shieldNode: SCNNode? = nil
    private var smokeEmitters: [SCNNode] = []
    
    private var localScore: Int = 0
    private var localPU: PowerUpType? = nil
    private var localPUTime: Double = 0
    
    private var publishedScore: Int = -1
    private var publishedSpeed: Float = -1
    private var publishedPU: PowerUpType? = nil
    private var publishedPUTime: Double = -1
    private var publishedLap: Int = -1
    private var publishedLapTime: Double = -1
    
    private var coinRespawn: [(time: TimeInterval, pos: SCNVector3)] = []
    private var puRespawn: [(time: TimeInterval, type: PowerUpType, pos: SCNVector3)] = []
    
    private let trackCenterRadius: Float = 55
    private let trackWidth: Float = 14
    private var lapStartTime: TimeInterval = 0
    private var lastAngle: Float = 0
    private var crossedHalf: Bool = false
    private var lapsDone: Int = 0
    
    init(state: GameState) {
        self.state = state
        self.car = state.car
        self.tread = state.tread
        super.init()
        build()
    }
    
    private func build() {
        scene.background.contents = UIColor(red: 0.55, green: 0.78, blue: 1.0, alpha: 1)
        scene.fogColor = UIColor(red: 0.75, green: 0.86, blue: 1.0, alpha: 1)
        scene.fogStartDistance = 80
        scene.fogEndDistance = 200
        
        addLights()
        addGround()
        addTrack()
        addTerrain()
        addStructures()
        addCar()
        addCoinsAlongTrack(count: 40)
        addPowerUpsAlongTrack(count: 6)
        addCamera()
        
        carNode.position = trackPoint(angle: -.pi/2)
        carNode.eulerAngles.y = 0
    }
    
    private func addLights() {
        let amb = SCNNode()
        amb.light = SCNLight()
        amb.light?.type = .ambient
        amb.light?.color = UIColor(white: 0.55, alpha: 1)
        amb.light?.intensity = 400
        scene.rootNode.addChildNode(amb)
        
        let sun = SCNNode()
        sun.light = SCNLight()
        sun.light?.type = .directional
        sun.light?.color = UIColor.white
        sun.light?.intensity = 1200
        sun.light?.castsShadow = true
        sun.light?.shadowSampleCount = 8
        sun.light?.shadowRadius = 3
        sun.light?.shadowColor = UIColor.black.withAlphaComponent(0.45)
        sun.light?.shadowMapSize = CGSize(width: 1024, height: 1024)
        sun.eulerAngles = SCNVector3(-Float.pi * 0.4, Float.pi * 0.25, 0)
        scene.rootNode.addChildNode(sun)
    }
    
    private func addGround() {
        let floor = SCNFloor()
        floor.reflectivity = 0
        let m = SCNMaterial()
        m.diffuse.contents = UIColor(red: 0.42, green: 0.62, blue: 0.32, alpha: 1)
        m.roughness.contents = 0.9
        floor.firstMaterial = m
        scene.rootNode.addChildNode(SCNNode(geometry: floor))
    }
    
    private func trackPoint(angle: Float) -> SCNVector3 {
        SCNVector3(cos(angle) * trackCenterRadius, 0.05,
                   sin(angle) * trackCenterRadius)
    }
    
    private func addTrack() {
        let segments = 96
        for i in 0..<segments {
            let a = Float(i) / Float(segments) * Float.pi * 2
            let p = trackPoint(angle: a)
            
            let seg = SCNBox(width: CGFloat(trackWidth), height: 0.1,
                             length: CGFloat(2 * .pi * trackCenterRadius / Float(segments)) + 0.5,
                             chamferRadius: 0)
            let m = SCNMaterial()
            m.diffuse.contents = UIColor(white: 0.18, alpha: 1)
            m.roughness.contents = 0.85
            seg.firstMaterial = m
            let n = SCNNode(geometry: seg)
            n.position = p
            n.eulerAngles.y = -a + .pi/2
            scene.rootNode.addChildNode(n)
            
            if i % 2 == 0 {
                let stripe = SCNBox(width: 0.3, height: 0.12, length: 1.6, chamferRadius: 0)
                let sm = SCNMaterial()
                sm.diffuse.contents = UIColor.white
                sm.emission.contents = UIColor(white: 0.3, alpha: 1)
                stripe.firstMaterial = sm
                let sN = SCNNode(geometry: stripe)
                sN.position = SCNVector3(p.x, 0.11, p.z)
                sN.eulerAngles.y = -a + .pi/2
                scene.rootNode.addChildNode(sN)
            }
        }
        
        let startAngle: Float = -.pi/2
        let sp = trackPoint(angle: startAngle)
        let lineCount = 8
        for i in 0..<lineCount {
            let isWhite = i % 2 == 0
            let block = SCNBox(width: CGFloat(trackWidth) / CGFloat(lineCount),
                               height: 0.13, length: 1.0, chamferRadius: 0)
            let bm = SCNMaterial()
            bm.diffuse.contents = isWhite ? UIColor.white : UIColor.black
            block.firstMaterial = bm
            let bN = SCNNode(geometry: block)
            let off = (Float(i) - Float(lineCount-1)/2) * (trackWidth / Float(lineCount))
            bN.position = SCNVector3(sp.x + off, 0.13, sp.z)
            scene.rootNode.addChildNode(bN)
        }
        
        for sx in [-trackWidth/2 - 1, trackWidth/2 + 1] {
            let pillar = SCNBox(width: 0.6, height: 6, length: 0.6, chamferRadius: 0.1)
            let pm = SCNMaterial()
            pm.diffuse.contents = UIColor(red: 0.95, green: 0.4, blue: 0.4, alpha: 1)
            pillar.firstMaterial = pm
            let pN = SCNNode(geometry: pillar)
            pN.position = SCNVector3(sp.x + sx, 3, sp.z)
            pN.castsShadow = true
            scene.rootNode.addChildNode(pN)
        }
        let banner = SCNBox(width: CGFloat(trackWidth) + 3, height: 1.2,
                            length: 0.4, chamferRadius: 0.1)
        let bnm = SCNMaterial()
        bnm.diffuse.contents = UIColor(red: 0.95, green: 0.4, blue: 0.4, alpha: 1)
        banner.firstMaterial = bnm
        let bnN = SCNNode(geometry: banner)
        bnN.position = SCNVector3(sp.x, 6.2, sp.z)
        bnN.castsShadow = true
        scene.rootNode.addChildNode(bnN)
        
        let coneCount = 60
        for i in 0..<coneCount {
            let a = Float(i) / Float(coneCount) * Float.pi * 2
            for radius in [trackCenterRadius - trackWidth/2 - 0.5,
                           trackCenterRadius + trackWidth/2 + 0.5] {
                let cone = SCNCone(topRadius: 0.08, bottomRadius: 0.32, height: 0.7)
                let cm = SCNMaterial()
                cm.diffuse.contents = UIColor(red: 0.95, green: 0.55, blue: 0.10, alpha: 1)
                cm.emission.contents = UIColor(red: 0.45, green: 0.20, blue: 0, alpha: 1)
                cone.firstMaterial = cm
                let cN = SCNNode(geometry: cone)
                cN.position = SCNVector3(cos(a) * radius, 0.35, sin(a) * radius)
                scene.rootNode.addChildNode(cN)
            }
        }
    }
    
    private func addTerrain() {
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<14 {
            let pos = randomOffTrackPosition(rng: &rng, minDist: 20)
            let hillRadius = Float.random(in: 6...12, using: &rng)
            let hillTop = Float.random(in: 1.5...3.5, using: &rng)
            let s = SCNSphere(radius: CGFloat(hillRadius))
            s.segmentCount = 16
            let m = SCNMaterial()
            let g = CGFloat.random(in: 0.50...0.68, using: &rng)
            m.diffuse.contents = UIColor(red: 0.36, green: g, blue: 0.30, alpha: 1)
            s.firstMaterial = m
            let n = SCNNode(geometry: s)
            n.scale = SCNVector3(1, hillTop / hillRadius, 1)
            n.castsShadow = true
            n.position = SCNVector3(pos.x, 0, pos.z)
            scene.rootNode.addChildNode(n)
        }
    }
    
    private func addStructures() {
        var rng = SystemRandomNumberGenerator()
        let palette: [UIColor] = [
            UIColor(red: 0.86, green: 0.40, blue: 0.40, alpha: 1),
            UIColor(red: 0.45, green: 0.55, blue: 0.85, alpha: 1),
            UIColor(red: 0.95, green: 0.85, blue: 0.45, alpha: 1),
            UIColor(red: 0.65, green: 0.40, blue: 0.75, alpha: 1),
            UIColor(red: 0.35, green: 0.70, blue: 0.60, alpha: 1)
        ]
        
        for _ in 0..<22 {
            let pos = randomOffTrackPosition(rng: &rng, minDist: 18)
            let w = CGFloat.random(in: 4...8, using: &rng)
            let l = CGFloat.random(in: 4...8, using: &rng)
            let h = CGFloat.random(in: 6...18, using: &rng)
            let box = SCNBox(width: w, height: h, length: l, chamferRadius: 0.2)
            let m = SCNMaterial()
            m.diffuse.contents = palette.randomElement(using: &rng)!
            m.roughness.contents = 0.7
            box.firstMaterial = m
            let n = SCNNode(geometry: box)
            n.position = SCNVector3(pos.x, Float(h)/2, pos.z)
            n.castsShadow = true
            scene.rootNode.addChildNode(n)
        }
        
        for _ in 0..<35 {
            let pos = randomOffTrackPosition(rng: &rng, minDist: 12)
            let trunkH = Float.random(in: 1.8...3.2, using: &rng)
            let trunk = SCNCylinder(radius: 0.35, height: CGFloat(trunkH))
            let tm = SCNMaterial()
            tm.diffuse.contents = UIColor(red: 0.42, green: 0.27, blue: 0.16, alpha: 1)
            trunk.firstMaterial = tm
            let trunkN = SCNNode(geometry: trunk)
            trunkN.position.y = trunkH / 2
            
            let leavesH = Float.random(in: 3.0...5.0, using: &rng)
            let leavesR = Float.random(in: 1.3...2.1, using: &rng)
            let cone = SCNCone(topRadius: 0, bottomRadius: CGFloat(leavesR),
                               height: CGFloat(leavesH))
            let lm = SCNMaterial()
            let g = CGFloat.random(in: 0.45...0.62, using: &rng)
            lm.diffuse.contents = UIColor(red: 0.18, green: g, blue: 0.22, alpha: 1)
            cone.firstMaterial = lm
            let coneN = SCNNode(geometry: cone)
            coneN.position.y = trunkH + leavesH / 2 - 0.4
            
            let tree = SCNNode()
            tree.addChildNode(trunkN)
            tree.addChildNode(coneN)
            tree.castsShadow = true
            tree.position = SCNVector3(pos.x, 0, pos.z)
            scene.rootNode.addChildNode(tree)
        }
        
        let lampCount = 16
        for i in 0..<lampCount {
            let a = Float(i) / Float(lampCount) * Float.pi * 2
            let r = trackCenterRadius + trackWidth/2 + 2.5
            let h: Float = 6
            let post = SCNCylinder(radius: 0.18, height: CGFloat(h))
            let pm = SCNMaterial()
            pm.diffuse.contents = UIColor(white: 0.82, alpha: 1)
            post.firstMaterial = pm
            let postN = SCNNode(geometry: post)
            postN.position.y = h / 2
            
            let head = SCNSphere(radius: 0.4)
            let hm = SCNMaterial()
            hm.diffuse.contents = UIColor(red: 1, green: 0.95, blue: 0.7, alpha: 1)
            hm.emission.contents = UIColor(red: 1, green: 0.85, blue: 0.5, alpha: 1)
            head.firstMaterial = hm
            let headN = SCNNode(geometry: head)
            headN.position.y = h + 0.3
            
            let lamp = SCNNode()
            lamp.addChildNode(postN)
            lamp.addChildNode(headN)
            lamp.castsShadow = true
            lamp.position = SCNVector3(cos(a) * r, 0, sin(a) * r)
            scene.rootNode.addChildNode(lamp)
        }
    }
    
    private func addCar() {
        let body = SCNBox(width: 2, height: 0.7, length: 4, chamferRadius: 0.25)
        let bm = SCNMaterial()
        bm.diffuse.contents = car.body
        bm.metalness.contents = 0.5
        bm.roughness.contents = 0.25
        body.firstMaterial = bm
        let bodyN = SCNNode(geometry: body)
        bodyN.position.y = 0.7
        carNode.addChildNode(bodyN)
        
        let cab = SCNBox(width: 1.7, height: 0.7, length: 2, chamferRadius: 0.2)
        let cm = SCNMaterial()
        cm.diffuse.contents = car.cabin
        cm.metalness.contents = 0.7
        cm.roughness.contents = 0.08
        cab.firstMaterial = cm
        let cabN = SCNNode(geometry: cab)
        cabN.position = SCNVector3(0, 1.4, 0)
        carNode.addChildNode(cabN)
        
        let wheels: [(Float, Float)] = [(-1, 1.4), (1, 1.4), (-1, -1.4), (1, -1.4)]
        for (xs, zs) in wheels {
            let wheel = SCNCylinder(radius: tread.radius, height: tread.width)
            let wm = SCNMaterial()
            wm.diffuse.contents = tread.color
            wheel.firstMaterial = wm
            let n = SCNNode(geometry: wheel)
            n.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
            n.position = SCNVector3(xs * 1.05, Float(tread.radius), zs)
            carNode.addChildNode(n)
        }
        
        for x in [Float(-0.6), Float(0.6)] {
            let l = SCNSphere(radius: 0.18)
            let lm = SCNMaterial()
            lm.diffuse.contents = UIColor.white
            lm.emission.contents = UIColor(red: 1, green: 1, blue: 0.85, alpha: 1)
            l.firstMaterial = lm
            let n = SCNNode(geometry: l)
            n.position = SCNVector3(x, 0.7, -1.95)
            carNode.addChildNode(n)
        }
        
        for x in [Float(-0.6), Float(0.6)] {
            let l = SCNBox(width: 0.4, height: 0.15, length: 0.1, chamferRadius: 0.02)
            let lm = SCNMaterial()
            lm.diffuse.contents = UIColor(red: 0.6, green: 0.1, blue: 0.1, alpha: 1)
            lm.emission.contents = UIColor(red: 1, green: 0.2, blue: 0.15, alpha: 1)
            l.firstMaterial = lm
            let n = SCNNode(geometry: l)
            n.position = SCNVector3(x, 0.85, 1.95)
            carNode.addChildNode(n)
        }
        
        for x in [Float(-1.05), Float(1.05)] {
            let emitter = SCNNode()
            emitter.position = SCNVector3(x, 0.3, 1.4)
            carNode.addChildNode(emitter)
            smokeEmitters.append(emitter)
        }
        
        carNode.position = SCNVector3(0, 0.5, 0)
        scene.rootNode.addChildNode(carNode)
    }
    
    private func addCoinsAlongTrack(count: Int) {
        var rng = SystemRandomNumberGenerator()
        for i in 0..<count {
            let a = Float(i) / Float(count) * Float.pi * 2
            let lateral = Float.random(in: -trackWidth/2 + 1.5 ... trackWidth/2 - 1.5,
                                       using: &rng)
            let r = trackCenterRadius + lateral
            let pos = SCNVector3(cos(a) * r, 1.0, sin(a) * r)
            let n = makeCoin()
            n.position = pos
            scene.rootNode.addChildNode(n)
            coins.append(n)
        }
    }
    
    private func addPowerUpsAlongTrack(count: Int) {
        var rng = SystemRandomNumberGenerator()
        for i in 0..<count {
            let a = Float(i) / Float(count) * Float.pi * 2 + 0.1
            let lateral = Float.random(in: -trackWidth/2 + 2 ... trackWidth/2 - 2,
                                       using: &rng)
            let r = trackCenterRadius + lateral
            let pos = SCNVector3(cos(a) * r, 1.5, sin(a) * r)
            let type = PowerUpType.allCases.randomElement(using: &rng)!
            let n = makePowerUp(type)
            n.position = pos
            scene.rootNode.addChildNode(n)
            powerUps.append((n, type))
        }
    }
    
    private func makeCoin() -> SCNNode {
        let geo = SCNCylinder(radius: 0.55, height: 0.14)
        let m = SCNMaterial()
        m.diffuse.contents = UIColor(red: 1.0, green: 0.85, blue: 0.18, alpha: 1)
        m.metalness.contents = 0.85
        m.roughness.contents = 0.18
        m.emission.contents = UIColor(red: 0.55, green: 0.40, blue: 0.05, alpha: 1)
        geo.firstMaterial = m
        let coin = SCNNode(geometry: geo)
        coin.eulerAngles.z = Float.pi / 2
        let spinner = SCNNode()
        spinner.addChildNode(coin)
        spinner.runAction(SCNAction.repeatForever(
            SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 1.6)
        ))
        return spinner
    }
    
    private func makePowerUp(_ type: PowerUpType) -> SCNNode {
        let geo = SCNBox(width: 1.2, height: 1.2, length: 1.2, chamferRadius: 0.18)
        let m = SCNMaterial()
        m.diffuse.contents = type.uiColor
        m.emission.contents = type.uiColor.withAlphaComponent(0.65)
        m.metalness.contents = 0.6
        m.roughness.contents = 0.2
        geo.firstMaterial = m
        let cube = SCNNode(geometry: geo)
        cube.runAction(SCNAction.repeatForever(
            SCNAction.rotateBy(x: 0.5, y: CGFloat.pi * 2, z: 0.3, duration: 3)
        ))
        let container = SCNNode()
        container.addChildNode(cube)
        return container
    }
    
    private func addCamera() {
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zNear = 0.2
        cameraNode.camera?.zFar = 350
        cameraNode.camera?.fieldOfView = 65
        cameraNode.camera?.bloomIntensity = 0.4
        cameraNode.camera?.bloomThreshold = 0.85
        cameraNode.camera?.wantsHDR = true
        cameraNode.position = SCNVector3(0, 5.5, 11)
        cameraNode.look(at: SCNVector3(0, 1.4, -2),
                        up: SCNVector3(0, 1, 0),
                        localFront: SCNVector3(0, 0, -1))
        scene.rootNode.addChildNode(cameraNode)
    }
    
    private func randomOffTrackPosition(rng: inout SystemRandomNumberGenerator,
                                        minDist: Float) -> SCNVector3 {
        for _ in 0..<30 {
            let x = Float.random(in: -90...90, using: &rng)
            let z = Float.random(in: -90...90, using: &rng)
            let r = sqrt(x*x + z*z)
            if abs(r - trackCenterRadius) > trackWidth/2 + 4 && r > 8 && r < 90 {
                return SCNVector3(x, 0, z)
            }
        }
        return SCNVector3(60, 0, 60)
    }
    
    private func addShield() {
        removeShield()
        let s = SCNSphere(radius: 2.4)
        let m = SCNMaterial()
        m.diffuse.contents = UIColor.clear
        m.emission.contents = UIColor(red: 0.35, green: 0.75, blue: 1.0, alpha: 1)
        m.transparency = 0.45
        m.cullMode = .front
        s.firstMaterial = m
        let n = SCNNode(geometry: s)
        n.position = SCNVector3(0, 1.0, 0)
        carNode.addChildNode(n)
        n.runAction(SCNAction.repeatForever(
            SCNAction.rotateBy(x: 0.2, y: 1, z: 0.3, duration: 4)
        ))
        shieldNode = n
    }
    
    private func removeShield() {
        shieldNode?.removeFromParentNode()
        shieldNode = nil
    }
    
    private func isDescendantOfCar(_ node: SCNNode) -> Bool {
        var n: SCNNode? = node
        while let nn = n {
            if nn === carNode { return true }
            n = nn.parent
        }
        return false
    }
    
    private func spawnSmokePuff(at worldPos: SCNVector3) {
        let puff = SCNSphere(radius: 0.35)
        let m = SCNMaterial()
        m.diffuse.contents = UIColor.white
        m.emission.contents = UIColor(white: 0.9, alpha: 1)
        m.transparency = 0.7
        puff.firstMaterial = m
        let n = SCNNode(geometry: puff)
        n.position = worldPos
        scene.rootNode.addChildNode(n)
        let fade = SCNAction.group([
            SCNAction.fadeOut(duration: 0.7),
            SCNAction.scale(by: 2.2, duration: 0.7),
            SCNAction.move(by: SCNVector3(0, 0.6, 0), duration: 0.7)
        ])
        n.runAction(SCNAction.sequence([fade, SCNAction.removeFromParentNode()]))
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let state = state else { return }
        
        let dt: Float
        if lastTime == 0 {
            dt = Float(1.0 / 60.0)
            lapStartTime = time
        } else {
            dt = min(Float(time - lastTime), Float(0.1))
        }
        lastTime = time
        
        if state.isPaused || state.isFinished { return }
        
        let steer = state.steerInput
        let throttle = state.throttleInput
        let isDrift = state.driftHeld
        
        let isBoost = (localPU == .speed)
        let baseFwd = car.topSpeed
        let baseAccel = car.acceleration
        let maxFwd: Float = isBoost ? baseFwd * 1.7 : baseFwd
        let maxRev: Float = baseFwd * 0.5
        let accel: Float = isBoost ? baseAccel * 1.5 : baseAccel
        
        if throttle > 0 {
            velocity = min(velocity + throttle * accel * dt, maxFwd)
        } else if throttle < 0 {
            velocity = max(velocity + throttle * accel * dt, -maxRev)
        } else {
            let drag: Float = isDrift ? 3.5 : 7
            if velocity > 0 { velocity = max(velocity - drag * dt, 0) }
            else if velocity < 0 { velocity = min(velocity + drag * dt, 0) }
        }
        
        let speedAbs = abs(velocity)
        if speedAbs > 0.5 {
            let speedFactor = speedAbs / max(maxFwd, 0.001)
            let driftMul: Float = isDrift ? 1.7 : 1.0
            let yaw = steer * car.handling * tread.gripBonus *
            (0.25 + 0.75 * speedFactor) * driftMul
            let sign: Float = velocity >= 0 ? 1 : -1
            carNode.eulerAngles.y -= yaw * sign * dt
        }
        
        let heading = carNode.eulerAngles.y
        var newPos = carNode.position
        newPos.x += -sin(heading) * velocity * dt
        newPos.z += -cos(heading) * velocity * dt
        
        let r = sqrt(newPos.x * newPos.x + newPos.z * newPos.z)
        if r > 95 {
            let s = 95 / r
            newPos.x *= s
            newPos.z *= s
            velocity *= 0.4
        }
        
        let from = SCNVector3(newPos.x, newPos.y + 12, newPos.z)
        let to = SCNVector3(newPos.x, newPos.y - 12, newPos.z)
        let hits = scene.rootNode.hitTestWithSegment(from: from, to: to, options: nil)
        var groundY: Float = 0
        for hit in hits {
            if isDescendantOfCar(hit.node) { continue }
            if hit.worldCoordinates.y > newPos.y + 4 { continue }
            groundY = hit.worldCoordinates.y
            break
        }
        let targetY = groundY + Float(tread.radius) + 0.08
        newPos.y += (targetY - newPos.y) * min(Float(1), 8 * dt)
        carNode.position = newPos
        
        let camDist: Float = 11
        let camHeight: Float = 5.5
        let smoothing = min(Float(1), 5 * dt)
        let desiredCamPos = SCNVector3(
            newPos.x + sin(heading) * camDist,
            newPos.y + camHeight,
            newPos.z + cos(heading) * camDist
        )
        cameraNode.position = SCNVector3(
            cameraNode.position.x + (desiredCamPos.x - cameraNode.position.x) * smoothing,
            cameraNode.position.y + (desiredCamPos.y - cameraNode.position.y) * smoothing,
            cameraNode.position.z + (desiredCamPos.z - cameraNode.position.z) * smoothing
        )
        cameraNode.look(
            at: SCNVector3(newPos.x - sin(heading) * 2,
                           newPos.y + 1.4,
                           newPos.z - cos(heading) * 2),
            up: SCNVector3(0, 1, 0),
            localFront: SCNVector3(0, 0, -1)
        )
        
        if isDrift && speedAbs > 4 {
            for emitter in smokeEmitters where Float.random(in: 0...1) < 0.6 {
                let world = emitter.convertPosition(SCNVector3Zero, to: nil)
                spawnSmokePuff(at: world)
            }
        }
        
        let magnetRange: Float = (localPU == .magnet) ? 14 : 0
        let pickupRange: Float = 1.8
        for coin in coins where coin.parent != nil {
            let dx = coin.position.x - newPos.x
            let dz = coin.position.z - newPos.z
            let dist = sqrt(dx*dx + dz*dz)
            if magnetRange > 0 && dist < magnetRange && dist > 0.001 && dist > pickupRange {
                let pull: Float = 28
                coin.position.x -= (dx / dist) * pull * dt
                coin.position.z -= (dz / dist) * pull * dt
            }
            if dist < pickupRange {
                coin.removeFromParentNode()
                coinRespawn.append((time + 6, coin.position))
                localScore += 1
            }
        }
        coins.removeAll { $0.parent == nil }
        
        for entry in powerUps where entry.node.parent != nil {
            let dx = entry.node.position.x - newPos.x
            let dz = entry.node.position.z - newPos.z
            if sqrt(dx*dx + dz*dz) < 2.2 {
                entry.node.removeFromParentNode()
                puRespawn.append((time + 14,
                                  PowerUpType.allCases.randomElement()!,
                                  entry.node.position))
                localPU = entry.type
                localPUTime = entry.type.duration
                if entry.type == .shield { addShield() } else { removeShield() }
            }
        }
        powerUps.removeAll { $0.node.parent == nil }
        
        for entry in coinRespawn where entry.time <= time {
            let c = makeCoin(); c.position = entry.pos
            scene.rootNode.addChildNode(c)
            coins.append(c)
        }
        coinRespawn.removeAll { $0.time <= time }
        for entry in puRespawn where entry.time <= time {
            let n = makePowerUp(entry.type); n.position = entry.pos
            scene.rootNode.addChildNode(n)
            powerUps.append((n, entry.type))
        }
        puRespawn.removeAll { $0.time <= time }
        
        if localPU != nil {
            localPUTime -= Double(dt)
            if localPUTime <= 0 {
                if localPU == .shield { removeShield() }
                localPU = nil
                localPUTime = 0
            }
        }
        
        let angle = atan2(newPos.z, newPos.x)
        if !crossedHalf && abs(angle - .pi/2) < 0.5 { crossedHalf = true }
        let nearStart = abs(angle - (-.pi/2)) < 0.5
        if crossedHalf && nearStart && lastAngle > -.pi/2 - 0.5 && angle <= -.pi/2 + 0.1 {
            let lapDuration = time - lapStartTime
            lapStartTime = time
            crossedHalf = false
            lapsDone += 1
            DispatchQueue.main.async {
                state.lap = self.lapsDone
                state.lastLapTime = lapDuration
                if state.bestLapTime == 0 || lapDuration < state.bestLapTime {
                    state.bestLapTime = lapDuration
                }
                if self.lapsDone >= state.totalLaps {
                    state.isFinished = true
                    if state.score > state.bestScore { state.bestScore = state.score }
                }
            }
        }
        lastAngle = angle
        
        let liveLapTime = time - lapStartTime
        let speedRounded = Float(Int(speedAbs * 10)) / 10
        let timeRounded = Double(Int(localPUTime * 10)) / 10
        let lapTimeRounded = Double(Int(liveLapTime * 10)) / 10
        if localScore != publishedScore || speedRounded != publishedSpeed ||
            localPU != publishedPU || timeRounded != publishedPUTime ||
            lapsDone != publishedLap || lapTimeRounded != publishedLapTime {
            publishedScore = localScore
            publishedSpeed = speedRounded
            publishedPU = localPU
            publishedPUTime = timeRounded
            publishedLap = lapsDone
            publishedLapTime = lapTimeRounded
            
            let scoreCopy = localScore
            let speedCopy = speedAbs
            let puCopy = localPU
            let puTimeCopy = localPUTime
            let lapCopy = lapsDone
            let liveLapCopy = liveLapTime
            DispatchQueue.main.async {
                state.score = scoreCopy
                state.speed = speedCopy
                state.activePowerUp = puCopy
                state.powerUpTimeRemaining = max(0, puTimeCopy)
                state.lap = lapCopy
                state.lapTime = liveLapCopy
            }
        }
    }
}

// =====================================================
// MARK: - SCENEKIT BRIDGE
// =====================================================

struct GameSceneView: UIViewRepresentable {
    let state: GameState
    
    func makeUIView(context: Context) -> SCNView {
        let v = SCNView(frame: .zero, options: nil)
        let world = GameWorld(state: state)
        context.coordinator.world = world
        v.scene = world.scene
        v.pointOfView = world.cameraNode
        v.delegate = world
        v.isPlaying = true
        v.rendersContinuously = true
        v.antialiasingMode = .multisampling4X
        v.preferredFramesPerSecond = 60
        v.allowsCameraControl = false
        v.backgroundColor = .clear
        return v
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator { var world: GameWorld? }
}

// =====================================================
// MARK: - HELPERS
// =====================================================

func formatTime(_ t: Double) -> String {
    if t <= 0 { return "—:——.—" }
    let m = Int(t) / 60
    let s = t - Double(m * 60)
    return String(format: "%d:%05.2f", m, s)
}

// Reusable mini car illustration for menus
struct MiniCarIllustration: View {
    let bodyColor: Color
    let cabinColor: Color
    var width: CGFloat = 110
    var height: CGFloat = 60
    
    var bodyShape: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(bodyColor)
            .frame(width: width, height: height * 0.55)
    }
    
    var cabinShape: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(cabinColor)
            .frame(width: width * 0.55, height: height * 0.4)
            .offset(y: -height * 0.25)
    }
    
    var headlight: some View {
        Circle().fill(Color.yellow.opacity(0.9))
            .frame(width: 6, height: 6)
            .offset(x: width * 0.42, y: 0)
    }
    
    var wheels: some View {
        HStack(spacing: width * 0.45) {
            Circle().fill(Color.black).frame(width: 14, height: 14)
            Circle().fill(Color.black).frame(width: 14, height: 14)
        }
        .offset(y: height * 0.25)
    }
    
    var body: some View {
        ZStack {
            wheels
            bodyShape
            cabinShape
            headlight
        }
        .frame(width: width, height: height)
    }
}

// =====================================================
// MARK: - HUD COMPONENTS
// =====================================================

struct ScoreBadge: View {
    let score: Int
    
    private var coinIcon: some View {
        Circle().fill(LinearGradient(colors: [
            Color(red: 1, green: 0.92, blue: 0.4),
            Color(red: 0.95, green: 0.65, blue: 0.1)
        ], startPoint: .top, endPoint: .bottom))
        .frame(width: 22, height: 22)
    }
    
    private var scoreText: some View {
        Text("\(score)")
            .font(.system(size: 22, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .monospacedDigit()
    }
    
    var body: some View {
        HStack(spacing: 8) {
            coinIcon
            scoreText
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.18), lineWidth: 1))
    }
}

struct LapBadge: View {
    let lap: Int
    let total: Int
    let lapTime: Double
    let bestLap: Double
    
    private var lapLabel: some View {
        Text("LAP \(min(lap+1, total))/\(total)")
            .font(.system(size: 11, weight: .heavy))
            .kerning(1.5)
            .foregroundStyle(.white.opacity(0.7))
    }
    
    private var timeText: some View {
        Text(formatTime(lapTime))
            .font(.system(size: 18, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .monospacedDigit()
    }
    
    private var bestText: some View {
        Group {
            if bestLap > 0 {
                Text("Best \(formatTime(bestLap))")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color(red: 1, green: 0.85, blue: 0.3))
                    .monospacedDigit()
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            lapLabel
            timeText
            bestText
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.18), lineWidth: 1))
    }
}

struct SpeedBadge: View {
    let speed: Float
    var kmh: Int { Int(speed * 4.2) }
    
    private var speedNumber: some View {
        Text("\(kmh)")
            .font(.system(size: 18, weight: .heavy, design: .rounded))
            .foregroundColor(.white)
            .monospacedDigit()
    }
    
    private var speedLabel: some View {
        Text("KM/H")
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.white.opacity(0.6))
            .kerning(0.5)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "gauge.with.needle")
                .foregroundColor(.white)
                .font(.system(size: 18, weight: .semibold))
            VStack(alignment: .leading, spacing: -1) {
                speedNumber
                speedLabel
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.18), lineWidth: 1))
    }
}

struct PowerUpIndicator: View {
    let type: PowerUpType
    let timeRemaining: Double
    var fraction: Double { max(0, min(1, timeRemaining / type.duration)) }
    
    private var iconView: some View {
        Image(systemName: type.symbol)
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(type.tint)
            .frame(width: 30)
    }
    
    private var nameLabel: some View {
        Text(type.name.uppercased())
            .font(.system(size: 11, weight: .heavy))
            .kerning(1.5)
            .foregroundStyle(.white)
    }
    
    private var progressBar: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(Color.white.opacity(0.15))
                .frame(width: 90, height: 5)
            Capsule().fill(type.tint)
                .frame(width: 90 * fraction, height: 5)
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            iconView
            VStack(alignment: .leading, spacing: 5) {
                nameLabel
                progressBar
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(type.tint.opacity(0.55), lineWidth: 1.5))
    }
}

struct ControlButton: View {
    let symbol: String
    let tint: Color
    @Binding var isPressed: Bool
    
    private var iconView: some View {
        Image(systemName: symbol)
            .font(.system(size: 30, weight: .heavy))
            .foregroundStyle(.white)
    }
    
    private var background: some View {
        Circle()
            .fill(.ultraThinMaterial)
            .overlay(Circle().stroke(tint.opacity(0.6), lineWidth: 2))
    }
    
    var body: some View {
        iconView
            .frame(width: 72, height: 72)
            .background(background)
            .scaleEffect(isPressed ? 0.88 : 1)
            .opacity(isPressed ? 0.7 : 1)
            .shadow(color: tint.opacity(isPressed ? 0.6 : 0.2), radius: 10)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
            .contentShape(Circle())
            .onLongPressGesture(minimumDuration: 0,
                                maximumDistance: .infinity,
                                perform: {},
                                onPressingChanged: { isPressed = $0 })
    }
}

// =====================================================
// MARK: - SPLASH SCREEN
// =====================================================

enum AppScreen { case splash, carSelect, treadSelect, ready, playing, finished }

struct AnimatedRoadStripes: View {
    @State private var offset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<8) { i in
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 6, height: 30)
                        .offset(y: CGFloat(i) * 60 - offset)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                offset = 60
            }
        }
    }
}

struct SplashScreen: View {
    let onStart: () -> Void
    let bestScore: Int
    @State private var pulse = false
    
    private var bgGradient: some View {
        LinearGradient(colors: [
            Color(red: 0.05, green: 0.08, blue: 0.18),
            Color(red: 0.18, green: 0.08, blue: 0.30)
        ], startPoint: .top, endPoint: .bottom)
        .ignoresSafeArea()
    }
    
    private var carIcon: some View {
        Image(systemName: "car.side.fill")
            .font(.system(size: 80, weight: .heavy))
            .foregroundStyle(LinearGradient(
                colors: [Color(red: 1, green: 0.5, blue: 0.3),
                         Color(red: 1, green: 0.85, blue: 0.4)],
                startPoint: .leading, endPoint: .trailing))
            .shadow(color: .orange.opacity(0.6), radius: 20)
            .scaleEffect(pulse ? 1.05 : 1)
            .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true),
                       value: pulse)
    }
    
    private var titleStack: some View {
        VStack(spacing: 6) {
            Text("CRUISER 3D")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .kerning(3)
                .foregroundStyle(.white)
            Text("CIRCUIT EDITION")
                .font(.system(size: 13, weight: .heavy))
                .kerning(4)
                .foregroundStyle(.white.opacity(0.6))
        }
    }
    
    private var startButton: some View {
        Button(action: onStart) {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                    .font(.system(size: 18, weight: .heavy))
                Text("START").kerning(2)
                    .font(.system(size: 18, weight: .heavy))
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 50)
            .padding(.vertical, 18)
            .background(Capsule().fill(.white))
            .shadow(color: .white.opacity(0.4), radius: 16)
        }
    }
    
    private var bestScoreBadge: some View {
        Group {
            if bestScore > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(.yellow)
                    Text("Best: \(bestScore)")
                        .foregroundStyle(.white)
                }
                .font(.system(size: 13, weight: .bold))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Capsule().fill(.white.opacity(0.1)))
            }
        }
    }
    
    private var hintText: some View {
        Text("HOLD GAS · TAP TURN · DRIFT TO SLIDE")
            .font(.system(size: 10, weight: .bold))
            .kerning(2)
            .foregroundStyle(.white.opacity(0.4))
            .padding(.bottom, 30)
    }
    
    var body: some View {
        ZStack {
            bgGradient
            AnimatedRoadStripes()
                .opacity(0.8)
            
            VStack(spacing: 30) {
                Spacer()
                carIcon
                titleStack
                bestScoreBadge
                Spacer()
                startButton
                hintText
            }
            .padding()
        }
        .onAppear { pulse = true }
    }
}

// =====================================================
// MARK: - CAR SELECT
// =====================================================

struct CarSelectScreen: View {
    @Binding var selected: Int
    let bestScore: Int
    let onNext: () -> Void
    let onBack: () -> Void
    
    private var bg: some View {
        LinearGradient(colors: [
            Color(red: 0.05, green: 0.08, blue: 0.18),
            Color(red: 0.10, green: 0.18, blue: 0.30)
        ], startPoint: .top, endPoint: .bottom)
        .ignoresSafeArea()
    }
    
    private var topBar: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Circle().fill(.white.opacity(0.15)))
            }
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "trophy.fill").foregroundStyle(.yellow)
                Text("Best: \(bestScore)")
                    .foregroundStyle(.white)
            }
            .font(.system(size: 12, weight: .bold))
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(Capsule().fill(.white.opacity(0.1)))
        }
    }
    
    private var title: some View {
        VStack(spacing: 4) {
            Text("CHOOSE YOUR CAR")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .kerning(2)
                .foregroundStyle(.white)
            Text("Each car has different stats")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.6))
        }
    }
    
    private var carList: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(CarConfig.all) { car in
                    CarCard(car: car,
                            selected: selected == car.id,
                            locked: car.unlockScore > bestScore,
                            onTap: {
                        if car.unlockScore <= bestScore { selected = car.id }
                    })
                }
            }
        }
    }
    
    private var nextButton: some View {
        Button(action: onNext) {
            HStack(spacing: 10) {
                Text("NEXT").kerning(2)
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .heavy))
            }
            .font(.system(size: 17, weight: .heavy))
            .foregroundStyle(.black)
            .padding(.horizontal, 50)
            .padding(.vertical, 16)
            .background(Capsule().fill(.white))
        }
    }
    
    var body: some View {
        ZStack {
            bg
            VStack(spacing: 16) {
                topBar
                title
                carList
                nextButton
            }
            .padding(20)
        }
    }
}

struct CarCard: View {
    let car: CarConfig
    let selected: Bool
    let locked: Bool
    let onTap: () -> Void
    
    private var carPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(colors: [
                    Color.white.opacity(0.05),
                    Color.black.opacity(0.2)
                ], startPoint: .top, endPoint: .bottom))
                .frame(width: 130, height: 78)
            if locked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.6))
            } else {
                MiniCarIllustration(bodyColor: car.bodyColor, cabinColor: car.cabinColor)
            }
        }
    }
    
    private var nameLine: some View {
        Text(car.name.uppercased())
            .font(.system(size: 18, weight: .heavy))
            .kerning(1.5)
            .foregroundStyle(.white)
    }
    
    private var taglineOrLock: some View {
        Group {
            if locked {
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill").font(.system(size: 10))
                    Text("Score \(car.unlockScore) to unlock")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(.orange)
            } else {
                Text(car.tagline)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(2)
            }
        }
    }
    
    private var statsRow: some View {
        HStack(spacing: 8) {
            StatBar(label: "SPD", value: (car.topSpeed - 18) / 14)
            StatBar(label: "ACC", value: (car.acceleration - 18) / 12)
            StatBar(label: "HND", value: (2.1 - car.handling) / 0.6)
        }
    }
    
    private var infoStack: some View {
        VStack(alignment: .leading, spacing: 5) {
            nameLine
            taglineOrLock
            if !locked {
                statsRow.padding(.top, 2)
            }
        }
    }
    
    private var checkBadge: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 24))
            .foregroundStyle(.green)
    }
    
    private var cardBg: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(selected ? Color.white.opacity(0.18) : Color.white.opacity(0.08))
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(selected ? Color.white : Color.white.opacity(0.15),
                    lineWidth: selected ? 2 : 1)
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                carPreview
                infoStack
                Spacer()
                if selected { checkBadge }
            }
            .padding(12)
            .background(cardBg)
            .overlay(cardBorder)
            .opacity(locked ? 0.55 : 1)
        }
        .buttonStyle(.plain)
    }
}

struct StatBar: View {
    let label: String
    let value: Float
    var clamped: Float { max(0, min(1, value)) }
    
    private var labelText: some View {
        Text(label)
            .font(.system(size: 8, weight: .black))
            .foregroundStyle(.white.opacity(0.6))
            .kerning(0.5)
    }
    
    private var bar: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(Color.white.opacity(0.15))
                .frame(width: 50, height: 4)
            Capsule().fill(LinearGradient(colors: [.cyan, .blue],
                                          startPoint: .leading,
                                          endPoint: .trailing))
            .frame(width: CGFloat(50 * clamped), height: 4)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            labelText
            bar
        }
    }
}

// =====================================================
// MARK: - TREAD SELECT
// =====================================================

struct TreadSelectScreen: View {
    @Binding var selected: Int
    let onNext: () -> Void
    let onBack: () -> Void
    
    private var bg: some View {
        LinearGradient(colors: [
            Color(red: 0.05, green: 0.08, blue: 0.18),
            Color(red: 0.18, green: 0.10, blue: 0.18)
        ], startPoint: .top, endPoint: .bottom)
        .ignoresSafeArea()
    }
    
    private var topBar: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Circle().fill(.white.opacity(0.15)))
            }
            Spacer()
        }
    }
    
    private var title: some View {
        VStack(spacing: 4) {
            Text("CHOOSE YOUR TREADS")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .kerning(2)
                .foregroundStyle(.white)
            Text("Treads change grip and feel")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.6))
        }
    }
    
    private var treadList: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(TreadConfig.all) { tread in
                    TreadCard(tread: tread,
                              selected: selected == tread.id,
                              onTap: { selected = tread.id })
                }
            }
        }
    }
    
    private var readyButton: some View {
        Button(action: onNext) {
            HStack(spacing: 10) {
                Text("READY").kerning(2)
                Image(systemName: "flag.checkered")
                    .font(.system(size: 16, weight: .heavy))
            }
            .font(.system(size: 17, weight: .heavy))
            .foregroundStyle(.black)
            .padding(.horizontal, 50)
            .padding(.vertical, 16)
            .background(Capsule().fill(.white))
        }
    }
    
    var body: some View {
        ZStack {
            bg
            VStack(spacing: 16) {
                topBar
                title
                treadList
                readyButton
            }
            .padding(20)
        }
    }
}

struct TreadCard: View {
    let tread: TreadConfig
    let selected: Bool
    let onTap: () -> Void
    
    private var wheelIcon: some View {
        ZStack {
            Circle().fill(tread.swiftColor)
                .frame(width: 56, height: 56)
            Circle().stroke(Color.white.opacity(0.3), lineWidth: 2)
                .frame(width: 56, height: 56)
            Circle().fill(Color.white.opacity(0.15))
                .frame(width: 28, height: 28)
            Circle().fill(Color.white.opacity(0.25))
                .frame(width: 12, height: 12)
        }
    }
    
    private var nameText: some View {
        Text(tread.name.uppercased())
            .font(.system(size: 17, weight: .heavy))
            .kerning(1.5)
            .foregroundStyle(.white)
    }
    
    private var descText: some View {
        Text(tread.description)
            .font(.system(size: 12))
            .foregroundStyle(.white.opacity(0.7))
    }
    
    private var gripText: some View {
        let gripStr = String(format: "%.2fx", tread.gripBonus)
        return HStack(spacing: 4) {
            Image(systemName: "scope").font(.system(size: 9))
            Text("Grip \(gripStr)")
        }
        .font(.system(size: 10, weight: .bold))
        .foregroundStyle(.cyan)
    }
    
    private var infoStack: some View {
        VStack(alignment: .leading, spacing: 3) {
            nameText
            descText
            gripText
        }
    }
    
    private var checkmark: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 24))
            .foregroundStyle(.green)
    }
    
    private var cardBg: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(selected ? Color.white.opacity(0.18) : Color.white.opacity(0.08))
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(selected ? Color.white : Color.white.opacity(0.15),
                    lineWidth: selected ? 2 : 1)
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                wheelIcon
                infoStack
                Spacer()
                if selected { checkmark }
            }
            .padding(14)
            .background(cardBg)
            .overlay(cardBorder)
        }
        .buttonStyle(.plain)
    }
}

// =====================================================
// MARK: - READY (COUNTDOWN)
// =====================================================

struct ReadyScreen: View {
    let car: CarConfig
    let tread: TreadConfig
    let onGo: () -> Void
    let onBack: () -> Void
    @State private var count = 3
    @State private var timer: Timer?
    
    private var bg: some View {
        LinearGradient(colors: [Color.black, Color(red: 0.10, green: 0.05, blue: 0.20)],
                       startPoint: .top, endPoint: .bottom)
        .ignoresSafeArea()
    }
    
    private var backButton: some View {
        Button(action: {
            timer?.invalidate()
            onBack()
        }) {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(.white)
                .padding(12)
                .background(Circle().fill(.white.opacity(0.15)))
        }
    }
    
    private var carInfo: some View {
        VStack(spacing: 8) {
            MiniCarIllustration(bodyColor: car.bodyColor, cabinColor: car.cabinColor,
                                width: 140, height: 80)
            Text(car.name.uppercased())
                .font(.system(size: 28, weight: .black))
                .kerning(3)
                .foregroundStyle(.white)
            Text("on \(tread.name) treads")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white.opacity(0.6))
        }
    }
    
    private var countdownLabel: some View {
        Text(count > 0 ? "\(count)" : "GO!")
            .font(.system(size: 130, weight: .black, design: .rounded))
            .foregroundStyle(count > 0 ? Color(red: 1, green: 0.5, blue: 0.3) : .green)
            .shadow(color: count > 0 ? .orange : .green, radius: 30)
            .id(count)
            .transition(.scale.combined(with: .opacity))
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: count)
    }
    
    var body: some View {
        ZStack {
            bg
            VStack(spacing: 24) {
                HStack { backButton; Spacer() }
                Spacer()
                carInfo
                Spacer()
                countdownLabel
                Spacer()
            }
            .padding()
        }
        .onAppear {
            count = 3
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if count > 1 { count -= 1 }
                else if count == 1 {
                    count = 0
                } else {
                    timer?.invalidate()
                    onGo()
                }
            }
        }
        .onDisappear { timer?.invalidate() }
    }
}

// =====================================================
// MARK: - FINISH SCREEN
// =====================================================

struct FinishScreen: View {
    let score: Int
    let bestLap: Double
    let onRestart: () -> Void
    let onMenu: () -> Void
    
    private var medal: (name: String, color: Color, icon: String) {
        if score >= 30 {
            return ("GOLD", Color(red: 1, green: 0.85, blue: 0.3), "trophy.fill")
        } else if score >= 15 {
            return ("SILVER", Color(white: 0.8), "rosette")
        } else {
            return ("BRONZE", Color(red: 0.8, green: 0.5, blue: 0.3), "medal.fill")
        }
    }
    
    private var trophyIcon: some View {
        Image(systemName: medal.icon)
            .font(.system(size: 70))
            .foregroundStyle(medal.color)
            .shadow(color: medal.color, radius: 20)
    }
    
    private var medalLabel: some View {
        Text(medal.name)
            .font(.system(size: 14, weight: .black))
            .kerning(3)
            .foregroundStyle(medal.color)
    }
    
    private var titleText: some View {
        Text("RACE COMPLETE")
            .font(.system(size: 26, weight: .black))
            .kerning(3)
            .foregroundStyle(.white)
    }
    
    private var statsCard: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Coins").foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text("\(score)").foregroundStyle(.white).monospacedDigit()
            }
            HStack {
                Text("Best lap").foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text(formatTime(bestLap)).foregroundStyle(.white).monospacedDigit()
            }
        }
        .font(.system(size: 16, weight: .bold))
        .padding(20)
        .frame(maxWidth: 280)
        .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.1)))
    }
    
    private var menuButton: some View {
        Button(action: onMenu) {
            Text("MENU").kerning(2)
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(.white)
                .padding(.horizontal, 30).padding(.vertical, 14)
                .background(Capsule().fill(.white.opacity(0.15)))
        }
    }
    
    private var restartButton: some View {
        Button(action: onRestart) {
            Text("RACE AGAIN").kerning(2)
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(.black)
                .padding(.horizontal, 30).padding(.vertical, 14)
                .background(Capsule().fill(.white))
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            VStack(spacing: 18) {
                trophyIcon
                medalLabel
                titleText
                statsCard
                HStack(spacing: 14) {
                    menuButton
                    restartButton
                }
            }
            .padding()
        }
    }
}

// =====================================================
// MARK: - GAMEPLAY VIEW
// =====================================================

struct GameplayView: View {
    @ObservedObject var state: GameState
    let onPause: () -> Void
    
    private var topHUD: some View {
        HStack(alignment: .top) {
            ScoreBadge(score: state.score)
            Spacer()
            LapBadge(lap: state.lap, total: state.totalLaps,
                     lapTime: state.lapTime, bestLap: state.bestLapTime)
            Spacer()
            SpeedBadge(speed: state.speed)
        }
        .padding(.horizontal, 14)
        .padding(.top, 18)
    }
    
    private var powerUpRow: some View {
        Group {
            if let pu = state.activePowerUp {
                PowerUpIndicator(type: pu, timeRemaining: state.powerUpTimeRemaining)
                    .padding(.top, 10)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    private var pauseButton: some View {
        HStack {
            Spacer()
            Button(action: onPause) {
                Image(systemName: "pause.fill")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Circle().fill(.ultraThinMaterial))
                    .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
            }
        }
        .padding(.horizontal, 18)
    }
    
    private var leftControls: some View {
        VStack(spacing: 12) {
            ControlButton(symbol: "arrow.up", tint: .green,
                          isPressed: $state.gasHeld)
            ControlButton(symbol: "arrow.down", tint: .red,
                          isPressed: $state.brakeHeld)
        }
    }
    
    private var driftControl: some View {
        VStack(spacing: 6) {
            ControlButton(symbol: "tornado", tint: .orange,
                          isPressed: $state.driftHeld)
            Text("DRIFT")
                .font(.system(size: 9, weight: .black))
                .kerning(1.5)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.bottom, 4)
    }
    
    private var rightControls: some View {
        HStack(spacing: 14) {
            ControlButton(symbol: "arrow.left", tint: .cyan,
                          isPressed: $state.leftHeld)
            ControlButton(symbol: "arrow.right", tint: .cyan,
                          isPressed: $state.rightHeld)
        }
    }
    
    private var bottomControls: some View {
        HStack(alignment: .bottom) {
            leftControls
            Spacer()
            driftControl
            Spacer()
            rightControls
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 26)
    }
    
    var body: some View {
        ZStack {
            GameSceneView(state: state).ignoresSafeArea()
            VStack(spacing: 0) {
                topHUD
                powerUpRow
                Spacer()
                pauseButton
                Spacer()
                bottomControls
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7),
                       value: state.activePowerUp)
        }
        .preferredColorScheme(.dark)
    }
}

// =====================================================
// MARK: - PAUSE OVERLAY
// =====================================================

struct PauseOverlay: View {
    let onResume: () -> Void
    let onMenu: () -> Void
    
    private var titleText: some View {
        Text("PAUSED")
            .font(.system(size: 28, weight: .black))
            .kerning(4)
            .foregroundStyle(.white)
    }
    
    private var resumeButton: some View {
        Button(action: onResume) {
            HStack {
                Image(systemName: "play.fill")
                Text("RESUME").kerning(2)
            }
            .font(.system(size: 16, weight: .heavy))
            .foregroundStyle(.black)
            .padding(.horizontal, 36).padding(.vertical, 14)
            .background(Capsule().fill(.white))
        }
    }
    
    private var menuButton: some View {
        Button(action: onMenu) {
            HStack {
                Image(systemName: "house.fill")
                Text("MAIN MENU").kerning(2)
            }
            .font(.system(size: 14, weight: .heavy))
            .foregroundStyle(.white)
            .padding(.horizontal, 30).padding(.vertical, 12)
            .background(Capsule().fill(.white.opacity(0.15)))
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            VStack(spacing: 18) {
                titleText
                resumeButton
                menuButton
            }
        }
    }
}

// =====================================================
// MARK: - ROOT VIEW
// =====================================================

struct ContentView: View {
    @StateObject private var state = GameState()
    @State private var screen: AppScreen = .splash
    @State private var carIndex = 0
    @State private var treadIndex = 0
    @State private var sessionId = 0
    
    @ViewBuilder
    private func screenView() -> some View {
        switch screen {
        case .splash:
            SplashScreen(onStart: { screen = .carSelect },
                         bestScore: state.bestScore)
        case .carSelect:
            CarSelectScreen(selected: $carIndex,
                            bestScore: state.bestScore,
                            onNext: { screen = .treadSelect },
                            onBack: { screen = .splash })
        case .treadSelect:
            TreadSelectScreen(selected: $treadIndex,
                              onNext: { startReady() },
                              onBack: { screen = .carSelect })
        case .ready:
            ReadyScreen(car: CarConfig.all[carIndex],
                        tread: TreadConfig.all[treadIndex],
                        onGo: { screen = .playing },
                        onBack: { screen = .treadSelect })
        case .playing:
            ZStack {
                GameplayView(state: state, onPause: { state.isPaused = true })
                    .id(sessionId)
                if state.isPaused {
                    PauseOverlay(onResume: { state.isPaused = false },
                                 onMenu: {
                        state.isPaused = false
                        screen = .splash
                    })
                }
                if state.isFinished {
                    FinishScreen(score: state.score,
                                 bestLap: state.bestLapTime,
                                 onRestart: { startReady() },
                                 onMenu: { screen = .splash })
                }
            }
        case .finished:
            FinishScreen(score: state.score,
                         bestLap: state.bestLapTime,
                         onRestart: { startReady() },
                         onMenu: { screen = .splash })
        }
    }
    
    var body: some View {
        screenView()
            .animation(.easeInOut(duration: 0.25), value: screen)
    }
    
    private func startReady() {
        state.score = 0
        state.speed = 0
        state.activePowerUp = nil
        state.powerUpTimeRemaining = 0
        state.lap = 0
        state.lapTime = 0
        state.bestLapTime = 0
        state.lastLapTime = 0
        state.isFinished = false
        state.isPaused = false
        state.leftHeld = false
        state.rightHeld = false
        state.gasHeld = false
        state.brakeHeld = false
        state.driftHeld = false
        state.car = CarConfig.all[carIndex]
        state.tread = TreadConfig.all[treadIndex]
        sessionId += 1
        screen = .ready
    }
}
import SwiftUI
import SceneKit

// =====================================================
// MARK: - DATA MODELS
// =====================================================

enum PowerUpType: CaseIterable {
    case speed, shield, magnet
    var name: String {
        switch self {
        case .speed: return "Turbo"
        case .shield: return "Shield"
        case .magnet: return "Magnet"
        }
    }
    var symbol: String {
        switch self {
        case .speed: return "bolt.fill"
        case .shield: return "shield.lefthalf.filled"
        case .magnet: return "scope"
        }
    }
    var tint: Color {
        switch self {
        case .speed: return Color(red: 1.0, green: 0.85, blue: 0.2)
        case .shield: return Color(red: 0.3, green: 0.85, blue: 1.0)
        case .magnet: return Color(red: 1.0, green: 0.4, blue: 0.7)
        }
    }
    var uiColor: UIColor { UIColor(self.tint) }
    var duration: Double {
        switch self {
        case .speed: return 6
        case .shield: return 10
        case .magnet: return 12
        }
    }
}

struct CarConfig: Identifiable, Equatable {
    let id: Int
    let name: String
    let tagline: String
    let body: UIColor
    let cabin: UIColor
    let topSpeed: Float
    let acceleration: Float
    let handling: Float
    let unlockScore: Int
    
    var bodyColor: Color { Color(body) }
    var cabinColor: Color { Color(cabin) }
    
    static let all: [CarConfig] = [
        CarConfig(id: 0, name: "Ember",   tagline: "Reliable starter, balanced everywhere",
                  body: UIColor(red: 0.86, green: 0.16, blue: 0.18, alpha: 1),
                  cabin: UIColor(red: 0.10, green: 0.16, blue: 0.24, alpha: 1),
                  topSpeed: 20, acceleration: 20, handling: 1.8, unlockScore: 0),
        CarConfig(id: 1, name: "Glacier", tagline: "Cool runner with sharper steering",
                  body: UIColor(red: 0.20, green: 0.55, blue: 0.95, alpha: 1),
                  cabin: UIColor(red: 0.05, green: 0.10, blue: 0.18, alpha: 1),
                  topSpeed: 22, acceleration: 19, handling: 2.0, unlockScore: 25),
        CarConfig(id: 2, name: "Mantis",  tagline: "Quick off the line, eager to corner",
                  body: UIColor(red: 0.40, green: 0.85, blue: 0.30, alpha: 1),
                  cabin: UIColor(red: 0.10, green: 0.20, blue: 0.10, alpha: 1),
                  topSpeed: 23, acceleration: 22, handling: 1.7, unlockScore: 75),
        CarConfig(id: 3, name: "Solar",   tagline: "Big top-end, demands precision",
                  body: UIColor(red: 1.00, green: 0.78, blue: 0.10, alpha: 1),
                  cabin: UIColor(red: 0.18, green: 0.12, blue: 0.05, alpha: 1),
                  topSpeed: 26, acceleration: 24, handling: 1.6, unlockScore: 150),
        CarConfig(id: 4, name: "Phantom", tagline: "Pure speed for veteran drivers",
                  body: UIColor(red: 0.10, green: 0.10, blue: 0.14, alpha: 1),
                  cabin: UIColor(red: 0.55, green: 0.15, blue: 0.85, alpha: 1),
                  topSpeed: 30, acceleration: 28, handling: 1.5, unlockScore: 300)
    ]
}

struct TreadConfig: Identifiable, Equatable {
    let id: Int
    let name: String
    let description: String
    let radius: CGFloat
    let width: CGFloat
    let color: UIColor
    let gripBonus: Float
    
    var swiftColor: Color { Color(color) }
    
    static let all: [TreadConfig] = [
        TreadConfig(id: 0, name: "Street",   description: "Balanced grip and speed",
                    radius: 0.42, width: 0.32,
                    color: UIColor(white: 0.08, alpha: 1), gripBonus: 1.0),
        TreadConfig(id: 1, name: "Off-Road", description: "Better grip, chunky tread",
                    radius: 0.50, width: 0.45,
                    color: UIColor(red: 0.30, green: 0.20, blue: 0.12, alpha: 1), gripBonus: 1.1),
        TreadConfig(id: 2, name: "Slicks",   description: "Maximum grip, less stable",
                    radius: 0.40, width: 0.28,
                    color: UIColor(white: 0.04, alpha: 1), gripBonus: 1.25),
        TreadConfig(id: 3, name: "Monster",  description: "Massive but slow turning",
                    radius: 0.62, width: 0.55,
                    color: UIColor(white: 0.05, alpha: 1), gripBonus: 0.85)
    ]
}

// =====================================================
// MARK: - SHARED GAME STATE
// =====================================================

final class GameState: ObservableObject {
    @Published var score: Int = 0
    @Published var bestScore: Int = 0
    @Published var speed: Float = 0
    @Published var activePowerUp: PowerUpType? = nil
    @Published var powerUpTimeRemaining: Double = 0
    @Published var lap: Int = 0
    @Published var totalLaps: Int = 3
    @Published var lapTime: Double = 0
    @Published var bestLapTime: Double = 0
    @Published var lastLapTime: Double = 0
    @Published var isFinished: Bool = false
    
    @Published var leftHeld: Bool = false
    @Published var rightHeld: Bool = false
    @Published var gasHeld: Bool = false
    @Published var brakeHeld: Bool = false
    @Published var driftHeld: Bool = false
    
    @Published var isPaused: Bool = false
    
    var car: CarConfig = CarConfig.all[0]
    var tread: TreadConfig = TreadConfig.all[0]
    
    var steerInput: Float {
        var s: Float = 0
        if leftHeld { s -= 1 }
        if rightHeld { s += 1 }
        return s
    }
    var throttleInput: Float {
        var t: Float = 0
        if gasHeld { t += 1 }
        if brakeHeld { t -= 1 }
        return t
    }
}

// =====================================================
// MARK: - GAME WORLD (SceneKit)
// =====================================================

final class GameWorld: NSObject, SCNSceneRendererDelegate {
    let scene = SCNScene()
    let cameraNode = SCNNode()
    let carNode = SCNNode()
    
    private weak var state: GameState?
    private let car: CarConfig
    private let tread: TreadConfig
    
    private var coins: [SCNNode] = []
    private var powerUps: [(node: SCNNode, type: PowerUpType)] = []
    
    private var velocity: Float = 0
    private var lastTime: TimeInterval = 0
    private var shieldNode: SCNNode? = nil
    private var smokeEmitters: [SCNNode] = []
    
    private var localScore: Int = 0
    private var localPU: PowerUpType? = nil
    private var localPUTime: Double = 0
    
    private var publishedScore: Int = -1
    private var publishedSpeed: Float = -1
    private var publishedPU: PowerUpType? = nil
    private var publishedPUTime: Double = -1
    private var publishedLap: Int = -1
    private var publishedLapTime: Double = -1
    
    private var coinRespawn: [(time: TimeInterval, pos: SCNVector3)] = []
    private var puRespawn: [(time: TimeInterval, type: PowerUpType, pos: SCNVector3)] = []
    
    private let trackCenterRadius: Float = 55
    private let trackWidth: Float = 14
    private var lapStartTime: TimeInterval = 0
    private var lastAngle: Float = 0
    private var crossedHalf: Bool = false
    private var lapsDone: Int = 0
    
    init(state: GameState) {
        self.state = state
        self.car = state.car
        self.tread = state.tread
        super.init()
        build()
    }
    
    private func build() {
        scene.background.contents = UIColor(red: 0.55, green: 0.78, blue: 1.0, alpha: 1)
        scene.fogColor = UIColor(red: 0.75, green: 0.86, blue: 1.0, alpha: 1)
        scene.fogStartDistance = 80
        scene.fogEndDistance = 200
        
        addLights()
        addGround()
        addTrack()
        addTerrain()
        addStructures()
        addCar()
        addCoinsAlongTrack(count: 40)
        addPowerUpsAlongTrack(count: 6)
        addCamera()
        
        carNode.position = trackPoint(angle: -.pi/2)
        carNode.eulerAngles.y = 0
    }
    
    private func addLights() {
        let amb = SCNNode()
        amb.light = SCNLight()
        amb.light?.type = .ambient
        amb.light?.color = UIColor(white: 0.55, alpha: 1)
        amb.light?.intensity = 400
        scene.rootNode.addChildNode(amb)
        
        let sun = SCNNode()
        sun.light = SCNLight()
        sun.light?.type = .directional
        sun.light?.color = UIColor.white
        sun.light?.intensity = 1200
        sun.light?.castsShadow = true
        sun.light?.shadowSampleCount = 8
        sun.light?.shadowRadius = 3
        sun.light?.shadowColor = UIColor.black.withAlphaComponent(0.45)
        sun.light?.shadowMapSize = CGSize(width: 1024, height: 1024)
        sun.eulerAngles = SCNVector3(-Float.pi * 0.4, Float.pi * 0.25, 0)
        scene.rootNode.addChildNode(sun)
    }
    
    private func addGround() {
        let floor = SCNFloor()
        floor.reflectivity = 0
        let m = SCNMaterial()
        m.diffuse.contents = UIColor(red: 0.42, green: 0.62, blue: 0.32, alpha: 1)
        m.roughness.contents = 0.9
        floor.firstMaterial = m
        scene.rootNode.addChildNode(SCNNode(geometry: floor))
    }
    
    private func trackPoint(angle: Float) -> SCNVector3 {
        SCNVector3(cos(angle) * trackCenterRadius, 0.05,
                   sin(angle) * trackCenterRadius)
    }
    
    private func addTrack() {
        let segments = 96
        for i in 0..<segments {
            let a = Float(i) / Float(segments) * Float.pi * 2
            let p = trackPoint(angle: a)
            
            let seg = SCNBox(width: CGFloat(trackWidth), height: 0.1,
                             length: CGFloat(2 * .pi * trackCenterRadius / Float(segments)) + 0.5,
                             chamferRadius: 0)
            let m = SCNMaterial()
            m.diffuse.contents = UIColor(white: 0.18, alpha: 1)
            m.roughness.contents = 0.85
            seg.firstMaterial = m
            let n = SCNNode(geometry: seg)
            n.position = p
            n.eulerAngles.y = -a + .pi/2
            scene.rootNode.addChildNode(n)
            
            if i % 2 == 0 {
                let stripe = SCNBox(width: 0.3, height: 0.12, length: 1.6, chamferRadius: 0)
                let sm = SCNMaterial()
                sm.diffuse.contents = UIColor.white
                sm.emission.contents = UIColor(white: 0.3, alpha: 1)
                stripe.firstMaterial = sm
                let sN = SCNNode(geometry: stripe)
                sN.position = SCNVector3(p.x, 0.11, p.z)
                sN.eulerAngles.y = -a + .pi/2
                scene.rootNode.addChildNode(sN)
            }
        }
        
        let startAngle: Float = -.pi/2
        let sp = trackPoint(angle: startAngle)
        let lineCount = 8
        for i in 0..<lineCount {
            let isWhite = i % 2 == 0
            let block = SCNBox(width: CGFloat(trackWidth) / CGFloat(lineCount),
                               height: 0.13, length: 1.0, chamferRadius: 0)
            let bm = SCNMaterial()
            bm.diffuse.contents = isWhite ? UIColor.white : UIColor.black
            block.firstMaterial = bm
            let bN = SCNNode(geometry: block)
            let off = (Float(i) - Float(lineCount-1)/2) * (trackWidth / Float(lineCount))
            bN.position = SCNVector3(sp.x + off, 0.13, sp.z)
            scene.rootNode.addChildNode(bN)
        }
        
        for sx in [-trackWidth/2 - 1, trackWidth/2 + 1] {
            let pillar = SCNBox(width: 0.6, height: 6, length: 0.6, chamferRadius: 0.1)
            let pm = SCNMaterial()
            pm.diffuse.contents = UIColor(red: 0.95, green: 0.4, blue: 0.4, alpha: 1)
            pillar.firstMaterial = pm
            let pN = SCNNode(geometry: pillar)
            pN.position = SCNVector3(sp.x + sx, 3, sp.z)
            pN.castsShadow = true
            scene.rootNode.addChildNode(pN)
        }
        let banner = SCNBox(width: CGFloat(trackWidth) + 3, height: 1.2,
                            length: 0.4, chamferRadius: 0.1)
        let bnm = SCNMaterial()
        bnm.diffuse.contents = UIColor(red: 0.95, green: 0.4, blue: 0.4, alpha: 1)
        banner.firstMaterial = bnm
        let bnN = SCNNode(geometry: banner)
        bnN.position = SCNVector3(sp.x, 6.2, sp.z)
        bnN.castsShadow = true
        scene.rootNode.addChildNode(bnN)
        
        let coneCount = 60
        for i in 0..<coneCount {
            let a = Float(i) / Float(coneCount) * Float.pi * 2
            for radius in [trackCenterRadius - trackWidth/2 - 0.5,
                           trackCenterRadius + trackWidth/2 + 0.5] {
                let cone = SCNCone(topRadius: 0.08, bottomRadius: 0.32, height: 0.7)
                let cm = SCNMaterial()
                cm.diffuse.contents = UIColor(red: 0.95, green: 0.55, blue: 0.10, alpha: 1)
                cm.emission.contents = UIColor(red: 0.45, green: 0.20, blue: 0, alpha: 1)
                cone.firstMaterial = cm
                let cN = SCNNode(geometry: cone)
                cN.position = SCNVector3(cos(a) * radius, 0.35, sin(a) * radius)
                scene.rootNode.addChildNode(cN)
            }
        }
    }
    
    private func addTerrain() {
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<14 {
            let pos = randomOffTrackPosition(rng: &rng, minDist: 20)
            let hillRadius = Float.random(in: 6...12, using: &rng)
            let hillTop = Float.random(in: 1.5...3.5, using: &rng)
            let s = SCNSphere(radius: CGFloat(hillRadius))
            s.segmentCount = 16
            let m = SCNMaterial()
            let g = CGFloat.random(in: 0.50...0.68, using: &rng)
            m.diffuse.contents = UIColor(red: 0.36, green: g, blue: 0.30, alpha: 1)
            s.firstMaterial = m
            let n = SCNNode(geometry: s)
            n.scale = SCNVector3(1, hillTop / hillRadius, 1)
            n.castsShadow = true
            n.position = SCNVector3(pos.x, 0, pos.z)
            scene.rootNode.addChildNode(n)
        }
    }
    
    private func addStructures() {
        var rng = SystemRandomNumberGenerator()
        let palette: [UIColor] = [
            UIColor(red: 0.86, green: 0.40, blue: 0.40, alpha: 1),
            UIColor(red: 0.45, green: 0.55, blue: 0.85, alpha: 1),
            UIColor(red: 0.95, green: 0.85, blue: 0.45, alpha: 1),
            UIColor(red: 0.65, green: 0.40, blue: 0.75, alpha: 1),
            UIColor(red: 0.35, green: 0.70, blue: 0.60, alpha: 1)
        ]
        
        for _ in 0..<22 {
            let pos = randomOffTrackPosition(rng: &rng, minDist: 18)
            let w = CGFloat.random(in: 4...8, using: &rng)
            let l = CGFloat.random(in: 4...8, using: &rng)
            let h = CGFloat.random(in: 6...18, using: &rng)
            let box = SCNBox(width: w, height: h, length: l, chamferRadius: 0.2)
            let m = SCNMaterial()
            m.diffuse.contents = palette.randomElement(using: &rng)!
            m.roughness.contents = 0.7
            box.firstMaterial = m
            let n = SCNNode(geometry: box)
            n.position = SCNVector3(pos.x, Float(h)/2, pos.z)
            n.castsShadow = true
            scene.rootNode.addChildNode(n)
        }
        
        for _ in 0..<35 {
            let pos = randomOffTrackPosition(rng: &rng, minDist: 12)
            let trunkH = Float.random(in: 1.8...3.2, using: &rng)
            let trunk = SCNCylinder(radius: 0.35, height: CGFloat(trunkH))
            let tm = SCNMaterial()
            tm.diffuse.contents = UIColor(red: 0.42, green: 0.27, blue: 0.16, alpha: 1)
            trunk.firstMaterial = tm
            let trunkN = SCNNode(geometry: trunk)
            trunkN.position.y = trunkH / 2
            
            let leavesH = Float.random(in: 3.0...5.0, using: &rng)
            let leavesR = Float.random(in: 1.3...2.1, using: &rng)
            let cone = SCNCone(topRadius: 0, bottomRadius: CGFloat(leavesR),
                               height: CGFloat(leavesH))
            let lm = SCNMaterial()
            let g = CGFloat.random(in: 0.45...0.62, using: &rng)
            lm.diffuse.contents = UIColor(red: 0.18, green: g, blue: 0.22, alpha: 1)
            cone.firstMaterial = lm
            let coneN = SCNNode(geometry: cone)
            coneN.position.y = trunkH + leavesH / 2 - 0.4
            
            let tree = SCNNode()
            tree.addChildNode(trunkN)
            tree.addChildNode(coneN)
            tree.castsShadow = true
            tree.position = SCNVector3(pos.x, 0, pos.z)
            scene.rootNode.addChildNode(tree)
        }
        
        let lampCount = 16
        for i in 0..<lampCount {
            let a = Float(i) / Float(lampCount) * Float.pi * 2
            let r = trackCenterRadius + trackWidth/2 + 2.5
            let h: Float = 6
            let post = SCNCylinder(radius: 0.18, height: CGFloat(h))
            let pm = SCNMaterial()
            pm.diffuse.contents = UIColor(white: 0.82, alpha: 1)
            post.firstMaterial = pm
            let postN = SCNNode(geometry: post)
            postN.position.y = h / 2
            
            let head = SCNSphere(radius: 0.4)
            let hm = SCNMaterial()
            hm.diffuse.contents = UIColor(red: 1, green: 0.95, blue: 0.7, alpha: 1)
            hm.emission.contents = UIColor(red: 1, green: 0.85, blue: 0.5, alpha: 1)
            head.firstMaterial = hm
            let headN = SCNNode(geometry: head)
            headN.position.y = h + 0.3
            
            let lamp = SCNNode()
            lamp.addChildNode(postN)
            lamp.addChildNode(headN)
            lamp.castsShadow = true
            lamp.position = SCNVector3(cos(a) * r, 0, sin(a) * r)
            scene.rootNode.addChildNode(lamp)
        }
    }
    
    private func addCar() {
        let body = SCNBox(width: 2, height: 0.7, length: 4, chamferRadius: 0.25)
        let bm = SCNMaterial()
        bm.diffuse.contents = car.body
        bm.metalness.contents = 0.5
        bm.roughness.contents = 0.25
        body.firstMaterial = bm
        let bodyN = SCNNode(geometry: body)
        bodyN.position.y = 0.7
        carNode.addChildNode(bodyN)
        
        let cab = SCNBox(width: 1.7, height: 0.7, length: 2, chamferRadius: 0.2)
        let cm = SCNMaterial()
        cm.diffuse.contents = car.cabin
        cm.metalness.contents = 0.7
        cm.roughness.contents = 0.08
        cab.firstMaterial = cm
        let cabN = SCNNode(geometry: cab)
        cabN.position = SCNVector3(0, 1.4, 0)
        carNode.addChildNode(cabN)
        
        let wheels: [(Float, Float)] = [(-1, 1.4), (1, 1.4), (-1, -1.4), (1, -1.4)]
        for (xs, zs) in wheels {
            let wheel = SCNCylinder(radius: tread.radius, height: tread.width)
            let wm = SCNMaterial()
            wm.diffuse.contents = tread.color
            wheel.firstMaterial = wm
            let n = SCNNode(geometry: wheel)
            n.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
            n.position = SCNVector3(xs * 1.05, Float(tread.radius), zs)
            carNode.addChildNode(n)
        }
        
        for x in [Float(-0.6), Float(0.6)] {
            let l = SCNSphere(radius: 0.18)
            let lm = SCNMaterial()
            lm.diffuse.contents = UIColor.white
            lm.emission.contents = UIColor(red: 1, green: 1, blue: 0.85, alpha: 1)
            l.firstMaterial = lm
            let n = SCNNode(geometry: l)
            n.position = SCNVector3(x, 0.7, -1.95)
            carNode.addChildNode(n)
        }
        
        for x in [Float(-0.6), Float(0.6)] {
            let l = SCNBox(width: 0.4, height: 0.15, length: 0.1, chamferRadius: 0.02)
            let lm = SCNMaterial()
            lm.diffuse.contents = UIColor(red: 0.6, green: 0.1, blue: 0.1, alpha: 1)
            lm.emission.contents = UIColor(red: 1, green: 0.2, blue: 0.15, alpha: 1)
            l.firstMaterial = lm
            let n = SCNNode(geometry: l)
            n.position = SCNVector3(x, 0.85, 1.95)
            carNode.addChildNode(n)
        }
        
        for x in [Float(-1.05), Float(1.05)] {
            let emitter = SCNNode()
            emitter.position = SCNVector3(x, 0.3, 1.4)
            carNode.addChildNode(emitter)
            smokeEmitters.append(emitter)
        }
        
        carNode.position = SCNVector3(0, 0.5, 0)
        scene.rootNode.addChildNode(carNode)
    }
    
    private func addCoinsAlongTrack(count: Int) {
        var rng = SystemRandomNumberGenerator()
        for i in 0..<count {
            let a = Float(i) / Float(count) * Float.pi * 2
            let lateral = Float.random(in: -trackWidth/2 + 1.5 ... trackWidth/2 - 1.5,
                                       using: &rng)
            let r = trackCenterRadius + lateral
            let pos = SCNVector3(cos(a) * r, 1.0, sin(a) * r)
            let n = makeCoin()
            n.position = pos
            scene.rootNode.addChildNode(n)
            coins.append(n)
        }
    }
    
    private func addPowerUpsAlongTrack(count: Int) {
        var rng = SystemRandomNumberGenerator()
        for i in 0..<count {
            let a = Float(i) / Float(count) * Float.pi * 2 + 0.1
            let lateral = Float.random(in: -trackWidth/2 + 2 ... trackWidth/2 - 2,
                                       using: &rng)
            let r = trackCenterRadius + lateral
            let pos = SCNVector3(cos(a) * r, 1.5, sin(a) * r)
            let type = PowerUpType.allCases.randomElement(using: &rng)!
            let n = makePowerUp(type)
            n.position = pos
            scene.rootNode.addChildNode(n)
            powerUps.append((n, type))
        }
    }
    
    private func makeCoin() -> SCNNode {
        let geo = SCNCylinder(radius: 0.55, height: 0.14)
        let m = SCNMaterial()
        m.diffuse.contents = UIColor(red: 1.0, green: 0.85, blue: 0.18, alpha: 1)
        m.metalness.contents = 0.85
        m.roughness.contents = 0.18
        m.emission.contents = UIColor(red: 0.55, green: 0.40, blue: 0.05, alpha: 1)
        geo.firstMaterial = m
        let coin = SCNNode(geometry: geo)
        coin.eulerAngles.z = Float.pi / 2
        let spinner = SCNNode()
        spinner.addChildNode(coin)
        spinner.runAction(SCNAction.repeatForever(
            SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 1.6)
        ))
        return spinner
    }
    
    private func makePowerUp(_ type: PowerUpType) -> SCNNode {
        let geo = SCNBox(width: 1.2, height: 1.2, length: 1.2, chamferRadius: 0.18)
        let m = SCNMaterial()
        m.diffuse.contents = type.uiColor
        m.emission.contents = type.uiColor.withAlphaComponent(0.65)
        m.metalness.contents = 0.6
        m.roughness.contents = 0.2
        geo.firstMaterial = m
        let cube = SCNNode(geometry: geo)
        cube.runAction(SCNAction.repeatForever(
            SCNAction.rotateBy(x: 0.5, y: CGFloat.pi * 2, z: 0.3, duration: 3)
        ))
        let container = SCNNode()
        container.addChildNode(cube)
        return container
    }
    
    private func addCamera() {
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zNear = 0.2
        cameraNode.camera?.zFar = 350
        cameraNode.camera?.fieldOfView = 65
        cameraNode.camera?.bloomIntensity = 0.4
        cameraNode.camera?.bloomThreshold = 0.85
        cameraNode.camera?.wantsHDR = true
        cameraNode.position = SCNVector3(0, 5.5, 11)
        cameraNode.look(at: SCNVector3(0, 1.4, -2),
                        up: SCNVector3(0, 1, 0),
                        localFront: SCNVector3(0, 0, -1))
        scene.rootNode.addChildNode(cameraNode)
    }
    
    private func randomOffTrackPosition(rng: inout SystemRandomNumberGenerator,
                                        minDist: Float) -> SCNVector3 {
        for _ in 0..<30 {
            let x = Float.random(in: -90...90, using: &rng)
            let z = Float.random(in: -90...90, using: &rng)
            let r = sqrt(x*x + z*z)
            if abs(r - trackCenterRadius) > trackWidth/2 + 4 && r > 8 && r < 90 {
                return SCNVector3(x, 0, z)
            }
        }
        return SCNVector3(60, 0, 60)
    }
    
    private func addShield() {
        removeShield()
        let s = SCNSphere(radius: 2.4)
        let m = SCNMaterial()
        m.diffuse.contents = UIColor.clear
        m.emission.contents = UIColor(red: 0.35, green: 0.75, blue: 1.0, alpha: 1)
        m.transparency = 0.45
        m.cullMode = .front
        s.firstMaterial = m
        let n = SCNNode(geometry: s)
        n.position = SCNVector3(0, 1.0, 0)
        carNode.addChildNode(n)
        n.runAction(SCNAction.repeatForever(
            SCNAction.rotateBy(x: 0.2, y: 1, z: 0.3, duration: 4)
        ))
        shieldNode = n
    }
    
    private func removeShield() {
        shieldNode?.removeFromParentNode()
        shieldNode = nil
    }
    
    private func isDescendantOfCar(_ node: SCNNode) -> Bool {
        var n: SCNNode? = node
        while let nn = n {
            if nn === carNode { return true }
            n = nn.parent
        }
        return false
    }
    
    private func spawnSmokePuff(at worldPos: SCNVector3) {
        let puff = SCNSphere(radius: 0.35)
        let m = SCNMaterial()
        m.diffuse.contents = UIColor.white
        m.emission.contents = UIColor(white: 0.9, alpha: 1)
        m.transparency = 0.7
        puff.firstMaterial = m
        let n = SCNNode(geometry: puff)
        n.position = worldPos
        scene.rootNode.addChildNode(n)
        let fade = SCNAction.group([
            SCNAction.fadeOut(duration: 0.7),
            SCNAction.scale(by: 2.2, duration: 0.7),
            SCNAction.move(by: SCNVector3(0, 0.6, 0), duration: 0.7)
        ])
        n.runAction(SCNAction.sequence([fade, SCNAction.removeFromParentNode()]))
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let state = state else { return }
        
        let dt: Float
        if lastTime == 0 {
            dt = Float(1.0 / 60.0)
            lapStartTime = time
        } else {
            dt = min(Float(time - lastTime), Float(0.1))
        }
        lastTime = time
        
        if state.isPaused || state.isFinished { return }
        
        let steer = state.steerInput
        let throttle = state.throttleInput
        let isDrift = state.driftHeld
        
        let isBoost = (localPU == .speed)
        let baseFwd = car.topSpeed
        let baseAccel = car.acceleration
        let maxFwd: Float = isBoost ? baseFwd * 1.7 : baseFwd
        let maxRev: Float = baseFwd * 0.5
        let accel: Float = isBoost ? baseAccel * 1.5 : baseAccel
        
        if throttle > 0 {
            velocity = min(velocity + throttle * accel * dt, maxFwd)
        } else if throttle < 0 {
            velocity = max(velocity + throttle * accel * dt, -maxRev)
        } else {
            let drag: Float = isDrift ? 3.5 : 7
            if velocity > 0 { velocity = max(velocity - drag * dt, 0) }
            else if velocity < 0 { velocity = min(velocity + drag * dt, 0) }
        }
        
        let speedAbs = abs(velocity)
        if speedAbs > 0.5 {
            let speedFactor = speedAbs / max(maxFwd, 0.001)
            let driftMul: Float = isDrift ? 1.7 : 1.0
            let yaw = steer * car.handling * tread.gripBonus *
            (0.25 + 0.75 * speedFactor) * driftMul
            let sign: Float = velocity >= 0 ? 1 : -1
            carNode.eulerAngles.y -= yaw * sign * dt
        }
        
        let heading = carNode.eulerAngles.y
        var newPos = carNode.position
        newPos.x += -sin(heading) * velocity * dt
        newPos.z += -cos(heading) * velocity * dt
        
        let r = sqrt(newPos.x * newPos.x + newPos.z * newPos.z)
        if r > 95 {
            let s = 95 / r
            newPos.x *= s
            newPos.z *= s
            velocity *= 0.4
        }
        
        let from = SCNVector3(newPos.x, newPos.y + 12, newPos.z)
        let to = SCNVector3(newPos.x, newPos.y - 12, newPos.z)
        let hits = scene.rootNode.hitTestWithSegment(from: from, to: to, options: nil)
        var groundY: Float = 0
        for hit in hits {
            if isDescendantOfCar(hit.node) { continue }
            if hit.worldCoordinates.y > newPos.y + 4 { continue }
            groundY = hit.worldCoordinates.y
            break
        }
        let targetY = groundY + Float(tread.radius) + 0.08
        newPos.y += (targetY - newPos.y) * min(Float(1), 8 * dt)
        carNode.position = newPos
        
        let camDist: Float = 11
        let camHeight: Float = 5.5
        let smoothing = min(Float(1), 5 * dt)
        let desiredCamPos = SCNVector3(
            newPos.x + sin(heading) * camDist,
            newPos.y + camHeight,
            newPos.z + cos(heading) * camDist
        )
        cameraNode.position = SCNVector3(
            cameraNode.position.x + (desiredCamPos.x - cameraNode.position.x) * smoothing,
            cameraNode.position.y + (desiredCamPos.y - cameraNode.position.y) * smoothing,
            cameraNode.position.z + (desiredCamPos.z - cameraNode.position.z) * smoothing
        )
        cameraNode.look(
            at: SCNVector3(newPos.x - sin(heading) * 2,
                           newPos.y + 1.4,
                           newPos.z - cos(heading) * 2),
            up: SCNVector3(0, 1, 0),
            localFront: SCNVector3(0, 0, -1)
        )
        
        if isDrift && speedAbs > 4 {
            for emitter in smokeEmitters where Float.random(in: 0...1) < 0.6 {
                let world = emitter.convertPosition(SCNVector3Zero, to: nil)
                spawnSmokePuff(at: world)
            }
        }
        
        let magnetRange: Float = (localPU == .magnet) ? 14 : 0
        let pickupRange: Float = 1.8
        for coin in coins where coin.parent != nil {
            let dx = coin.position.x - newPos.x
            let dz = coin.position.z - newPos.z
            let dist = sqrt(dx*dx + dz*dz)
            if magnetRange > 0 && dist < magnetRange && dist > 0.001 && dist > pickupRange {
                let pull: Float = 28
                coin.position.x -= (dx / dist) * pull * dt
                coin.position.z -= (dz / dist) * pull * dt
            }
            if dist < pickupRange {
                coin.removeFromParentNode()
                coinRespawn.append((time + 6, coin.position))
                localScore += 1
            }
        }
        coins.removeAll { $0.parent == nil }
        
        for entry in powerUps where entry.node.parent != nil {
            let dx = entry.node.position.x - newPos.x
            let dz = entry.node.position.z - newPos.z
            if sqrt(dx*dx + dz*dz) < 2.2 {
                entry.node.removeFromParentNode()
                puRespawn.append((time + 14,
                                  PowerUpType.allCases.randomElement()!,
                                  entry.node.position))
                localPU = entry.type
                localPUTime = entry.type.duration
                if entry.type == .shield { addShield() } else { removeShield() }
            }
        }
        powerUps.removeAll { $0.node.parent == nil }
        
        for entry in coinRespawn where entry.time <= time {
            let c = makeCoin(); c.position = entry.pos
            scene.rootNode.addChildNode(c)
            coins.append(c)
        }
        coinRespawn.removeAll { $0.time <= time }
        for entry in puRespawn where entry.time <= time {
            let n = makePowerUp(entry.type); n.position = entry.pos
            scene.rootNode.addChildNode(n)
            powerUps.append((n, entry.type))
        }
        puRespawn.removeAll { $0.time <= time }
        
        if localPU != nil {
            localPUTime -= Double(dt)
            if localPUTime <= 0 {
                if localPU == .shield { removeShield() }
                localPU = nil
                localPUTime = 0
            }
        }
        
        let angle = atan2(newPos.z, newPos.x)
        if !crossedHalf && abs(angle - .pi/2) < 0.5 { crossedHalf = true }
        let nearStart = abs(angle - (-.pi/2)) < 0.5
        if crossedHalf && nearStart && lastAngle > -.pi/2 - 0.5 && angle <= -.pi/2 + 0.1 {
            let lapDuration = time - lapStartTime
            lapStartTime = time
            crossedHalf = false
            lapsDone += 1
            DispatchQueue.main.async {
                state.lap = self.lapsDone
                state.lastLapTime = lapDuration
                if state.bestLapTime == 0 || lapDuration < state.bestLapTime {
                    state.bestLapTime = lapDuration
                }
                if self.lapsDone >= state.totalLaps {
                    state.isFinished = true
                    if state.score > state.bestScore { state.bestScore = state.score }
                }
            }
        }
        lastAngle = angle
        
        let liveLapTime = time - lapStartTime
        let speedRounded = Float(Int(speedAbs * 10)) / 10
        let timeRounded = Double(Int(localPUTime * 10)) / 10
        let lapTimeRounded = Double(Int(liveLapTime * 10)) / 10
        if localScore != publishedScore || speedRounded != publishedSpeed ||
            localPU != publishedPU || timeRounded != publishedPUTime ||
            lapsDone != publishedLap || lapTimeRounded != publishedLapTime {
            publishedScore = localScore
            publishedSpeed = speedRounded
            publishedPU = localPU
            publishedPUTime = timeRounded
            publishedLap = lapsDone
            publishedLapTime = lapTimeRounded
            
            let scoreCopy = localScore
            let speedCopy = speedAbs
            let puCopy = localPU
            let puTimeCopy = localPUTime
            let lapCopy = lapsDone
            let liveLapCopy = liveLapTime
            DispatchQueue.main.async {
                state.score = scoreCopy
                state.speed = speedCopy
                state.activePowerUp = puCopy
                state.powerUpTimeRemaining = max(0, puTimeCopy)
                state.lap = lapCopy
                state.lapTime = liveLapCopy
            }
        }
    }
}

// =====================================================
// MARK: - SCENEKIT BRIDGE
// =====================================================

struct GameSceneView: UIViewRepresentable {
    let state: GameState
    
    func makeUIView(context: Context) -> SCNView {
        let v = SCNView(frame: .zero, options: nil)
        let world = GameWorld(state: state)
        context.coordinator.world = world
        v.scene = world.scene
        v.pointOfView = world.cameraNode
        v.delegate = world
        v.isPlaying = true
        v.rendersContinuously = true
        v.antialiasingMode = .multisampling4X
        v.preferredFramesPerSecond = 60
        v.allowsCameraControl = false
        v.backgroundColor = .clear
        return v
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator { var world: GameWorld? }
}

// =====================================================
// MARK: - HELPERS
// =====================================================

func formatTime(_ t: Double) -> String {
    if t <= 0 { return "—:——.—" }
    let m = Int(t) / 60
    let s = t - Double(m * 60)
    return String(format: "%d:%05.2f", m, s)
}

// Reusable mini car illustration for menus
struct MiniCarIllustration: View {
    let bodyColor: Color
    let cabinColor: Color
    var width: CGFloat = 110
    var height: CGFloat = 60
    
    var bodyShape: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(bodyColor)
            .frame(width: width, height: height * 0.55)
    }
    
    var cabinShape: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(cabinColor)
            .frame(width: width * 0.55, height: height * 0.4)
            .offset(y: -height * 0.25)
    }
    
    var headlight: some View {
        Circle().fill(Color.yellow.opacity(0.9))
            .frame(width: 6, height: 6)
            .offset(x: width * 0.42, y: 0)
    }
    
    var wheels: some View {
        HStack(spacing: width * 0.45) {
            Circle().fill(Color.black).frame(width: 14, height: 14)
            Circle().fill(Color.black).frame(width: 14, height: 14)
        }
        .offset(y: height * 0.25)
    }
    
    var body: some View {
        ZStack {
            wheels
            bodyShape
            cabinShape
            headlight
        }
        .frame(width: width, height: height)
    }
}

// =====================================================
// MARK: - HUD COMPONENTS
// =====================================================

struct ScoreBadge: View {
    let score: Int
    
    private var coinIcon: some View {
        Circle().fill(LinearGradient(colors: [
            Color(red: 1, green: 0.92, blue: 0.4),
            Color(red: 0.95, green: 0.65, blue: 0.1)
        ], startPoint: .top, endPoint: .bottom))
        .frame(width: 22, height: 22)
    }
    
    private var scoreText: some View {
        Text("\(score)")
            .font(.system(size: 22, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .monospacedDigit()
    }
    
    var body: some View {
        HStack(spacing: 8) {
            coinIcon
            scoreText
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.18), lineWidth: 1))
    }
}

struct LapBadge: View {
    let lap: Int
    let total: Int
    let lapTime: Double
    let bestLap: Double
    
    private var lapLabel: some View {
        Text("LAP \(min(lap+1, total))/\(total)")
            .font(.system(size: 11, weight: .heavy))
            .kerning(1.5)
            .foregroundStyle(.white.opacity(0.7))
    }
    
    private var timeText: some View {
        Text(formatTime(lapTime))
            .font(.system(size: 18, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .monospacedDigit()
    }
    
    private var bestText: some View {
        Group {
            if bestLap > 0 {
                Text("Best \(formatTime(bestLap))")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color(red: 1, green: 0.85, blue: 0.3))
                    .monospacedDigit()
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            lapLabel
            timeText
            bestText
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.18), lineWidth: 1))
    }
}

struct SpeedBadge: View {
    let speed: Float
    var kmh: Int { Int(speed * 4.2) }
    
    private var speedNumber: some View {
        Text("\(kmh)")
            .font(.system(size: 18, weight: .heavy, design: .rounded))
            .foregroundColor(.white)
            .monospacedDigit()
    }
    
    private var speedLabel: some View {
        Text("KM/H")
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.white.opacity(0.6))
            .kerning(0.5)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "gauge.with.needle")
                .foregroundColor(.white)
                .font(.system(size: 18, weight: .semibold))
            VStack(alignment: .leading, spacing: -1) {
                speedNumber
                speedLabel
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.18), lineWidth: 1))
    }
}

struct PowerUpIndicator: View {
    let type: PowerUpType
    let timeRemaining: Double
    var fraction: Double { max(0, min(1, timeRemaining / type.duration)) }
    
    private var iconView: some View {
        Image(systemName: type.symbol)
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(type.tint)
            .frame(width: 30)
    }
    
    private var nameLabel: some View {
        Text(type.name.uppercased())
            .font(.system(size: 11, weight: .heavy))
            .kerning(1.5)
            .foregroundStyle(.white)
    }
    
    private var progressBar: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(Color.white.opacity(0.15))
                .frame(width: 90, height: 5)
            Capsule().fill(type.tint)
                .frame(width: 90 * fraction, height: 5)
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            iconView
            VStack(alignment: .leading, spacing: 5) {
                nameLabel
                progressBar
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(type.tint.opacity(0.55), lineWidth: 1.5))
    }
}

struct ControlButton: View {
    let symbol: String
    let tint: Color
    @Binding var isPressed: Bool
    
    private var iconView: some View {
        Image(systemName: symbol)
            .font(.system(size: 30, weight: .heavy))
            .foregroundStyle(.white)
    }
    
    private var background: some View {
        Circle()
            .fill(.ultraThinMaterial)
            .overlay(Circle().stroke(tint.opacity(0.6), lineWidth: 2))
    }
    
    var body: some View {
        iconView
            .frame(width: 72, height: 72)
            .background(background)
            .scaleEffect(isPressed ? 0.88 : 1)
            .opacity(isPressed ? 0.7 : 1)
            .shadow(color: tint.opacity(isPressed ? 0.6 : 0.2), radius: 10)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
            .contentShape(Circle())
            .onLongPressGesture(minimumDuration: 0,
                                maximumDistance: .infinity,
                                perform: {},
                                onPressingChanged: { isPressed = $0 })
    }
}

// =====================================================
// MARK: - SPLASH SCREEN
// =====================================================

enum AppScreen { case splash, carSelect, treadSelect, ready, playing, finished }

struct AnimatedRoadStripes: View {
    @State private var offset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<8) { i in
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 6, height: 30)
                        .offset(y: CGFloat(i) * 60 - offset)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                offset = 60
            }
        }
    }
}

struct SplashScreen: View {
    let onStart: () -> Void
    let bestScore: Int
    @State private var pulse = false
    
    private var bgGradient: some View {
        LinearGradient(colors: [
            Color(red: 0.05, green: 0.08, blue: 0.18),
            Color(red: 0.18, green: 0.08, blue: 0.30)
        ], startPoint: .top, endPoint: .bottom)
        .ignoresSafeArea()
    }
    
    private var carIcon: some View {
        Image(systemName: "car.side.fill")
            .font(.system(size: 80, weight: .heavy))
            .foregroundStyle(LinearGradient(
                colors: [Color(red: 1, green: 0.5, blue: 0.3),
                         Color(red: 1, green: 0.85, blue: 0.4)],
                startPoint: .leading, endPoint: .trailing))
            .shadow(color: .orange.opacity(0.6), radius: 20)
            .scaleEffect(pulse ? 1.05 : 1)
            .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true),
                       value: pulse)
    }
    
    private var titleStack: some View {
        VStack(spacing: 6) {
            Text("CRUISER 3D")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .kerning(3)
                .foregroundStyle(.white)
            Text("CIRCUIT EDITION")
                .font(.system(size: 13, weight: .heavy))
                .kerning(4)
                .foregroundStyle(.white.opacity(0.6))
        }
    }
    
    private var startButton: some View {
        Button(action: onStart) {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                    .font(.system(size: 18, weight: .heavy))
                Text("START").kerning(2)
                    .font(.system(size: 18, weight: .heavy))
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 50)
            .padding(.vertical, 18)
            .background(Capsule().fill(.white))
            .shadow(color: .white.opacity(0.4), radius: 16)
        }
    }
    
    private var bestScoreBadge: some View {
        Group {
            if bestScore > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(.yellow)
                    Text("Best: \(bestScore)")
                        .foregroundStyle(.white)
                }
                .font(.system(size: 13, weight: .bold))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Capsule().fill(.white.opacity(0.1)))
            }
        }
    }
    
    private var hintText: some View {
        Text("HOLD GAS · TAP TURN · DRIFT TO SLIDE")
            .font(.system(size: 10, weight: .bold))
            .kerning(2)
            .foregroundStyle(.white.opacity(0.4))
            .padding(.bottom, 30)
    }
    
    var body: some View {
        ZStack {
            bgGradient
            AnimatedRoadStripes()
                .opacity(0.8)
            
            VStack(spacing: 30) {
                Spacer()
                carIcon
                titleStack
                bestScoreBadge
                Spacer()
                startButton
                hintText
            }
            .padding()
        }
        .onAppear { pulse = true }
    }
}

// =====================================================
// MARK: - CAR SELECT
// =====================================================

struct CarSelectScreen: View {
    @Binding var selected: Int
    let bestScore: Int
    let onNext: () -> Void
    let onBack: () -> Void
    
    private var bg: some View {
        LinearGradient(colors: [
            Color(red: 0.05, green: 0.08, blue: 0.18),
            Color(red: 0.10, green: 0.18, blue: 0.30)
        ], startPoint: .top, endPoint: .bottom)
        .ignoresSafeArea()
    }
    
    private var topBar: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Circle().fill(.white.opacity(0.15)))
            }
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "trophy.fill").foregroundStyle(.yellow)
                Text("Best: \(bestScore)")
                    .foregroundStyle(.white)
            }
            .font(.system(size: 12, weight: .bold))
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(Capsule().fill(.white.opacity(0.1)))
        }
    }
    
    private var title: some View {
        VStack(spacing: 4) {
            Text("CHOOSE YOUR CAR")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .kerning(2)
                .foregroundStyle(.white)
            Text("Each car has different stats")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.6))
        }
    }
    
    private var carList: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(CarConfig.all) { car in
                    CarCard(car: car,
                            selected: selected == car.id,
                            locked: car.unlockScore > bestScore,
                            onTap: {
                        if car.unlockScore <= bestScore { selected = car.id }
                    })
                }
            }
        }
    }
    
    private var nextButton: some View {
        Button(action: onNext) {
            HStack(spacing: 10) {
                Text("NEXT").kerning(2)
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .heavy))
            }
            .font(.system(size: 17, weight: .heavy))
            .foregroundStyle(.black)
            .padding(.horizontal, 50)
            .padding(.vertical, 16)
            .background(Capsule().fill(.white))
        }
    }
    
    var body: some View {
        ZStack {
            bg
            VStack(spacing: 16) {
                topBar
                title
                carList
                nextButton
            }
            .padding(20)
        }
    }
}

struct CarCard: View {
    let car: CarConfig
    let selected: Bool
    let locked: Bool
    let onTap: () -> Void
    
    private var carPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(colors: [
                    Color.white.opacity(0.05),
                    Color.black.opacity(0.2)
                ], startPoint: .top, endPoint: .bottom))
                .frame(width: 130, height: 78)
            if locked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.6))
            } else {
                MiniCarIllustration(bodyColor: car.bodyColor, cabinColor: car.cabinColor)
            }
        }
    }
    
    private var nameLine: some View {
        Text(car.name.uppercased())
            .font(.system(size: 18, weight: .heavy))
            .kerning(1.5)
            .foregroundStyle(.white)
    }
    
    private var taglineOrLock: some View {
        Group {
            if locked {
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill").font(.system(size: 10))
                    Text("Score \(car.unlockScore) to unlock")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(.orange)
            } else {
                Text(car.tagline)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(2)
            }
        }
    }
    
    private var statsRow: some View {
        HStack(spacing: 8) {
            StatBar(label: "SPD", value: (car.topSpeed - 18) / 14)
            StatBar(label: "ACC", value: (car.acceleration - 18) / 12)
            StatBar(label: "HND", value: (2.1 - car.handling) / 0.6)
        }
    }
    
    private var infoStack: some View {
        VStack(alignment: .leading, spacing: 5) {
            nameLine
            taglineOrLock
            if !locked {
                statsRow.padding(.top, 2)
            }
        }
    }
    
    private var checkBadge: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 24))
            .foregroundStyle(.green)
    }
    
    private var cardBg: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(selected ? Color.white.opacity(0.18) : Color.white.opacity(0.08))
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(selected ? Color.white : Color.white.opacity(0.15),
                    lineWidth: selected ? 2 : 1)
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                carPreview
                infoStack
                Spacer()
                if selected { checkBadge }
            }
            .padding(12)
            .background(cardBg)
            .overlay(cardBorder)
            .opacity(locked ? 0.55 : 1)
        }
        .buttonStyle(.plain)
    }
}

struct StatBar: View {
    let label: String
    let value: Float
    var clamped: Float { max(0, min(1, value)) }
    
    private var labelText: some View {
        Text(label)
            .font(.system(size: 8, weight: .black))
            .foregroundStyle(.white.opacity(0.6))
            .kerning(0.5)
    }
    
    private var bar: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(Color.white.opacity(0.15))
                .frame(width: 50, height: 4)
            Capsule().fill(LinearGradient(colors: [.cyan, .blue],
                                          startPoint: .leading,
                                          endPoint: .trailing))
            .frame(width: CGFloat(50 * clamped), height: 4)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            labelText
            bar
        }
    }
}

// =====================================================
// MARK: - TREAD SELECT
// =====================================================

struct TreadSelectScreen: View {
    @Binding var selected: Int
    let onNext: () -> Void
    let onBack: () -> Void
    
    private var bg: some View {
        LinearGradient(colors: [
            Color(red: 0.05, green: 0.08, blue: 0.18),
            Color(red: 0.18, green: 0.10, blue: 0.18)
        ], startPoint: .top, endPoint: .bottom)
        .ignoresSafeArea()
    }
    
    private var topBar: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Circle().fill(.white.opacity(0.15)))
            }
            Spacer()
        }
    }
    
    private var title: some View {
        VStack(spacing: 4) {
            Text("CHOOSE YOUR TREADS")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .kerning(2)
                .foregroundStyle(.white)
            Text("Treads change grip and feel")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.6))
        }
    }
    
    private var treadList: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(TreadConfig.all) { tread in
                    TreadCard(tread: tread,
                              selected: selected == tread.id,
                              onTap: { selected = tread.id })
                }
            }
        }
    }
    
    private var readyButton: some View {
        Button(action: onNext) {
            HStack(spacing: 10) {
                Text("READY").kerning(2)
                Image(systemName: "flag.checkered")
                    .font(.system(size: 16, weight: .heavy))
            }
            .font(.system(size: 17, weight: .heavy))
            .foregroundStyle(.black)
            .padding(.horizontal, 50)
            .padding(.vertical, 16)
            .background(Capsule().fill(.white))
        }
    }
    
    var body: some View {
        ZStack {
            bg
            VStack(spacing: 16) {
                topBar
                title
                treadList
                readyButton
            }
            .padding(20)
        }
    }
}

struct TreadCard: View {
    let tread: TreadConfig
    let selected: Bool
    let onTap: () -> Void
    
    private var wheelIcon: some View {
        ZStack {
            Circle().fill(tread.swiftColor)
                .frame(width: 56, height: 56)
            Circle().stroke(Color.white.opacity(0.3), lineWidth: 2)
                .frame(width: 56, height: 56)
            Circle().fill(Color.white.opacity(0.15))
                .frame(width: 28, height: 28)
            Circle().fill(Color.white.opacity(0.25))
                .frame(width: 12, height: 12)
        }
    }
    
    private var nameText: some View {
        Text(tread.name.uppercased())
            .font(.system(size: 17, weight: .heavy))
            .kerning(1.5)
            .foregroundStyle(.white)
    }
    
    private var descText: some View {
        Text(tread.description)
            .font(.system(size: 12))
            .foregroundStyle(.white.opacity(0.7))
    }
    
    private var gripText: some View {
        let gripStr = String(format: "%.2fx", tread.gripBonus)
        return HStack(spacing: 4) {
            Image(systemName: "scope").font(.system(size: 9))
            Text("Grip \(gripStr)")
        }
        .font(.system(size: 10, weight: .bold))
        .foregroundStyle(.cyan)
    }
    
    private var infoStack: some View {
        VStack(alignment: .leading, spacing: 3) {
            nameText
            descText
            gripText
        }
    }
    
    private var checkmark: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 24))
            .foregroundStyle(.green)
    }
    
    private var cardBg: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(selected ? Color.white.opacity(0.18) : Color.white.opacity(0.08))
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(selected ? Color.white : Color.white.opacity(0.15),
                    lineWidth: selected ? 2 : 1)
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                wheelIcon
                infoStack
                Spacer()
                if selected { checkmark }
            }
            .padding(14)
            .background(cardBg)
            .overlay(cardBorder)
        }
        .buttonStyle(.plain)
    }
}

// =====================================================
// MARK: - READY (COUNTDOWN)
// =====================================================

struct ReadyScreen: View {
    let car: CarConfig
    let tread: TreadConfig
    let onGo: () -> Void
    let onBack: () -> Void
    @State private var count = 3
    @State private var timer: Timer?
    
    private var bg: some View {
        LinearGradient(colors: [Color.black, Color(red: 0.10, green: 0.05, blue: 0.20)],
                       startPoint: .top, endPoint: .bottom)
        .ignoresSafeArea()
    }
    
    private var backButton: some View {
        Button(action: {
            timer?.invalidate()
            onBack()
        }) {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(.white)
                .padding(12)
                .background(Circle().fill(.white.opacity(0.15)))
        }
    }
    
    private var carInfo: some View {
        VStack(spacing: 8) {
            MiniCarIllustration(bodyColor: car.bodyColor, cabinColor: car.cabinColor,
                                width: 140, height: 80)
            Text(car.name.uppercased())
                .font(.system(size: 28, weight: .black))
                .kerning(3)
                .foregroundStyle(.white)
            Text("on \(tread.name) treads")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white.opacity(0.6))
        }
    }
    
    private var countdownLabel: some View {
        Text(count > 0 ? "\(count)" : "GO!")
            .font(.system(size: 130, weight: .black, design: .rounded))
            .foregroundStyle(count > 0 ? Color(red: 1, green: 0.5, blue: 0.3) : .green)
            .shadow(color: count > 0 ? .orange : .green, radius: 30)
            .id(count)
            .transition(.scale.combined(with: .opacity))
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: count)
    }
    
    var body: some View {
        ZStack {
            bg
            VStack(spacing: 24) {
                HStack { backButton; Spacer() }
                Spacer()
                carInfo
                Spacer()
                countdownLabel
                Spacer()
            }
            .padding()
        }
        .onAppear {
            count = 3
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if count > 1 { count -= 1 }
                else if count == 1 {
                    count = 0
                } else {
                    timer?.invalidate()
                    onGo()
                }
            }
        }
        .onDisappear { timer?.invalidate() }
    }
}

// =====================================================
// MARK: - FINISH SCREEN
// =====================================================

struct FinishScreen: View {
    let score: Int
    let bestLap: Double
    let onRestart: () -> Void
    let onMenu: () -> Void
    
    private var medal: (name: String, color: Color, icon: String) {
        if score >= 30 {
            return ("GOLD", Color(red: 1, green: 0.85, blue: 0.3), "trophy.fill")
        } else if score >= 15 {
            return ("SILVER", Color(white: 0.8), "rosette")
        } else {
            return ("BRONZE", Color(red: 0.8, green: 0.5, blue: 0.3), "medal.fill")
        }
    }
    
    private var trophyIcon: some View {
        Image(systemName: medal.icon)
            .font(.system(size: 70))
            .foregroundStyle(medal.color)
            .shadow(color: medal.color, radius: 20)
    }
    
    private var medalLabel: some View {
        Text(medal.name)
            .font(.system(size: 14, weight: .black))
            .kerning(3)
            .foregroundStyle(medal.color)
    }
    
    private var titleText: some View {
        Text("RACE COMPLETE")
            .font(.system(size: 26, weight: .black))
            .kerning(3)
            .foregroundStyle(.white)
    }
    
    private var statsCard: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Coins").foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text("\(score)").foregroundStyle(.white).monospacedDigit()
            }
            HStack {
                Text("Best lap").foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text(formatTime(bestLap)).foregroundStyle(.white).monospacedDigit()
            }
        }
        .font(.system(size: 16, weight: .bold))
        .padding(20)
        .frame(maxWidth: 280)
        .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.1)))
    }
    
    private var menuButton: some View {
        Button(action: onMenu) {
            Text("MENU").kerning(2)
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(.white)
                .padding(.horizontal, 30).padding(.vertical, 14)
                .background(Capsule().fill(.white.opacity(0.15)))
        }
    }
    
    private var restartButton: some View {
        Button(action: onRestart) {
            Text("RACE AGAIN").kerning(2)
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(.black)
                .padding(.horizontal, 30).padding(.vertical, 14)
                .background(Capsule().fill(.white))
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            VStack(spacing: 18) {
                trophyIcon
                medalLabel
                titleText
                statsCard
                HStack(spacing: 14) {
                    menuButton
                    restartButton
                }
            }
            .padding()
        }
    }
}

// =====================================================
// MARK: - GAMEPLAY VIEW
// =====================================================

struct GameplayView: View {
    @ObservedObject var state: GameState
    let onPause: () -> Void
    
    private var topHUD: some View {
        HStack(alignment: .top) {
            ScoreBadge(score: state.score)
            Spacer()
            LapBadge(lap: state.lap, total: state.totalLaps,
                     lapTime: state.lapTime, bestLap: state.bestLapTime)
            Spacer()
            SpeedBadge(speed: state.speed)
        }
        .padding(.horizontal, 14)
        .padding(.top, 18)
    }
    
    private var powerUpRow: some View {
        Group {
            if let pu = state.activePowerUp {
                PowerUpIndicator(type: pu, timeRemaining: state.powerUpTimeRemaining)
                    .padding(.top, 10)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    private var pauseButton: some View {
        HStack {
            Spacer()
            Button(action: onPause) {
                Image(systemName: "pause.fill")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Circle().fill(.ultraThinMaterial))
                    .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
            }
        }
        .padding(.horizontal, 18)
    }
    
    private var leftControls: some View {
        VStack(spacing: 12) {
            ControlButton(symbol: "arrow.up", tint: .green,
                          isPressed: $state.gasHeld)
            ControlButton(symbol: "arrow.down", tint: .red,
                          isPressed: $state.brakeHeld)
        }
    }
    
    private var driftControl: some View {
        VStack(spacing: 6) {
            ControlButton(symbol: "tornado", tint: .orange,
                          isPressed: $state.driftHeld)
            Text("DRIFT")
                .font(.system(size: 9, weight: .black))
                .kerning(1.5)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.bottom, 4)
    }
    
    private var rightControls: some View {
        HStack(spacing: 14) {
            ControlButton(symbol: "arrow.left", tint: .cyan,
                          isPressed: $state.leftHeld)
            ControlButton(symbol: "arrow.right", tint: .cyan,
                          isPressed: $state.rightHeld)
        }
    }
    
    private var bottomControls: some View {
        HStack(alignment: .bottom) {
            leftControls
            Spacer()
            driftControl
            Spacer()
            rightControls
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 26)
    }
    
    var body: some View {
        ZStack {
            GameSceneView(state: state).ignoresSafeArea()
            VStack(spacing: 0) {
                topHUD
                powerUpRow
                Spacer()
                pauseButton
                Spacer()
                bottomControls
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7),
                       value: state.activePowerUp)
        }
        .preferredColorScheme(.dark)
    }
}

// =====================================================
// MARK: - PAUSE OVERLAY
// =====================================================

struct PauseOverlay: View {
    let onResume: () -> Void
    let onMenu: () -> Void
    
    private var titleText: some View {
        Text("PAUSED")
            .font(.system(size: 28, weight: .black))
            .kerning(4)
            .foregroundStyle(.white)
    }
    
    private var resumeButton: some View {
        Button(action: onResume) {
            HStack {
                Image(systemName: "play.fill")
                Text("RESUME").kerning(2)
            }
            .font(.system(size: 16, weight: .heavy))
            .foregroundStyle(.black)
            .padding(.horizontal, 36).padding(.vertical, 14)
            .background(Capsule().fill(.white))
        }
    }
    
    private var menuButton: some View {
        Button(action: onMenu) {
            HStack {
                Image(systemName: "house.fill")
                Text("MAIN MENU").kerning(2)
            }
            .font(.system(size: 14, weight: .heavy))
            .foregroundStyle(.white)
            .padding(.horizontal, 30).padding(.vertical, 12)
            .background(Capsule().fill(.white.opacity(0.15)))
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            VStack(spacing: 18) {
                titleText
                resumeButton
                menuButton
            }
        }
    }
}

// =====================================================
// MARK: - ROOT VIEW
// =====================================================

struct ContentView: View {
    @StateObject private var state = GameState()
    @State private var screen: AppScreen = .splash
    @State private var carIndex = 0
    @State private var treadIndex = 0
    @State private var sessionId = 0
    
    @ViewBuilder
    private func screenView() -> some View {
        switch screen {
        case .splash:
            SplashScreen(onStart: { screen = .carSelect },
                         bestScore: state.bestScore)
        case .carSelect:
            CarSelectScreen(selected: $carIndex,
                            bestScore: state.bestScore,
                            onNext: { screen = .treadSelect },
                            onBack: { screen = .splash })
        case .treadSelect:
            TreadSelectScreen(selected: $treadIndex,
                              onNext: { startReady() },
                              onBack: { screen = .carSelect })
        case .ready:
            ReadyScreen(car: CarConfig.all[carIndex],
                        tread: TreadConfig.all[treadIndex],
                        onGo: { screen = .playing },
                        onBack: { screen = .treadSelect })
        case .playing:
            ZStack {
                GameplayView(state: state, onPause: { state.isPaused = true })
                    .id(sessionId)
                if state.isPaused {
                    PauseOverlay(onResume: { state.isPaused = false },
                                 onMenu: {
                        state.isPaused = false
                        screen = .splash
                    })
                }
                if state.isFinished {
                    FinishScreen(score: state.score,
                                 bestLap: state.bestLapTime,
                                 onRestart: { startReady() },
                                 onMenu: { screen = .splash })
                }
            }
        case .finished:
            FinishScreen(score: state.score,
                         bestLap: state.bestLapTime,
                         onRestart: { startReady() },
                         onMenu: { screen = .splash })
        }
    }
    
    var body: some View {
        screenView()
            .animation(.easeInOut(duration: 0.25), value: screen)
    }
    
    private func startReady() {
        state.score = 0
        state.speed = 0
        state.activePowerUp = nil
        state.powerUpTimeRemaining = 0
        state.lap = 0
        state.lapTime = 0
        state.bestLapTime = 0
        state.lastLapTime = 0
        state.isFinished = false
        state.isPaused = false
        state.leftHeld = false
        state.rightHeld = false
        state.gasHeld = false
        state.brakeHeld = false
        state.driftHeld = false
        state.car = CarConfig.all[carIndex]
        state.tread = TreadConfig.all[treadIndex]
        sessionId += 1
        screen = .ready
    }
}
