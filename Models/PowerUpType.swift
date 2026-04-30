import SwiftUI

enum PowerUpType: CaseIterable {
    case speed, shield, magnet
    var name: String {
        switch self {
        case .speed: return "Turbo"
        case .shield: return "Shield"
        case .magnet: return "Magnet"
        }
    }
    var symbol: String {
        switch self {
        case .speed: return "bolt.fill"
        case .shield: return "shield.lefthalf.filled"
        case .magnet: return "scope"
        }
    }
    var tint: Color {
        switch self {
        case .speed: return Color(red: 1.0, green: 0.85, blue: 0.2)
        case .shield: return Color(red: 0.3, green: 0.85, blue: 1.0)
        case .magnet: return Color(red: 1.0, green: 0.4, blue: 0.7)
        }
    }
    var uiColor: UIColor { UIColor(self.tint) }
    var duration: Double {
        switch self {
        case .speed: return 6
        case .shield: return 10
        case .magnet: return 12
        }
    }
}
