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
        books.compactMap { $0.usfm }
    }

    func bookName(_ bookUSFM: String) -> String? {
        guard let book = book(with: bookUSFM) else {
            return nil
        }
        return book.human ?? book.humanLong
    }
    
    func reference(with usfm: String) -> BibleReference? {
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
    func numberOfChaptersInBook(_ bookUSFM: String) -> Int {
        guard let book = book(with: bookUSFM) else {
            return 0
        }
        return book.chapters?.filter { $0.isCanonical == true }.count ?? 0
    }

    /// Returns an array of displayable labels for chapters.
    /// In standard English books, this'll be like ["1", "2"...] but other cases exist.
    /// If metadata hasn't yet been loaded, or if the book code is bad, this will return []
    func chapterLabels(_ bookUSFM: String) -> [String] {
        guard let book = book(with: bookUSFM) else {
            return []
        }
        return book.chapters?.filter({ $0.isCanonical == true }).compactMap { $0.human } ?? []
    }
    
    // Example: "https://www.bible.com/bible/111/1SA.3.10.NIV"
    func shareUrl(reference: BibleReference) -> URL? {
        let prefix = "https://www.bible.com/bible/\(id)/"
        let book = reference.bookUSFM
        let version = localizedAbbreviation ?? abbreviation ?? String(id)
        
        let urlString = if let verseStart = reference.verseStart {
            if let verseEnd = reference.verseEnd {
                "\(prefix)\(book).\(reference.chapter).\(verseStart)-\(verseEnd).\(version)"
            } else {
                "\(prefix)\(book).\(reference.chapter).\(verseStart).\(version)"
            }
        } else {
            "\(prefix)\(book).\(reference.chapter).\(version)"
        }

        return URL(string: urlString)
    }
    
    func displayTitle(for reference: BibleReference, includesVersionAbbreviation: Bool = true) -> String {
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
        let bookUSFM = reference.bookUSFM
        let bookName = bookName(bookUSFM) ?? ""
        
        let hasOneChapter = numberOfChaptersInBook(bookUSFM) == 1
        let chapterSeparator = hasOneChapter ? " " : ":"
        let bookAndChapterSeparator = hasOneChapter ? "" : " "
        let chapter = hasOneChapter ? "" : String(reference.chapter)

        switch (reference.verseStart, reference.verseEnd) {
        case (_, let verseEnd?) where verseEnd == 999:
            // Whole chapter
            return [bookName, bookAndChapterSeparator, chapter]
            
        case (nil, _):
            // Whole chapter
            return [bookName, bookAndChapterSeparator, chapter]
            
        case let (verseStart?, verseEnd?):
            if verseStart == verseEnd {
                // Single verse
                return [bookName, bookAndChapterSeparator, chapter, chapterSeparator, String(verseStart)]
            } else {
                // Verse range
                return [bookName, bookAndChapterSeparator, chapter, chapterSeparator, String(verseStart), "-", String(verseEnd)]
            }
            
        case let (verseStart?, nil):
            // Single verse with no verseEnd
            return [bookName, bookAndChapterSeparator, chapter, chapterSeparator, String(verseStart)]
        }
    }
}
