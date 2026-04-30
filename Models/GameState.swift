import SwiftUI

final class GameState: ObservableObject {
    @Published var score: Int = 0
    @Published var bestScore: Int = 0
    @Published var speed: Float = 0
    @Published var activePowerUp: PowerUpType? = nil
    @Published var powerUpTimeRemaining: Double = 0
    @Published var lap: Int = 0
    @Published var totalLaps: Int = 3
    @Published var lapTime: Double = 0
    @Published var bestLapTime: Double = 0
    @Published var lastLapTime: Double = 0
    @Published var isFinished: Bool = false

    @Published var leftHeld: Bool = false
    @Published var rightHeld: Bool = false
    @Published var gasHeld: Bool = false
    @Published var brakeHeld: Bool = false
    @Published var driftHeld: Bool = false

    @Published var isPaused: Bool = false

    var car: CarConfig = CarConfig.all[0]
    var tread: TreadConfig = TreadConfig.all[0]

    var steerInput: Float {
        var s: Float = 0
        if leftHeld { s -= 1 }
        if rightHeld { s += 1 }
        return s
    }
    var throttleInput: Float {
        var t: Float = 0
        if gasHeld { t += 1 }
        if brakeHeld { t -= 1 }
        return t
    }
}
