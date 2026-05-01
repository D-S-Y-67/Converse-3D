import SwiftUI

struct OnboardingScreen: View {
    @ObservedObject var profile: UserProfile
    let onContinue: () -> Void

    @State private var draftName: String = ""
    @State private var selectedTeam: F1Team = .ferrari
    @FocusState private var nameFocused: Bool

    private var canContinue: Bool {
        !draftName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    nameField
                    teamPicker
                    continueButton
                        .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 28)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            draftName = profile.username
            selectedTeam = profile.favoriteTeam
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Rectangle()
                .fill(selectedTeam.primaryColor)
                .frame(width: 56, height: 3)
            Text("DRIVER REGISTRATION")
                .font(.system(size: 12, weight: .heavy))
                .kerning(3)
                .foregroundStyle(.white.opacity(0.6))
            Text("WELCOME TO\nTHE GRID")
                .font(.system(size: 36, weight: .black))
                .kerning(2)
                .foregroundStyle(.white)
                .lineSpacing(-2)
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DRIVER NAME")
                .font(.system(size: 11, weight: .heavy))
                .kerning(2.5)
                .foregroundStyle(.white.opacity(0.55))
            TextField("", text: $draftName, prompt:
                Text("Enter callsign").foregroundStyle(.white.opacity(0.3)))
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled(true)
                .focused($nameFocused)
                .font(.system(size: 22, weight: .black))
                .kerning(2)
                .foregroundStyle(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(Color.white.opacity(0.06))
                .overlay(Rectangle()
                    .fill(selectedTeam.primaryColor)
                    .frame(height: 2),
                         alignment: .bottom)
        }
    }

    private var teamPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FAVOURITE TEAM")
                .font(.system(size: 11, weight: .heavy))
                .kerning(2.5)
                .foregroundStyle(.white.opacity(0.55))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(),
                                                          spacing: 8),
                                      count: 2),
                      spacing: 8) {
                ForEach(F1Team.allCases) { team in
                    teamRow(team)
                }
            }
        }
    }

    private func teamRow(_ team: F1Team) -> some View {
        let isSelected = team == selectedTeam
        return Button(action: { selectedTeam = team }) {
            HStack(spacing: 10) {
                TeamBadge(team: team, size: 36)
                Text(team.fullName.uppercased())
                    .font(.system(size: 11, weight: .heavy))
                    .kerning(1.2)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
            }
            .padding(8)
            .background(isSelected
                ? Color.white.opacity(0.12)
                : Color.white.opacity(0.04))
            .overlay(Rectangle()
                .fill(isSelected ? team.primaryColor : .clear)
                .frame(width: 3),
                     alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    private var continueButton: some View {
        Button(action: commit) {
            HStack(spacing: 8) {
                Text("ENTER PADDOCK").kerning(3)
                Image(systemName: "arrow.right")
            }
            .font(.system(size: 15, weight: .heavy))
            .foregroundStyle(canContinue ? .black : .white.opacity(0.4))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(canContinue
                ? Color.white
                : Color.white.opacity(0.08))
        }
        .buttonStyle(.plain)
        .disabled(!canContinue)
    }

    private func commit() {
        profile.username = draftName.trimmingCharacters(in: .whitespaces)
        profile.favoriteTeam = selectedTeam
        profile.hasOnboarded = true
        nameFocused = false
        onContinue()
    }
}
