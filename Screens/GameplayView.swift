import SwiftUI

struct GameplayView: View {
    @ObservedObject var state: GameState
    let onPause: () -> Void

    private var topHUD: some View {
        HStack(alignment: .top) {
            PositionBadge(position: state.playerPosition,
                          total: state.totalCars)
            Spacer()
            LapBadge(lap: state.lap, total: state.totalLaps,
                     lapTime: state.lapTime, bestLap: state.bestLapTime)
            Spacer()
            SpeedBadge(speed: state.speed)
        }
        .padding(.horizontal, 14)
        .padding(.top, 18)
    }

    private var drsRow: some View {
        Group {
            if state.racePhase == .racing {
                DRSIndicator(active: state.drsActive,
                             available: state.drsAvailable)
                    .padding(.top, 10)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private var pauseButton: some View {
        HStack {
            Spacer()
            Button(action: onPause) {
                Image(systemName: "pause.fill")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Circle().fill(.ultraThinMaterial))
                    .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
            }
        }
        .padding(.horizontal, 18)
    }

    private var leftControls: some View {
        VStack(spacing: 12) {
            ControlButton(symbol: "arrow.up", tint: .green,
                          isPressed: $state.gasHeld)
            ControlButton(symbol: "arrow.down", tint: .red,
                          isPressed: $state.brakeHeld)
        }
    }

    private var drsControl: some View {
        VStack(spacing: 6) {
            ControlButton(symbol: "arrow.up.to.line",
                          tint: state.drsActive ? .green : .yellow,
                          isPressed: $state.drsHeld)
            Text(state.drsActive ? "DRS ON" : "DRS")
                .font(.system(size: 9, weight: .black))
                .kerning(1.5)
                .foregroundStyle(state.drsActive
                                 ? .green : .white.opacity(0.6))
        }
        .padding(.bottom, 4)
    }

    private var rightControls: some View {
        HStack(spacing: 14) {
            ControlButton(symbol: "arrow.left", tint: .cyan,
                          isPressed: $state.leftHeld)
            ControlButton(symbol: "arrow.right", tint: .cyan,
                          isPressed: $state.rightHeld)
        }
    }

    private var bottomControls: some View {
        HStack(alignment: .bottom) {
            leftControls
            Spacer()
            drsControl
            Spacer()
            rightControls
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 26)
    }

    private var startLightsOverlay: some View {
        Group {
            if state.racePhase == .countdown {
                VStack {
                    RaceStartLights(countdown: state.countdownValue)
                        .padding(.top, 80)
                    Spacer()
                }
            }
        }
    }

    var body: some View {
        ZStack {
            GameSceneView(state: state).ignoresSafeArea()
            startLightsOverlay
            VStack(spacing: 0) {
                topHUD
                drsRow
                Spacer()
                pauseButton
                Spacer()
                bottomControls
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7),
                       value: state.drsActive)
        }
        .preferredColorScheme(.dark)
    }
}
