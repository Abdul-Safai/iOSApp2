import Foundation
import UIKit

enum Haptics {
    // Toggleable in SettingsView
    static var enabled: Bool {
        get { UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "hapticsEnabled") }
    }

    static func flip() {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func marked() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func error() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
