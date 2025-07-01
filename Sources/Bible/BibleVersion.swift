import Foundation

@MainActor
public class BibleVersion: ObservableObject {
    @Published public var isReady = false  // true when the metadata is cached
    public let id: Int  // version identifier, e.g. 111 for NIV

    private var metadata: BibleVersionData?

    // MARK: - Init and loading
    public init(_ id: Int) {
        assert(id > 0, "Version identifier must be greater than zero.")
        
        self.id = id
        if let m = BibleVersionCache.metadataIfCached(versionId: id) {
            self.metadata = m
            self.isReady = true
        }
    }

    public var readied: BibleVersion {
        if isReady {
            return self
        }
        Task {
            await loadMetadataIfNeeded()
            isReady = metadata != nil
        }
        return self
    }

    private func loadMetadataIfNeeded() async {
        if metadata == nil {
            metadata = BibleVersionCache.metadataIfCached(versionId: id)
        }
        
        if metadata == nil {
            do {
                metadata = try await BibleVersionCache.metadataFromServer(versionId: id)
            } catch {
                print("error getting metadata: \(error.localizedDescription)")
            }
        }
    }

    public static func forLanguageTag(_ languageTag: String? = nil) async -> [BibleVersionOverview] {
        do {
            return try await BibleVersionAPIs.versions(forLanguageTag: languageTag)
        } catch {
            print("forLanguageTag error: \(error.localizedDescription)")
            return []
        }
    }

    public func isBookUSFMValid(_ usfm: String) -> Bool {
        let usfmUpper = usfm.uppercased()
        return metadata?.books.contains(where: { $0.usfm == usfmUpper }) == true
    }

    // Example: "https://www.bible.com/bible/111/1SA.3.10.NIV"
    public func shareUrl(reference: BibleReference) -> URL? {
        let prefix = "https://www.bible.com/bible/\(id)/"
        var urlString = ""
        let book = reference.bookUSFM
        
        if reference.isRange {
            urlString = "\(prefix)\(book).\(reference.chapterStart).\(reference.verseStart)-\(reference.verseEnd).\(abbreviation ?? String(id))"
        } else {
            urlString = "\(prefix)\(book).\(reference.chapterStart).\(reference.verseStart).\(abbreviation ?? String(id))"
        }

        return URL(string: urlString)
    }

    // MARK: - Formatting
    public func formatWithVersion(_ reference: BibleReference) -> String {
        let base = format(reference)
        if let abbreviation = metadata?.localizedAbbreviation ?? metadata?.abbreviation {
            if metadata?.language?.textDirection == "rtl" {
                return "\(abbreviation) \(base)"
            } else {
                return "\(base) \(abbreviation)"
            }
        }
        return base
    }

    public func format(_ reference: BibleReference) -> String {
        var chunks = formatWorker(reference)
        if metadata?.language?.textDirection == "rtl" {
            chunks.reverse()
        }
        return chunks.joined()
    }

    private func formatWorker(_ reference: BibleReference) -> [String] {
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

    // MARK: - Simple Accessors

    /// e.g. "KJV". Meant to be user-visible.
    public var abbreviation: String? {
        let version = BibleVersionCache.metadataIfCached(versionId: id)
        return version?.localizedAbbreviation
    }

    public var copyrightLong: String? {
        let version = BibleVersionCache.metadataIfCached(versionId: id)
        return version?.copyrightLong?.text
    }

    public var copyrightShort: String? {
        let version = BibleVersionCache.metadataIfCached(versionId: id)
        return version?.copyrightShort?.text
    }

    public var bookUSFMs: [String] {
        metadata?.books.compactMap { $0.usfm } ?? []
    }

    public func bookName(_ bookUSFM: String) -> String? {
        guard let book = metadata?.book(with: bookUSFM) else {
            return nil
        }
        return book.human ?? book.humanLong
    }

    /// If metadata hasn't yet been loaded, or if the book code is bad, this will return 0.
    public func numberOfChaptersInBook(_ bookUSFM: String) -> Int {
        guard let book = metadata?.book(with: bookUSFM) else {
            return 0
        }
        return book.chapters?.filter { $0.isCanonical == true }.count ?? 0
    }

    /// Returns an array of displayable labels for chapters.
    /// In standard English books, this'll be like ["1", "2"...] but other cases exist.
    /// If metadata hasn't yet been loaded, or if the book code is bad, this will return []
    public func chapterLabels(_ bookUSFM: String) -> [String] {
        guard let book = metadata?.book(with: bookUSFM) else {
            return []
        }
        return book.chapters?.filter({ $0.isCanonical == true }).compactMap { $0.human } ?? []
    }

}
