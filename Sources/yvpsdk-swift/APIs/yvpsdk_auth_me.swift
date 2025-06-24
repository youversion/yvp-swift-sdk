import Foundation

public struct YouVersionUserInfo: Sendable {
    public let firstName: String
    public let lastName: String
    public let userId: String
    public let avatarUrl: String?
}

// private; only for decoding the server response
struct AuthMeResponse: Codable {
    let first_name: String // swiftlint:disable:this identifier_name
    let last_name: String // swiftlint:disable:this identifier_name
    let avatar_url: String? // swiftlint:disable:this identifier_name
    let id: Int
}

public func fetchUserInfo(lat: String) async throws -> YouVersionUserInfo {
    if lat == "preview" {
        let info = YouVersionUserInfo(firstName: "John", lastName: "Smith", userId: "12345", avatarUrl: nil)
        return info
    }
    
    var components = URLComponents()
    components.scheme = "https"
    components.host = YouVersionPlatformConfiguration.apiHost
    components.path = "/auth/me"
    components.queryItems = [
        URLQueryItem(name: "lat", value: lat)
    ]
    
    guard let url = components.url else {
        throw URLError(.badURL)
    }
    
    let (data, _) = try await URLSession.shared.data(from: url)
    guard let decodedResponse = try? JSONDecoder().decode(AuthMeResponse.self, from: data) else {
        throw URLError(.badServerResponse)
    }
    var avatarUrl = decodedResponse.avatar_url
    if avatarUrl != nil {
        if avatarUrl!.hasPrefix("//") {
            avatarUrl = "https:" + avatarUrl!
        }
        avatarUrl = avatarUrl?.replacingOccurrences(of: "{width}", with: "200")
        avatarUrl = avatarUrl?.replacingOccurrences(of: "{height}", with: "200")
    }
    return YouVersionUserInfo(firstName: decodedResponse.first_name,
                              lastName: decodedResponse.last_name,
                              userId: String(decodedResponse.id),
                              avatarUrl: avatarUrl)
}
