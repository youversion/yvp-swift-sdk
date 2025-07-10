import SwiftUI

public struct BibleReaderHeaderView: View {
    @State private var showingBookPicker = false
    @State private var showingChapterPicker = false
    @State private var showingVersionPicker = false
    @State private var expandedBook: String? = nil
    @StateObject private var viewModel: BibleReaderHeaderViewModel
    let showChrome: Bool
    let onSelectionChange: ((Int, String, Int) -> Void)?
    let onCompactTap: (() -> Void)?

    public init(version: BibleVersion, book: String, chapter: Int, showChrome: Bool = true, onSelectionChange: ((Int, String, Int) -> Void)? = nil, onCompactTap: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: BibleReaderHeaderViewModel(version: version, book: book, chapter: chapter))
        self.showChrome = showChrome
        self.onSelectionChange = onSelectionChange
        self.onCompactTap = onCompactTap
    }

    public var body: some View {
        HStack {
            if showChrome {
                HalfPillPickers
                    .transition(.opacity)
            } else {
                CompactLabels
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: showChrome)
        .sheet(isPresented: $showingVersionPicker) {
            BibleVersionPickerView(
                permittedVersions: viewModel.permittedVersions,
                currentBook: viewModel.book,
                currentChapter: viewModel.chapter,
                isPresented: $showingVersionPicker,
                onVersionSelected: { versionId, book, chapter in
                    onSelectionChange?(versionId, book, chapter)
                }
            )
        }
        .sheet(isPresented: $showingBookPicker, onDismiss: { expandedBook = nil }) {
            BookAndChapterPickerView(
                expandedBook: $expandedBook,
                isPresented: $showingBookPicker,
                bookCodes: viewModel.bookCodes,
                versionId: viewModel.versionId,
                bookNameProvider: { bookCode in viewModel.bookName(for: bookCode) },
                chapterLabelsProvider: { bookCode in viewModel.chapterLabels(for: bookCode) },
                onSelectionChange: onSelectionChange
            )
        }
    }

    var HalfPillPickers: some View {
        let bookAndChapter = "\(viewModel.bookName(for: viewModel.book) ?? viewModel.book) \(viewModel.chapter)"
        return HStack(spacing: 0) {
            Button(action: { showingBookPicker = true }) {
                Text(bookAndChapter)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(minWidth: 60)
                    .padding(.horizontal, 10)
            }
            .buttonStyle(PlainButtonStyle())
            .clipShape(HalfPillShape(side: .left))

            Divider()
                .frame(width: 2, height: 40)
                .background(Color.white)
                .overlay(Color.white)

            Button(action: { handleVersionTap() }) {
                Text(viewModel.versionAbbreviation ?? String(viewModel.versionId))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(minWidth: 36)
                    .padding(.horizontal, 10)
            }
            .buttonStyle(PlainButtonStyle())
            .clipShape(HalfPillShape(side: .right))
        }
        .background(
            Capsule()
                .fill(Color.gray.opacity(0.15))
        )
        .padding(.bottom, 2)
        .frame(height: 40)
    }

    var CompactLabels: some View {
        let bookAndChapter = "\(viewModel.bookName(for: viewModel.book) ?? viewModel.book) \(viewModel.chapter)"
        return HStack(spacing: 8) {
            Text(bookAndChapter)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.black)
            
            Divider()
                .frame(width: 1, height: 14)
                .background(Color.black)
            
            Text(viewModel.versionAbbreviation ?? String(viewModel.versionId))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.black)
        }
        .frame(height: 24)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                onCompactTap?()
            }
        }
    }

    // Custom shape for half-pill sides
    enum HalfPillSide { case left, right }
    struct HalfPillShape: Shape {
        let side: HalfPillSide
        func path(in rect: CGRect) -> Path {
            var path = Path()
            let radius = rect.height / 2
            switch side {
            case .left:
                path.addArc(center: CGPoint(x: radius, y: rect.midY), radius: radius, startAngle: .degrees(90), endAngle: .degrees(270), clockwise: false)
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                path.closeSubpath()
            case .right:
                path.move(to: CGPoint(x: rect.minX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
                path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.midY), radius: radius, startAngle: .degrees(270), endAngle: .degrees(90), clockwise: false)
                path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
                path.closeSubpath()
            }
            return path
        }
    }

    func handleVersionTap() {
        viewModel.loadVersionsList()
        showingVersionPicker = true
    }

}

@MainActor
class BibleReaderHeaderViewModel: ObservableObject {
    @Published var permittedVersions: [BibleVersionOverview] = []

    let version: BibleVersion
    let book: String
    let chapter: Int

    init(version: BibleVersion, book: String, chapter: Int) {
        self.version = version
        self.book = book
        self.chapter = chapter
    }

    var bookCodes: [String] {
        version.bookUSFMs
    }

    func bookName(for bookCode: String) -> String? {
        version.bookName(bookCode)
    }

    func chapterLabels(for bookCode: String) -> [String] {
        version.chapterLabels(bookCode)
    }

    var versionId: Int {
        version.id
    }

    var versionAbbreviation: String? {
        version.abbreviation
    }

    func loadVersionsList() {
        guard permittedVersions.isEmpty else { return }
        Task {
            do {
                let versions = try await YouVersionAPI.Bible.versions(forLanguageTag: "eng")
                let sorted = versions.sorted {
                    ($0.title ?? "").localizedCaseInsensitiveCompare($1.title ?? "") == .orderedAscending
                }
                await MainActor.run {
                    permittedVersions = sorted
                }
            } catch {
                print("Error loading versions: \(error)")
                await MainActor.run {
                    permittedVersions = []
                }
            }
        }
    }
}

#Preview {
    // Create a minimal BibleVersion for preview purposes
    let sampleLanguage = BibleLanguage(
        localName: "English",
        name: "English",
        textDirection: "ltr"
    )
    
    let sampleChapters = Array(1...21).map { chapterNum in
        BibleBookChapter(isCanonical: true, human: String(chapterNum))
    }
    
    let sampleBook = BibleBook(
        usfm: "JHN",
        abbreviation: "John",
        human: "John",
        humanLong: "The Gospel of John",
        chapters: sampleChapters
    )
    
    let sampleVersion = BibleVersion(
        id: 1,
        localizedTitle: "King James Version",
        localizedAbbreviation: "KJV",
        abbreviation: "KJV",
        language: sampleLanguage,
        offline: nil,
        readerFooter: nil,
        readerFooterUrl: nil,
        copyrightShort: nil,
        copyrightLong: nil,
        books: [sampleBook]
    )
    
    VStack {
        Divider()
        BibleReaderHeaderView(version: sampleVersion, book: "JHN", chapter: 3, showChrome: true, onSelectionChange: { versionId, book, chapter in
            print("Version: \(versionId), Book: \(book), Chapter: \(chapter)")
        })
        Divider()
        BibleReaderHeaderView(version: sampleVersion, book: "JHN", chapter: 3, showChrome: false, onSelectionChange: { versionId, book, chapter in
            print("Version: \(versionId), Book: \(book), Chapter: \(chapter)")
        }, onCompactTap: {
            print("Compact header tapped!")
        })
        Divider()
    }
}
