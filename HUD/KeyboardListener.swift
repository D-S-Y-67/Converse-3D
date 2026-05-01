import SwiftUI

struct KeyboardListener: View {
    @ObservedObject var state: GameState
    let onPause: () -> Void
    @FocusState private var focused: Bool

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .focusable()
            .focused($focused)
            .onAppear { focused = true }
            .onKeyPress(phases: [.down, .up]) { press in
                handle(press)
            }
    }

    private func handle(_ press: KeyPress) -> KeyPress.Result {
        let down = (press.phase == .down)
        switch press.key {
        case .upArrow:    state.gasHeld = down;   return .handled
        case .downArrow:  state.brakeHeld = down; return .handled
        case .leftArrow:  state.leftHeld = down;  return .handled
        case .rightArrow: state.rightHeld = down; return .handled
        case .space:      state.drsHeld = down;   return .handled
        case .escape:
            if down { onPause() }
            return .handled
        default: break
        }
        switch press.characters.lowercased() {
        case "w": state.gasHeld = down;   return .handled
        case "s": state.brakeHeld = down; return .handled
        case "a": state.leftHeld = down;  return .handled
        case "d": state.rightHeld = down; return .handled
        case "k": state.drsHeld = down;   return .handled
        default:  return .ignored
        }
    }
}
