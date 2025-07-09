import Foundation
import SwiftUI

class FullReaderViewModel: ObservableObject {
    @Published var reference: BibleReference
    @Published var highlights: [BibleHighlight]?
    @Published var version: BibleVersion?
    @Published var isVersionLoaded: Bool = false
    @Published var showChrome: Bool = true
    @Published var lastScrollOffset: CGFloat = 0
    @Published var isUserScrolling: Bool = false

    let textOptions = BibleTextOptions(fontFamily: "Georgia", fontSize: 18)
    let highlightColor = "fffeca"
    let versionRepository = BibleVersionRepository()

    init(reference: BibleReference, version: BibleVersion? = nil) {
        self.reference = reference
        self.version = version
        self.isVersionLoaded = version != nil
        self.highlights = nil
    }

    @MainActor
    func loadVersionIfNeeded() async {
        if !isVersionLoaded {
            do {
                version = try await versionRepository.version(withId: reference.versionId)
                isVersionLoaded = true
            } catch {
                print("Error loading default version: \(error)")
            }
        }
    }

    func goToPreviousChapter() {
        if reference.chapter > 1 {
            reference = BibleReference(versionId: reference.versionId, bookUSFM: reference.bookUSFM, chapter: reference.chapter - 1)
            highlights = []
        } else if let version = version {
            if let index = version.books.firstIndex(where: { $0.usfm == reference.bookUSFM }), index > 0 {
                let previousBook = version.books[index - 1]
                let maxChapter = previousBook.chapters?.count ?? 0
                reference = BibleReference(versionId: reference.versionId, bookUSFM: previousBook.usfm ?? "", chapter: maxChapter)
                highlights = []
            }
        }
    }

    func goToNextChapter() {
        guard let version else { return }
        if let index = version.books.firstIndex(where: { $0.usfm == reference.bookUSFM }) {
            let currentBook = version.books[index]
            let maxChapter = currentBook.chapters?.count ?? 0
            if reference.chapter < maxChapter {
                reference = BibleReference(versionId: reference.versionId, bookUSFM: currentBook.usfm ?? "", chapter: reference.chapter + 1)
                highlights = []
            } else if index < version.books.count - 1 {
                let nextBook = version.books[index + 1]
                reference = BibleReference(versionId: reference.versionId, bookUSFM: nextBook.usfm ?? "", chapter: 1)
                highlights = []
            }
        }
    }

    func handleScroll(offset: CGFloat) {
        let threshold: CGFloat = 10
        if offset <= 0 {
            withAnimation(.easeInOut(duration: 0.1)) { self.showChrome = true }
        } else if abs(offset - lastScrollOffset) >= threshold {
            if offset < lastScrollOffset - threshold {
                withAnimation(.easeInOut(duration: 0.1)) { self.showChrome = false }
            } else if offset > lastScrollOffset + threshold {
                withAnimation(.easeInOut(duration: 0.1)) { self.showChrome = true }
            }
        }
        lastScrollOffset = offset
    }

    func handleVerseTap(chapter: Int, verse: Int) {
        guard let version = version else { return }
        let h = BibleHighlight(versionId: version.id, chapter: chapter, verse: verse, color: highlightColor)
        if var highlights = self.highlights,
           let index = highlights.firstIndex(where: { $0.versionId == h.versionId && $0.chapter == h.chapter && $0.verse == h.verse }) {
            if highlights[index].color == h.color {
                highlights.remove(at: index)
                self.highlights = highlights
            }
        } else {
            self.highlights?.append(h)
        }
    }

    @MainActor
    func onHeaderSelectionChange(v: Int, b: String?, c: Int) async {
        do {
            if self.version?.id != v {
                self.version = try await versionRepository.version(withId: v)
                self.isVersionLoaded = true
            }
            let newBookUSFM = b ?? self.reference.bookUSFM
            self.reference = BibleReference(versionId: v, bookUSFM: newBookUSFM, chapter: c)
            self.highlights = []
        } catch {
            print("Error loading version/chapter: \(error)")
        }
    }
}
