import SwiftUI

struct BibleReaderHeader: View {
    @State private var showingBookPicker = false
    @State private var showingChapterPicker = false
    @State private var showingVersionPicker = false
    @StateObject private var viewModel = BibleReaderHeaderViewModel()
    let version: BibleVersion
    let book: String
    let chapter: Int
    private let bookCodes: [String]
    let onSelectionChange: ((Int, String, Int) -> Void)?

    init(version: BibleVersion, book: String, chapter: Int, onSelectionChange: ((Int, String, Int) -> Void)? = nil) {
        self.version = version
        self.book = book
        self.chapter = chapter
        self.bookCodes = version.bookCodes()
        self.onSelectionChange = onSelectionChange
    }

    var body: some View {
        HStack {
            VBCPickers
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
                    onSelectionChange?(version.code, bookCode, 1)
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
                        onSelectionChange?(version.code, book, index + 1)
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

    var VBCPickers: some View {
        HStack {
            Text(version.abbreviation ?? String(version.code))
                .font(.caption)
                .padding(8)
                .background(
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                )
                .onTapGesture { handleVersionTap() }
            Text(version.bookName(book) ?? book)
                .font(.caption)
                .padding(8)
                .background(
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                )
                .onTapGesture { showingBookPicker = true }
            Text(String(chapter))
                .font(.caption)
                .padding(8)
                .background(
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                )
                .onTapGesture { showingChapterPicker = true }
            }
    }

    func handleVersionTap() {
        viewModel.loadVersionsList()  // in case it wasn't done yet
        showingVersionPicker = true
    }

}

@MainActor
class BibleReaderHeaderViewModel: ObservableObject {
    @Published var permittedVersions: [BibleVersionOverview] = []

    func loadVersionsList() {
        guard permittedVersions.isEmpty else { return }
        Task {
            let t = await BibleVersion.findByLanguage()
            let sorted = t.sorted {
                ($0.title ?? "").localizedCaseInsensitiveCompare($1.title ?? "") == .orderedAscending
            }
            await MainActor.run {
                permittedVersions = sorted
            }
        }
    }
}

#Preview {
    VStack {
        Divider()
        BibleReaderHeader(version: BibleVersion(1), book: "JHN", chapter: 3) { versionCode, book, chapter in
            print("Version: \(versionCode), Book: \(book), Chapter: \(chapter)")
        }
        Divider()
    }
}
