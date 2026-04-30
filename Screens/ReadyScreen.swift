import SwiftUI

struct ReadyScreen: View {
    let car: CarConfig
    let tread: TreadConfig
    let track: TrackLayout
    let onGo: () -> Void
    let onBack: () -> Void

    private var bg: some View {
        LinearGradient(colors: [
            Color.black,
            Color(red: 0.10, green: 0.05, blue: 0.20)
        ], startPoint: .top, endPoint: .bottom)
        .ignoresSafeArea()
    }

    private var backButton: some View {
        Button(action: onBack) {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(.white)
                .padding(12)
                .background(Circle().fill(.white.opacity(0.15)))
        }
    }

    private var trackPreview: some View {
        VStack(spacing: 6) {
            TrackSilhouette(waypoints: track.waypoints,
                            accent: Color(track.accentColor))
                .frame(width: 200, height: 130)
            HStack(spacing: 6) {
                Text(track.country).font(.system(size: 18))
                Text(track.name.uppercased())
                    .font(.system(size: 22, weight: .black))
                    .kerning(2.5)
                    .foregroundStyle(.white)
            }
        }
    }

    private var carInfo: some View {
        VStack(spacing: 4) {
            MiniCarIllustration(bodyColor: car.bodyColor,
                                cabinColor: car.cabinColor,
                                width: 130, height: 70)
            Text(car.name.uppercased())
                .font(.system(size: 22, weight: .black))
                .kerning(2.5)
                .foregroundStyle(.white)
            Text("\(tread.name) compound · 3 laps")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private var startButton: some View {
        Button(action: onGo) {
            HStack(spacing: 10) {
                Image(systemName: "flag.checkered.2.crossed")
                Text("TO THE GRID").kerning(2)
            }
            .font(.system(size: 18, weight: .heavy))
            .foregroundStyle(.black)
            .padding(.horizontal, 50)
            .padding(.vertical, 16)
            .background(Capsule().fill(.white))
            .shadow(color: .white.opacity(0.4), radius: 14)
        }
    }

    var body: some View {
        ZStack {
            bg
            VStack(spacing: 24) {
                HStack { backButton; Spacer() }
                Spacer()
                trackPreview
                carInfo
                Spacer()
                startButton
                    .padding(.bottom, 20)
            }
            .padding()
        }
    }
}
