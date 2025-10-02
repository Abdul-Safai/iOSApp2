import Foundation

enum Seed {
    static let items: [HuntItem] = [
        .init(id: UUID(), name: "Bluebird Café", address: "12 King St W", description: "Cozy brunch spot with local art.", clue: "Find the ceramic bluebird near the pastry case."),
        .init(id: UUID(), name: "Green Leaf Books", address: "88 Queen St E", description: "Indie bookstore & community hub.", clue: "Hunt for the vintage typewriter on the poetry shelf."),
        .init(id: UUID(), name: "CineTown", address: "101 Main St", description: "Classic cinema with retro posters.", clue: "Spot the golden ticket under the marquee display."),
        .init(id: UUID(), name: "Pixel Arcade", address: "5 Maple Ave", description: "Retro games & neon lights.", clue: "Check by the pinball machine with the highest score."),
        .init(id: UUID(), name: "Bean Roasters", address: "47 Victoria Rd", description: "Small-batch roastery.", clue: "Look for the tiny burlap sack near the cupping table."),
        .init(id: UUID(), name: "Riverwalk Deli", address: "3 Riverwalk Ln", description: "Sandwiches with local ingredients.", clue: "Clue hides behind a jar of house pickles."),
        .init(id: UUID(), name: "Skyline Theatre", address: "72 Elm St", description: "Live stage & improv.", clue: "Peek near Seat B12 sign at the aisle."),
        .init(id: UUID(), name: "Paper & Pen", address: "19 Oak St", description: "Stationery & gifts.", clue: "Find the wax seal stamp next to journals."),
        .init(id: UUID(), name: "Sunset Sushi", address: "23 Bayview Blvd", description: "Fresh rolls & omakase.", clue: "Search by the koi painting at the entrance."),
        .init(id: UUID(), name: "City Comics", address: "9 Wellington Rd", description: "Comics & collectibles.", clue: "Hidden near Issue #1 display case.")
    ]
}
