import Foundation

public struct BibleReference: Comparable, Codable, Hashable {
    public let versionId: Int
    public let bookUSFM: String
    public let chapterStart: Int
    public let chapterEnd: Int
    public let verseStart: Int
    public let verseEnd: Int

    public init(versionId: Int, bookUSFM: String, chapter: Int, verse: Int) {
        assert(chapter >= 1, "Chapter must be greater than or equal to 1.")
        assert(verse >= 1, "Verse must be greater than or equal to 1.")
        
        self.versionId = versionId
        self.bookUSFM = bookUSFM
        self.chapterStart = chapter
        self.chapterEnd = chapter
        self.verseStart = verse
        self.verseEnd = verse
    }
    
    public init(versionId: Int, bookUSFM: String, chapterStart: Int, verseStart: Int, chapterEnd: Int, verseEnd: Int) {
        assert(chapterStart >= 1, "Starting chapter must be greater than or equal to 1.")
        assert(verseStart >= 1, "Starting verse must be greater than or equal to 1.")
        assert(chapterEnd >= 1, "Ending chapter must be greater than or equal to 1.")
        assert(verseEnd >= 1, "Ending verse must be greater than or equal to 1.")
        assert(chapterEnd >= chapterStart, "Ending chapter must be equal to or after starting chapter.")
        if chapterStart == chapterEnd {
            assert(verseEnd >= verseStart, "Ending verse must be equal to or after starting verse.")
        }
        
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
        return (a.bookUSFM < b.bookUSFM) ? -1 : 1
    }
    
    public static func < (lhs: BibleReference, rhs: BibleReference) -> Bool {
        compare(a: lhs, b: rhs) < 0
    }

    public var chapterUSFM: String? {
        "\(bookUSFM.uppercased()).\(chapterStart)"
    }
    
    public func isAdjacentOrOverlapping(with otherReference: BibleReference) -> Bool {
        guard versionId == otherReference.versionId && bookUSFM == otherReference.bookUSFM else {
            return false
        }
        
        let a = min(self, otherReference)
        let b = max(self, otherReference)
        
        if a.chapterEnd < b.chapterStart {
            return false
        } else if a.chapterEnd > b.chapterStart {
            return true
        } else {
            return a.verseEnd + 1 >= b.verseStart
        }
    }
    
    public static func referencesByMerging(references: [BibleReference]) -> [BibleReference] {
        var tmp = references
        tmp.sort()
        var i = 1
        while i < tmp.count {
            let previousReference = tmp[i - 1]
            let currentReference = tmp[i]
            if previousReference.isAdjacentOrOverlapping(with: currentReference) {
                tmp[i - 1] = referenceByMerging(a: previousReference, b: currentReference)
                tmp.remove(at: i)
            } else {
                i += 1
            }
        }
        return tmp
    }
    
    public static func referenceByMerging(a: BibleReference, b: BibleReference) -> BibleReference {
        assert(a.isAdjacentOrOverlapping(with: b), "This function requires the two references to be adjacent or overlapping.")
        
        let minReference = min(a, b)
        let maxReference = max(a, b)
        
        let further = if minReference.chapterEnd > maxReference.chapterEnd {
            minReference
        } else if minReference.chapterEnd < maxReference.chapterEnd {
            maxReference
        } else if minReference.verseEnd > maxReference.verseEnd {
            minReference
        } else {
            maxReference
        }
        return BibleReference(
            versionId: minReference.versionId,
            bookUSFM: minReference.bookUSFM,
            chapterStart: minReference.chapterStart,
            verseStart: minReference.verseStart,
            chapterEnd: further.chapterEnd,
            verseEnd: further.verseEnd
        )
    }
    
    static func unvalidatedReference(with usfm: String, versionId: Int) -> BibleReference? {
        func reference(bookUSFM: String, chapterStart: Int, verseStart: Int, chapterEnd: Int, verseEnd: Int) -> BibleReference? {
            if chapterStart > chapterEnd {
                return nil
            }
            if (chapterStart == chapterEnd) && (verseStart > verseEnd) {
                return nil
            }
            return BibleReference(versionId: versionId, bookUSFM: bookUSFM, chapterStart: chapterStart, verseStart: verseStart, chapterEnd: chapterEnd, verseEnd: verseEnd)
        }
        
        // GEN.1.3-1.5
        let patBCVCV = /(\w\w\w)\.(\d+)\.(\d+)-(\d+)\.(\d+)/
        if let match = usfm.wholeMatch(of: patBCVCV) {
            let (_, bText, cText, vText, c2Text, v2Text) = match.output
            if let c = Int(cText), let v = Int(vText), let c2 = Int(c2Text), let v2 = Int(v2Text) {
                return reference(bookUSFM: bText.uppercased(), chapterStart: c, verseStart: v, chapterEnd: c2, verseEnd: v2)
            }
            return nil
        }
        
        // GEN.1.3-GEN.1.5
        let patBCVBCV = /(\w\w\w)\.(\d+)\.(\d+)-(\w\w\w)\.(\d+)\.(\d+)/
        if let match = usfm.wholeMatch(of: patBCVBCV) {
            let (_, bText, cText, vText, b2Text, c2Text, v2Text) = match.output
            if let c = Int(cText), let v = Int(vText), let c2 = Int(c2Text), let v2 = Int(v2Text) {
                if String(bText) != String(b2Text) {
                    return nil
                }
                return reference(bookUSFM: bText.uppercased(), chapterStart: c, verseStart: v, chapterEnd: c2, verseEnd: v2)
            }
            return nil
        }
        
        // GEN.1.3-5
        let patBCVV = /(\w\w\w)\.(\d+)\.(\d+)-(\d+)/
        if let match = usfm.wholeMatch(of: patBCVV) {
            let (_, bText, cText, vText, v2Text) = match.output
            if let c = Int(cText), let v = Int(vText), let v2 = Int(v2Text) {
                return reference(bookUSFM: bText.uppercased(), chapterStart: c, verseStart: v, chapterEnd: c, verseEnd: v2)
            }
            return nil
        }
        
        // GEN.1.3
        let patBCV = /(\w\w\w)\.(\d+)\.(\d+)/
        if let match = usfm.wholeMatch(of: patBCV) {
            let (_, bText, cText, vText) = match.output
            if let c = Int(cText), let v = Int(vText) {
                return reference(bookUSFM: bText.uppercased(), chapterStart: c, verseStart: v, chapterEnd: c, verseEnd: v)
            }
            return nil
        }
        
        // GEN.1
        let patBC = /(\w\w\w)\.(\d+)/
        if let match = usfm.wholeMatch(of: patBC) {
            let (_, bText, cText) = match.output
            if let c = Int(cText) {
                return reference(bookUSFM: bText.uppercased(), chapterStart: c, verseStart: 1, chapterEnd: c, verseEnd: 1)
            }
            return nil
        }
        
        // GEN.1-2
        let patBCC = /(\w\w\w)\.(\d+)-(\d+)/
        if let match = usfm.wholeMatch(of: patBCC) {
            let (_, bText, cText, c2Text) = match.output
            if let c = Int(cText), let c2 = Int(c2Text) {
                return reference(bookUSFM: bText.uppercased(), chapterStart: c, verseStart: 1, chapterEnd: c2, verseEnd: 1)
            }
            return nil
        }
        
        return nil
    }
}
