import SwiftUI

public struct BibleReaderHeaderView: View {
    @State private var showingBookPicker = false
    @State private var showingChapterPicker = false
    @State private var showingVersionPicker = false
    @StateObject private var viewModel = BibleReaderHeaderViewModel()
    let version: BibleVersion
    let book: String
    let chapter: Int
    private let bookCodes: [String]
    let onSelectionChange: ((Int, String, Int) -> Void)?

    public init(version: BibleVersion, book: String, chapter: Int, onSelectionChange: ((Int, String, Int) -> Void)? = nil) {
        self.version = version
        self.book = book
        self.chapter = chapter
        self.bookCodes = version.bookUSFMs
        self.onSelectionChange = onSelectionChange
    }

    public var body: some View {
        HStack {
            HalfPillPickers
        }
        .sheet(isPresented: $showingVersionPicker) {
            versionPickerView
        }
        .sheet(isPresented: $showingBookPicker) {
            bookPickerView
        }
        .sheet(isPresented: $showingChapterPicker) {
            chaptersList
                .frame(maxWidth: 400, maxHeight: 600)
                .padding()
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
                            onSelectionChange?(v.id, book, chapter)
                        }
                }
            }
        }
    }

    var bookPickerView: some View {
        List(bookCodes, id: \.self) { bookCode in
            Text(version.bookName(bookCode) ?? bookCode)
                .onTapGesture {
                    showingBookPicker = false
                    onSelectionChange?(version.id, bookCode, 1)
                }
        }
    }

    var chaptersList: some View {
        let chapters = version.chapterLabels(book)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
        return ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(chapters.indices, id: \.self) { index in
                    Button(action: {
                        showingChapterPicker = false
                        onSelectionChange?(version.id, book, index + 1)
                    }) {
                        Text(chapters[index])
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(
                                Capsule()
                                    .fill(Color.gray.opacity(0.2))
                            )
                    }
                }
            }
            .padding()
        }
    }

    var HalfPillPickers: some View {
        let bookAndChapter = "\(version.bookName(book) ?? book) \(chapter)"
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
                Text(version.abbreviation ?? String(version.id))
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
