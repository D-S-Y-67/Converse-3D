import SwiftUI
import simd

struct TrackCard: View {
    let layout: TrackLayout
    let selected: Bool
    let onTap: () -> Void

    private var silhouette: some View {
        TrackSilhouette(waypoints: layout.waypoints,
                        accent: Color(layout.accentColor))
            .frame(width: 120, height: 80)
    }

    private var infoStack: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(layout.country).font(.system(size: 16))
                Text(layout.name.uppercased())
                    .font(.system(size: 18, weight: .heavy))
                    .kerning(1.5)
                    .foregroundStyle(.white)
            }
            Text("\(layout.lapCount) laps · width \(Int(layout.trackWidth))")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.65))
            HStack(spacing: 4) {
                Image(systemName: "speedometer")
                    .font(.system(size: 9, weight: .bold))
                Text("Length \(Int(layout.totalLength))u")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(Color(layout.accentColor))
        }
    }

    private var checkmark: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 24))
            .foregroundStyle(.green)
    }

    private var cardBg: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(selected ? Color.white.opacity(0.18)
                           : Color.white.opacity(0.08))
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(selected ? Color.white : Color.white.opacity(0.15),
                    lineWidth: selected ? 2 : 1)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                silhouette
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

struct TrackSilhouette: View {
    let waypoints: [SIMD2<Float>]
    let accent: Color

    var body: some View {
        GeometryReader { geo in
            let bounds = computeBounds()
            let path = buildPath(in: geo.size, bounds: bounds)
            ZStack {
                path.stroke(Color.white.opacity(0.18), lineWidth: 8)
                path.stroke(accent, lineWidth: 3)
                if let p = startPoint(in: geo.size, bounds: bounds) {
                    Circle().fill(.white)
                        .frame(width: 6, height: 6)
                        .position(p)
                }
            }
        }
    }

    private func computeBounds() -> (min: SIMD2<Float>, max: SIMD2<Float>) {
        var minP = SIMD2<Float>(Float.greatestFiniteMagnitude,
                                Float.greatestFiniteMagnitude)
        var maxP = SIMD2<Float>(-Float.greatestFiniteMagnitude,
                                -Float.greatestFiniteMagnitude)
        for p in waypoints {
            minP = simd_min(minP, p)
            maxP = simd_max(maxP, p)
        }
        return (minP, maxP)
    }

    private func mapToView(_ p: SIMD2<Float>, size: CGSize,
                           bounds: (min: SIMD2<Float>, max: SIMD2<Float>))
    -> CGPoint {
        let pad: CGFloat = 8
        let w = size.width - pad * 2
        let h = size.height - pad * 2
        let bw = max(0.001, bounds.max.x - bounds.min.x)
        let bh = max(0.001, bounds.max.y - bounds.min.y)
        let nx = CGFloat((p.x - bounds.min.x) / bw)
        let ny = CGFloat((p.y - bounds.min.y) / bh)
        return CGPoint(x: pad + nx * w, y: pad + ny * h)
    }

    private func buildPath(in size: CGSize,
                           bounds: (min: SIMD2<Float>, max: SIMD2<Float>))
    -> Path {
        var p = Path()
        let n = 96
        var first: CGPoint? = nil
        for i in 0..<n {
            let t = Float(i) / Float(n)
            let pt = TrackLayout.evaluate(waypoints: waypoints, t: t)
            let cgp = mapToView(pt, size: size, bounds: bounds)
            if first == nil { first = cgp; p.move(to: cgp) }
            else { p.addLine(to: cgp) }
        }
        if let f = first { p.addLine(to: f) }
        return p
    }

    private func startPoint(in size: CGSize,
                            bounds: (min: SIMD2<Float>, max: SIMD2<Float>))
    -> CGPoint? {
        guard !waypoints.isEmpty else { return nil }
        return mapToView(waypoints[0], size: size, bounds: bounds)
    }
}
