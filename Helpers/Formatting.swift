import Foundation

func formatTime(_ t: Double) -> String {
    if t <= 0 { return "—:——.—" }
    let m = Int(t) / 60
    let s = t - Double(m * 60)
    return String(format: "%d:%05.2f", m, s)
}

func formatPosition(_ p: Int) -> String {
    "P\(p)"
}
