import SwiftUI

struct TreadSelectScreen: View {
    @Binding var selected: Int
    let onNext: () -> Void
    let onBack: () -> Void

    private var bg: some View {
        Color.black.ignoresSafeArea()
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
                .kerning(2)
                .foregroundStyle(.white)
            Text("Treads change grip and feel")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private var treadList: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(TreadConfig.all) { tread in
                    TreadCard(tread: tread,
                              selected: selected == tread.id,
                              onTap: { selected = tread.id })
                }
            }
        }
    }

    private var readyButton: some View {
        Button(action: onNext) {
            HStack(spacing: 10) {
                Text("PICK CIRCUIT").kerning(2)
                Image(systemName: "flag.checkered")
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
                treadList
                readyButton
            }
            .padding(20)
        }
    }
}

struct TreadCard: View {
    let tread: TreadConfig
    let selected: Bool
    let onTap: () -> Void

    private var wheelIcon: some View {
        ZStack {
            Circle().fill(tread.swiftColor)
                .frame(width: 56, height: 56)
            Circle().stroke(Color.white.opacity(0.3), lineWidth: 2)
                .frame(width: 56, height: 56)
            Circle().fill(Color.white.opacity(0.15))
                .frame(width: 28, height: 28)
            Circle().fill(Color.white.opacity(0.25))
                .frame(width: 12, height: 12)
        }
    }

    private var nameText: some View {
        Text(tread.name.uppercased())
            .font(.system(size: 17, weight: .heavy))
            .kerning(1.5)
            .foregroundStyle(.white)
    }

    private var descText: some View {
        Text(tread.description)
            .font(.system(size: 12))
            .foregroundStyle(.white.opacity(0.7))
    }

    private var gripText: some View {
        let gripStr = String(format: "%.2fx", tread.gripBonus)
        return HStack(spacing: 4) {
            Image(systemName: "scope").font(.system(size: 9))
            Text("Grip \(gripStr)")
        }
        .font(.system(size: 10, weight: .bold))
        .foregroundStyle(.cyan)
    }

    private var infoStack: some View {
        VStack(alignment: .leading, spacing: 3) {
            nameText
            descText
            gripText
        }
    }

    private var checkmark: some View {
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
            HStack(spacing: 14) {
                wheelIcon
                infoStack
                Spacer()
                if selected { checkmark }
            }
            .padding(14)
            .background(cardBg)
            .overlay(cardBorder)
        }
        .buttonStyle(.plain)
    }
}
