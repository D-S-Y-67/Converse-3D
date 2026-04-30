import SwiftUI

struct TrackSelectScreen: View {
    @Binding var selected: Int
    let onNext: () -> Void
    let onBack: () -> Void

    private var bg: some View {
        LinearGradient(colors: [
            Color(red: 0.05, green: 0.08, blue: 0.18),
            Color(red: 0.18, green: 0.05, blue: 0.20)
        ], startPoint: .top, endPoint: .bottom)
        .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Circle().fill(.white.opacity(0.15)))
            }
            Spacer()
        }
    }

    private var title: some View {
        VStack(spacing: 4) {
            Text("CHOOSE YOUR CIRCUIT")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .kerning(2)
                .foregroundStyle(.white)
            Text("Five iconic Grand Prix layouts")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private var trackList: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(TrackLayout.all) { layout in
                    TrackCard(layout: layout,
                              selected: selected == layout.id,
                              onTap: { selected = layout.id })
                }
            }
        }
    }

    private var startButton: some View {
        Button(action: onNext) {
            HStack(spacing: 10) {
                Text("LIGHTS OUT").kerning(2)
                Image(systemName: "flag.checkered.2.crossed")
                    .font(.system(size: 16, weight: .heavy))
            }
            .font(.system(size: 17, weight: .heavy))
            .foregroundStyle(.black)
            .padding(.horizontal, 50)
            .padding(.vertical, 16)
            .background(Capsule().fill(.white))
        }
    }

    var body: some View {
        ZStack {
            bg
            VStack(spacing: 16) {
                topBar
                title
                trackList
                startButton
            }
            .padding(20)
        }
    }
}
