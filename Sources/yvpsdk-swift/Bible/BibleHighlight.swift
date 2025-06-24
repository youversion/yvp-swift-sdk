import Foundation

public struct BibleHighlight: CustomDebugStringConvertible {
    var versionCode: Int
    var chapter: Int
    var verse: Int
    var color: String  // a hex value, e.g. "#FF00FF"

    public var debugDescription: String {
        return "\(chapter):\(verse) (\(versionCode)): \(color)"
    }
}
