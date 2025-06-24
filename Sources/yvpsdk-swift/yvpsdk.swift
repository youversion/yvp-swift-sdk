import Foundation

public struct YouVersionPlatformConfiguration {
    nonisolated(unsafe) public static var appKey: String?
    nonisolated(unsafe) public static var apiHost: String = "api-dev.youversion.com"
    nonisolated(unsafe) public static var hostEnv: String?

    public static func configure(appKey: String?, apiHost: String? = nil, hostEnv: String? = nil) {
        if let appKey = appKey {
            Self.appKey = appKey
        }
        if let apiHost = apiHost {
            Self.apiHost = apiHost
        }
        if let hostEnv = hostEnv {
            Self.hostEnv = hostEnv
        }
    }
}

// convenience function so the app can write their setup more simply:
// "import YouVersionPlatform; YouVersionPlatform.configure(appKey: ...)"
public func configure(appKey: String?, apiHost: String? = nil, hostEnv: String? = nil) {
    YouVersionPlatformConfiguration.configure(appKey: appKey, apiHost: apiHost, hostEnv: hostEnv)
}
