import UIKit

enum Haptics {
    static var enabled: Bool = true

    private static let impact = UIImpactFeedbackGenerator(style: .medium)
    private static let success = UINotificationFeedbackGenerator()

    static func flip() {
        guard enabled else { return }
        impact.prepare()
        impact.impactOccurred()
    }

    static func marked() {
        guard enabled else { return }
        success.notificationOccurred(.success)
    }
}
