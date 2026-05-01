import SwiftUI

struct TeamBadge: View {
    let team: F1Team
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                .fill(team.primaryColor)

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                Text(team.abbrev)
                    .font(.system(size: size * 0.34,
                                  weight: .black,
                                  design: .default))
                    .kerning(1.5)
                    .foregroundStyle(textColor)
                Spacer(minLength: 0)
                Rectangle()
                    .fill(team.secondaryColor)
                    .frame(height: max(2, size * 0.08))
            }
            .clipShape(RoundedRectangle(cornerRadius: size * 0.18,
                                        style: .continuous))
        }
        .frame(width: size * 1.4, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
    }

    private var textColor: Color {
        let p = team.primary
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        p.getRed(&r, green: &g, blue: &b, alpha: &a)
        let luma = 0.299 * r + 0.587 * g + 0.114 * b
        return luma > 0.65 ? .black : .white
    }
}
