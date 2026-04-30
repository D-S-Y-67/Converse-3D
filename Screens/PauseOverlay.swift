import SwiftUI

struct PauseOverlay: View {
    let onResume: () -> Void
    let onMenu: () -> Void

    private var titleText: some View {
        Text("PAUSED")
            .font(.system(size: 28, weight: .black))
            .kerning(4)
            .foregroundStyle(.white)
    }

    private var resumeButton: some View {
        Button(action: onResume) {
            HStack {
                Image(systemName: "play.fill")
                Text("RESUME").kerning(2)
            }
            .font(.system(size: 16, weight: .heavy))
            .foregroundStyle(.black)
            .padding(.horizontal, 36).padding(.vertical, 14)
            .background(Capsule().fill(.white))
        }
    }

    private var menuButton: some View {
        Button(action: onMenu) {
            HStack {
                Image(systemName: "house.fill")
                Text("MAIN MENU").kerning(2)
            }
            .font(.system(size: 14, weight: .heavy))
            .foregroundStyle(.white)
            .padding(.horizontal, 30).padding(.vertical, 12)
            .background(Capsule().fill(.white.opacity(0.15)))
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            VStack(spacing: 18) {
                titleText
                resumeButton
                menuButton
            }
        }
    }
}
