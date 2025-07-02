import Foundation

public extension BibleVersion {
    
    func book(with usfm: String) -> BibleBook? {
        books.first { $0.usfm == usfm }
    }
    
    func isBookUSFMValid(_ usfm: String) -> Bool {
        let usfmUpper = usfm.uppercased()
        return books.contains(where: { $0.usfm == usfmUpper }) == true
    }
    
    var bookUSFMs: [String] {
        books.compactMap { $0.usfm } ?? []
    }

    func bookName(_ bookUSFM: String) -> String? {
        guard let book = book(with: bookUSFM) else {
            return nil
        }
        return book.human ?? book.humanLong
    }
    
    public func reference(with usfm: String) -> BibleReference? {
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
        
        guard let reference = BibleReference.unvalidatedReference(with: usfm, versionId: id),
              isBookUSFMValid(reference.bookUSFM) else {
            return nil
        }
        return reference
        // TODO: check that the chapter and verse numbers are valid for this version.
    }
    
    /// If metadata hasn't yet been loaded, or if the book code is bad, this will return 0.
    public func numberOfChaptersInBook(_ bookUSFM: String) -> Int {
        guard let book = book(with: bookUSFM) else {
            return 0
        }
        return book.chapters?.filter { $0.isCanonical == true }.count ?? 0
    }

    /// Returns an array of displayable labels for chapters.
    /// In standard English books, this'll be like ["1", "2"...] but other cases exist.
    /// If metadata hasn't yet been loaded, or if the book code is bad, this will return []
    public func chapterLabels(_ bookUSFM: String) -> [String] {
        guard let book = book(with: bookUSFM) else {
            return []
        }
        return book.chapters?.filter({ $0.isCanonical == true }).compactMap { $0.human } ?? []
    }
    
    // Example: "https://www.bible.com/bible/111/1SA.3.10.NIV"
    public func shareUrl(reference: BibleReference) -> URL? {
        let prefix = "https://www.bible.com/bible/\(id)/"
        let book = reference.bookUSFM
        let version = localizedAbbreviation ?? abbreviation ?? String(id ?? 0)
        
        let urlString = if reference.isRange {
            "\(prefix)\(book).\(reference.chapterStart).\(reference.verseStart)-\(reference.verseEnd).\(version)"
        } else {
            "\(prefix)\(book).\(reference.chapterStart).\(reference.verseStart).\(version)"
        }

        return URL(string: urlString)
    }
    
    public func displayTitle(for reference: BibleReference, includesVersionAbbreviation: Bool = true) -> String {
        var referenceOnlyChunks = titleChunks(for: reference)
        let isRTL = language?.textDirection == "rtl"
        if isRTL {
            referenceOnlyChunks.reverse()
        }
        let referenceOnlyTitle = referenceOnlyChunks.joined()
        var titleChunks = [referenceOnlyTitle]
        
        if includesVersionAbbreviation, let abbreviation = localizedAbbreviation ?? abbreviation {
            titleChunks.append(abbreviation)
            if isRTL {
                titleChunks.reverse()
            }
        }
        return titleChunks.joined(separator: " ")
    }

    private func titleChunks(for reference: BibleReference) -> [String] {
        // for convenience:
        let b = reference.bookUSFM
        let c = reference.chapterStart
        let v = reference.verseStart
        let c2 = reference.chapterEnd
        let v2 = reference.verseEnd

        let bcPart1 = bookName(b) ?? ""
        let bcPart2: String
        let bcPart3: String
        var csep = ":"

        if numberOfChaptersInBook(b) == 1 {
            csep = " "
            bcPart2 = ""
            bcPart3 = ""
        } else {
            bcPart2 = " "
            bcPart3 = String(c)
        }
        if (v == 0) ||
            ((v <= 1) && (v2 == 0)) {  // previously, we also looked here at numVersesIn c2, to merge. Removed for now.
            if c == c2 {
                return [bcPart1, bcPart2, bcPart3]
            }
            return [bcPart1, bcPart2, bcPart3, "-", String(c2)]
        } else if c != c2 {
            var vNotZero = v
            if vNotZero == 0 {
                vNotZero = 1
            }
            var v2NotZero = v2
            if v2NotZero == 0 {
                v2NotZero = 999  // TODO fix this hack. Previously, this set it to: numVersesIn(b: b, c: c2)
            }
            return [bcPart1, bcPart2, bcPart3, csep, String(vNotZero), "-", String(c2), csep, String(v2NotZero)]
        } else {
            if v2 == 999 {
                return [bcPart1, bcPart2, bcPart3, csep, String(v), "-"]
            }
            if reference.isRange {
                return [bcPart1, bcPart2, bcPart3, csep, String(v), "-", String(v2)]
            }
            if v != 0 {
                return [bcPart1, bcPart2, bcPart3, csep, String(v)]
            }
            return [bcPart1, bcPart2, bcPart3]
        }
    }
}
