import UIKit

enum AppHaptics {
    static func flip() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func marked() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
}
