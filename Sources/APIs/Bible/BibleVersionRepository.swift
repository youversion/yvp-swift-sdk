
import Foundation

public protocol BibleVersionAPIClient: Sendable {
    func version(withId id: Int) async throws -> BibleVersion
}

public protocol BibleVersionCaching: Sendable {
    func version(withId id: Int) async -> BibleVersion?
    func addVersion(_ version: BibleVersion) async
}

public final class VersionClient: BibleVersionAPIClient {
    public init() {}
    
    public func version(withId id: Int) async throws -> BibleVersion {
        let rawData = try await YouVersionAPI.Bible.metadata(versionId: id)
        let versionObject = try JSONDecoder().decode(BibleVersionObject.self, from: rawData)
        return versionObject.response.data
    }
}

public actor VersionMemoryCache: BibleVersionCaching {
    public init() {}
    
    private var cache: [Int: BibleVersion] = [:]
    
    public func version(withId id: Int) async -> BibleVersion? {
        cache[id]
    }
    
    public func addVersion(_ version: BibleVersion) async {
        cache[version.id] = version
    }
}

public actor VersionDiskCache: BibleVersionCaching {
    public init() {}
    
    static func urlForCachedVersion(_ versionId: Int) -> URL {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return cachesDirectory.appendingPathComponent("bible_\(versionId)")
    }
    
    public func version(withId id: Int) -> BibleVersion? {
        let url = VersionDiskCache.urlForCachedVersion(id)
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder().decode(BibleVersion.self, from: data)
    }
    
    public func addVersion(_ version: BibleVersion) async {
        let url = VersionDiskCache.urlForCachedVersion(version.id)
        if let data = try? JSONEncoder().encode(version) {
            try? data.write(to: url, options: .atomic)
        }
    }
}

public actor BibleVersionRepository: ObservableObject {

    private let apiClient = VersionClient()
    private let memoryCache: BibleVersionCaching = VersionMemoryCache()
    private let diskCache: BibleVersionCaching = VersionDiskCache()
    
    private var inFlightTasks: [Int: Task<BibleVersion, Error>] = [:]
    
    public init() {}
    
    public func version(withId id: Int) async throws -> BibleVersion {
        // Check caches first
        if let cached = await memoryCache.version(withId: id) {
            return cached
        }
        
        if let cached = await diskCache.version(withId: id) {
            await memoryCache.addVersion(cached)
            return cached
        }
        
        // If a fetch is already in-flight, await its result
        if let task = inFlightTasks[id] {
            return try await task.value
        }
        
        // Otherwise, create a new fetch task
        let task = Task { [apiClient, diskCache] in
            let version = try await apiClient.version(withId: id)
            await diskCache.addVersion(version)
            return version
        }
        
        inFlightTasks[id] = task
        
        defer {
            inFlightTasks[id] = nil
        }
        
        let version = try await task.value
        await memoryCache.addVersion(version)
        await diskCache.addVersion(version)
        return version
    }
}
