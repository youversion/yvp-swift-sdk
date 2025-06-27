import Foundation

@MainActor
public class BibleVersion: ObservableObject {
    @Published public var isReady = false  // true when the metadata is cached
    public let id: Int  // version identifier, e.g. 111 for NIV

    private var metadata: BibleVersionData?

    // MARK: - Init and loading
    public init(_ id: Int) {
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
            self.isReady = (self.metadata != nil)
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

    public static func findByLanguage(_ lang: String? = nil) async -> [BibleVersionOverview] {
        do {
            return try await BibleVersionAPIs.findVersions(byLanguage: lang)
        } catch {
            print("findByLanguage error: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Misc

    public func isValidUSFMBookName(_ name: String) -> String? {
        guard let metadata else {
            return nil
        }
        let usfm = name.uppercased()
        for usfmCode in metadata.books.map(\.self.usfm) where usfmCode == usfm {
            return usfmCode
        }
        return nil
    }

    // Example: "https://www.bible.com/bible/111/1SA.3.10.NIV"
    public func shareUrl(reference: BibleReference) -> URL? {
        let prefix = "https://www.bible.com/bible/\(id)/"
        var urlString = ""

        guard let book = reference.book else {
            return nil
        }
        if reference.isRange {
            urlString = "\(prefix)\(book).\(reference.c).\(reference.v)-\(reference.v2).\(abbreviation ?? String(id))"
        } else {
            urlString = "\(prefix)\(book).\(reference.c).\(reference.v).\(abbreviation ?? String(id))"
        }

        return URL(string: urlString)
    }

    // MARK: - Formatting
    public func formatWithVersion(_ reference: BibleReference) -> String {
        let base = format(reference)
        if let abbreviation = metadata?.local_abbreviation ?? metadata?.abbreviation {
            if metadata?.language?.text_direction == "rtl" {
                return "\(abbreviation) \(base)"
            } else {
                return "\(base) \(abbreviation)"
            }
        }
        return base
    }

    public func format(_ reference: BibleReference) -> String {
        var chunks = formatWorker(reference)
        if metadata?.language?.text_direction == "rtl" {
            chunks.reverse()
        }
        return chunks.joined()
    }

    private func formatWorker(_ reference: BibleReference) -> [String] {
        // for convenience:
        let b = reference.book
        let c = reference.c
        let v = reference.v
        let c2 = reference.c2
        let v2 = reference.v2

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

    // MARK: - Operations

    private func isContiguousWith(_ first: BibleReference, other: BibleReference) -> Bool {
        if first.book != other.book {
            return false
        }
        if first.book == nil {
            return false
        }
        let a, b: BibleReference
        if BibleReference.compare(a: first, b: other) < 0 {
            a = first
            b = other
        } else {
            a = other
            b = first
        }

        // previously, here, we merged across chapter boundaries.
        // we can't do that without knowing the # of verses in the chapter in this version.
        // we don't have that info (well, not yet, not easily).

        if a.c2 < b.c {
            return false
        }
        if a.c2 > b.c {
            return true
        }
        if (a.v2 + 1) < b.v {
            return false
        }
        return true
    }

    public func mergeOverlapping(refs: [BibleReference]) -> [BibleReference] {
        var tmp = refs
        tmp.sort()
        var i = 1
        while i < tmp.count {
            if isContiguousWith(tmp[i - 1], other: tmp[i]) {
                tmp[i - 1] = fromOverlappingPair(a: tmp[i - 1], b: tmp[i])
                tmp.remove(at: i)
            } else {
                i += 1
            }
        }
        return tmp
    }

    nonisolated private func fromOverlappingPair(a: BibleReference, b: BibleReference) -> BibleReference {
        let x, y: BibleReference
        guard a.book == b.book, a.book != nil else {  // this shouldn't ever happen; fail in a reasonable way.
            return a
        }
        if BibleReference.compare(a: a, b: b) > 0 {
            x = b
            y = a
        } else {
            x = a
            y = b
        }
        var further: BibleReference
        if x.c2 > y.c2 {
            further = x
        } else if x.c2 < y.c2 {
            further = y
        } else if x.v2 > y.v2 {
            further = x
        } else {
            further = y
        }
        return BibleReference(versionId: x.versionId, b: x.book!, c: x.c, v: x.v, c2: further.c2, v2: further.v2)
    }

    // MARK: - Simple Accessors

    /// e.g. "KJV". Meant to be user-visible.
    public var abbreviation: String? {
        if let versionData = BibleVersionCache.metadataIfCached(versionId: id),
           let abbreviation = versionData.local_abbreviation {
            return abbreviation
        }
        return nil
    }

    public var copyrightLong: String? {
        if let versionData = BibleVersionCache.metadataIfCached(versionId: id),
           let str = versionData.copyright_long {
            return str.text
        }
        return nil
    }

    public var copyrightShort: String? {
        if let versionData = BibleVersionCache.metadataIfCached(versionId: id),
           let str = versionData.copyright_short {
            return str.text
        }
        return nil
    }

    public var bookCodes: [String] {
        metadata?.books.compactMap { $0.usfm } ?? []
    }

    public func bookName(_ book: String?) -> String? {
        guard let metadata, let book else {
            return nil
        }
        for b in metadata.books where b.usfm == book {
            return b.human ?? b.human_long
        }
        return nil
    }

    /// If metadata hasn't yet been loaded, or if the book code is bad, this will return 0.
    public func numberOfChaptersInBook(_ bookCode: String?) -> Int {
        guard let metadata, let bookCode else {
            return 0
        }
        for b in metadata.books where b.usfm == bookCode {
            if let chapters = b.chapters {
                return chapters.reduce(0) { $0 + (($1.canonical == true) ? 1 : 0) }
            }
        }
        return 0
    }

    /// Returns an array of human-visible labels for chapters.
    /// In standard English books, this'll be like ["1", "2"...] but other cases exist.
    /// If metadata hasn't yet been loaded, or if the book code is bad, this will return []
    public func chapterLabels(_ bookCode: String) -> [String] {
        guard let metadata else {
            return []
        }
        for b in metadata.books where b.usfm == bookCode {
            if let chapters = b.chapters {
                return chapters.compactMap { ($0.canonical == true) ? $0.human : nil }
            }
        }
        return []
    }

}
