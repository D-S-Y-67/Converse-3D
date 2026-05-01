import SwiftUI

enum F1Team: String, CaseIterable, Identifiable, Codable {
    case ferrari, mercedes, mclaren, redBull, astonMartin
    case alpine, williams, haas, racingBulls, audi, cadillac

    var id: String { rawValue }

    var fullName: String {
        switch self {
        case .ferrari:      return "Ferrari"
        case .mercedes:     return "Mercedes"
        case .mclaren:      return "McLaren"
        case .redBull:      return "Red Bull"
        case .astonMartin:  return "Aston Martin"
        case .alpine:       return "Alpine"
        case .williams:     return "Williams"
        case .haas:         return "Haas"
        case .racingBulls:  return "Racing Bulls"
        case .audi:         return "Audi"
        case .cadillac:     return "Cadillac"
        }
    }

    var abbrev: String {
        switch self {
        case .ferrari:      return "FER"
        case .mercedes:     return "MER"
        case .mclaren:      return "MCL"
        case .redBull:      return "RBR"
        case .astonMartin:  return "AST"
        case .alpine:       return "ALP"
        case .williams:     return "WIL"
        case .haas:         return "HAS"
        case .racingBulls:  return "RBV"
        case .audi:         return "AUD"
        case .cadillac:     return "CAD"
        }
    }

    var primary: UIColor {
        switch self {
        case .ferrari:      return rgb(0xDC, 0x00, 0x00)
        case .mercedes:     return rgb(0x27, 0xF4, 0xD2)
        case .mclaren:      return rgb(0xFF, 0x80, 0x00)
        case .redBull:      return rgb(0x1E, 0x2A, 0x6B)
        case .astonMartin:  return rgb(0x00, 0x6F, 0x62)
        case .alpine:       return rgb(0x00, 0x90, 0xD0)
        case .williams:     return rgb(0x00, 0x5A, 0xFF)
        case .haas:         return rgb(0xF0, 0xF0, 0xF0)
        case .racingBulls:  return rgb(0x66, 0x92, 0xFF)
        case .audi:         return rgb(0x14, 0x14, 0x14)
        case .cadillac:     return rgb(0x0E, 0x22, 0x40)
        }
    }

    var secondary: UIColor {
        switch self {
        case .ferrari:      return rgb(0xFF, 0xF2, 0x00)
        case .mercedes:     return rgb(0x10, 0x10, 0x10)
        case .mclaren:      return rgb(0x00, 0x90, 0xD0)
        case .redBull:      return rgb(0xFF, 0x1E, 0x00)
        case .astonMartin:  return rgb(0xCE, 0xDC, 0x00)
        case .alpine:       return rgb(0xFF, 0x87, 0xBC)
        case .williams:     return rgb(0xFF, 0xFF, 0xFF)
        case .haas:         return rgb(0xE4, 0x05, 0x21)
        case .racingBulls:  return rgb(0x1E, 0x2A, 0x6B)
        case .audi:         return rgb(0xE4, 0x05, 0x21)
        case .cadillac:     return rgb(0xFF, 0xD4, 0x00)
        }
    }

    var primaryColor: Color { Color(primary) }
    var secondaryColor: Color { Color(secondary) }

    private func rgb(_ r: Int, _ g: Int, _ b: Int) -> UIColor {
        UIColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255,
                blue: CGFloat(b) / 255, alpha: 1)
    }
}
