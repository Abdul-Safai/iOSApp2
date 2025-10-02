import Foundation

struct HuntItem: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var address: String
    var description: String
    var clue: String

    var storageKey: String { "hunt_item_" + id.uuidString }
}

struct HuntProgress: Codable {
    var found: Bool
    var imageDataBase64: String?
}
