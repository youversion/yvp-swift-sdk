import AuthenticationServices
import Foundation

public enum YVPPermission: String, CaseIterable, Hashable, Codable, CustomStringConvertible, Sendable {
    case bibles = "bibles"
    case highlights = "highlights"
    case votd = "votd"
    case demographics = "demographics"
    case bibleActivity = "bible_activity"

    public var description: String { rawValue }
}

public func login(
    contextProvider: ASWebAuthenticationPresentationContextProviding,
    required: Set<YVPPermission>,
    optional: Set<YVPPermission>,
    completion: @escaping (Result<YouVersionLoginResult, Error>) -> Void
) {
    guard let appKey = YouVersionPlatformConfiguration.appKey else {
        preconditionFailure("YouVersionPlatformConfiguration.appKey must be set")
    }
    guard let authURL = buildAuthURL(
        appKey: appKey,
        requiredPermissions: Array(required),
        optionalPermissions: Array(optional)
    ) else {
        completion(.failure(URLError(.badURL)))
        return
    }

    let session = ASWebAuthenticationSession(
        url: authURL,
        callbackURLScheme: "youversionauth"
    ) { callbackURL, error in
        if let error = error {
            completion(.failure(error))
        } else if let callbackURL = callbackURL {
            do {
                let result = try parseAuthCallback(callbackURL)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        } else {
            completion(.failure(URLError(.badServerResponse)))
        }
    }
    session.presentationContextProvider = contextProvider
    session.start()
}

private func buildAuthURL(appKey: String,
                          requiredPermissions: [YVPPermission] = [],
                          optionalPermissions: [YVPPermission] = []) -> URL? {
    var components = URLComponents()
    components.scheme = "https"
    components.host = YouVersionPlatformConfiguration.apiHost
    components.path = "/auth/login"
    components.queryItems = [
        URLQueryItem(name: "app_id", value: appKey),
        URLQueryItem(name: "language", value: "en"),  // TODO load from the system
        URLQueryItem(name: "required_perms", value: requiredPermissions.map { $0.rawValue }.joined(separator: ",")),
        URLQueryItem(name: "opt_perms", value: optionalPermissions.map { $0.rawValue }.joined(separator: ","))
    ]
    return components.url
}

public struct YouVersionLoginResult: Sendable {
    public let lat: String?
    public let permissions: [YVPPermission]
    public let errorMsg: String?
    public let yvpUserId: String?
}

private func parseAuthCallback(_ callbackURL: URL) throws -> YouVersionLoginResult {
    guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
          let queryItems = components.queryItems else {
        throw URLError(.badServerResponse)
    }
    let status = queryItems.first(where: { $0.name == "status" })?.value
    let yvpUserId = queryItems.first(where: { $0.name == "yvp_user_id" })?.value
    let latValue = queryItems.first(where: { $0.name == "lat" })?.value
    let permissions = queryItems.first(where: { $0.name == "grants" })?.value
    let perms = permissions?
        .split(separator: ",")
        .compactMap { YVPPermission(rawValue: String($0)) }
    ?? []

    if status == "success", let latValue = latValue, let yvpUserId = yvpUserId {
        return YouVersionLoginResult(lat: latValue, permissions: perms, errorMsg: nil, yvpUserId: yvpUserId)
    } else if status == "canceled" {
        return YouVersionLoginResult(lat: nil, permissions: [], errorMsg: nil, yvpUserId: nil)
    }
    // error!
    return YouVersionLoginResult(lat: nil, permissions: perms, errorMsg: callbackURL.query(), yvpUserId: nil)
}
