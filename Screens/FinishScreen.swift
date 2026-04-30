import SwiftUI

struct FinishScreen: View {
    let score: Int
    let bestLap: Double
    let onRestart: () -> Void
    let onMenu: () -> Void

    private var medal: (name: String, color: Color, icon: String) {
        if score >= 30 {
            return ("GOLD", Color(red: 1, green: 0.85, blue: 0.3), "trophy.fill")
        } else if score >= 15 {
            return ("SILVER", Color(white: 0.8), "rosette")
        } else {
            return ("BRONZE", Color(red: 0.8, green: 0.5, blue: 0.3), "medal.fill")
        }
    }

    private var trophyIcon: some View {
        Image(systemName: medal.icon)
            .font(.system(size: 70))
            .foregroundStyle(medal.color)
            .shadow(color: medal.color, radius: 20)
    }

    private var medalLabel: some View {
        Text(medal.name)
            .font(.system(size: 14, weight: .black))
            .kerning(3)
            .foregroundStyle(medal.color)
    }

    private var titleText: some View {
        Text("RACE COMPLETE")
            .font(.system(size: 26, weight: .black))
            .kerning(3)
            .foregroundStyle(.white)
    }

    private var statsCard: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Coins").foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text("\(score)").foregroundStyle(.white).monospacedDigit()
            }
            HStack {
                Text("Best lap").foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text(formatTime(bestLap)).foregroundStyle(.white).monospacedDigit()
            }
        }
        .font(.system(size: 16, weight: .bold))
        .padding(20)
        .frame(maxWidth: 280)
        .background(RoundedRectangle(cornerRadius: 16).fill(.white.opacity(0.1)))
    }

    private var menuButton: some View {
        Button(action: onMenu) {
            Text("MENU").kerning(2)
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(.white)
                .padding(.horizontal, 30).padding(.vertical, 14)
                .background(Capsule().fill(.white.opacity(0.15)))
        }
    }

    private var restartButton: some View {
        Button(action: onRestart) {
            Text("RACE AGAIN").kerning(2)
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(.black)
                .padding(.horizontal, 30).padding(.vertical, 14)
                .background(Capsule().fill(.white))
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            VStack(spacing: 18) {
                trophyIcon
                medalLabel
                titleText
                statsCard
                HStack(spacing: 14) {
                    menuButton
                    restartButton
                }
            }
            .padding()
        }
    }
}
