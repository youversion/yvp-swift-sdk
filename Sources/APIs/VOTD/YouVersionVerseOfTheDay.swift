import Foundation

public struct YouVersionVerseOfTheDay: Codable, Sendable {
    public let reference: String
    public let abbreviation: String
    public let text: String
    public let copyright: String
    
    enum CodingKeys: String, CodingKey {
        case reference = "human"
        case abbreviation, text, copyright
    }
    
    static var preview: YouVersionVerseOfTheDay {
        YouVersionVerseOfTheDay(
            reference: "John 1:1",
            abbreviation: "KJV",
            text: "In the beginning was the Word, and the Word was with God, and the Word was God. PREVIEW ONLY.",
            copyright: "Copyright goes here."
        )
    }
}
