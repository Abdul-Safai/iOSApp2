import Foundation

public struct HuntItem: Identifiable, Hashable, Codable {
    public let id: UUID
    public var name: String
    public var address: String
    public var description: String
    public var clue: String
    public var lat: Double? = nil
    public var lon: Double? = nil

    public var storageKey: String { "hunt_item_" + id.uuidString }
}

public enum AppSeed {
    public static let items: [HuntItem] = [
        .init(id: UUID(), name: "City Diner",    address: "12 King St.",    description: "Cozy local restaurant",   clue: "Look by the pickup counter."),
        .init(id: UUID(), name: "Grand Cinema",  address: "45 Queen Ave.",   description: "Indie movie theatre",     clue: "Check below the marquee poster."),
        .init(id: UUID(), name: "Pages & Co.",   address: "77 Maple Rd.",    description: "Independent bookstore",   clue: "Find the classics wall."),
        .init(id: UUID(), name: "Bean Bar",      address: "9 Elm St.",       description: "Specialty coffee",        clue: "Near the pastry case."),
        .init(id: UUID(), name: "Gift Nook",     address: "101 Market Ln.",  description: "Gifts & cards",           clue: "Greeting cards rack."),
        .init(id: UUID(), name: "Tech Stop",     address: "210 Bay Blvd.",   description: "Electronics shop",        clue: "By phone accessories."),
        .init(id: UUID(), name: "Green Grocer",  address: "5 River Way",     description: "Local produce",           clue: "Berry display table."),
        .init(id: UUID(), name: "Playhouse",     address: "3 Theatre Sq.",   description: "Community stage",         clue: "Poster board in lobby."),
        .init(id: UUID(), name: "City Library",  address: "400 Park Dr.",    description: "Public library",          clue: "New arrivals shelf."),
        .init(id: UUID(), name: "Sunny Toys",    address: "18 Cedar Ct.",    description: "Toy store",               clue: "Puzzle section.")
    ]
}
