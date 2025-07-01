import Foundation

extension BibleVersion {
    
    public func reference(with usfm: String) -> BibleReference? {
        guard isReady else {
            return nil
        }

        let trimmedUSFM = usfm.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard trimmedUSFM.count >= 3 else {
            return nil
        }

        // if there's a range indicated with + characters, return the first valid range:
        let subUSFMs = trimmedUSFM.split(separator: "+")
        if subUSFMs.count > 1 {
            let refs = subUSFMs.compactMap { reference(with: String($0)) }
            let merged = BibleReference.referencesByMerging(references: refs.compactMap { $0 })
            return merged.first
        }
        
        guard let reference = unvalidatedReference(with: usfm),
              isBookUSFMValid(reference.bookUSFM) else {
            return nil
        }
        return reference
        // TODO: check that the chapter and verse numbers are valid for this version.
    }

    /// Most people should call `reference(with:)`. This function skips all validation and only handles the simple case.
    /// In particular, the book name is not validated.
    nonisolated func unvalidatedReference(with usfm: String) -> BibleReference? {
        let patBCVCV = /(\w\w\w)\.(\d+)\.(\d+)-(\d+)\.(\d+)/
        if let match = usfm.wholeMatch(of: patBCVCV) {
            let (_, bText, cText, vText, c2Text, v2Text) = match.output
            if let c = Int(cText), let v = Int(vText), let c2 = Int(c2Text), let v2 = Int(v2Text) {
                if c > c2 {
                    return nil
                }
                if (c == c2) && (v > v2) {
                    return nil
                }
                return BibleReference(versionId: id, bookUSFM: String(bText.uppercased()), chapterStart: c, verseStart: v, chapterEnd: c2, verseEnd: v2)
            }
            return nil
        }
        
        let patBCVBCV = /(\w\w\w)\.(\d+)\.(\d+)-(\w\w\w)\.(\d+)\.(\d+)/
        if let match = usfm.wholeMatch(of: patBCVBCV) {
            let (_, bText, cText, vText, b2Text, c2Text, v2Text) = match.output
            if let c = Int(cText),
               let v = Int(vText),
               let c2 = Int(c2Text),
               let v2 = Int(v2Text) {
                if String(bText) != String(b2Text) {
                    return nil
                }
                if c > c2 {
                    return nil
                }
                if (c == c2) && (v > v2) {
                    return nil
                }
                return BibleReference(versionId: id, bookUSFM: String(bText.uppercased()), chapterStart: c, verseStart: v, chapterEnd: c2, verseEnd: v2)
            }
            return nil
        }
        
        let patBCVV = /(\w\w\w)\.(\d+)\.(\d+)-(\d+)/
        if let match = usfm.wholeMatch(of: patBCVV) {
            let (_, bText, cText, vText, v2Text) = match.output
            if let c = Int(cText), let v = Int(vText), let v2 = Int(v2Text) {
                if v > v2 {
                    return nil
                }
                return BibleReference(versionId: id, bookUSFM: String(bText.uppercased()), chapterStart: c, verseStart: v, chapterEnd: c, verseEnd: v2)
            }
            return nil
        }
        
        let patBCV = /(\w\w\w)\.(\d+)\.(\d+)/
        if let match = usfm.wholeMatch(of: patBCV) {
            let (_, bText, cText, vText) = match.output
            if let c = Int(cText), let v = Int(vText) {
                return BibleReference(versionId: id, bookUSFM: String(bText.uppercased()), chapter: c, verse: v)
            }
            return nil
        }
        
        let patBC = /(\w\w\w)\.(\d+)/
        if let match = usfm.wholeMatch(of: patBC) {
            let (_, bText, cText) = match.output
            if let c = Int(cText) {
                return BibleReference(versionId: id, bookUSFM: String(bText.uppercased()), chapter: c, verse: 0)
            }
            return nil
        }
        
        let patBCC = /(\w\w\w)\.(\d+)-(\d+)/
        if let match = usfm.wholeMatch(of: patBCC) {
            let (_, bText, cText, c2Text) = match.output
            if let c = Int(cText), let c2 = Int(c2Text) {
                if c > c2 {
                    return nil
                }
                return BibleReference(versionId: id, bookUSFM: String(bText.uppercased()), chapterStart: c, verseStart: 0, chapterEnd: c2, verseEnd: 0)
            }
            return nil
        }
        
        return nil
    }
    
}
