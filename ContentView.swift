import SwiftUI

struct ContentView: View {
    @StateObject private var state = GameState()
    @StateObject private var profile = UserProfile.shared
    @State private var screen: AppScreen = .onboarding
    @State private var carIndex = 0
    @State private var treadIndex = 0
    @State private var trackIndex = 0
    @State private var sessionId = 0

    @ViewBuilder
    private func screenView() -> some View {
        switch screen {
        case .onboarding:
            OnboardingScreen(profile: profile,
                             onContinue: { enterAfterOnboarding() })
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
                              onNext: { screen = .trackSelect },
                              onBack: { screen = .carSelect })
        case .trackSelect:
            TrackSelectScreen(selected: $trackIndex,
                              onNext: { startReady() },
                              onBack: { screen = .treadSelect })
        case .ready:
            ReadyScreen(car: CarConfig.all[carIndex],
                        tread: TreadConfig.all[treadIndex],
                        track: TrackLayout.all[trackIndex],
                        onGo: { screen = .playing },
                        onBack: { screen = .trackSelect })
        case .playing:
            playingScreen
        case .finished:
            finishView
        }
    }

    private var playingScreen: some View {
        ZStack {
            GameplayView(state: state, onPause: { state.isPaused = true })
                .id(sessionId)
            KeyboardListener(state: state,
                             onPause: { state.isPaused.toggle() })
            if state.isPaused {
                PauseOverlay(onResume: { state.isPaused = false },
                             onMenu: {
                    state.isPaused = false
                    screen = .splash
                })
            }
            if state.racePhase == .finished {
                finishView
            }
        }
    }

    private var finishView: some View {
        FinishScreen(position: state.playerPosition,
                     totalTime: state.totalRaceTime,
                     bestLap: state.bestLapTime,
                     trackName: state.track.name,
                     results: state.raceResults,
                     onRestart: { startReady() },
                     onMenu: { screen = .splash })
    }

    var body: some View {
        screenView()
            .animation(.easeInOut(duration: 0.25), value: screen)
            .onAppear {
                if profile.hasOnboarded {
                    screen = .splash
                    syncCarIndexFromProfile()
                }
            }
    }

    private func enterAfterOnboarding() {
        syncCarIndexFromProfile()
        screen = .splash
    }

    private func syncCarIndexFromProfile() {
        carIndex = CarConfig.index(for: profile.favoriteTeam)
    }

    private func startReady() {
        state.car = CarConfig.all[carIndex]
        state.tread = TreadConfig.all[treadIndex]
        state.track = TrackLayout.all[trackIndex]
        state.playerTeam = state.car.team
        state.speed = 0
        state.lap = 0
        state.lapTime = 0
        state.bestLapTime = 0
        state.lastLapTime = 0
        state.totalRaceTime = 0
        state.playerPosition = 1
        state.totalCars = 22
        state.raceResults = []
        state.racePhase = .grid
        state.countdownValue = 3
        state.isPaused = false
        state.resetInputs()
        sessionId += 1
        screen = .ready
    }
}
