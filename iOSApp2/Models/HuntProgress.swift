import Foundation

struct HuntProgress: Codable {
    var found: Bool
    var imageDataBase64: String?
    var foundDate: Date?

    // <- needed for map/address in PDF
    var address: String?
    var latitude: Double?
    var longitude: Double?
}
