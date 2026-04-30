import SwiftUI

struct ControlButton: View {
    let symbol: String
    let tint: Color
    @Binding var isPressed: Bool

    private var iconView: some View {
        Image(systemName: symbol)
            .font(.system(size: 30, weight: .heavy))
            .foregroundStyle(.white)
    }

    private var background: some View {
        Circle()
            .fill(.ultraThinMaterial)
            .overlay(Circle().stroke(tint.opacity(0.6), lineWidth: 2))
    }

    var body: some View {
        iconView
            .frame(width: 72, height: 72)
            .background(background)
            .scaleEffect(isPressed ? 0.88 : 1)
            .opacity(isPressed ? 0.7 : 1)
            .shadow(color: tint.opacity(isPressed ? 0.6 : 0.2), radius: 10)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
            .contentShape(Circle())
            .onLongPressGesture(minimumDuration: 0,
                                maximumDistance: .infinity,
                                perform: {},
                                onPressingChanged: { isPressed = $0 })
    }
}
