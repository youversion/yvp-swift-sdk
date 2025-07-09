import SwiftUI

public struct BibleReaderHeaderView: View {
    @State private var showingBookPicker = false
    @State private var showingChapterPicker = false
    @State private var showingVersionPicker = false
    @State private var expandedBook: String? = nil
    @StateObject private var viewModel: BibleReaderHeaderViewModel
    let onSelectionChange: ((Int, String, Int) -> Void)?

    public init(version: BibleVersion, book: String, chapter: Int, onSelectionChange: ((Int, String, Int) -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: BibleReaderHeaderViewModel(version: version, book: book, chapter: chapter))
        self.onSelectionChange = onSelectionChange
    }

    public var body: some View {
        HStack {
            HalfPillPickers
        }
        .sheet(isPresented: $showingVersionPicker) {
            versionPickerView
        }
        .sheet(isPresented: $showingBookPicker, onDismiss: { expandedBook = nil }) {
            // Reset expandedBook each time the picker appears
            bookAndChapterPickerView
        }
    }
    var versionPickerView: some View {
        Group {
            if viewModel.permittedVersions.isEmpty {
                ProgressView()
            } else {
                List(viewModel.permittedVersions, id: \.id) { v in
                    Text(v.title ?? v.abbreviation ?? String(v.id))
                        .onTapGesture {
                            showingVersionPicker = false
                            onSelectionChange?(v.id, viewModel.book, viewModel.chapter)
                        }
                }
            }
        }
    }

    /// Combined Book & Chapter Picker: tap a book to expand, then pick a chapter from a grid
    var bookAndChapterPickerView: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Text("Books")
                        .font(.headline)
                    Spacer()
                }
                .padding(.vertical, 16)
                List {
                    ForEach(viewModel.bookCodes, id: \.self) { bookCode in
                        Section(
                            header:
                                HStack(spacing: 8) {
                                    Text(viewModel.bookName(for: bookCode) ?? bookCode)
                                        .font(.body)
                                        .foregroundColor(.black)
                                    Spacer(minLength: 4)
                                    Image(systemName: expandedBook == bookCode ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 14))
                                }
                                .contentShape(Rectangle())
                                .padding(.vertical, 2)
                                .listRowInsets(EdgeInsets(top: 2, leading: 12, bottom: 2, trailing: 12))
                                .onTapGesture {
                                    withAnimation {
                                        expandedBook = expandedBook == bookCode ? nil : bookCode
                                    }
                                }
                                .textCase(nil)
                        ) {
                            if expandedBook == bookCode {
                                let chapters = viewModel.chapterLabels(for: bookCode)
                                let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
                                LazyVGrid(columns: columns, spacing: 12) {
                                    ForEach(chapters.indices, id: \.self) { idx in
                                        Button(action: {
                                            showingBookPicker = false
                                            onSelectionChange?(viewModel.versionId, bookCode, idx + 1)
                                        }) {
                                            Text(chapters[idx])
                                                .foregroundColor(.black)
                                                .frame(width: 50, height: 50)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(Color.gray.opacity(0.2))
                                                )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
            }
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
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
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
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
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
        BibleReaderHeaderView(version: sampleVersion, book: "JHN", chapter: 3) { versionId, book, chapter in
            print("Version: \(versionId), Book: \(book), Chapter: \(chapter)")
        }
        Divider()
    }
}
