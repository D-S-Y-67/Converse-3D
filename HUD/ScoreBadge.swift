import SwiftUI

struct ScoreBadge: View {
    let score: Int

    private var coinIcon: some View {
        Circle().fill(LinearGradient(colors: [
            Color(red: 1, green: 0.92, blue: 0.4),
            Color(red: 0.95, green: 0.65, blue: 0.1)
        ], startPoint: .top, endPoint: .bottom))
        .frame(width: 22, height: 22)
    }

    private var scoreText: some View {
        Text("\(score)")
            .font(.system(size: 22, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .monospacedDigit()
    }

    var body: some View {
        HStack(spacing: 8) {
            coinIcon
            scoreText
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.18), lineWidth: 1))
    }
}
