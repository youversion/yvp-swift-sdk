import Foundation

enum URLBuilder {
    
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
            URLQueryItem(name: "usfm", value: usfm)
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
    
    static func authURL(
        appKey: String,
        requiredPermissions: Set<YouVersionPermission> = [],
        optionalPermissions: Set<YouVersionPermission> = []
    ) -> URL? {
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
    
    static func votdURL(versionId: Int) -> URL? {
        var components = baseURLComponents
        components.path = "/votd/today"
        components.queryItems = [
            URLQueryItem(name: "version", value: String(versionId))
        ]
        return components.url
    }
    
    static func versionURL(versionId: Int) -> URL? {
        var components = baseURLComponents
        components.path = "/bible/version"
        
        let env = YouVersionPlatformConfiguration.hostEnv ?? ""
        components.queryItems = [
            URLQueryItem(name: "version", value: "\(versionId)\(env)")
        ]
        return components.url
    }
    
    static func chapterURL(usfm: String, versionId: Int) -> URL? {
        var components = baseURLComponents
        components.path = "/bible/chapter"
        
        let env = YouVersionPlatformConfiguration.hostEnv ?? ""
        components.queryItems = [
            URLQueryItem(name: "version", value: "\(versionId)"),
            URLQueryItem(name: "usfm", value: "\(usfm)\(env)")
        ]
        return components.url
    }
    
    static func versionsURL(languageTag: String) -> URL? {
        var components = baseURLComponents
        components.path = "/bible/versions"
        
        let env = YouVersionPlatformConfiguration.hostEnv ?? ""
        components.queryItems = [
            URLQueryItem(name: "language", value: "\(languageTag)\(env)")
        ]
        return components.url
    }
}
