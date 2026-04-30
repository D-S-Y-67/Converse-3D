import SwiftUI

struct ContentView: View {
    @StateObject private var state = GameState()
    @State private var screen: AppScreen = .splash
    @State private var carIndex = 0
    @State private var treadIndex = 0
    @State private var sessionId = 0

    @ViewBuilder
    private func screenView() -> some View {
        switch screen {
        case .splash:
            SplashScreen(onStart: { screen = .carSelect },
                         bestScore: state.bestScore)
        case .carSelect:
            CarSelectScreen(selected: $carIndex,
                            bestScore: state.bestScore,
                            onNext: { screen = .treadSelect },
                            onBack: { screen = .splash })
        case .treadSelect:
            TreadSelectScreen(selected: $treadIndex,
                              onNext: { startReady() },
                              onBack: { screen = .carSelect })
        case .ready:
            ReadyScreen(car: CarConfig.all[carIndex],
                        tread: TreadConfig.all[treadIndex],
                        onGo: { screen = .playing },
                        onBack: { screen = .treadSelect })
        case .playing:
            ZStack {
                GameplayView(state: state, onPause: { state.isPaused = true })
                    .id(sessionId)
                if state.isPaused {
                    PauseOverlay(onResume: { state.isPaused = false },
                                 onMenu: {
                        state.isPaused = false
                        screen = .splash
                    })
                }
                if state.isFinished {
                    FinishScreen(score: state.score,
                                 bestLap: state.bestLapTime,
                                 onRestart: { startReady() },
                                 onMenu: { screen = .splash })
                }
            }
        case .finished:
            FinishScreen(score: state.score,
                         bestLap: state.bestLapTime,
                         onRestart: { startReady() },
                         onMenu: { screen = .splash })
        }
    }

    var body: some View {
        screenView()
            .animation(.easeInOut(duration: 0.25), value: screen)
    }

    private func startReady() {
        state.score = 0
        state.speed = 0
        state.activePowerUp = nil
        state.powerUpTimeRemaining = 0
        state.lap = 0
        state.lapTime = 0
        state.bestLapTime = 0
        state.lastLapTime = 0
        state.isFinished = false
        state.isPaused = false
        state.leftHeld = false
        state.rightHeld = false
        state.gasHeld = false
        state.brakeHeld = false
        state.driftHeld = false
        state.car = CarConfig.all[carIndex]
        state.tread = TreadConfig.all[treadIndex]
        sessionId += 1
        screen = .ready
    }
}
