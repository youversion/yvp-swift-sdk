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
    static func metadata(code: Int) async throws -> Data {
        guard let appKey = YouVersionPlatformConfiguration.appKey else {
            preconditionFailure("YouVersionPlatformConfiguration.appKey must be set.")
        }

        let host = YouVersionPlatformConfiguration.apiHost
        let env = YouVersionPlatformConfiguration.hostEnv ?? ""
        let url = URL(string: "https://\(host)/bible/version?version=\(code)\(env)")!
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
    static func chapter(ref: BibleReference) async throws -> YVDOMContent {
        guard let appKey = YouVersionPlatformConfiguration.appKey else {
            preconditionFailure("YouVersionPlatformConfiguration.appKey must be set.")
        }

        guard let chap = ref.toUSFMOfChapter else {
            throw BibleVersionAPIError.invalidDownload
        }

        let code = ref.versionCode
        let host = YouVersionPlatformConfiguration.apiHost
        let env = YouVersionPlatformConfiguration.hostEnv ?? ""
        let url = URL(string: "https://\(host)/bible/chapter?version=\(code)&usfm=\(chap)\(env)")!

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
    static func findVersions(byLanguage lang: String? = nil) async throws -> [BibleVersionOverview] {
        guard let appKey = YouVersionPlatformConfiguration.appKey else {
            preconditionFailure("YouVersionPlatformConfiguration.appKey must be set.")
        }

        if let lang, lang.count != 3 {
            print("Invalid language code: \(lang)")
            return []
        }

        let langParam = lang == nil ? "" : "language=/\(lang!)"
        let host = YouVersionPlatformConfiguration.apiHost
        let env = YouVersionPlatformConfiguration.hostEnv ?? ""
        let url = URL(string: "https://\(host)/bible/versions?\(langParam)\(env)")!

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
