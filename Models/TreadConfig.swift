import SwiftUI

struct TreadConfig: Identifiable, Equatable {
    let id: Int
    let name: String
    let description: String
    let radius: CGFloat
    let width: CGFloat
    let color: UIColor
    let gripBonus: Float

    var swiftColor: Color { Color(color) }

    static let all: [TreadConfig] = [
        TreadConfig(id: 0, name: "Street",   description: "Balanced grip and speed",
                    radius: 0.42, width: 0.32,
                    color: UIColor(white: 0.08, alpha: 1), gripBonus: 1.0),
        TreadConfig(id: 1, name: "Off-Road", description: "Better grip, chunky tread",
                    radius: 0.50, width: 0.45,
                    color: UIColor(red: 0.30, green: 0.20, blue: 0.12, alpha: 1), gripBonus: 1.1),
        TreadConfig(id: 2, name: "Slicks",   description: "Maximum grip, less stable",
                    radius: 0.40, width: 0.28,
                    color: UIColor(white: 0.04, alpha: 1), gripBonus: 1.25),
        TreadConfig(id: 3, name: "Monster",  description: "Massive but slow turning",
                    radius: 0.62, width: 0.55,
                    color: UIColor(white: 0.05, alpha: 1), gripBonus: 0.85)
    ]
}
