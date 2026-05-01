import SwiftUI

struct SplashScreen: View {
    let onStart: () -> Void
    let bestScore: Int
    @State private var pulse = false

    private var bgGradient: some View {
        Color.black.ignoresSafeArea()
    }

    private var teamAccent: Color {
        UserProfile.shared.favoriteTeam.primaryColor
    }

    private var carIcon: some View {
        Image(systemName: "car.side.fill")
            .font(.system(size: 80, weight: .heavy))
            .foregroundStyle(teamAccent)
            .scaleEffect(pulse ? 1.05 : 1)
            .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true),
                       value: pulse)
    }

    private var titleStack: some View {
        VStack(spacing: 6) {
            Rectangle().fill(teamAccent)
                .frame(width: 80, height: 3)
            Text("APEX")
                .font(.system(size: 56, weight: .black))
                .kerning(8)
                .foregroundStyle(.white)
            Text("FORMULA RACING")
                .font(.system(size: 12, weight: .heavy))
                .kerning(5)
                .foregroundStyle(.white.opacity(0.55))
        }
    }

    private var startButton: some View {
        Button(action: onStart) {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                    .font(.system(size: 18, weight: .heavy))
                Text("START").kerning(2)
                    .font(.system(size: 18, weight: .heavy))
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 50)
            .padding(.vertical, 18)
            .background(Capsule().fill(.white))
            .shadow(color: .white.opacity(0.4), radius: 16)
        }
    }

    private var bestScoreBadge: some View {
        Group {
            if bestScore > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(.yellow)
                    Text("Best: \(bestScore)")
                        .foregroundStyle(.white)
                }
                .font(.system(size: 13, weight: .bold))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Capsule().fill(.white.opacity(0.1)))
            }
        }
    }

    private var hintText: some View {
        Text("HOLD GAS · STEER · DRS ON STRAIGHTS")
            .font(.system(size: 10, weight: .bold))
            .kerning(2)
            .foregroundStyle(.white.opacity(0.4))
            .padding(.bottom, 30)
    }

    var body: some View {
        ZStack {
            bgGradient
            AnimatedRoadStripes()
                .opacity(0.8)

            VStack(spacing: 30) {
                Spacer()
                carIcon
                titleStack
                bestScoreBadge
                Spacer()
                startButton
                hintText
            }
            .padding()
        }
        .onAppear { pulse = true }
    }
}
