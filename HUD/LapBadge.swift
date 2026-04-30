import SwiftUI

struct LapBadge: View {
    let lap: Int
    let total: Int
    let lapTime: Double
    let bestLap: Double

    private var lapLabel: some View {
        Text("LAP \(min(lap+1, total))/\(total)")
            .font(.system(size: 11, weight: .heavy))
            .kerning(1.5)
            .foregroundStyle(.white.opacity(0.7))
    }

    private var timeText: some View {
        Text(formatTime(lapTime))
            .font(.system(size: 18, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .monospacedDigit()
    }

    private var bestText: some View {
        Group {
            if bestLap > 0 {
                Text("Best \(formatTime(bestLap))")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color(red: 1, green: 0.85, blue: 0.3))
                    .monospacedDigit()
            }
        }
    }

    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            lapLabel
            timeText
            bestText
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.18), lineWidth: 1))
    }
}
