import Foundation

public struct BibleVersionOverview: Decodable, Sendable {
    var id: Int
    var title: String?
    var abbreviation: String?
    var language: String?  // iso_639_3
}
