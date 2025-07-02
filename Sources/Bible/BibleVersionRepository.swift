
import Foundation

public protocol BibleVersionAPIClient: Sendable {
    func version(withId id: Int) async throws -> BibleVersion
}

public protocol BibleVersionDiskCache: Sendable {
    func version(withId id: Int) async -> BibleVersion?
    func setVersion(_ version: BibleVersion) async
}

public final class VersionClient: BibleVersionAPIClient {
    public init() {}
    
    public func version(withId id: Int) async throws -> BibleVersion {
        let rawData = try await BibleAPIs.metadata(versionId: id)
        let versionObject = try JSONDecoder().decode(BibleVersionObject.self, from: rawData)
        return versionObject.response.data
    }
}

public actor VersionCache: BibleVersionDiskCache {
    public init() {}
    
    private var cache: [Int: BibleVersion] = [:]
    
    public func version(withId id: Int) async -> BibleVersion? {
        cache[id]
    }
    
    public func setVersion(_ version: BibleVersion) async {
        cache[version.id] = version
    }
}

public actor BibleVersionRepository: ObservableObject {

    private let apiClient: BibleVersionAPIClient
    private let diskCache: BibleVersionDiskCache
    
    private var inFlightTasks: [Int: Task<BibleVersion, Error>] = [:]
    
    public init(apiClient: BibleVersionAPIClient, diskCache: BibleVersionDiskCache) {
        self.apiClient = apiClient
        self.diskCache = diskCache
    }
    
    public func version(withId id: Int) async throws -> BibleVersion {
        // Check cache first
        if let cached = await diskCache.version(withId: id) {
            return cached
        }
        
        // If a fetch is already in-flight, await its result
        if let task = inFlightTasks[id] {
            return try await task.value
        }
        
        // Otherwise, create a new fetch task
        let task = Task { [apiClient, diskCache] in
            let version = try await apiClient.version(withId: id)
            await diskCache.setVersion(version)
            return version
        }
        
        inFlightTasks[id] = task
        
        defer { inFlightTasks[id] = nil }
        
        return try await task.value
    }
    
//    func loadFixture(_ testFixture) {
//        
//    }
}
