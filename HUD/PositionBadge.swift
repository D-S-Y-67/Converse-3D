import SwiftUI

struct PositionBadge: View {
    let position: Int
    let total: Int

    private var color: Color {
        switch position {
        case 1: return Color(red: 1.0, green: 0.85, blue: 0.25)
        case 2: return Color(white: 0.85)
        case 3: return Color(red: 0.85, green: 0.55, blue: 0.30)
        default: return .white
        }
    }

    private var positionLabel: some View {
        Text("P\(position)")
            .font(.system(size: 22, weight: .heavy, design: .rounded))
            .foregroundStyle(color)
            .monospacedDigit()
    }

    private var totalLabel: some View {
        Text("/ \(total)")
            .font(.system(size: 12, weight: .heavy))
            .foregroundStyle(.white.opacity(0.55))
            .monospacedDigit()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            positionLabel
            totalLabel
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(color.opacity(0.6), lineWidth: 1.2))
    }
}
