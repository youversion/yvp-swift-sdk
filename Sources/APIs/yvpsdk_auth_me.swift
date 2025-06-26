import Foundation

public struct YouVersionUserInfo: Codable, Sendable {
    public let firstName: String
    public let lastName: String
    public let userId: Int
    public let avatarUrlFormat: String?
    
    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case userId = "id"
        case avatarUrlFormat = "avatar_url"
    }
    
    public var avatarUrl: URL? {
        guard var urlString = avatarUrlFormat else {
            return nil
        }
        
        if urlString.hasPrefix("//") {
            urlString = "https:" + urlString
        }
        urlString = urlString.replacingOccurrences(of: "{width}", with: "200")
        urlString = urlString.replacingOccurrences(of: "{height}", with: "200")
        return URL(string: urlString)
    }
    
    static var preview: YouVersionUserInfo {
        YouVersionUserInfo(firstName: "John", lastName: "Smith", userId: 12345, avatarUrlFormat: nil)
    }
}

public func fetchUserInfo(lat: String) async throws -> YouVersionUserInfo {
    if lat == "preview" {
        return YouVersionUserInfo.preview
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
    guard var decodedResponse = try? JSONDecoder().decode(YouVersionUserInfo.self, from: data) else {
        throw URLError(.badServerResponse)
    }
    return decodedResponse
}
