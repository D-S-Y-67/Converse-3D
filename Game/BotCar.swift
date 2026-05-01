import SceneKit
import simd

final class BotCar {
    var position: SCNVector3
    var heading: Float
    var velocity: Float
    var trackProgress: Float
    var lapsDone: Int
    let gridOffset: Float
    var lastLapStart: TimeInterval = 0
    var bestLap: Double = 0
    var finishTime: Double = 0
    var hasFinished: Bool = false

    let baseTopSpeed: Float
    let acceleration: Float
    let cornerSkill: Float
    let lateralBias: Float
    let bodyColor: UIColor
    let accentColor: UIColor
    let team: F1Team
    let name: String

    let node: SCNNode
    private let rearWingNode: SCNNode?

    var drsActive: Bool = false
    var drsCooldown: Double = 0
    private var drsTimeRemaining: Double = 0
    private let drsDuration: Double = 5.0
    private let drsCooldownTime: Double = 4.0

    var topSpeed: Float {
        baseTopSpeed * (drsActive ? 1.22 : 1.0)
    }

    init(position: SCNVector3, heading: Float, trackProgress: Float,
         topSpeed: Float, acceleration: Float, cornerSkill: Float,
         lateralBias: Float, team: F1Team,
         driverName: String, treadRadius: CGFloat, treadColor: UIColor,
         treadStripeColor: UIColor) {
        self.position = position
        self.heading = heading
        self.velocity = 0
        self.trackProgress = trackProgress
        self.gridOffset = trackProgress
        self.lapsDone = 0
        self.baseTopSpeed = topSpeed
        self.acceleration = acceleration
        self.cornerSkill = cornerSkill
        self.lateralBias = lateralBias
        self.team = team
        self.bodyColor = team.primary
        self.accentColor = team.secondary
        self.name = driverName
        let built = F1CarBuilder.build(bodyColor: team.primary,
                                       accentColor: team.secondary,
                                       cabinColor: team.secondary,
                                       treadRadius: treadRadius,
                                       treadColor: treadColor,
                                       treadStripeColor: treadStripeColor,
                                       decal: team.abbrev)
        self.node = built.node
        self.rearWingNode = built.rearWingFlap
        node.position = position
        node.eulerAngles.y = heading
    }

    var lapProgress: Float {
        lapProgressFor(laps: lapsDone, t: trackProgress)
    }

    private func lapProgressFor(laps: Int, t: Float) -> Float {
        Float(laps) + t - gridOffset
    }

    func tick(dt: Float, time: TimeInterval, layout: TrackLayout,
              totalLaps: Int) {
        if hasFinished {
            velocity = max(0, velocity - 18 * dt)
            advancePosition(dt: dt)
            clampToTrack(layout: layout)
            updateNode()
            return
        }

        updateDRS(dt: dt, layout: layout)

        let lookahead: Float = 5.5 / max(layout.totalLength, 1)
        let aimT = trackProgress + lookahead
        let aimPoint = layout.point(at: aimT)
        let tangent = layout.tangent(at: aimT)
        let perp = SIMD2<Float>(-tangent.y, tangent.x)
        let target = aimPoint + perp * lateralBias

        let dx = target.x - position.x
        let dz = target.y - position.z
        let desiredHeading = atan2(-dx, -dz)

        var headingError = desiredHeading - heading
        while headingError >  Float.pi { headingError -= 2 * Float.pi }
        while headingError < -Float.pi { headingError += 2 * Float.pi }
        let steer = max(-1, min(1, headingError * 2.4))
        let steerRate: Float = 2.6 + cornerSkill * 0.4
        heading += steer * steerRate * dt

        let aheadT = trackProgress + (10.0 / max(layout.totalLength, 1))
        let curve = layout.curvature(at: aheadT)
        let cornerLimit = topSpeed * max(0.42, 1.0 - curve * (28 - cornerSkill * 6))
        let targetSpeed = max(cornerLimit, topSpeed * 0.42)

        let accel = acceleration * (drsActive ? 1.10 : 1.0)
        if velocity < targetSpeed - 0.5 {
            velocity = min(velocity + accel * dt, targetSpeed)
        } else if velocity > targetSpeed + 0.5 {
            velocity = max(velocity - accel * 1.6 * dt, targetSpeed)
        }

        advancePosition(dt: dt)
        clampToTrack(layout: layout)

        let newT = layout.trackProgress(for: SIMD2(position.x, position.z))
        let delta = newT - trackProgress
        if delta < -0.5 {
            lapsDone += 1
            let lapDuration = time - lastLapStart
            if lastLapStart > 0 {
                if bestLap == 0 || lapDuration < bestLap { bestLap = lapDuration }
            }
            lastLapStart = time
            if lapProgressFor(laps: lapsDone, t: newT) >= Float(totalLaps) {
                hasFinished = true
                finishTime = time
            }
        }
        trackProgress = newT

        updateNode()
    }

    private func updateDRS(dt: Float, layout: TrackLayout) {
        let inZone = layout.isDRSZone(at: trackProgress)
        if drsActive {
            drsTimeRemaining -= Double(dt)
            if drsTimeRemaining <= 0 || !inZone {
                drsActive = false
                drsCooldown = drsCooldownTime
            }
        } else {
            if drsCooldown > 0 {
                drsCooldown = max(0, drsCooldown - Double(dt))
            } else if inZone {
                drsActive = true
                drsTimeRemaining = drsDuration
            }
        }
        setRearWing(open: drsActive)
    }

    func setRearWing(open: Bool) {
        guard let wing = rearWingNode else { return }
        let target: Float = open ? -0.35 : 0
        wing.eulerAngles.x = wing.eulerAngles.x + (target - wing.eulerAngles.x) * 0.4
    }

    func clampToTrack(layout: TrackLayout) {
        let xz = SIMD2<Float>(position.x, position.z)
        let t = layout.trackProgress(for: xz)
        let centerP = layout.point(at: t)
        let off = xz - centerP
        let dist = simd_length(off)
        let limit = layout.trackWidth / 2 - 0.6
        if dist > limit && dist > 0.001 {
            let n = off / dist
            let clamped = centerP + n * limit
            position.x = clamped.x
            position.z = clamped.y
            velocity *= 0.94
        }
    }

    private func advancePosition(dt: Float) {
        position.x += -sin(heading) * velocity * dt
        position.z += -cos(heading) * velocity * dt
    }

    private func updateNode() {
        node.position = position
        node.eulerAngles.y = heading
    }
}
