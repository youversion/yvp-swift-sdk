import Foundation

public enum URLBuilder {
    
    private static var baseURLComponents: URLComponents {
        var components = URLComponents()
        components.scheme = "https"
        components.host = YouVersionPlatformConfiguration.apiHost
        return components
    }
    
    static func highlightsURL(usfm: String, versionId: Int, accessToken: String) -> URL? {
        var components = baseURLComponents
        components.path = "/highlights/chapter"
        components.queryItems = [
            URLQueryItem(name: "lat", value: accessToken),
            URLQueryItem(name: "version", value: String(versionId)),
            URLQueryItem(name: "usfm", value: usfm),
        ]
        return components.url
    }
    
    static func userURL(accessToken: String) -> URL? {
        var components = baseURLComponents
        components.path = "/auth/me"
        components.queryItems = [
            URLQueryItem(name: "lat", value: accessToken)
        ]
        return components.url
    }
    
    static func authURL(appKey: String,
                         requiredPermissions: Set<YVPPermission> = [],
                         optionalPermissions: Set<YVPPermission> = []) -> URL? {
        var components = baseURLComponents
        components.path = "/auth/login"
        components.queryItems = [
            URLQueryItem(name: "app_id", value: appKey),
            URLQueryItem(name: "language", value: "en"),  // TODO load from the system
            URLQueryItem(name: "required_perms", value: requiredPermissions.map { $0.rawValue }.joined(separator: ",")),
            URLQueryItem(name: "opt_perms", value: optionalPermissions.map { $0.rawValue }.joined(separator: ","))
        ]
        return components.url
    }
    
    static func votdURL(versionId: Int, accessToken: String) -> URL? {
        var components = baseURLComponents
        components.path = "/votd/today"
        components.queryItems = [
            URLQueryItem(name: "lat", value: accessToken),
            URLQueryItem(name: "translationId", value: String(versionId)),
        ]
        return components.url
    }
}
