import Foundation
import ZipArchive

enum BibleVersionAPIError: Error {
    case cannotDownload
    case invalidDownload
    case notPermitted
    case invalidResponse
}

enum BibleVersionAPIs {
    // MARK: - Version Metadata

    /// Fetches version metadata from the server
    static func metadata(versionId: Int) async throws -> Data {
        guard let appKey = YouVersionPlatformConfiguration.appKey else {
            preconditionFailure("YouVersionPlatformConfiguration.appKey must be set.")
        }

        guard let url = URLBuilder.versionURL(versionId: versionId) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue(appKey, forHTTPHeaderField: "apikey")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            print("metadataFromServer: unexpected response type")
            throw BibleVersionAPIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            print("metadataFromServer: 401 Unauthorized (possibly a bad app_key)")
            throw BibleVersionAPIError.notPermitted
        }

        guard httpResponse.statusCode == 200 else {
            print("error \(httpResponse.statusCode) while downloading metadata")
            throw BibleVersionAPIError.cannotDownload
        }

        return data
    }

    // MARK: - Chapter Content

    public typealias YVDOMContent = Youversion_Red_Biblecontent_Api_Model_Youversion_ApiContent

    /// Fetches a single chapter's content from the server
    static func chapter(reference: BibleReference) async throws -> YVDOMContent {
        guard let appKey = YouVersionPlatformConfiguration.appKey else {
            preconditionFailure("YouVersionPlatformConfiguration.appKey must be set.")
        }

        guard let chapter = reference.toUSFMOfChapter else {
            throw BibleVersionAPIError.invalidDownload
        }

        guard let url = URLBuilder.chapterURL(usfm: chapter, versionId: reference.versionId) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue(appKey, forHTTPHeaderField: "apikey")

        let (data, response) = try await URLSession.shared.data(for: request)
        // TODO: investigate how iOS's caching might confuse our server-side chapter fetch logic.
        // These fetches are cached by iOS by default. Which is good, but, less control.

        guard let httpResponse = response as? HTTPURLResponse else {
            print("unexpected response type")
            throw BibleVersionAPIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            print("Not permitted; check your appKey and its entitlements.")
            throw BibleVersionAPIError.notPermitted
        }

        guard httpResponse.statusCode == 200 else {
            print("error \(httpResponse.statusCode) while fetching a chapter")
            throw BibleVersionAPIError.cannotDownload
        }

        let passage = try Youversion_Red_Biblecontent_Api_Model_Bible_Passage(serializedBytes: data)
        return passage.content
    }

    // MARK: - Version Discovery

    /// Finds Bible versions by language code
    static func versions(forLanguageTag languageTag: String? = nil) async throws -> [BibleVersionOverview] {
        guard let appKey = YouVersionPlatformConfiguration.appKey else {
            preconditionFailure("YouVersionPlatformConfiguration.appKey must be set.")
        }

        guard let languageTag, languageTag.count == 3 else {
            print("Invalid language code: \(languageTag ?? "unknown")")
            return []
        }
        
        guard let url = URLBuilder.versionsURL(languageTag: languageTag) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue(appKey, forHTTPHeaderField: "apikey")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("unexpected response type")
            throw BibleVersionAPIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            print("error 401: unauthorized. Check your appKey")
            throw BibleVersionAPIError.notPermitted
        }

        guard httpResponse.statusCode == 200 else {
            print("error in findVersions: \(httpResponse.statusCode)")
            throw BibleVersionAPIError.cannotDownload
        }

        let responseObject = try JSONDecoder().decode(BibleVersionOverviewsResponse.self, from: data)
        return responseObject.versions
    }

    private struct BibleVersionOverviewsResponse: Decodable {
        let versions: [BibleVersionOverview]
    }

}
