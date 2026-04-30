import SwiftUI

enum RacePhase: Equatable {
    case grid
    case countdown
    case racing
    case finished
}

struct RaceResult: Identifiable {
    let id: Int
    let name: String
    let color: Color
    let position: Int
    let lapsCompleted: Int
    let bestLap: Double
    let isPlayer: Bool
}
