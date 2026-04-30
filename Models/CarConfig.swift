import SwiftUI

struct CarConfig: Identifiable, Equatable {
    let id: Int
    let name: String
    let tagline: String
    let body: UIColor
    let cabin: UIColor
    let topSpeed: Float
    let acceleration: Float
    let handling: Float
    let unlockScore: Int

    var bodyColor: Color { Color(body) }
    var cabinColor: Color { Color(cabin) }

    static let all: [CarConfig] = [
        CarConfig(id: 0, name: "Ember",   tagline: "Balanced rookie machine, easy to learn",
                  body: UIColor(red: 0.86, green: 0.16, blue: 0.18, alpha: 1),
                  cabin: UIColor(red: 0.10, green: 0.16, blue: 0.24, alpha: 1),
                  topSpeed: 58, acceleration: 32, handling: 2.2, unlockScore: 0),
        CarConfig(id: 1, name: "Glacier", tagline: "Sharper turn-in, smooth on cold tarmac",
                  body: UIColor(red: 0.20, green: 0.55, blue: 0.95, alpha: 1),
                  cabin: UIColor(red: 0.05, green: 0.10, blue: 0.18, alpha: 1),
                  topSpeed: 62, acceleration: 33, handling: 2.5, unlockScore: 1),
        CarConfig(id: 2, name: "Mantis",  tagline: "Punchy mid-pack, eager to corner",
                  body: UIColor(red: 0.40, green: 0.85, blue: 0.30, alpha: 1),
                  cabin: UIColor(red: 0.10, green: 0.20, blue: 0.10, alpha: 1),
                  topSpeed: 65, acceleration: 36, handling: 2.0, unlockScore: 3),
        CarConfig(id: 3, name: "Solar",   tagline: "Big top end, demands precision",
                  body: UIColor(red: 1.00, green: 0.78, blue: 0.10, alpha: 1),
                  cabin: UIColor(red: 0.18, green: 0.12, blue: 0.05, alpha: 1),
                  topSpeed: 70, acceleration: 38, handling: 1.9, unlockScore: 5),
        CarConfig(id: 4, name: "Phantom", tagline: "Pure pace for podium contenders",
                  body: UIColor(red: 0.10, green: 0.10, blue: 0.14, alpha: 1),
                  cabin: UIColor(red: 0.55, green: 0.15, blue: 0.85, alpha: 1),
                  topSpeed: 78, acceleration: 44, handling: 1.7, unlockScore: 8)
    ]
}
