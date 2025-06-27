import Foundation
import ZipArchive

class BibleVersionCache {
    enum BibleVersionCacheError: Error {
        case cannotDownload
        case invalidDownload
        case notPermitted
    }

    public typealias YVDOMContent = Youversion_Red_Biblecontent_Api_Model_Youversion_ApiContent
    private static let chaptersCache = ThreadSafeDictionary<String, YVDOMContent>()
    private static let versionsCache = ThreadSafeDictionary<Int, BibleVersionData>()

    static func metadataIfCached(versionId: Int) -> BibleVersionData? {
        if let v = versionsCache[versionId] {
            return v
        }

        let cachePath = urlForCachedMetadata(versionId).path
        if FileManager.default.fileExists(atPath: cachePath),
            let filedata = FileManager.default.contents(atPath: cachePath) {
            if let v = try? JSONDecoder().decode(BibleVersionObject.self, from: filedata) {
                //print("Loaded metadata for \(versionId) from \(cachePath)")
                versionsCache[versionId] = v.response.data
                return v.response.data
            }
        }
        return nil
    }

    static func metadataFromServer(versionId: Int) async throws -> BibleVersionData {
        if let version = metadataIfCached(versionId: versionId) {
            return version
        }

        do {
            let data = try await BibleVersionAPIs.metadata(versionId: versionId)

            let versionObject = try JSONDecoder().decode(BibleVersionObject.self, from: data)
            let metadata = versionObject.response.data
            versionsCache[versionId] = metadata

            // Cache the raw data to disk
            let cachePath = urlForCachedMetadata(versionId).path
            FileManager.default.createFile(atPath: cachePath, contents: data)

            return metadata
        } catch let error as BibleVersionAPIError {
            switch error {
            case .notPermitted:
                throw BibleVersionCacheError.notPermitted
            case .cannotDownload, .invalidDownload, .invalidResponse:
                throw BibleVersionCacheError.cannotDownload
            }
        } catch {
            print("could not download Bible version metadata: \(error.localizedDescription)")
            throw BibleVersionCacheError.invalidDownload
        }
    }

    private static func urlForCachedMetadata(_ version: Int) -> URL {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return cachesDirectory.appendingPathComponent("bible_\(version)")
    }

    /// This probably is not a function that you want to call.
    /// Use `chapter(reference:)` since it'll also pull from the server if necessary.
    static func chapterFromCache(reference: BibleReference) -> YVDOMContent? {
        guard let book = reference.bookUSFM,
              let usfm = reference.chapterUSFM else {
            return nil
        }

        let cacheKey = "\(reference.versionId).\(book).\(reference.chapterStart)"
        if let c = chaptersCache[cacheKey] {
            return c
        }

        if let meta = metadataIfCached(versionId: reference.versionId) {
            let dir = urlForCachedVersion(reference.versionId, offlineBuildVersion: meta.offline?.build?.max ?? 0)
            let fileURL = dir.appendingPathComponent(usfm)
            if let data = try? Data(contentsOf: fileURL) {
                if let c = try? YVDOMContent(serializedBytes: data) {
                    chaptersCache[cacheKey] = c
                    return c
                }
            }
        }
        return nil
    }

    /// Better than `chapterFromCache(reference:)` because it'll also try to fetch from the server, if the given chapter
    /// isn't in cache and also isn't downloaded. This one is preferred.
    static func chapter(reference: BibleReference) async -> YVDOMContent? {
        if let content = chapterFromCache(reference: reference) {
            return content
        }
        return await chapterFromServer(reference: reference)
    }

    private static func chapterFromServer(reference: BibleReference) async -> YVDOMContent? {
        guard let book = reference.bookUSFM else {
            return nil
        }

        do {
            let content = try await BibleVersionAPIs.chapter(reference: reference)
            let cacheKey = "\(reference.versionId).\(book).\(reference.chapterStart)"
            chaptersCache[cacheKey] = content
            writeChapterToCache(reference: reference, content: content)
            return content
        } catch {
            print("could not get a chapter from the server: \(error.localizedDescription)")
            return nil
        }
    }

    private static func writeChapterToCache(reference: BibleReference, content: YVDOMContent) {
        // TODO: write this.
        // 1. see if we already have a directory at urlForCachedVersion() and create if not.
        // 2. consider if an old file needs to be deleted (if the disk cache is "full".)
        // 3. write content to fileURL = dir.appendingPathComponent(reference.chapterUSFM)
    }

    private static func urlForCachedVersion(_ versionId: Int, offlineBuildVersion: Int) -> URL {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return cachesDirectory.appendingPathComponent("bible_\(versionId)_\(offlineBuildVersion)")
    }

}
