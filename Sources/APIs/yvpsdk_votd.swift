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

public func verseOfTheDay(
    versionId: Int = 1
) async throws -> YouVersionVerseOfTheDay {
    guard let appKey = YouVersionPlatformConfiguration.appKey else {
        preconditionFailure("YouVersionPlatformConfiguration.appKey must be set.")
    }

    guard let url = URLBuilder.votdURL(versionId: versionId) else {
        throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.setValue(YouVersionPlatformConfiguration.appKey, forHTTPHeaderField: "apikey")
    let (data, _) = try await URLSession.shared.data(for: request)
    guard let decodedResponse = try? JSONDecoder().decode(YouVersionVerseOfTheDay.self, from: data) else {
        throw URLError(.badServerResponse)
    }
    return decodedResponse
}
