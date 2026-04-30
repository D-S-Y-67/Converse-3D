import SwiftUI

struct MiniCarIllustration: View {
    let bodyColor: Color
    let cabinColor: Color
    var width: CGFloat = 110
    var height: CGFloat = 60

    var bodyShape: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(bodyColor)
            .frame(width: width, height: height * 0.55)
    }

    var cabinShape: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(cabinColor)
            .frame(width: width * 0.55, height: height * 0.4)
            .offset(y: -height * 0.25)
    }

    var headlight: some View {
        Circle().fill(Color.yellow.opacity(0.9))
            .frame(width: 6, height: 6)
            .offset(x: width * 0.42, y: 0)
    }

    var wheels: some View {
        HStack(spacing: width * 0.45) {
            Circle().fill(Color.black).frame(width: 14, height: 14)
            Circle().fill(Color.black).frame(width: 14, height: 14)
        }
        .offset(y: height * 0.25)
    }

    var body: some View {
        ZStack {
            wheels
            bodyShape
            cabinShape
            headlight
        }
        .frame(width: width, height: height)
    }
}
