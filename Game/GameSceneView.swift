import SwiftUI
import SceneKit

#if canImport(UIKit)
struct GameSceneView: UIViewRepresentable {
    let state: GameState

    func makeUIView(context: Context) -> SCNView {
        configure(SCNView(frame: .zero, options: nil),
                  coordinator: context.coordinator)
    }
    func updateUIView(_ uiView: SCNView, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator { var world: GameWorld? }

    private func configure(_ v: SCNView,
                           coordinator: Coordinator) -> SCNView {
        let world = GameWorld(state: state)
        coordinator.world = world
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
}
#else
struct GameSceneView: NSViewRepresentable {
    let state: GameState

    func makeNSView(context: Context) -> SCNView {
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
    func updateNSView(_ nsView: SCNView, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator { var world: GameWorld? }
}
#endif
