import SwiftUI

struct FinishScreen: View {
    let position: Int
    let totalTime: Double
    let bestLap: Double
    let trackName: String
    let results: [RaceResult]
    let onRestart: () -> Void
    let onMenu: () -> Void

    private var medal: (name: String, color: Color, icon: String) {
        switch position {
        case 1: return ("WINNER", Color(red: 1, green: 0.85, blue: 0.3),
                        "trophy.fill")
        case 2: return ("PODIUM",  Color(white: 0.85), "rosette")
        case 3: return ("PODIUM",  Color(red: 0.85, green: 0.55, blue: 0.30),
                        "medal.fill")
        default: return ("FINISHED", Color(white: 0.7), "flag.checkered")
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
        VStack(spacing: 4) {
            Text("P\(position)")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text(trackName.uppercased())
                .font(.system(size: 13, weight: .heavy))
                .kerning(3)
                .foregroundStyle(.white.opacity(0.55))
        }
    }

    private var statsCard: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Race time").foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text(formatTime(totalTime)).foregroundStyle(.white)
                    .monospacedDigit()
            }
            HStack {
                Text("Best lap").foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text(formatTime(bestLap)).foregroundStyle(.white)
                    .monospacedDigit()
            }
        }
        .font(.system(size: 16, weight: .bold))
        .padding(20)
        .frame(maxWidth: 320)
        .background(RoundedRectangle(cornerRadius: 16)
            .fill(.white.opacity(0.10)))
    }

    private var resultsTable: some View {
        VStack(spacing: 6) {
            ForEach(results) { r in
                HStack(spacing: 10) {
                    Text(formatPosition(r.position))
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(positionColor(r.position))
                        .frame(width: 32, alignment: .leading)
                    Circle().fill(r.color).frame(width: 10, height: 10)
                    Text(r.name)
                        .font(.system(size: 13,
                                      weight: r.isPlayer ? .black : .semibold))
                        .foregroundStyle(r.isPlayer ? .white
                                                    : .white.opacity(0.78))
                    Spacer()
                    if r.bestLap > 0 {
                        Text(formatTime(r.bestLap))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.55))
                            .monospacedDigit()
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 10)
                    .fill(r.isPlayer ? Color.white.opacity(0.16)
                                     : Color.white.opacity(0.05)))
            }
        }
        .frame(maxWidth: 360)
    }

    private func positionColor(_ p: Int) -> Color {
        switch p {
        case 1: return Color(red: 1.0, green: 0.85, blue: 0.25)
        case 2: return Color(white: 0.85)
        case 3: return Color(red: 0.85, green: 0.55, blue: 0.30)
        default: return Color.white.opacity(0.55)
        }
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
            Color.black.opacity(0.88).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    trophyIcon
                    medalLabel
                    titleText
                    statsCard
                    resultsTable
                    HStack(spacing: 14) {
                        menuButton
                        restartButton
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
        }
    }
}
