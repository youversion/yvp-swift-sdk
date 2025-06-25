import Foundation

public struct BibleHighlight: CustomDebugStringConvertible {
    public var versionCode: Int
    public var chapter: Int
    public var verse: Int
    public var color: String  // a hex value, e.g. "#FF00FF"

    public init(versionCode: Int, chapter: Int, verse: Int, color: String) {
        self.versionCode = versionCode
        self.chapter = chapter
        self.verse = verse
        self.color = color
    }

    public var debugDescription: String {
        return "\(chapter):\(verse) (\(versionCode)): \(color)"
    }
}
