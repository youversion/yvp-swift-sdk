import AuthenticationServices
import Foundation

public enum YouVersionAPI {
    
    public static func highlightsForChapter(
        usfm: String,
        versionId: Int,
        accessToken: String
    ) async throws -> [BibleHighlight] {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return [BibleHighlight.preview]
        }
        
        guard let appKey = YouVersionPlatformConfiguration.appKey else {
            preconditionFailure("YouVersionPlatformConfiguration.appKey must be set.")
        }
        
        guard let url = URLBuilder.highlightsURL(usfm: usfm, versionId: versionId, accessToken: accessToken) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue(appKey, forHTTPHeaderField: "X-App-Id")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse: HTTPURLResponse = response as? HTTPURLResponse else {
            print("highlightsForChapter: unexpected response type")
            return []
        }
        if httpResponse.statusCode == 401 {
            print("highlightsForChapter: error 401: unauthorized. Check your appKey")
            return []
        }
        guard httpResponse.statusCode == 200 else {
            print("highlightsForChapter: \(httpResponse.statusCode)")
            return []
        }
        
        struct BibleHighlightsResponseList: Decodable {
            let highlights: [BibleHighlightResponse]
        }

        struct BibleHighlightResponse: Decodable {
            let color: String?
            let usfm: String?
            let versionId: Int?
            
            enum CodingKeys: String, CodingKey {
                case color
                case usfm
                case versionId = "version_id"
            }
        }
        
        func highlight(from response: BibleHighlightResponse, versionId: Int) -> BibleHighlight? {
            guard let usfm = response.usfm,
                  let reference = BibleReference.unvalidatedReference(with: usfm, versionId: versionId) else {
                return nil
            }
            return BibleHighlight(
                versionId: response.versionId ?? 0,
                chapter: reference.chapterStart,
                verse: reference.verseStart,
                color: response.color ?? "#FFF9B1"
            )
        }

        guard let decodedResponse = try? JSONDecoder().decode(BibleHighlightsResponseList.self, from: data) else {
            throw URLError(.badServerResponse)
        }
        return decodedResponse.highlights.compactMap { highlight(from: $0, versionId: versionId) }
    }
}
