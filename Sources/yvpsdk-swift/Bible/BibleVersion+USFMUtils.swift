import Foundation

extension BibleVersion {
    
    public func usfm(_ txt: String) -> BibleReference? {
        guard self.isReady else {
            return nil
        }

        let text = txt.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let len = text.count
        if len < 3 {
            return nil
        }

        // if there's a range indicated with + characters, return the first valid range:
        let subs = text.split(separator: "+")
        if subs.count > 1 {
            let refs = subs.map { usfm(String($0)) }
            let merged = mergeOverlapping(refs: refs.compactMap { $0 })
            return merged[0]
        }

        if var ref = simpleUsfmParse(txt), let validBook = isValidUSFMBookName(ref.book ?? "") {
            ref.book = validBook
            return ref
        }
        // TODO: check that the chapter and verse numbers are valid for this version.
        return nil
    }

    /// Most people should call usfm(); this skips all validation and only handles the simple easy case.
    /// In particular, the book name is not validated.
    nonisolated func simpleUsfmParse(_ text: String) -> BibleReference? {
        let patBCVCV = /(\w\w\w)\.(\d+)\.(\d+)-(\d+)\.(\d+)/
        if let match = text.wholeMatch(of: patBCVCV) {
            let (_, bText, cText, vText, c2Text, v2Text) = match.output
            if let c = Int(cText), let v = Int(vText), let c2 = Int(c2Text), let v2 = Int(v2Text) {
                if c > c2 {
                    return nil
                }
                if (c == c2) && (v > v2) {
                    return nil
                }
                return BibleReference(versionCode: code, b: String(bText), c: c, v: v, c2: c2, v2: v2)
            }
            return nil
        }
        
        let patBCVBCV = /(\w\w\w)\.(\d+)\.(\d+)-(\w\w\w)\.(\d+)\.(\d+)/
        if let match = text.wholeMatch(of: patBCVBCV) {
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
                return BibleReference(versionCode: code, b: String(bText), c: c, v: v, c2: c2, v2: v2)
            }
            return nil
        }
        
        let patBCVV = /(\w\w\w)\.(\d+)\.(\d+)-(\d+)/
        if let match = text.wholeMatch(of: patBCVV) {
            let (_, bText, cText, vText, v2Text) = match.output
            if let c = Int(cText), let v = Int(vText), let v2 = Int(v2Text) {
                if v > v2 {
                    return nil
                }
                return BibleReference(versionCode: code, b: String(bText), c: c, v: v, c2: c, v2: v2)
            }
            return nil
        }
        
        let patBCV = /(\w\w\w)\.(\d+)\.(\d+)/
        if let match = text.wholeMatch(of: patBCV) {
            let (_, bText, cText, vText) = match.output
            if let c = Int(cText), let v = Int(vText) {
                return BibleReference(versionCode: code, b: String(bText), c: c, v: v)
            }
            return nil
        }
        
        let patBC = /(\w\w\w)\.(\d+)/
        if let match = text.wholeMatch(of: patBC) {
            let (_, bText, cText) = match.output
            if let c = Int(cText) {
                return BibleReference(versionCode: code, b: String(bText), c: c, v: 0)
            }
            return nil
        }
        
        let patBCC = /(\w\w\w)\.(\d+)-(\d+)/
        if let match = text.wholeMatch(of: patBCC) {
            let (_, bText, cText, c2Text) = match.output
            if let c = Int(cText), let c2 = Int(c2Text) {
                if c > c2 {
                    return nil
                }
                return BibleReference(versionCode: code, b: String(bText), c: c, v: 0, c2: c2, v2: 0)
            }
            return nil
        }
        
        return nil
    }
    
}
