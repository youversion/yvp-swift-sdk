import AuthenticationServices
import Foundation

public extension YouVersionAPI {
    enum Users {
        
        @MainActor
        public static func logIn(
            requiredPermissions: Set<YouVersionPermission>,
            optionalPermissions: Set<YouVersionPermission>,
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
                                let result = try YouVersionLoginResult(url: callbackURL)
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
        
        public static func userInfo(accessToken: String) async throws -> YouVersionUserInfo {
            if accessToken == "preview" {
                return YouVersionUserInfo.preview
            }
            
            guard let url = URLBuilder.userURL(accessToken: accessToken) else {
                throw URLError(.badURL)
            }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let decodedResponse = try? JSONDecoder().decode(YouVersionUserInfo.self, from: data) else {
                throw URLError(.badServerResponse)
            }
            return decodedResponse
        }
        
    }
}
