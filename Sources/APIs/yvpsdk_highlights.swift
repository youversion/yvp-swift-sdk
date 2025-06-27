import Foundation

public func fetchHighlightsForChapter(lat: String,
                                      usfm: String,
                                      version: BibleVersion) async throws -> [BibleHighlight] {
    if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
        return [BibleHighlight.preview]
    }
    
    guard let appKey = YouVersionPlatformConfiguration.appKey else {
        preconditionFailure("YouVersionPlatformConfiguration.appKey must be set.")
    }

    guard let url = URLBuilder.highlightsURL(usfm: usfm, versionId: version.code, accessToken: lat) else {
        throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.setValue(appKey, forHTTPHeaderField: "apikey")
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse: HTTPURLResponse = response as? HTTPURLResponse else {
        print("fetchHighlightsForChapter: unexpected response type")
        return []
    }
    if httpResponse.statusCode == 401 {
        print("fetchHighlightsForChapter: error 401: unauthorized. Check your appKey")
        return []
    }
    guard httpResponse.statusCode == 200 else {
        print("fetchHighlightsForChapter: \(httpResponse.statusCode)")
        return []
    }

    func convertHighlightResponse(response: BibleHighlightResponse, version: BibleVersion) -> BibleHighlight? {
        guard let usfm = response.usfm, let ref = version.simpleUsfmParse(usfm) else {
            return nil
        }
        return BibleHighlight(
            versionCode: response.version ?? 0,
            chapter: ref.c,
            verse: ref.v,
            color: response.color ?? "#FFF9B1"
        )
    }

    guard let decodedResponse = try? JSONDecoder().decode(BibleHighlightsResponseList.self, from: data) else {
        throw URLError(.badServerResponse)
    }
    return decodedResponse.highlights.compactMap { convertHighlightResponse(response: $0, version: version) }
}

private struct BibleHighlightsResponseList: Codable {
    let highlights: [BibleHighlightResponse]
}

private struct BibleHighlightResponse: Codable {
    let color: String?
    let created_dt: Int?
    let updated_dt: Int?
    let usfm: String?
    let version: Int?
}
