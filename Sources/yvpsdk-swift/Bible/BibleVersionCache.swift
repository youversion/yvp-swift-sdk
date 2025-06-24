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

    static func metadataIfCached(code: Int) -> BibleVersionData? {
        if let v = versionsCache[code] {
            return v
        }

        let cachePath = urlForCachedMetadata(code).path
        if FileManager.default.fileExists(atPath: cachePath),
            let filedata = FileManager.default.contents(atPath: cachePath) {
            if let v = try? JSONDecoder().decode(BibleVersionObject.self, from: filedata) {
                //print("Loaded metadata for \(code) from \(cachePath)")
                versionsCache[code] = v.response.data
                return v.response.data
            }
        }
        return nil
    }

    static func metadataFromServer(code: Int) async throws -> BibleVersionData {
        if let v = metadataIfCached(code: code) {
            return v
        }

        do {
            let data = try await BibleVersionAPIs.fetchMetadata(code: code)

            let versionObject = try JSONDecoder().decode(BibleVersionObject.self, from: data)
            let metadata = versionObject.response.data
            versionsCache[code] = metadata

            // Cache the raw data to disk
            let cachePath = urlForCachedMetadata(code).path
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

    static func getChapterIfCached(ref: BibleReference) -> YVDOMContent? {
        guard let book = ref.book else {
            return nil
        }
        guard let usfm = ref.toUSFMOfChapter else {
            return nil
        }

        let cacheKey = "\(ref.versionCode).\(book).\(ref.c)"
        if let c = chaptersCache[cacheKey] {
            return c
        }

        if let meta = metadataIfCached(code: ref.versionCode) {
            let dir = urlForCachedVersion(ref.versionCode, version: meta.offline?.build?.max ?? 0)
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

    /// This probably is not a function that you want to call.
    /// Use getChapterAsync since it'll also pull from the server if necessary.
    static func getChapter(ref: BibleReference) -> YVDOMContent? {
        return getChapterIfCached(ref: ref)
    }

    /// Better than getChapterIfCached because it'll also try to fetch from the server, if the given chapter
    /// isn't in cache and also isn't downloaded. This one is preferred.
    static func getChapterAsync(ref: BibleReference) async -> YVDOMContent? {
        if let c = getChapter(ref: ref) {
            return c
        }
        return await getChapterFromServer(ref: ref)
    }

    static private func getChapterFromServer(ref: BibleReference) async -> YVDOMContent? {
        guard let book = ref.book else {
            return nil
        }

        do {
            let content = try await BibleVersionAPIs.fetchChapter(ref: ref)
            let cacheKey = "\(ref.versionCode).\(book).\(ref.c)"
            chaptersCache[cacheKey] = content
            writeChapterToCache(ref: ref, content: content)
            return content
        } catch {
            print("could not get a chapter from the server: \(error.localizedDescription)")
            return nil
        }
    }

    static private func writeChapterToCache(ref: BibleReference, content: YVDOMContent) {
        // TODO: write this.
        // 1. see if we already have a directory at urlForCachedVersion() and create if not.
        // 2. consider if an old file needs to be deleted (if the disk cache is "full".)
        // 3. write content to fileURL = dir.appendingPathComponent(ref.toUSFMOfChapter)
    }

    static private func urlForCachedVersion(_ code: Int, version: Int) -> URL {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return cachesDirectory.appendingPathComponent("bible_\(code)_\(version)")
    }

}
