import SwiftUI

struct CarSelectScreen: View {
    @Binding var selected: Int
    let bestScore: Int
    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                topBar
                title
                list
                footerButton
            }
            .padding(20)
        }
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
            bestBadge
        }
    }

    private var bestBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "trophy.fill").foregroundStyle(.yellow)
            Text("Best: \(bestScore)").foregroundStyle(.white)
        }
        .font(.system(size: 12, weight: .bold))
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Capsule().fill(.white.opacity(0.1)))
    }

    private var title: some View {
        VStack(spacing: 4) {
            Text("CHOOSE YOUR CAR")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .kerning(2).foregroundStyle(.white)
            Text("Each car has different stats")
                .font(.system(size: 12)).foregroundStyle(.white.opacity(0.6))
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(CarConfig.all) { car in
                    row(car)
                }
            }
        }
    }

    @ViewBuilder
    private func row(_ car: CarConfig) -> some View {
        let isLocked = car.unlockScore > bestScore
        CarCard(
            car: car,
            selected: selected == car.id,
            locked: isLocked,
            onTap: {
                if !isLocked { selected = car.id }
            }
        )
    }

    private var footerButton: some View {
        Button(action: onNext) {
            HStack(spacing: 10) {
                Text("NEXT").kerning(2)
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .heavy))
            }
            .font(.system(size: 17, weight: .heavy))
            .foregroundStyle(.black)
            .padding(.horizontal, 50).padding(.vertical, 16)
            .background(Capsule().fill(.white))
        }
    }
}

struct CarCard: View {
    let car: CarConfig
    let selected: Bool
    let locked: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                preview
                info
                Spacer()
                if selected { check }
            }
            .padding(12)
            .background(cardBg)
            .overlay(cardBorder)
            .opacity(locked ? 0.55 : 1)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var preview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .frame(width: 130, height: 78)
            if locked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.6))
            } else {
                MiniCarIllustration(bodyColor: car.bodyColor,
                                    cabinColor: car.cabinColor)
            }
        }
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(car.name.uppercased())
                .font(.system(size: 18, weight: .heavy)).kerning(1.5)
                .foregroundStyle(.white)
            taglineOrLock
        }
    }

    @ViewBuilder
    private var taglineOrLock: some View {
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

    private var check: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 24)).foregroundStyle(.green)
    }

    private var cardBg: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(selected ? Color.white.opacity(0.18)
                           : Color.white.opacity(0.08))
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(selected ? Color.white : Color.white.opacity(0.15),
                    lineWidth: selected ? 2 : 1)
    }
}
