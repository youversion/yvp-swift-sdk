import Foundation

public struct BibleReference: Comparable, Codable, Hashable {
    public var versionId = 0
    public var book: String?
    public var c = 0
    public var c2 = 0
    public var v = 0
    public var v2 = 0

    public init(versionId: Int, b: String, c: Int, v: Int) {
        self.versionId = versionId
        self.book = b
        self.c = c
        self.c2 = c
        self.v = v
        self.v2 = v
    }
    
    public init(versionId: Int, b: String, c: Int, v: Int, c2: Int, v2: Int) {
        self.versionId = versionId
        self.book = b
        self.c = c
        self.c2 = c2
        self.v = v
        self.v2 = v2
    }
    
    public var isRange: Bool {
        c != c2 || v != v2
    }
    
    public static func compare(a: BibleReference, b: BibleReference) -> Int {
        // returns -1, 0, or 1
        if a.book == b.book {
            if a.c == b.c {
                if a.v == b.v {
                    if a.v2 == b.v2 {
                        return 0
                    }
                    return (a.v2 < b.v2) ? -1 : 1
                }
                return (a.v < b.v) ? -1 : 1
            }
            return (a.c < b.c) ? -1 : 1
        }
        return (a.book ?? "" < b.book ?? "") ? -1 : 1
    }
    
    public static func < (lhs: BibleReference, rhs: BibleReference) -> Bool {
        compare(a: lhs, b: rhs) < 0
    }

    public var toUSFMOfChapter: String? {
        guard let book else {
            return nil
        }
        return "\(book.uppercased()).\(c)"
    }
    
}
