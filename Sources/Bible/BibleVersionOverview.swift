import Foundation

public struct BibleVersionOverview: Decodable, Sendable {
    public var id: Int
    public var title: String?
    public var abbreviation: String?
    public var language: String?  // iso_639_3
}
