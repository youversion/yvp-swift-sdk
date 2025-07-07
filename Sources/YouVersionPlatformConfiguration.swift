import Foundation

public struct YouVersionPlatformConfiguration {
    nonisolated(unsafe) public static var appId: String?
    nonisolated(unsafe) public static var apiHost = "api-dev.youversion.com"
    nonisolated(unsafe) public static var hostEnv: String?

    public static func configure(appId: String?, apiHost: String? = nil, hostEnv: String? = nil) {
        if let appId {
            Self.appId = appId
        }
        if let apiHost {
            Self.apiHost = apiHost
        }
        if let hostEnv {
            Self.hostEnv = hostEnv
        }
    }
}

// convenience function so the app can write their setup more simply:
// "import YouVersionPlatform; YouVersionPlatform.configure(appId: ...)"
public func configure(appId: String?, apiHost: String? = nil, hostEnv: String? = nil) {
    YouVersionPlatformConfiguration.configure(appId: appId, apiHost: apiHost, hostEnv: hostEnv)
}
