import SwiftUI

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
