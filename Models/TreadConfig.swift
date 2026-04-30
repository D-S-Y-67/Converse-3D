import SwiftUI

struct TreadConfig: Identifiable, Equatable {
    let id: Int
    let name: String
    let description: String
    let radius: CGFloat
    let width: CGFloat
    let color: UIColor
    let stripeColor: UIColor
    let gripBonus: Float

    var swiftColor: Color { Color(color) }
    var stripeSwiftColor: Color { Color(stripeColor) }

    static let all: [TreadConfig] = [
        TreadConfig(id: 0, name: "Soft",   description: "Sticky compound, fastest lap pace",
                    radius: 0.42, width: 0.55,
                    color: UIColor(white: 0.04, alpha: 1),
                    stripeColor: UIColor(red: 0.95, green: 0.15, blue: 0.15, alpha: 1),
                    gripBonus: 1.20),
        TreadConfig(id: 1, name: "Medium", description: "Balanced grip and durability",
                    radius: 0.44, width: 0.55,
                    color: UIColor(white: 0.05, alpha: 1),
                    stripeColor: UIColor(red: 0.95, green: 0.85, blue: 0.20, alpha: 1),
                    gripBonus: 1.05),
        TreadConfig(id: 2, name: "Hard",   description: "Tough compound, steady all race",
                    radius: 0.46, width: 0.58,
                    color: UIColor(white: 0.06, alpha: 1),
                    stripeColor: UIColor(white: 0.92, alpha: 1),
                    gripBonus: 0.95)
    ]
}
