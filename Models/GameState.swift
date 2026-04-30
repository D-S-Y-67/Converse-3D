import SwiftUI

final class GameState: ObservableObject {
    @Published var bestScore: Int = 0
    @Published var speed: Float = 0

    @Published var lap: Int = 0
    @Published var totalLaps: Int = 3
    @Published var lapTime: Double = 0
    @Published var bestLapTime: Double = 0
    @Published var lastLapTime: Double = 0
    @Published var totalRaceTime: Double = 0

    @Published var racePhase: RacePhase = .grid
    @Published var countdownValue: Int = 3
    @Published var playerPosition: Int = 1
    @Published var totalCars: Int = 6
    @Published var raceResults: [RaceResult] = []

    @Published var drsHeld: Bool = false
    @Published var drsAvailable: Bool = false
    @Published var drsActive: Bool = false
    @Published var drsCooldown: Double = 0

    @Published var leftHeld: Bool = false
    @Published var rightHeld: Bool = false
    @Published var gasHeld: Bool = false
    @Published var brakeHeld: Bool = false

    @Published var isPaused: Bool = false

    var car: CarConfig = CarConfig.all[0]
    var tread: TreadConfig = TreadConfig.all[0]
    var track: TrackLayout = TrackLayout.silverstone

    private(set) var steerInput: Float = 0

    func updateSteer(dt: Float) {
        var target: Float = 0
        if leftHeld  { target -= 1 }
        if rightHeld { target += 1 }
        let rampRate: Float = (target == 0) ? 14.0 : 9.0
        let blend = min(Float(1), rampRate * dt)
        steerInput += (target - steerInput) * blend
        if abs(target - steerInput) < 0.005 { steerInput = target }
    }

    func resetInputs() {
        leftHeld = false
        rightHeld = false
        gasHeld = false
        brakeHeld = false
        drsHeld = false
        drsActive = false
        drsCooldown = 0
        steerInput = 0
    }

    var throttleInput: Float {
        var t: Float = 0
        if gasHeld { t += 1 }
        if brakeHeld { t -= 1 }
        return t
    }
}
