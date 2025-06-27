import Foundation

public func highlightsForChapter(
    usfm: String,
    version: BibleVersion,
    lat: String
) async throws -> [BibleHighlight] {
    if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
        return [BibleHighlight.preview]
    }
    
    guard let appKey = YouVersionPlatformConfiguration.appKey else {
        preconditionFailure("YouVersionPlatformConfiguration.appKey must be set.")
    }
    
    guard let url = URLBuilder.highlightsURL(usfm: usfm, versionId: version.id, accessToken: lat) else {
        throw URLError(.badURL)
    }
    
    var request = URLRequest(url: url)
    request.setValue(appKey, forHTTPHeaderField: "apikey")
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
    
    func convertHighlightResponse(_ response: BibleHighlightResponse, version: BibleVersion) -> BibleHighlight? {
        guard let usfm = response.usfm, let ref = version.simpleUsfmParse(usfm) else {
            return nil
        }
        return BibleHighlight(
            versionId: response.version ?? 0,
            chapter: ref.c,
            verse: ref.v,
            color: response.color ?? "#FFF9B1"
        )
    }

    guard let decodedResponse = try? JSONDecoder().decode(BibleHighlightsResponseList.self, from: data) else {
        throw URLError(.badServerResponse)
    }
    return decodedResponse.highlights.compactMap { convertHighlightResponse($0, version: version) }
}

private struct BibleHighlightsResponseList: Decodable {
    let highlights: [BibleHighlightResponse]
}

private struct BibleHighlightResponse: Decodable {
    let color: String?
    let created_dt: Int?
    let updated_dt: Int?
    let usfm: String?
    let version: Int?
}
