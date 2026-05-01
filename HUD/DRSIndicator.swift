import SwiftUI

struct DRSIndicator: View {
    let active: Bool
    let available: Bool

    private var statusText: String {
        if active { return "DRS OPEN" }
        if available { return "DRS ARMED" }
        return "DRS"
    }

    private var statusColor: Color {
        if active { return Color(red: 0.20, green: 0.95, blue: 0.30) }
        if available { return Color(red: 0.95, green: 0.85, blue: 0.20) }
        return Color.white.opacity(0.45)
    }

    private var iconView: some View {
        Image(systemName: active ? "arrow.up.to.line"
                                 : "minus.circle")
            .font(.system(size: 16, weight: .heavy))
            .foregroundStyle(statusColor)
    }

    private var label: some View {
        Text(statusText)
            .font(.system(size: 12, weight: .black))
            .kerning(2)
            .foregroundStyle(statusColor)
    }

    var body: some View {
        HStack(spacing: 8) {
            iconView
            label
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(statusColor.opacity(0.55), lineWidth: 1.4))
    }
}
