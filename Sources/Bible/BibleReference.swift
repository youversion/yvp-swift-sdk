import Foundation

public struct BibleReference: Comparable, Codable, Hashable {
    public let versionId: Int
    public var bookUSFM: String?
    public let chapterStart: Int
    public let chapterEnd: Int
    public let verseStart: Int
    public let verseEnd: Int

    public init(versionId: Int, bookUSFM: String, chapter: Int, verse: Int) {
        self.versionId = versionId
        self.bookUSFM = bookUSFM
        self.chapterStart = chapter
        self.chapterEnd = chapter
        self.verseStart = verse
        self.verseEnd = verse
    }
    
    public init(versionId: Int, bookUSFM: String, chapterStart: Int, verseStart: Int, chapterEnd: Int, verseEnd: Int) {
        self.versionId = versionId
        self.bookUSFM = bookUSFM
        self.chapterStart = chapterStart
        self.chapterEnd = chapterEnd
        self.verseStart = verseStart
        self.verseEnd = verseEnd
    }
    
    public var isRange: Bool {
        chapterStart != chapterEnd || verseStart != verseEnd
    }
    
    public static func compare(a: BibleReference, b: BibleReference) -> Int {
        // returns -1, 0, or 1
        if a.bookUSFM == b.bookUSFM {
            if a.chapterStart == b.chapterStart {
                if a.verseStart == b.verseStart {
                    if a.verseEnd == b.verseEnd {
                        return 0
                    }
                    return (a.verseEnd < b.verseEnd) ? -1 : 1
                }
                return (a.verseStart < b.verseStart) ? -1 : 1
            }
            return (a.chapterStart < b.chapterStart) ? -1 : 1
        }
        return (a.bookUSFM ?? "" < b.bookUSFM ?? "") ? -1 : 1
    }
    
    public static func < (lhs: BibleReference, rhs: BibleReference) -> Bool {
        compare(a: lhs, b: rhs) < 0
    }

    public var chapterUSFM: String? {
        guard let bookUSFM else {
            return nil
        }
        return "\(bookUSFM.uppercased()).\(chapterStart)"
    }
    
}
