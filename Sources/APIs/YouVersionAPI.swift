import AuthenticationServices
import Foundation

public enum YouVersionAPI {
    /// Retrieves the user's highlights for a specific Bible chapter from YouVersion.
    ///
    /// This function fetches highlights for the chapter identified by the provided `usfm` code and `versionId`
    /// for the authenticated user, using the provided `accessToken`. The highlights include color, chapter,
    /// and verse information for the user's saved highlights in that chapter.
    ///
    /// A valid `YouVersionPlatformConfiguration.appKey` must be set before calling this function.
    ///
    /// - Parameters:
    ///   - usfm: The USFM identifier for the chapter (e.g., `"JHN.3"`).
    ///   - versionId: The ID of the Bible version to fetch highlights for.
    ///   - accessToken: The access token for the authenticated user, obtained from YouVersion login.
    /// - Returns: An array of ``BibleHighlight`` objects representing the user's highlights in the specified chapter.
    /// - Throws:
    ///   - `URLError.badURL` if the URL could not be constructed.
    ///   - `URLError.badServerResponse` if the server response could not be decoded or was invalid.
    ///
    /// If the server returns a `401 Unauthorized` or other non-200 status, the function logs the error and returns an empty array.
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
                  let reference = BibleReference.unvalidatedReference(with: usfm, versionId: versionId),
                  let firstVerse = reference.verseStart else {
                return nil
            }
            return BibleHighlight(
                versionId: response.versionId ?? 0,
                chapter: reference.chapter,
                verse: firstVerse,
                color: response.color ?? "#FFF9B1"
            )
        }

        guard let decodedResponse = try? JSONDecoder().decode(BibleHighlightsResponseList.self, from: data) else {
            throw URLError(.badServerResponse)
        }
        return decodedResponse.highlights.compactMap { highlight(from: $0, versionId: versionId) }
    }
}
