import SwiftUI

struct CarSelectScreen: View {
    @Binding var selected: Int
    let bestScore: Int
    let onNext: () -> Void
    let onBack: () -> Void

    private var bg: some View {
        LinearGradient(colors: [
            Color(red: 0.05, green: 0.08, blue: 0.18),
            Color(red: 0.10, green: 0.18, blue: 0.30)
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
            HStack(spacing: 6) {
                Image(systemName: "trophy.fill").foregroundStyle(.yellow)
                Text("Best: \(bestScore)")
                    .foregroundStyle(.white)
            }
            .font(.system(size: 12, weight: .bold))
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(Capsule().fill(.white.opacity(0.1)))
        }
    }

    private var title: some View {
        VStack(spacing: 4) {
            Text("CHOOSE YOUR CAR")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .kerning(2)
                .foregroundStyle(.white)
            Text("Each car has different stats")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private var carList: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(CarConfig.all) { car in
                    CarCard(car: car,
                            selected: selected == car.id,
                            locked: car.unlockScore > bestScore,
                            onTap: {
                        if car.unlockScore <= bestScore { selected = car.id }
                    })
                }
            }
        }
    }

    private var nextButton: some View {
        Button(action: onNext) {
            HStack(spacing: 10) {
                Text("NEXT").kerning(2)
                Image(systemName: "chevron.right")
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
                carList
                nextButton
            }
            .padding(20)
        }
    }
}

struct CarCard: View {
    let car: CarConfig
    let selected: Bool
    let locked: Bool
    let onTap: () -> Void

    private var carPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(colors: [
                    Color.white.opacity(0.05),
                    Color.black.opacity(0.2)
                ], startPoint: .top, endPoint: .bottom))
                .frame(width: 130, height: 78)
            if locked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.6))
            } else {
                MiniCarIllustration(bodyColor: car.bodyColor, cabinColor: car.cabinColor)
            }
        }
    }

    private var nameLine: some View {
        Text(car.name.uppercased())
            .font(.system(size: 18, weight: .heavy))
            .kerning(1.5)
            .foregroundStyle(.white)
    }

    private var taglineOrLock: some View {
        Group {
            if locked {
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill").font(.system(size: 10))
                    Text("\(car.unlockScore) reputation to unlock")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(.orange)
            } else {
                Text(car.tagline)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(2)
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 8) {
            StatBar(label: "SPD", value: (car.topSpeed - 50) / 30)
            StatBar(label: "ACC", value: (car.acceleration - 28) / 18)
            StatBar(label: "HND", value: (2.6 - car.handling) / 0.9)
        }
    }

    private var infoStack: some View {
        VStack(alignment: .leading, spacing: 5) {
            nameLine
            taglineOrLock
            if !locked {
                statsRow.padding(.top, 2)
            }
        }
    }

    private var checkBadge: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 24))
            .foregroundStyle(.green)
    }

    private var cardBg: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(selected ? Color.white.opacity(0.18) : Color.white.opacity(0.08))
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(selected ? Color.white : Color.white.opacity(0.15),
                    lineWidth: selected ? 2 : 1)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                carPreview
                infoStack
                Spacer()
                if selected { checkBadge }
            }
            .padding(12)
            .background(cardBg)
            .overlay(cardBorder)
            .opacity(locked ? 0.55 : 1)
        }
        .buttonStyle(.plain)
    }
}

struct StatBar: View {
    let label: String
    let value: Float
    var clamped: Float { max(0, min(1, value)) }

    private var labelText: some View {
        Text(label)
            .font(.system(size: 8, weight: .black))
            .foregroundStyle(.white.opacity(0.6))
            .kerning(0.5)
    }

    private var bar: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(Color.white.opacity(0.15))
                .frame(width: 50, height: 4)
            Capsule().fill(LinearGradient(colors: [.cyan, .blue],
                                          startPoint: .leading,
                                          endPoint: .trailing))
            .frame(width: CGFloat(50 * clamped), height: 4)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            labelText
            bar
        }
    }
}
