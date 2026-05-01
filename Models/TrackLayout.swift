import SceneKit
import simd

struct TrackLayout: Identifiable {
    let id: Int
    let name: String
    let country: String
    let accentColor: UIColor
    let waypoints: [SIMD2<Float>]
    let trackWidth: Float

    private let samples: [SIMD2<Float>]
    private let segmentLengths: [Float]
    let totalLength: Float

    init(id: Int, name: String, country: String, accentColor: UIColor,
         trackWidth: Float, waypoints: [SIMD2<Float>]) {
        self.id = id
        self.name = name
        self.country = country
        self.accentColor = accentColor
        self.trackWidth = trackWidth
        self.waypoints = waypoints

        let n = 512
        var pts: [SIMD2<Float>] = []
        pts.reserveCapacity(n)
        for i in 0..<n {
            let t = Float(i) / Float(n)
            pts.append(Self.evaluate(waypoints: waypoints, t: t))
        }
        self.samples = pts
        var segs: [Float] = []
        segs.reserveCapacity(n)
        var total: Float = 0
        for i in 0..<n {
            let a = pts[i]
            let b = pts[(i + 1) % n]
            let d = simd_distance(a, b)
            segs.append(d)
            total += d
        }
        self.segmentLengths = segs
        self.totalLength = total
    }

    static func catmullRom(_ p0: SIMD2<Float>, _ p1: SIMD2<Float>,
                           _ p2: SIMD2<Float>, _ p3: SIMD2<Float>,
                           t: Float) -> SIMD2<Float> {
        let t2: Float = t * t
        let t3: Float = t2 * t
        let term1: SIMD2<Float> = p1 * 2.0
        let term2: SIMD2<Float> = (p2 - p0) * t
        let inner3: SIMD2<Float> = p0 * 2.0 - p1 * 5.0 + p2 * 4.0 - p3
        let term3: SIMD2<Float> = inner3 * t2
        let inner4: SIMD2<Float> = p1 * 3.0 - p0 - p2 * 3.0 + p3
        let term4: SIMD2<Float> = inner4 * t3
        let sum: SIMD2<Float> = term1 + term2 + term3 + term4
        return sum * 0.5
    }

    static func evaluate(waypoints: [SIMD2<Float>], t: Float) -> SIMD2<Float> {
        let n = waypoints.count
        let scaled = (t.truncatingRemainder(dividingBy: 1) + 1)
            .truncatingRemainder(dividingBy: 1) * Float(n)
        let i = Int(scaled) % n
        let localT = scaled - Float(Int(scaled))
        let p0 = waypoints[(i - 1 + n) % n]
        let p1 = waypoints[i]
        let p2 = waypoints[(i + 1) % n]
        let p3 = waypoints[(i + 2) % n]
        return catmullRom(p0, p1, p2, p3, t: localT)
    }

    func point(at t: Float) -> SIMD2<Float> {
        Self.evaluate(waypoints: waypoints, t: t)
    }

    func tangent(at t: Float) -> SIMD2<Float> {
        let h: Float = 0.001
        let a = point(at: t - h)
        let b = point(at: t + h)
        let d = b - a
        let len = simd_length(d)
        return len > 0.0001 ? d / len : SIMD2<Float>(1, 0)
    }

    func curvature(at t: Float) -> Float {
        let h: Float = 0.005
        let p0 = point(at: t - h)
        let p1 = point(at: t)
        let p2 = point(at: t + h)
        let d1 = p1 - p0
        let d2 = p2 - p1
        let cross = d1.x * d2.y - d1.y * d2.x
        let mag: Float = simd_length(d1) * simd_length(d2) * simd_length(d2 - d1)
        return mag < 0.0001 ? 0.0 : abs(cross) / max(mag, 0.0001)
    }

    func isDRSZone(at t: Float) -> Bool {
        curvature(at: t) < 0.012
    }

    func trackProgress(for worldXZ: SIMD2<Float>) -> Float {
        var bestDist = Float.greatestFiniteMagnitude
        var bestIdx = 0
        for i in 0..<samples.count {
            let d = simd_distance_squared(samples[i], worldXZ)
            if d < bestDist { bestDist = d; bestIdx = i }
        }
        return Float(bestIdx) / Float(samples.count)
    }

    func distanceFromCenterline(_ worldXZ: SIMD2<Float>) -> Float {
        let t = trackProgress(for: worldXZ)
        let centre = point(at: t)
        return simd_distance(centre, worldXZ)
    }

    static let all: [TrackLayout] = [silverstone, monaco, spa, monza, suzuka]

    static let silverstone = TrackLayout(
        id: 0, name: "Silverstone", country: "🇬🇧",
        accentColor: UIColor(red: 0.0, green: 0.45, blue: 0.85, alpha: 1),
        trackWidth: 22,
        waypoints: [
            SIMD2(  0, -60), SIMD2( 22, -58), SIMD2( 50, -50), SIMD2( 62, -30),
            SIMD2( 58,  -5), SIMD2( 42,  18), SIMD2( 22,  30), SIMD2(  0,  35),
            SIMD2(-25,  32), SIMD2(-48,  20), SIMD2(-60,  -2), SIMD2(-58, -25),
            SIMD2(-42, -38), SIMD2(-22, -45), SIMD2( -8, -52), SIMD2( -2, -62)
        ])

    static let monaco = TrackLayout(
        id: 1, name: "Monaco", country: "🇲🇨",
        accentColor: UIColor(red: 0.85, green: 0.1, blue: 0.1, alpha: 1),
        trackWidth: 18,
        waypoints: [
            SIMD2(  0, -55), SIMD2( 18, -58), SIMD2( 35, -48), SIMD2( 48, -32),
            SIMD2( 50, -10), SIMD2( 42,  10), SIMD2( 28,  18), SIMD2( 18,  10),
            SIMD2(  8,  20), SIMD2( -4,  35), SIMD2(-22,  45), SIMD2(-42,  38),
            SIMD2(-52,  20), SIMD2(-55,  -2), SIMD2(-50, -22), SIMD2(-38, -35),
            SIMD2(-22, -40), SIMD2( -8, -42), SIMD2(  0, -48)
        ])

    static let spa = TrackLayout(
        id: 2, name: "Spa", country: "🇧🇪",
        accentColor: UIColor(red: 0.95, green: 0.7, blue: 0.0, alpha: 1),
        trackWidth: 22,
        waypoints: [
            SIMD2(  0, -58), SIMD2( 12, -62), SIMD2(  2, -52), SIMD2(-18, -42),
            SIMD2(-28, -20), SIMD2(-30,   5), SIMD2(-22,  28), SIMD2( -2,  38),
            SIMD2( 22,  40), SIMD2( 42,  28), SIMD2( 50,   8), SIMD2( 45, -12),
            SIMD2( 30, -25), SIMD2( 12, -28), SIMD2( -2, -18), SIMD2(-12,  -2),
            SIMD2( -8,  18), SIMD2(  8,  22), SIMD2( 18,  10), SIMD2( 12, -38)
        ])

    static let monza = TrackLayout(
        id: 3, name: "Monza", country: "🇮🇹",
        accentColor: UIColor(red: 0.85, green: 0.05, blue: 0.05, alpha: 1),
        trackWidth: 24,
        waypoints: [
            SIMD2(  0, -62), SIMD2( 32, -60), SIMD2( 48, -52), SIMD2( 42, -38),
            SIMD2( 52, -18), SIMD2( 58,   8), SIMD2( 48,  28), SIMD2( 28,  42),
            SIMD2(  2,  48), SIMD2(-28,  40), SIMD2(-50,  20), SIMD2(-58,  -4),
            SIMD2(-50, -28), SIMD2(-30, -45), SIMD2( -8, -55), SIMD2( 12, -62)
        ])

    static let suzuka = TrackLayout(
        id: 4, name: "Suzuka", country: "🇯🇵",
        accentColor: UIColor(red: 0.95, green: 0.4, blue: 0.0, alpha: 1),
        trackWidth: 20,
        waypoints: [
            SIMD2(  0, -60), SIMD2( 22, -58), SIMD2( 40, -45), SIMD2( 50, -22),
            SIMD2( 42,  -2), SIMD2( 52,  18), SIMD2( 42,  38), SIMD2( 18,  42),
            SIMD2( -5,  30), SIMD2(-22,  18), SIMD2(-30,  -2), SIMD2(-42, -22),
            SIMD2(-45, -42), SIMD2(-30, -55), SIMD2(-10, -62), SIMD2(  8, -55)
        ])
}
