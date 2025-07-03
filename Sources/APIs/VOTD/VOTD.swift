import Foundation

public extension YouVersionAPI {
    enum VOTD {
        public static func verseOfTheDay(versionId: Int = 1) async throws -> YouVersionVerseOfTheDay {
            guard let url = URLBuilder.votdURL(versionId: versionId) else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url)
            request.setValue(YouVersionPlatformConfiguration.appKey, forHTTPHeaderField: "X-App-Id")
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let decodedResponse = try? JSONDecoder().decode(YouVersionVerseOfTheDay.self, from: data) else {
                throw URLError(.badServerResponse)
            }
            return decodedResponse
        }
    }
}
