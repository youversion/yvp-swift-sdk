import Foundation

public actor ChapterDiskCache {
    static func urlForCachedChapter(withUSFM usfm: String, versionId: Int) -> URL {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let directory = cachesDirectory.appending(path: "Chapters", directoryHint: .isDirectory)
        return directory.appending(path: usfm, directoryHint: .notDirectory)
    }
    
    func chapterContent(withReference reference: BibleReference) -> BibleChapterContent? {
        guard let chapterUSFM = reference.chapterUSFM else {
            return nil
        }
        let url = Self.urlForCachedChapter(withUSFM: chapterUSFM, versionId: reference.versionId)
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? BibleChapterContent(serializedBytes: data)
    }
    
    func addChapterContent(_ content: BibleChapterContent, reference: BibleReference) {
        guard let chapterUSFM = reference.chapterUSFM else {
            return
        }
        let url = Self.urlForCachedChapter(withUSFM: chapterUSFM, versionId: reference.versionId)
        do {
            try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try content.serializedData()
            try data.write(to: url, options: .atomic)
        } catch {
            print("WARNING: ChapterDiskCache failed to write data to \(url): \(error)")
        }
    }
}

public actor BibleChapterRepository: ObservableObject {
    
    public static let shared = BibleChapterRepository()
    
    private var memoryCache: [String: BibleChapterContent] = [:]
    private var diskCache = ChapterDiskCache()
    
    static func cacheKey(reference: BibleReference) -> String {
        "\(reference.chapterUSFM)-\(reference.versionId)"
    }
    
    func chapter(withReference reference: BibleReference) async throws -> BibleChapterContent {
        let cacheKey = Self.cacheKey(reference: reference)
        
        if let cachedContent = memoryCache[cacheKey] {
            return cachedContent
        }
        
        if let cachedContent = await diskCache.chapterContent(withReference: reference) {
            memoryCache[cacheKey] = cachedContent
            return cachedContent
        }
        
        let content = try await BibleAPIs.chapter(reference: reference)
        
        memoryCache[cacheKey] = content
        await diskCache.addChapterContent(content, reference: reference)
        
        return content
    }
    
    func cachedChapter(withReference reference: BibleReference) throws -> BibleChapterContent? {
        let cacheKey = Self.cacheKey(reference: reference)
        return memoryCache[cacheKey]
    }
}
