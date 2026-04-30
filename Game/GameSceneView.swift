import SwiftUI
import SceneKit

struct GameSceneView: UIViewRepresentable {
    let state: GameState

    func makeUIView(context: Context) -> SCNView {
        let v = SCNView(frame: .zero, options: nil)
        let world = GameWorld(state: state)
        context.coordinator.world = world
        v.scene = world.scene
        v.pointOfView = world.cameraNode
        v.delegate = world
        v.isPlaying = true
        v.rendersContinuously = true
        v.antialiasingMode = .multisampling4X
        v.preferredFramesPerSecond = 60
        v.allowsCameraControl = false
        v.backgroundColor = .clear
        return v
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator { var world: GameWorld? }
}
