import SwiftUI
import SceneKit

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

    private var pausedAt: TimeInterval? = nil

    private let camDist: Float = 11
    private let camHeight: Float = 5.5

    private let spawnAngle: Float = -.pi / 2
    private let spawnHeading: Float = -.pi / 2

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

        carNode.position = trackPoint(angle: spawnAngle)
        carNode.eulerAngles.y = spawnHeading

        positionCameraBehindCar()
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
            m.diffuse.contents = palette.randomElement(using: &rng) ?? UIColor.white
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
            let type = PowerUpType.allCases.randomElement(using: &rng) ?? .speed
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
        scene.rootNode.addChildNode(cameraNode)
    }

    private func positionCameraBehindCar() {
        let pos = carNode.position
        let h = carNode.eulerAngles.y
        cameraNode.position = SCNVector3(
            pos.x + sin(h) * camDist,
            pos.y + camHeight,
            pos.z + cos(h) * camDist
        )
        cameraNode.look(
            at: SCNVector3(pos.x - sin(h) * 2, pos.y + 1.4, pos.z - cos(h) * 2),
            up: SCNVector3(0, 1, 0),
            localFront: SCNVector3(0, 0, -1)
        )
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

        if state.isPaused || state.isFinished {
            if state.isPaused && pausedAt == nil { pausedAt = time }
            return
        }
        if let pStart = pausedAt {
            lapStartTime += time - pStart
            pausedAt = nil
        }

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
                let nextType = PowerUpType.allCases.randomElement() ?? .speed
                puRespawn.append((time + 14, nextType, entry.node.position))
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
