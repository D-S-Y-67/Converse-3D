import SwiftUI
import UIKit

struct KeyboardListener: UIViewRepresentable {
    let state: GameState
    let onPause: () -> Void

    func makeUIView(context: Context) -> KeyboardListenerView {
        let v = KeyboardListenerView(state: state, onPause: onPause)
        v.backgroundColor = .clear
        DispatchQueue.main.async { v.becomeFirstResponder() }
        return v
    }

    func updateUIView(_ uiView: KeyboardListenerView, context: Context) {
        if !uiView.isFirstResponder { uiView.becomeFirstResponder() }
    }
}

final class KeyboardListenerView: UIView {
    private weak var state: GameState?
    private let onPause: () -> Void

    init(state: GameState, onPause: @escaping () -> Void) {
        self.state = state
        self.onPause = onPause
        super.init(frame: .zero)
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) { fatalError() }

    override var canBecomeFirstResponder: Bool { true }

    override func pressesBegan(_ presses: Set<UIPress>,
                               with event: UIPressesEvent?) {
        var handled = false
        for press in presses {
            if let key = press.key, apply(key: key, pressed: true) {
                handled = true
            }
        }
        if !handled { super.pressesBegan(presses, with: event) }
    }

    override func pressesEnded(_ presses: Set<UIPress>,
                               with event: UIPressesEvent?) {
        var handled = false
        for press in presses {
            if let key = press.key, apply(key: key, pressed: false) {
                handled = true
            }
        }
        if !handled { super.pressesEnded(presses, with: event) }
    }

    private func apply(key: UIKey, pressed: Bool) -> Bool {
        guard let state = state else { return false }
        let chars = key.charactersIgnoringModifiers.lowercased()
        switch key.keyCode {
        case .keyboardUpArrow, .keyboardW:
            state.gasHeld = pressed; return true
        case .keyboardDownArrow, .keyboardS:
            state.brakeHeld = pressed; return true
        case .keyboardLeftArrow, .keyboardA:
            state.leftHeld = pressed; return true
        case .keyboardRightArrow, .keyboardD:
            state.rightHeld = pressed; return true
        case .keyboardSpacebar, .keyboardK:
            state.drsHeld = pressed; return true
        case .keyboardEscape:
            if pressed { onPause() }
            return true
        default: break
        }
        switch chars {
        case "w": state.gasHeld = pressed; return true
        case "s": state.brakeHeld = pressed; return true
        case "a": state.leftHeld = pressed; return true
        case "d": state.rightHeld = pressed; return true
        case "k", " ": state.drsHeld = pressed; return true
        default: return false
        }
    }
}
