import Foundation

public struct BibleHighlight: CustomDebugStringConvertible, Sendable {
    public let versionCode: Int
    public let chapter: Int
    public let verse: Int
    public let color: String  // a hex value, e.g. "#FF00FF"

    public var debugDescription: String {
        "\(chapter):\(verse) (\(versionCode)): \(color)"
    }
    
    static var preview: BibleHighlight {
        BibleHighlight(versionCode: 1, chapter: 3, verse: 2, color: "#FFF9B1")
    }
}
