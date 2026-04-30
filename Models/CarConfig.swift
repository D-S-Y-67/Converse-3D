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
        CarConfig(id: 0, name: "Ember",   tagline: "Reliable starter, balanced everywhere",
                  body: UIColor(red: 0.86, green: 0.16, blue: 0.18, alpha: 1),
                  cabin: UIColor(red: 0.10, green: 0.16, blue: 0.24, alpha: 1),
                  topSpeed: 20, acceleration: 20, handling: 1.8, unlockScore: 0),
        CarConfig(id: 1, name: "Glacier", tagline: "Cool runner with sharper steering",
                  body: UIColor(red: 0.20, green: 0.55, blue: 0.95, alpha: 1),
                  cabin: UIColor(red: 0.05, green: 0.10, blue: 0.18, alpha: 1),
                  topSpeed: 22, acceleration: 19, handling: 2.0, unlockScore: 25),
        CarConfig(id: 2, name: "Mantis",  tagline: "Quick off the line, eager to corner",
                  body: UIColor(red: 0.40, green: 0.85, blue: 0.30, alpha: 1),
                  cabin: UIColor(red: 0.10, green: 0.20, blue: 0.10, alpha: 1),
                  topSpeed: 23, acceleration: 22, handling: 1.7, unlockScore: 75),
        CarConfig(id: 3, name: "Solar",   tagline: "Big top-end, demands precision",
                  body: UIColor(red: 1.00, green: 0.78, blue: 0.10, alpha: 1),
                  cabin: UIColor(red: 0.18, green: 0.12, blue: 0.05, alpha: 1),
                  topSpeed: 26, acceleration: 24, handling: 1.6, unlockScore: 150),
        CarConfig(id: 4, name: "Phantom", tagline: "Pure speed for veteran drivers",
                  body: UIColor(red: 0.10, green: 0.10, blue: 0.14, alpha: 1),
                  cabin: UIColor(red: 0.55, green: 0.15, blue: 0.85, alpha: 1),
                  topSpeed: 30, acceleration: 28, handling: 1.5, unlockScore: 300)
    ]
}
