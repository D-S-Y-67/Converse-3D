import SwiftUI
import SceneKit
import simd

final class GameWorld: NSObject, SCNSceneRendererDelegate {
    let scene = SCNScene()
    let cameraNode = SCNNode()
    let carNode = SCNNode()

    private weak var state: GameState?
    private let car: CarConfig
    private let tread: TreadConfig
    private let layout: TrackLayout

    private var bots: [BotCar] = []
    private var rearWingFlap: SCNNode?
    private var smokeEmitters: [SCNNode] = []

    private var velocity: Float = 0
    private var lastTime: TimeInterval = 0
    private var pausedAt: TimeInterval? = nil
    private var raceStartTime: TimeInterval = 0
    private var lastLapStart: TimeInterval = 0
    private var lastProgress: Float = 0
    private var playerLapsDone: Int = 0
    private var hasFinished: Bool = false
    private var finishWallTime: TimeInterval = 0
    private var bestLap: Double = 0

    private var drsActive: Bool = false
    private var drsCooldown: Double = 0
    private var drsTimeRemaining: Double = 0
    private var countdownTime: Double = 3.0

    private var publishedSpeed: Float = -1
    private var publishedLap: Int = -1
    private var publishedLapTime: Double = -1
    private var publishedPosition: Int = -1
    private var publishedDRSAvail: Bool = false
    private var publishedDRSActive: Bool = false
    private var publishedCountdown: Int = -1
    private var publishedPhase: RacePhase = .grid

    private let camDist: Float = 13
    private let camHeight: Float = 6
    private let drsDuration: Double = 5.0
    private let drsCooldownTime: Double = 8.0

    init(state: GameState) {
        self.state = state
        self.car = state.car
        self.tread = state.tread
        self.layout = state.track
        super.init()
        build()
    }

    private func build() {
        configureScene()
        addLights()
        addGround()
        buildTrackGeometry()
        addEnvironmentDecor()
        addPlayerCar()
        spawnBotsOnGrid()
        addCamera()
        placeCameraBehindCar()
        beginCountdown()
    }

    private func configureScene() {
        scene.background.contents = UIColor(red: 0.55, green: 0.78, blue: 1.0, alpha: 1)
        scene.fogColor = UIColor(red: 0.75, green: 0.86, blue: 1.0, alpha: 1)
        scene.fogStartDistance = 90
        scene.fogEndDistance = 240
    }

    private func beginCountdown() {
        countdownTime = 3.0
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let state = self.state else { return }
            state.racePhase = .countdown
            state.countdownValue = 3
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let state = state else { return }

        let dt: Float
        if lastTime == 0 { dt = 1.0 / 60.0 } else {
            dt = min(Float(time - lastTime), 0.1)
        }
        lastTime = time

        if state.isPaused {
            if pausedAt == nil { pausedAt = time }
            return
        }
        if let p = pausedAt {
            let pauseDelta = time - p
            raceStartTime += pauseDelta
            lastLapStart += pauseDelta
            for b in bots { b.lastLapStart += pauseDelta }
            pausedAt = nil
        }

        switch state.racePhase {
        case .grid: break
        case .countdown:
            tickCountdown(dt: dt, time: time)
        case .racing:
            tickRacing(dt: dt, time: time)
            updateCamera(dt: dt)
        case .finished:
            tickFinishedCoast(dt: dt, time: time)
            updateCamera(dt: dt)
        }

        publishHUD(time: time)
    }

    private func tickCountdown(dt: Float, time: TimeInterval) {
        countdownTime -= Double(dt)
        let displayed = max(0, Int(ceil(countdownTime)))
        if displayed != publishedCountdown {
            publishedCountdown = displayed
            DispatchQueue.main.async { [weak self] in
                self?.state?.countdownValue = displayed
            }
        }
        if countdownTime <= 0 {
            raceStartTime = time
            lastLapStart = time
            for b in bots { b.lastLapStart = time }
            DispatchQueue.main.async { [weak self] in
                self?.state?.racePhase = .racing
            }
        }
    }

    private func addLights() {
        let amb = SCNNode()
        amb.light = SCNLight()
        amb.light?.type = .ambient
        amb.light?.color = UIColor(white: 0.55, alpha: 1)
        amb.light?.intensity = 420
        scene.rootNode.addChildNode(amb)

        let sun = SCNNode()
        sun.light = SCNLight()
        sun.light?.type = .directional
        sun.light?.color = UIColor.white
        sun.light?.intensity = 1300
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

    private func addEnvironmentDecor() {
        var rng = SystemRandomNumberGenerator()
        addHills(rng: &rng)
        addTrees(rng: &rng)
        addGrandstands()
    }

    private func addHills(rng: inout SystemRandomNumberGenerator) {
        for _ in 0..<14 {
            let pos = randomOffTrackPosition(rng: &rng, minDist: 22)
            let hillR = Float.random(in: 6...14, using: &rng)
            let hillTop = Float.random(in: 1.5...3.8, using: &rng)
            let s = SCNSphere(radius: CGFloat(hillR))
            s.segmentCount = 16
            let g = CGFloat.random(in: 0.50...0.68, using: &rng)
            s.firstMaterial = makeMaterial(
                UIColor(red: 0.36, green: g, blue: 0.30, alpha: 1),
                metalness: 0, roughness: 0.95)
            let n = SCNNode(geometry: s)
            n.scale = SCNVector3(1, hillTop / hillR, 1)
            n.castsShadow = true
            n.position = SCNVector3(pos.x, 0, pos.z)
            scene.rootNode.addChildNode(n)
        }
    }

    private func addTrees(rng: inout SystemRandomNumberGenerator) {
        for _ in 0..<48 {
            let pos = randomOffTrackPosition(rng: &rng, minDist: 14)
            let trunkH = Float.random(in: 1.8...3.2, using: &rng)
            let trunk = SCNCylinder(radius: 0.35, height: CGFloat(trunkH))
            trunk.firstMaterial = makeMaterial(
                UIColor(red: 0.42, green: 0.27, blue: 0.16, alpha: 1),
                metalness: 0, roughness: 0.9)
            let trunkN = SCNNode(geometry: trunk)
            trunkN.position.y = trunkH / 2

            let leavesH = Float.random(in: 3.0...5.0, using: &rng)
            let leavesR = Float.random(in: 1.3...2.1, using: &rng)
            let cone = SCNCone(topRadius: 0,
                               bottomRadius: CGFloat(leavesR),
                               height: CGFloat(leavesH))
            let g = CGFloat.random(in: 0.45...0.62, using: &rng)
            cone.firstMaterial = makeMaterial(
                UIColor(red: 0.18, green: g, blue: 0.22, alpha: 1),
                metalness: 0, roughness: 0.85)
            let coneN = SCNNode(geometry: cone)
            coneN.position.y = trunkH + leavesH / 2 - 0.4

            let tree = SCNNode()
            tree.addChildNode(trunkN)
            tree.addChildNode(coneN)
            tree.castsShadow = true
            tree.position = SCNVector3(pos.x, 0, pos.z)
            scene.rootNode.addChildNode(tree)
        }
    }

    private func makeMaterial(_ color: UIColor, metalness: CGFloat = 0.4,
                              roughness: CGFloat = 0.6,
                              emission: UIColor? = nil) -> SCNMaterial {
        let m = SCNMaterial()
        m.diffuse.contents = color
        m.metalness.contents = metalness
        m.roughness.contents = roughness
        if let e = emission { m.emission.contents = e }
        return m
    }

    private func randomOffTrackPosition(rng: inout SystemRandomNumberGenerator,
                                        minDist: Float) -> SCNVector3 {
        for _ in 0..<40 {
            let x = Float.random(in: -100...100, using: &rng)
            let z = Float.random(in: -100...100, using: &rng)
            let xz = SIMD2<Float>(x, z)
            let dist = layout.distanceFromCenterline(xz)
            if dist > layout.trackWidth / 2 + minDist
                && abs(x) < 100 && abs(z) < 100 {
                return SCNVector3(x, 0, z)
            }
        }
        return SCNVector3(80, 0, 80)
    }

    private func tickBotsAndRace(dt: Float, time: TimeInterval) {
        let totalLaps = state?.totalLaps ?? 3
        for bot in bots {
            bot.tick(dt: dt, time: time, layout: layout,
                     totalLaps: totalLaps)
            bot.setRearWing(open: false)
        }
        resolveCarCollisions()
        updatePlayerLapProgress(time: time, totalLaps: totalLaps)
    }

    private func resolveCarCollisions() {
        let minSep: Float = 2.6
        struct Item { let id: Int; var pos: SCNVector3; var vel: Float }
        var items: [Item] = [Item(id: -1, pos: carNode.position, vel: velocity)]
        for (i, b) in bots.enumerated() {
            items.append(Item(id: i, pos: b.position, vel: b.velocity))
        }

        for i in 0..<items.count {
            for j in (i + 1)..<items.count {
                let a = items[i].pos
                let b = items[j].pos
                let dx = b.x - a.x
                let dz = b.z - a.z
                let dist = sqrt(dx * dx + dz * dz)
                if dist < minSep && dist > 0.001 {
                    let overlap = (minSep - dist) / 2
                    let nx = dx / dist
                    let nz = dz / dist
                    items[i].pos.x -= nx * overlap
                    items[i].pos.z -= nz * overlap
                    items[j].pos.x += nx * overlap
                    items[j].pos.z += nz * overlap
                    items[i].vel *= 0.88
                    items[j].vel *= 0.88
                }
            }
        }
        carNode.position = items[0].pos
        velocity = items[0].vel
        for k in 1..<items.count {
            let bIdx = items[k].id
            bots[bIdx].position = items[k].pos
            bots[bIdx].velocity = items[k].vel
            bots[bIdx].node.position = items[k].pos
        }
    }

    private func updatePlayerLapProgress(time: TimeInterval, totalLaps: Int) {
        let xz = SIMD2<Float>(carNode.position.x, carNode.position.z)
        let newT = layout.trackProgress(for: xz)
        let delta = newT - lastProgress
        if delta < -0.5 {
            playerLapsDone += 1
            let lapDuration = time - lastLapStart
            lastLapStart = time
            if playerLapsDone > 0 {
                if bestLap == 0 || lapDuration < bestLap {
                    bestLap = lapDuration
                }
            }
            if playerLapsDone >= totalLaps && !hasFinished {
                hasFinished = true
                finishWallTime = time
                finalizeRace(time: time)
            }
        }
        lastProgress = newT
    }

    private func finalizeRace(time: TimeInterval) {
        let totalTime = time - raceStartTime
        let position = computePlayerPosition()
        let results = buildResults(time: time, playerPosition: position)
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let state = self.state else { return }
            state.racePhase = .finished
            state.playerPosition = position
            state.totalRaceTime = totalTime
            state.bestLapTime = self.bestLap
            state.raceResults = results
            if position == 1 {
                state.bestScore += 5
            } else if position == 2 {
                state.bestScore += 3
            } else if position == 3 {
                state.bestScore += 2
            } else {
                state.bestScore += 1
            }
        }
    }

    private func computePlayerPosition() -> Int {
        let playerProgress = Float(playerLapsDone) + lastProgress
        var ahead = 0
        for b in bots {
            if b.lapProgress > playerProgress { ahead += 1 }
        }
        return ahead + 1
    }

    private func buildResults(time: TimeInterval,
                              playerPosition: Int) -> [RaceResult] {
        var entries: [(name: String, color: UIColor,
                       progress: Float, isPlayer: Bool,
                       laps: Int, best: Double)] = []
        entries.append((car.name, car.body,
                        Float(playerLapsDone) + lastProgress,
                        true, playerLapsDone, bestLap))
        for b in bots {
            entries.append((b.name, b.bodyColor, b.lapProgress,
                            false, b.lapsDone, b.bestLap))
        }
        entries.sort { $0.progress > $1.progress }
        return entries.enumerated().map { (idx, e) in
            RaceResult(id: idx, name: e.name, color: Color(e.color),
                       position: idx + 1, lapsCompleted: e.laps,
                       bestLap: e.best, isPlayer: e.isPlayer)
        }
    }

    private func publishHUD(time: TimeInterval) {
        guard let state = state else { return }

        let speedAbs = abs(velocity)
        let speedRounded = Float(Int(speedAbs * 10)) / 10
        let liveLapTime = state.racePhase == .racing
            ? time - lastLapStart : 0
        let lapTimeRounded = Double(Int(liveLapTime * 10)) / 10
        let position = computePlayerPosition()
        let inZone = layout.isDRSZone(at: lastProgress)
        let drsAvail = drsCooldown <= 0 && !drsActive && inZone
        let phase = state.racePhase

        if speedRounded == publishedSpeed
            && playerLapsDone == publishedLap
            && lapTimeRounded == publishedLapTime
            && position == publishedPosition
            && drsAvail == publishedDRSAvail
            && drsActive == publishedDRSActive
            && phase == publishedPhase {
            return
        }
        publishedSpeed = speedRounded
        publishedLap = playerLapsDone
        publishedLapTime = lapTimeRounded
        publishedPosition = position
        publishedDRSAvail = drsAvail
        publishedDRSActive = drsActive
        publishedPhase = phase

        let s = speedAbs
        let lapsCopy = playerLapsDone
        let lapCopy = liveLapTime
        let bestCopy = bestLap
        let drsActiveCopy = drsActive
        DispatchQueue.main.async { [weak self] in
            guard let st = self?.state else { return }
            st.speed = s
            st.lap = lapsCopy
            st.lapTime = lapCopy
            st.bestLapTime = bestCopy
            st.playerPosition = position
            st.drsAvailable = drsAvail
            st.drsActive = drsActiveCopy
        }
    }

    private func tickRacing(dt: Float, time: TimeInterval) {
        guard let state = state else { return }

        state.updateSteer(dt: dt)
        let steer = state.steerInput
        let throttle = state.throttleInput

        let inDRSZone = layout.isDRSZone(at: lastProgress)
        updateDRSState(dt: dt, inZone: inDRSZone, drsHeld: state.drsHeld)

        let drsBoost: Float = drsActive ? 1.22 : 1.0
        let baseFwd = car.topSpeed * drsBoost
        let baseAccel = car.acceleration * (drsActive ? 1.10 : 1.0)
        let maxRev: Float = baseFwd * 0.4

        if throttle > 0 {
            velocity = min(velocity + throttle * baseAccel * dt, baseFwd)
        } else if throttle < 0 {
            velocity = max(velocity - baseAccel * 1.6 * dt, -maxRev)
        } else {
            let drag: Float = 11
            if velocity > 0 { velocity = max(velocity - drag * dt, 0) }
            else if velocity < 0 { velocity = min(velocity + drag * dt, 0) }
        }

        let speedAbs = abs(velocity)
        if speedAbs > 0.5 {
            let speedFactor = min(1, speedAbs / max(car.topSpeed, 0.001))
            let downforceGrip: Float = 1.0 + speedFactor * 0.55
            let authority: Float = 0.42 + 0.58 * speedFactor
            let yaw = steer * car.handling * tread.gripBonus *
                downforceGrip * authority
            let sign: Float = velocity >= 0 ? 1 : -1
            carNode.eulerAngles.y -= yaw * sign * dt
        }

        let heading = carNode.eulerAngles.y
        var newPos = carNode.position
        newPos.x += -sin(heading) * velocity * dt
        newPos.z += -cos(heading) * velocity * dt

        let xz = SIMD2<Float>(newPos.x, newPos.z)
        let dCenter = layout.distanceFromCenterline(xz)
        let halfW = layout.trackWidth / 2
        if dCenter > halfW + 1.2 {
            velocity *= 0.92
        }
        if dCenter > halfW + 6 {
            let t = layout.trackProgress(for: xz)
            let centerP = layout.point(at: t)
            let pull: Float = 0.18
            newPos.x += (centerP.x - newPos.x) * pull
            newPos.z += (centerP.y - newPos.z) * pull
        }

        let from = SCNVector3(newPos.x, newPos.y + 12, newPos.z)
        let to = SCNVector3(newPos.x, newPos.y - 12, newPos.z)
        let hits = scene.rootNode.hitTestWithSegment(from: from, to: to,
                                                     options: nil)
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

        let driftiness = abs(steer) * speedAbs / max(car.topSpeed, 1)
        if driftiness > 0.55 {
            for emitter in smokeEmitters where Float.random(in: 0...1) < 0.35 {
                let world = emitter.convertPosition(SCNVector3Zero, to: nil)
                spawnSmokePuff(at: world)
            }
        }

        tickBotsAndRace(dt: dt, time: time)
    }

    private func tickFinishedCoast(dt: Float, time: TimeInterval) {
        velocity = max(0, velocity - 14 * dt)
        let heading = carNode.eulerAngles.y
        var pos = carNode.position
        pos.x += -sin(heading) * velocity * dt
        pos.z += -cos(heading) * velocity * dt
        carNode.position = pos
        for b in bots {
            b.tick(dt: dt, time: time, layout: layout,
                   totalLaps: state?.totalLaps ?? 3)
        }
    }

    private func updateDRSState(dt: Float, inZone: Bool, drsHeld: Bool) {
        if drsActive {
            drsTimeRemaining -= Double(dt)
            if drsTimeRemaining <= 0 || !inZone {
                drsActive = false
                drsCooldown = drsCooldownTime
                if let wing = rearWingFlap {
                    wing.eulerAngles.x += (0 - wing.eulerAngles.x) * 0.5
                }
            }
        } else {
            if drsCooldown > 0 {
                drsCooldown = max(0, drsCooldown - Double(dt))
            } else if drsHeld && inZone {
                drsActive = true
                drsTimeRemaining = drsDuration
            }
        }
        rearWingFlap?.eulerAngles.x = drsActive ? -0.35 : 0
    }

    private func isDescendantOfCar(_ node: SCNNode) -> Bool {
        var n: SCNNode? = node
        while let nn = n {
            if nn === carNode { return true }
            n = nn.parent
        }
        return false
    }

    private func addPlayerCar() {
        let built = F1CarBuilder.build(
            bodyColor: car.body,
            accentColor: layout.accentColor,
            cabinColor: car.cabin,
            treadRadius: tread.radius,
            treadColor: tread.color,
            treadStripeColor: tread.stripeColor)
        carNode.addChildNode(built.node)
        rearWingFlap = built.rearWingFlap
        smokeEmitters = built.smokeEmitters

        let startT: Float = 0.0
        let p = layout.point(at: startT)
        let tang = layout.tangent(at: startT)
        carNode.position = SCNVector3(p.x, Float(tread.radius) + 0.1, p.y)
        carNode.eulerAngles.y = atan2(-tang.x, -tang.y)
        scene.rootNode.addChildNode(carNode)
        lastProgress = startT
    }

    private static let botLiveries: [(name: String, body: UIColor, accent: UIColor)] = [
        ("Aero",   UIColor(red: 0.0, green: 0.45, blue: 0.95, alpha: 1),
                   UIColor.white),
        ("Stinger",UIColor(red: 0.85, green: 0.0, blue: 0.05, alpha: 1),
                   UIColor(red: 1, green: 0.85, blue: 0.10, alpha: 1)),
        ("Forge",  UIColor(red: 0.00, green: 0.55, blue: 0.30, alpha: 1),
                   UIColor(red: 0.85, green: 0.75, blue: 0.0, alpha: 1)),
        ("Volt",   UIColor(red: 0.96, green: 0.85, blue: 0.0, alpha: 1),
                   UIColor.black),
        ("Blaze",  UIColor(red: 0.95, green: 0.40, blue: 0.0, alpha: 1),
                   UIColor(red: 0.05, green: 0.05, blue: 0.18, alpha: 1))
    ]

    private func spawnBotsOnGrid() {
        let grid: [(row: Int, side: Float)] = [
            (1, -1), (1, +1),
            (2, -1), (2, +1),
            (3,  0)
        ]
        let startT: Float = 0
        let startP = layout.point(at: startT)
        let tang = layout.tangent(at: startT)
        let perp = SIMD2<Float>(-tang.y, tang.x)
        let backward = -tang
        let rowSpacing: Float = 5.5
        let lateralOff: Float = 3.0
        let baseHeading = atan2(-tang.x, -tang.y)

        let speeds: [Float] = [0.95, 0.92, 0.90, 0.88, 0.86]
        let skills: [Float] = [3.4, 3.0, 2.8, 2.5, 2.2]

        for (i, slot) in grid.enumerated() {
            let liv = Self.botLiveries[i % Self.botLiveries.count]
            let pos2D = startP
                + backward * (Float(slot.row) * rowSpacing)
                + perp * (slot.side * lateralOff)
            let pos = SCNVector3(pos2D.x, Float(tread.radius) + 0.1, pos2D.y)
            let bot = BotCar(
                position: pos, heading: baseHeading,
                trackProgress: startT,
                topSpeed: car.topSpeed * speeds[i] + Float.random(in: -1.5...1.5),
                acceleration: car.acceleration * 0.92 + Float.random(in: -1.0...1.0),
                cornerSkill: skills[i],
                lateralBias: [-2.0, 1.5, -1.0, 1.0, 0][i % 5],
                bodyColor: liv.body, accentColor: liv.accent,
                name: liv.name,
                treadRadius: tread.radius,
                treadColor: tread.color,
                treadStripeColor: tread.stripeColor)
            scene.rootNode.addChildNode(bot.node)
            bots.append(bot)
        }
    }

    private func addCamera() {
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zNear = 0.2
        cameraNode.camera?.zFar = 380
        cameraNode.camera?.fieldOfView = 68
        cameraNode.camera?.bloomIntensity = 0.45
        cameraNode.camera?.bloomThreshold = 0.85
        cameraNode.camera?.wantsHDR = true
        scene.rootNode.addChildNode(cameraNode)
    }

    private func placeCameraBehindCar() {
        let h = carNode.eulerAngles.y
        let p = carNode.position
        cameraNode.position = SCNVector3(
            p.x + sin(h) * camDist,
            p.y + camHeight,
            p.z + cos(h) * camDist)
        cameraNode.look(
            at: SCNVector3(p.x - sin(h) * 2, p.y + 1.3, p.z - cos(h) * 2),
            up: SCNVector3(0, 1, 0),
            localFront: SCNVector3(0, 0, -1))
    }

    private func updateCamera(dt: Float) {
        let h = carNode.eulerAngles.y
        let p = carNode.position
        let smoothing = min(Float(1), 5 * dt)
        let desired = SCNVector3(
            p.x + sin(h) * camDist,
            p.y + camHeight,
            p.z + cos(h) * camDist)
        cameraNode.position = SCNVector3(
            cameraNode.position.x +
                (desired.x - cameraNode.position.x) * smoothing,
            cameraNode.position.y +
                (desired.y - cameraNode.position.y) * smoothing,
            cameraNode.position.z +
                (desired.z - cameraNode.position.z) * smoothing)
        cameraNode.look(
            at: SCNVector3(p.x - sin(h) * 2, p.y + 1.3, p.z - cos(h) * 2),
            up: SCNVector3(0, 1, 0),
            localFront: SCNVector3(0, 0, -1))
    }

    private func spawnSmokePuff(at worldPos: SCNVector3) {
        let puff = SCNSphere(radius: 0.35)
        puff.firstMaterial = makeMaterial(
            UIColor.white, metalness: 0, roughness: 0.4,
            emission: UIColor(white: 0.85, alpha: 1))
        puff.firstMaterial?.transparency = 0.65
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

    private func buildTrackGeometry() {
        let steps = 240
        let segLen = layout.totalLength / Float(steps) + 0.4
        let trackMat = makeMaterial(UIColor(white: 0.18, alpha: 1),
                                    metalness: 0.1, roughness: 0.85)
        let stripeMat = makeMaterial(
            UIColor.white, metalness: 0, roughness: 0.5,
            emission: UIColor(white: 0.25, alpha: 1))

        for i in 0..<steps {
            let t = Float(i) / Float(steps)
            let mid = layout.point(at: t)
            let tang = layout.tangent(at: t)
            let angle = atan2(tang.x, tang.y)

            let seg = SCNBox(width: CGFloat(layout.trackWidth),
                             height: 0.1, length: CGFloat(segLen),
                             chamferRadius: 0)
            seg.firstMaterial = trackMat
            let n = SCNNode(geometry: seg)
            n.position = SCNVector3(mid.x, 0.05, mid.y)
            n.eulerAngles.y = angle
            scene.rootNode.addChildNode(n)

            if i % 6 == 0 {
                let dash = SCNBox(width: 0.32, height: 0.12,
                                  length: 1.6, chamferRadius: 0)
                dash.firstMaterial = stripeMat
                let dN = SCNNode(geometry: dash)
                dN.position = SCNVector3(mid.x, 0.11, mid.y)
                dN.eulerAngles.y = angle
                scene.rootNode.addChildNode(dN)
            }
        }
        addStartFinishLine()
        addBarriers(steps: steps)
        addCornerCurbs(steps: steps)
    }

    private func addStartFinishLine() {
        let p = layout.point(at: 0)
        let tang = layout.tangent(at: 0)
        let angle = atan2(tang.x, tang.y)
        let blocks = 8
        for i in 0..<blocks {
            let isWhite = i % 2 == 0
            let block = SCNBox(width: CGFloat(layout.trackWidth) / CGFloat(blocks),
                               height: 0.13, length: 1.0, chamferRadius: 0)
            block.firstMaterial = makeMaterial(
                isWhite ? UIColor.white : UIColor.black,
                metalness: 0, roughness: 0.6)
            let bN = SCNNode(geometry: block)
            let off = (Float(i) - Float(blocks - 1) / 2) *
                (layout.trackWidth / Float(blocks))
            let perp = SIMD2<Float>(-tang.y, tang.x)
            let pos = p + perp * off
            bN.position = SCNVector3(pos.x, 0.13, pos.y)
            bN.eulerAngles.y = angle
            scene.rootNode.addChildNode(bN)
        }

        let bannerHeight: Float = 6.5
        for side: Float in [-1, 1] {
            let perp = SIMD2<Float>(-tang.y, tang.x)
            let pillar = SCNBox(width: 0.6, height: CGFloat(bannerHeight),
                                length: 0.6, chamferRadius: 0.1)
            pillar.firstMaterial = makeMaterial(
                layout.accentColor, metalness: 0.4, roughness: 0.4)
            let pN = SCNNode(geometry: pillar)
            let pos = p + perp * (layout.trackWidth / 2 + 1) * side
            pN.position = SCNVector3(pos.x, bannerHeight / 2, pos.y)
            pN.castsShadow = true
            scene.rootNode.addChildNode(pN)
        }
        let banner = SCNBox(width: CGFloat(layout.trackWidth) + 3,
                            height: 1.4, length: 0.4, chamferRadius: 0.1)
        banner.firstMaterial = makeMaterial(
            layout.accentColor, metalness: 0.4, roughness: 0.3)
        let bnN = SCNNode(geometry: banner)
        bnN.position = SCNVector3(p.x, bannerHeight + 0.2, p.y)
        bnN.eulerAngles.y = angle
        bnN.castsShadow = true
        scene.rootNode.addChildNode(bnN)
    }

    private func addBarriers(steps: Int) {
        let barrierMat = makeMaterial(UIColor.white,
                                      metalness: 0.1, roughness: 0.7)
        let accent = makeMaterial(layout.accentColor,
                                  metalness: 0.1, roughness: 0.6)
        for i in stride(from: 0, to: steps, by: 2) {
            let t = Float(i) / Float(steps)
            let p = layout.point(at: t)
            let tang = layout.tangent(at: t)
            let perp = SIMD2<Float>(-tang.y, tang.x)
            let angle = atan2(tang.x, tang.y)
            let edge = layout.trackWidth / 2 + 0.5
            let segLen = layout.totalLength / Float(steps) * 2 + 0.3
            for side: Float in [-1, 1] {
                let pos = p + perp * (edge * side)
                let geom = SCNBox(width: 0.4, height: 0.5,
                                  length: CGFloat(segLen),
                                  chamferRadius: 0.06)
                geom.firstMaterial = i % 4 == 0 ? accent : barrierMat
                let n = SCNNode(geometry: geom)
                n.position = SCNVector3(pos.x, 0.30, pos.y)
                n.eulerAngles.y = angle
                n.castsShadow = true
                scene.rootNode.addChildNode(n)
            }
        }
    }

    private func addCornerCurbs(steps: Int) {
        let red = makeMaterial(UIColor(red: 0.92, green: 0.2,
                                       blue: 0.2, alpha: 1),
                               metalness: 0, roughness: 0.6)
        let white = makeMaterial(UIColor.white,
                                 metalness: 0, roughness: 0.6)
        for i in 0..<steps {
            let t = Float(i) / Float(steps)
            let curve = layout.curvature(at: t)
            if curve < 0.020 { continue }
            let p = layout.point(at: t)
            let tang = layout.tangent(at: t)
            let perp = SIMD2<Float>(-tang.y, tang.x)
            let angle = atan2(tang.x, tang.y)
            let edge = layout.trackWidth / 2 - 0.1
            for side: Float in [-1, 1] {
                let pos = p + perp * (edge * side)
                let curb = SCNBox(width: 1.0, height: 0.12, length: 0.9,
                                  chamferRadius: 0.02)
                curb.firstMaterial = i % 2 == 0 ? red : white
                let n = SCNNode(geometry: curb)
                n.position = SCNVector3(pos.x, 0.10, pos.y)
                n.eulerAngles.y = angle
                scene.rootNode.addChildNode(n)
            }
        }
    }

    private func addGrandstands() {
        let grandstandTs: [Float] = [0.05, 0.30, 0.55, 0.78]
        for t in grandstandTs {
            let p = layout.point(at: t)
            let tang = layout.tangent(at: t)
            let perp = SIMD2<Float>(-tang.y, tang.x)
            let outward = layout.trackWidth / 2 + 6
            let standCenter = p + perp * outward
            let angle = atan2(tang.x, tang.y)

            let baseGeom = SCNBox(width: 14, height: 0.6, length: 4,
                                  chamferRadius: 0.1)
            baseGeom.firstMaterial = makeMaterial(
                UIColor(white: 0.55, alpha: 1),
                metalness: 0.1, roughness: 0.8)
            let baseN = SCNNode(geometry: baseGeom)
            baseN.position = SCNVector3(standCenter.x, 0.3, standCenter.y)
            baseN.eulerAngles.y = angle
            scene.rootNode.addChildNode(baseN)

            for row in 0..<4 {
                let rowGeom = SCNBox(width: 14, height: 0.6, length: 0.8,
                                     chamferRadius: 0.05)
                let hue = CGFloat(row) * 0.18
                rowGeom.firstMaterial = makeMaterial(
                    UIColor(hue: hue, saturation: 0.45,
                            brightness: 0.85, alpha: 1),
                    metalness: 0, roughness: 0.7)
                let rowN = SCNNode(geometry: rowGeom)
                let yOff = Float(row) * 0.55 + 0.85
                let zOff = Float(row) * 0.6 - 0.6
                let local = SCNNode()
                local.addChildNode(rowN)
                rowN.position = SCNVector3(0, yOff, zOff)
                local.position = SCNVector3(standCenter.x, 0, standCenter.y)
                local.eulerAngles.y = angle
                scene.rootNode.addChildNode(local)
            }

            let canopy = SCNBox(width: 15, height: 0.2, length: 5,
                                chamferRadius: 0.08)
            canopy.firstMaterial = makeMaterial(
                layout.accentColor,
                metalness: 0.2, roughness: 0.4)
            let canopyN = SCNNode(geometry: canopy)
            canopyN.position = SCNVector3(standCenter.x, 4.2, standCenter.y)
            canopyN.eulerAngles.y = angle
            scene.rootNode.addChildNode(canopyN)
        }
    }
}
