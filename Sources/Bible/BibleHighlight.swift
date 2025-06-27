import Foundation

public struct BibleHighlight: CustomDebugStringConvertible, Sendable {
    public let versionId: Int
    public let chapter: Int
    public let verse: Int
    public let color: String  // a hex value, e.g. "#FF00FF"

    public var debugDescription: String {
        "\(chapter):\(verse) (\(versionId)): \(color)"
    }
    
    static var preview: BibleHighlight {
        BibleHighlight(versionId: 1, chapter: 3, verse: 2, color: "#FFF9B1")
    }
}
