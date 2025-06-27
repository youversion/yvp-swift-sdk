import Foundation

public struct BibleVersionOverview: Decodable, Sendable {
    public let id: Int
    public let title: String?
    public let abbreviation: String?
    public let language: String?  // iso_639_3
}
