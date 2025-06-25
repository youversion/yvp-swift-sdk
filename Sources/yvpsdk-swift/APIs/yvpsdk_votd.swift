import Foundation

public struct YouVersionVerseOfTheDay: Sendable {
    public let reference: String
    public let abbreviation: String
    public let text: String
    public let copyright: String
}

// private; only for decoding the server response
struct VotdResponse: Codable {
    let human: String
    let text: String
    let copyright: String
    let abbreviation: String
}

public func fetchVerseOfTheDay(lat: String,
                               versionCode: Int = 1) async throws -> YouVersionVerseOfTheDay {
    guard let appKey = YouVersionPlatformConfiguration.appKey else {
        fatalError("YouVersionPlatformConfiguration.appKey must be set.")
    }
    if appKey == "preview" {
        return YouVersionVerseOfTheDay(
            reference: "John 1:1",
            abbreviation: "KJV",
            text: "In the beginning was the Word, and the Word was with God, and the Word was God. PREVIEW ONLY.",
            copyright: "Copyright goes here.")
    }

    var components = URLComponents()
    components.scheme = "https"
    components.host = YouVersionPlatformConfiguration.apiHost
    components.path = "/votd/today"
    components.queryItems = [
        URLQueryItem(name: "lat", value: lat),
        URLQueryItem(name: "translationId", value: "\(versionCode)"),
        URLQueryItem(name: "platform", value: "iOS")
    ]
    guard let url = components.url else {
        throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.setValue(YouVersionPlatformConfiguration.appKey, forHTTPHeaderField: "apikey")
    let (data, _) = try await URLSession.shared.data(for: request)
    guard let decodedResponse = try? JSONDecoder().decode(VotdResponse.self, from: data) else {
        throw URLError(.badServerResponse)
    }

    return YouVersionVerseOfTheDay(
        reference: decodedResponse.human,
        abbreviation: decodedResponse.abbreviation,
        text: decodedResponse.text,
        copyright: decodedResponse.copyright)
}
