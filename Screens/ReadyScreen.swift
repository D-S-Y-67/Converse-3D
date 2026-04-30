import SwiftUI

struct ReadyScreen: View {
    let car: CarConfig
    let tread: TreadConfig
    let onGo: () -> Void
    let onBack: () -> Void
    @State private var count = 3
    @State private var timer: Timer?

    private var bg: some View {
        LinearGradient(colors: [Color.black, Color(red: 0.10, green: 0.05, blue: 0.20)],
                       startPoint: .top, endPoint: .bottom)
        .ignoresSafeArea()
    }

    private var backButton: some View {
        Button(action: {
            timer?.invalidate()
            timer = nil
            onBack()
        }) {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(.white)
                .padding(12)
                .background(Circle().fill(.white.opacity(0.15)))
        }
    }

    private var carInfo: some View {
        VStack(spacing: 8) {
            MiniCarIllustration(bodyColor: car.bodyColor, cabinColor: car.cabinColor,
                                width: 140, height: 80)
            Text(car.name.uppercased())
                .font(.system(size: 28, weight: .black))
                .kerning(3)
                .foregroundStyle(.white)
            Text("on \(tread.name) treads")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private var countdownLabel: some View {
        Text(count > 0 ? "\(count)" : "GO!")
            .font(.system(size: 130, weight: .black, design: .rounded))
            .foregroundStyle(count > 0 ? Color(red: 1, green: 0.5, blue: 0.3) : .green)
            .shadow(color: count > 0 ? .orange : .green, radius: 30)
            .id(count)
            .transition(.scale.combined(with: .opacity))
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: count)
    }

    var body: some View {
        ZStack {
            bg
            VStack(spacing: 24) {
                HStack { backButton; Spacer() }
                Spacer()
                carInfo
                Spacer()
                countdownLabel
                Spacer()
            }
            .padding()
        }
        .onAppear {
            count = 3
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if count > 1 { count -= 1 }
                else if count == 1 {
                    count = 0
                } else {
                    timer?.invalidate()
                    timer = nil
                    onGo()
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
}
