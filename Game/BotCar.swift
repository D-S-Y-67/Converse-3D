import SceneKit
import simd

final class BotCar {
    var position: SCNVector3
    var heading: Float
    var velocity: Float
    var trackProgress: Float
    var lapsDone: Int
    var lastLapStart: TimeInterval = 0
    var bestLap: Double = 0
    var finishTime: Double = 0
    var hasFinished: Bool = false

    let topSpeed: Float
    let acceleration: Float
    let cornerSkill: Float
    let lateralBias: Float
    let bodyColor: UIColor
    let accentColor: UIColor
    let name: String

    let node: SCNNode
    private let rearWingNode: SCNNode?

    init(position: SCNVector3, heading: Float, trackProgress: Float,
         topSpeed: Float, acceleration: Float, cornerSkill: Float,
         lateralBias: Float, bodyColor: UIColor, accentColor: UIColor,
         name: String, treadRadius: CGFloat, treadColor: UIColor,
         treadStripeColor: UIColor) {
        self.position = position
        self.heading = heading
        self.velocity = 0
        self.trackProgress = trackProgress
        self.lapsDone = 0
        self.topSpeed = topSpeed
        self.acceleration = acceleration
        self.cornerSkill = cornerSkill
        self.lateralBias = lateralBias
        self.bodyColor = bodyColor
        self.accentColor = accentColor
        self.name = name
        let built = F1CarBuilder.build(bodyColor: bodyColor,
                                       accentColor: accentColor,
                                       cabinColor: UIColor(white: 0.05, alpha: 1),
                                       treadRadius: treadRadius,
                                       treadColor: treadColor,
                                       treadStripeColor: treadStripeColor)
        self.node = built.node
        self.rearWingNode = built.rearWingFlap
        node.position = position
        node.eulerAngles.y = heading
    }

    var lapProgress: Float { Float(lapsDone) + trackProgress }

    func tick(dt: Float, time: TimeInterval, layout: TrackLayout,
              totalLaps: Int) {
        if hasFinished {
            velocity = max(0, velocity - 18 * dt)
            advancePosition(dt: dt)
            updateNode()
            return
        }

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

        if velocity < targetSpeed - 0.5 {
            velocity = min(velocity + acceleration * dt, targetSpeed)
        } else if velocity > targetSpeed + 0.5 {
            velocity = max(velocity - acceleration * 1.6 * dt, targetSpeed)
        }

        advancePosition(dt: dt)

        let newT = layout.trackProgress(for: SIMD2(position.x, position.z))
        let delta = newT - trackProgress
        if delta < -0.5 {
            lapsDone += 1
            let lapDuration = time - lastLapStart
            if lastLapStart > 0 {
                if bestLap == 0 || lapDuration < bestLap { bestLap = lapDuration }
            }
            lastLapStart = time
            if lapsDone >= totalLaps {
                hasFinished = true
                finishTime = time
            }
        }
        trackProgress = newT

        updateNode()
    }

    func setRearWing(open: Bool) {
        guard let wing = rearWingNode else { return }
        let target: Float = open ? -0.35 : 0
        wing.eulerAngles.x = wing.eulerAngles.x + (target - wing.eulerAngles.x) * 0.4
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
