import AuthenticationServices
import Foundation

public extension YouVersionAPI {
    enum Users {
        
        /// Presents the YouVersion login flow to the user and returns the login result upon completion.
        ///
        /// This function uses `ASWebAuthenticationSession` to authenticate the user with YouVersion, requesting the specified required and optional permissions.
        /// The function suspends until the user completes or cancels the login flow, returning the login result containing the authorization code and granted permissions.
        ///
        /// - Parameters:
        ///   - requiredPermissions: The set of permissions that must be granted by the user for successful login.
        ///   - optionalPermissions: The set of permissions that will be requested from the user but are not required for successful login.
        ///   - contextProvider: The presentation context provider used for presenting the authentication session.
        ///
        /// - Returns: A ``YouVersionLoginResult`` containing the authorization code and granted permissions upon successful login.
        ///
        /// - Throws: An error if authentication fails or is cancelled by the user.
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
        
        /// Retrieves user information for the authenticated user using the provided access token.
        ///
        /// This function fetches the user's profile information from the YouVersion API, decoding it into a ``YouVersionUserInfo`` model.
        /// If `"preview"` is provided as the access token, a preview user info object will be returned for development or testing purposes.
        ///
        /// - Parameter accessToken: The access token obtained from the login process, or `"preview"` for test data.
        ///
        /// - Returns: A ``YouVersionUserInfo`` object containing the user's profile information.
        ///
        /// - Throws: An error if the URL is invalid, the network request fails, or the response cannot be decoded.
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
