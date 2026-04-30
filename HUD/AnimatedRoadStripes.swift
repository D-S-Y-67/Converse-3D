import SwiftUI

struct AnimatedRoadStripes: View {
    @State private var offset: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<8) { i in
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 6, height: 30)
                        .offset(y: CGFloat(i) * 60 - offset)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                offset = 60
            }
        }
    }
}
