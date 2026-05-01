import SwiftUI

struct TreadSelectScreen: View {
    @Binding var selected: Int
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
        }
    }

    private var title: some View {
        VStack(spacing: 4) {
            Text("CHOOSE YOUR TREADS")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .kerning(2).foregroundStyle(.white)
            Text("Treads change grip and feel")
                .font(.system(size: 12)).foregroundStyle(.white.opacity(0.6))
        }
    }

    private var list: some View {
        VStack(spacing: 14) {
            ForEach(TreadConfig.all) { tread in
                row(tread)
            }
        }
    }

    @ViewBuilder
    private func row(_ tread: TreadConfig) -> some View {
        let isSelected = selected == tread.id
        TreadCard(
            tread: tread,
            selected: isSelected,
            onTap: { selected = tread.id }
        )
    }

    private var footerButton: some View {
        Button(action: onNext) {
            HStack(spacing: 10) {
                Text("PICK CIRCUIT").kerning(2)
                Image(systemName: "flag.checkered")
                    .font(.system(size: 16, weight: .heavy))
            }
            .font(.system(size: 17, weight: .heavy))
            .foregroundStyle(.black)
            .padding(.horizontal, 50).padding(.vertical, 16)
            .background(Capsule().fill(.white))
        }
    }
}

struct TreadCard: View {
    let tread: TreadConfig
    let selected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                wheelIcon
                info
                Spacer()
                if selected { check }
            }
            .padding(14)
            .background(cardBg)
            .overlay(cardBorder)
        }
        .buttonStyle(.plain)
    }

    private var wheelIcon: some View {
        ZStack {
            Circle().fill(tread.swiftColor).frame(width: 56, height: 56)
            Circle().stroke(Color.white.opacity(0.3), lineWidth: 2)
                .frame(width: 56, height: 56)
            Circle().fill(Color.white.opacity(0.15)).frame(width: 28, height: 28)
            Circle().fill(Color.white.opacity(0.25)).frame(width: 12, height: 12)
        }
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(tread.name.uppercased())
                .font(.system(size: 17, weight: .heavy)).kerning(1.5)
                .foregroundStyle(.white)
            Text(tread.description)
                .font(.system(size: 12)).foregroundStyle(.white.opacity(0.7))
            gripLine
        }
    }

    private var gripLine: some View {
        let gripStr = String(format: "%.2fx", tread.gripBonus)
        return HStack(spacing: 4) {
            Image(systemName: "scope").font(.system(size: 9))
            Text("Grip \(gripStr)")
        }
        .font(.system(size: 10, weight: .bold)).foregroundStyle(.cyan)
    }

    private var check: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 24)).foregroundStyle(.green)
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
}
