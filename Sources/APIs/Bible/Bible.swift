import Foundation

enum BibleVersionAPIError: Error {
    case cannotDownload
    case invalidDownload
    case notPermitted
    case invalidResponse
}

typealias BibleChapterContent = Youversion_Red_Biblecontent_Api_Model_Youversion_ApiContent

public extension YouVersionAPI {
    enum Bible {
        
        /// Retrieves metadata for a specific Bible version from the server.
        ///
        /// This function fetches metadata for the Bible version identified by `versionId`.
        /// The request requires a valid `YouVersionPlatformConfiguration.appKey` to be set.
        ///
        /// - Parameter versionId: The identifier of the Bible version to fetch metadata for.
        /// - Returns: The raw `Data` containing the version metadata.
        ///
        /// - Throws:
        ///   - `URLError` if the URL is invalid.
        ///   - `BibleVersionAPIError.notPermitted` if the app key is invalid or lacks permission.
        ///   - `BibleVersionAPIError.cannotDownload` if the server returns an error response.
        ///   - `BibleVersionAPIError.invalidResponse` if the server response is not valid.
        static func metadata(versionId: Int) async throws -> Data {
            guard let appKey = YouVersionPlatformConfiguration.appKey else {
                preconditionFailure("YouVersionPlatformConfiguration.appKey must be set.")
            }

            guard let url = URLBuilder.versionURL(versionId: versionId) else {
                throw URLError(.badURL)
            }
            
            var request = URLRequest(url: url)
            request.setValue(appKey, forHTTPHeaderField: "X-App-Id")

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

        /// Fetches the content of a single Bible chapter from the server.
        ///
        /// This function retrieves the content of the chapter specified in the provided ``BibleReference``.
        /// A valid `YouVersionPlatformConfiguration.appKey` must be set for the request to succeed.
        ///
        /// - Parameter reference: The ``BibleReference`` specifying the version and chapter to fetch.
        /// - Returns: A ``BibleChapterContent`` object containing the chapter's structured content.
        ///
        /// - Throws:
        ///   - `BibleVersionAPIError.invalidDownload` if the ``BibleReference`` does not contain a valid chapter.
        ///   - `URLError` if the URL is invalid.
        ///   - `BibleVersionAPIError.notPermitted` if the app key is invalid or lacks permission.
        ///   - `BibleVersionAPIError.cannotDownload` if the server returns an error response.
        ///   - `BibleVersionAPIError.invalidResponse` if the server response is not valid.
        static func chapter(reference: BibleReference) async throws -> BibleChapterContent {
            guard let appKey = YouVersionPlatformConfiguration.appKey else {
                preconditionFailure("YouVersionPlatformConfiguration.appKey must be set.")
            }

            guard let chapter = reference.chapterUSFM else {
                throw BibleVersionAPIError.invalidDownload
            }

            guard let url = URLBuilder.chapterURL(usfm: chapter, versionId: reference.versionId) else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url)
            request.setValue(appKey, forHTTPHeaderField: "X-App-Id")

            let (data, response) = try await URLSession.shared.data(for: request)

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
        
        /// Retrieves a list of Bible versions available for a specified language code.
        ///
        /// This function fetches Bible version overviews for the provided three-letter language code (e.g., `"eng"`).
        /// A valid `YouVersionPlatformConfiguration.appKey` must be set for the request to succeed.
        ///
        /// - Parameter languageTag: An optional three-letter language code for filtering available Bible versions. If `nil` or invalid, the function returns an empty list.
        /// - Returns: An array of ``BibleVersionOverview`` objects representing the available Bible versions for the language.
        ///
        /// - Throws:
        ///   - `URLError` if the URL is invalid.
        ///   - `BibleVersionAPIError.notPermitted` if the app key is invalid or lacks permission.
        ///   - `BibleVersionAPIError.cannotDownload` if the server returns an error response.
        ///   - `BibleVersionAPIError.invalidResponse` if the server response is not valid.
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
            request.setValue(appKey, forHTTPHeaderField: "X-App-Id")

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
}
