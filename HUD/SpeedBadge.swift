import SwiftUI

struct SpeedBadge: View {
    let speed: Float
    var kmh: Int { Int(speed * 3.6) }

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
