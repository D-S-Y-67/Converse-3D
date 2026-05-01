import SwiftUI

struct CarConfig: Identifiable, Equatable {
    let id: Int
    let team: F1Team
    let name: String
    let tagline: String
    let topSpeed: Float
    let acceleration: Float
    let handling: Float
    let unlockScore: Int

    var body: UIColor { team.primary }
    var cabin: UIColor { team.secondary }
    var bodyColor: Color { team.primaryColor }
    var cabinColor: Color { team.secondaryColor }

    static let all: [CarConfig] = [
        CarConfig(id: 0, team: .ferrari,     name: "SF-26",
                  tagline: "Italian thunder, V6 hybrid bite",
                  topSpeed: 78, acceleration: 42, handling: 1.9, unlockScore: 0),
        CarConfig(id: 1, team: .mercedes,    name: "W17",
                  tagline: "Silver Arrow precision in every apex",
                  topSpeed: 76, acceleration: 41, handling: 2.1, unlockScore: 0),
        CarConfig(id: 2, team: .mclaren,     name: "MCL40",
                  tagline: "Papaya pace through the corners",
                  topSpeed: 77, acceleration: 42, handling: 2.0, unlockScore: 0),
        CarConfig(id: 3, team: .redBull,     name: "RB22",
                  tagline: "Energy drink rocketship",
                  topSpeed: 79, acceleration: 43, handling: 1.9, unlockScore: 0),
        CarConfig(id: 4, team: .astonMartin, name: "AMR26",
                  tagline: "British racing green, sharper than ever",
                  topSpeed: 74, acceleration: 39, handling: 2.2, unlockScore: 0),
        CarConfig(id: 5, team: .alpine,      name: "A526",
                  tagline: "French flair, pink-and-blue rhythm",
                  topSpeed: 72, acceleration: 38, handling: 2.1, unlockScore: 0),
        CarConfig(id: 6, team: .williams,    name: "FW48",
                  tagline: "Grove resurgence in deep blue",
                  topSpeed: 73, acceleration: 38, handling: 2.0, unlockScore: 0),
        CarConfig(id: 7, team: .haas,        name: "VF-26",
                  tagline: "American grit on the grid",
                  topSpeed: 71, acceleration: 37, handling: 1.9, unlockScore: 0),
        CarConfig(id: 8, team: .racingBulls, name: "VCARB02",
                  tagline: "Faenza's feisty junior squad",
                  topSpeed: 73, acceleration: 39, handling: 2.0, unlockScore: 0),
        CarConfig(id: 9, team: .audi,        name: "R26",
                  tagline: "Four rings storm the paddock",
                  topSpeed: 75, acceleration: 40, handling: 2.0, unlockScore: 0),
        CarConfig(id: 10, team: .cadillac,   name: "GMC-01",
                  tagline: "Detroit muscle, F1 attitude",
                  topSpeed: 74, acceleration: 39, handling: 1.9, unlockScore: 0)
    ]

    static func config(for team: F1Team) -> CarConfig {
        all.first(where: { $0.team == team }) ?? all[0]
    }

    static func index(for team: F1Team) -> Int {
        all.firstIndex(where: { $0.team == team }) ?? 0
    }
}
