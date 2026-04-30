import SwiftUI

struct RaceStartLights: View {
    let countdown: Int

    private var lightCount: Int { 5 }

    private func isLit(index: Int) -> Bool {
        let cd = max(0, min(3, countdown))
        switch cd {
        case 3: return index < 2
        case 2: return index < 3
        case 1: return index < 5
        case 0: return false
        default: return false
        }
    }

    private func light(at index: Int) -> some View {
        Circle()
            .fill(isLit(index: index)
                  ? Color(red: 0.95, green: 0.10, blue: 0.10)
                  : Color.black.opacity(0.55))
            .frame(width: 28, height: 28)
            .overlay(Circle().stroke(.white.opacity(0.18), lineWidth: 1))
            .shadow(color: isLit(index: index)
                    ? Color.red.opacity(0.6) : .clear,
                    radius: 12)
    }

    private var lightRow: some View {
        HStack(spacing: 8) {
            ForEach(0..<lightCount, id: \.self) { i in
                light(at: i)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 12)
            .fill(Color.black.opacity(0.55)))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(.white.opacity(0.15), lineWidth: 1))
    }

    private var goLabel: some View {
        Text("GO!")
            .font(.system(size: 96, weight: .black, design: .rounded))
            .foregroundStyle(.green)
            .shadow(color: .green, radius: 24)
    }

    var body: some View {
        VStack(spacing: 16) {
            if countdown == 0 {
                goLabel
                    .transition(.scale.combined(with: .opacity))
            } else {
                lightRow
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6),
                   value: countdown)
    }
}
