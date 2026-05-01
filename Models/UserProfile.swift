import SwiftUI

final class UserProfile: ObservableObject {
    static let shared = UserProfile()

    @AppStorage("profile.username") var username: String = ""
    @AppStorage("profile.favoriteTeam") var favoriteTeamRaw: String = F1Team.ferrari.rawValue
    @AppStorage("profile.hasOnboarded") var hasOnboarded: Bool = false

    var favoriteTeam: F1Team {
        get { F1Team(rawValue: favoriteTeamRaw) ?? .ferrari }
        set { favoriteTeamRaw = newValue.rawValue }
    }
}
