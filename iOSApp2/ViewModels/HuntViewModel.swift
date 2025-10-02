import Foundation
import SwiftUI

final class HuntViewModel: ObservableObject {
    @Published private(set) var items: [HuntItem] = Seed.items
    @Published var filterText: String = ""

    @Published private(set) var progress: [UUID: HuntProgress] = [:]

    init() { loadProgress() }

    var filtered: [HuntItem] {
        guard !filterText.trimmingCharacters(in: .whitespaces).isEmpty else { return items }
        return items.filter {
            $0.name.localizedCaseInsensitiveContains(filterText)
            || $0.address.localizedCaseInsensitiveContains(filterText)
        }
    }

    // MARK: - Progress
    func isFound(_ item: HuntItem) -> Bool { progress[item.id]?.found == true }

    func image(for item: HuntItem) -> UIImage? {
        guard let b64 = progress[item.id]?.imageDataBase64,
              let data = Data(base64Encoded: b64) else { return nil }
        return UIImage(data: data)
    }

    func markFound(_ item: HuntItem, image: UIImage) {
        let resized = image.resizedForThumb(maxDimension: 900) // keep size reasonable
        let data = resized.jpegData(compressionQuality: 0.8)
        let b64 = data?.base64EncodedString()

        var hp = progress[item.id] ?? HuntProgress(found: false, imageDataBase64: nil)
        hp.found = true
        hp.imageDataBase64 = b64
        progress[item.id] = hp
        saveProgress(for: item, hp)
        objectWillChange.send()
    }

    func clearFound(_ item: HuntItem) {
        let hp = HuntProgress(found: false, imageDataBase64: nil)
        progress[item.id] = hp
        saveProgress(for: item, hp)
        objectWillChange.send()
    }

    var foundCount: Int { progress.values.filter { $0.found }.count }

    // MARK: - Discount
    func discountSummary() -> (title: String, message: String) {
        let n = foundCount
        switch n {
        case 0..<5:
            return ("Keep Hunting!", "You’ve found \(n)/10 items. Find at least 5 to unlock a 10% discount.")
        case 5..<7:
            return ("10% Unlocked 🎉", "You’ve found \(n)/10 items. Your code: 10OFF-\(codeSuffix()).")
        case 7..<10:
            return ("20% Unlocked 🎉", "You’ve found \(n)/10 items. Your code: 20OFF-\(codeSuffix()).")
        default:
            return ("Grand Prize Entry 🎉", "You found all 10! Your code: 20OFF-\(codeSuffix()). You’re entered into the $5000 draw.")
        }
    }

    private func codeSuffix() -> String {
        String(UUID().uuidString.prefix(6)).uppercased()
    }

    // MARK: - Reset all progress (NEW)
    func resetAll() {
        for item in items {
            let hp = HuntProgress(found: false, imageDataBase64: nil)
            progress[item.id] = hp
            saveProgress(for: item, hp)
        }
        objectWillChange.send()
    }

    // MARK: - Persistence
    private func loadProgress() {
        var dict: [UUID: HuntProgress] = [:]
        for item in items {
            if let data = UserDefaults.standard.data(forKey: item.storageKey),
               let hp = try? JSONDecoder().decode(HuntProgress.self, from: data) {
                dict[item.id] = hp
            } else {
                dict[item.id] = HuntProgress(found: false, imageDataBase64: nil)
            }
        }
        self.progress = dict
    }

    private func saveProgress(for item: HuntItem, _ hp: HuntProgress) {
        if let data = try? JSONEncoder().encode(hp) {
            UserDefaults.standard.set(data, forKey: item.storageKey)
        }
    }
}

// MARK: - UIImage helper
import UIKit
extension UIImage {
    func resizedForThumb(maxDimension: CGFloat) -> UIImage {
        let maxSide = Swift.max(size.width, size.height)
        guard maxSide > maxDimension, maxSide > 0 else { return self }
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}
