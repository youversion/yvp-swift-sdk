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

@MainActor
public func logIn(
    requiredPermissions: Set<YVPPermission>,
    optionalPermissions: Set<YVPPermission>,
    contextProvider: ASWebAuthenticationPresentationContextProviding
) async throws -> YouVersionLoginResult {
    guard let appKey = YouVersionPlatformConfiguration.appKey else {
        preconditionFailure("YouVersionPlatformConfiguration.appKey must be set")
    }
    
    guard let url = URLBuilder.authURL(
        appKey: appKey,
        requiredPermissions: requiredPermissions,
        optionalPermissions: optionalPermissions
    ) else {
        throw URLError(.badURL)
    }
    
    return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<YouVersionLoginResult, Error>) in
        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: "youversionauth"
        ) { callbackURL, error in
            Task { @MainActor in
                if let error {
                    continuation.resume(throwing: error)
                } else if let callbackURL {
                    do {
                        let result = try parseAuthCallback(callbackURL)
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                } else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                }
            }
        }
        
        session.presentationContextProvider = contextProvider
        session.start()
    }
}

public struct YouVersionLoginResult: Sendable {
    public let accessToken: String?
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

    if status == "success", let latValue, let yvpUserId {
        return YouVersionLoginResult(accessToken: latValue, permissions: perms, errorMsg: nil, yvpUserId: yvpUserId)
    } else if status == "canceled" {
        return YouVersionLoginResult(accessToken: nil, permissions: [], errorMsg: nil, yvpUserId: nil)
    }
    // error!
    return YouVersionLoginResult(accessToken: nil, permissions: perms, errorMsg: callbackURL.query(), yvpUserId: nil)
}
