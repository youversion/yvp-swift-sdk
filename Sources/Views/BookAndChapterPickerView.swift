import SwiftUI

public struct BookAndChapterPickerView: View {
    @Binding var expandedBook: String?
    @Binding var isPresented: Bool
    let bookCodes: [String]
    let versionId: Int
    let bookNameProvider: (String) -> String?
    let chapterLabelsProvider: (String) -> [String]
    let onSelectionChange: ((Int, String, Int) -> Void)?
    
    public init(
        expandedBook: Binding<String?>,
        isPresented: Binding<Bool>,
        bookCodes: [String],
        versionId: Int,
        bookNameProvider: @escaping (String) -> String?,
        chapterLabelsProvider: @escaping (String) -> [String],
        onSelectionChange: ((Int, String, Int) -> Void)? = nil
    ) {
        self._expandedBook = expandedBook
        self._isPresented = isPresented
        self.bookCodes = bookCodes
        self.versionId = versionId
        self.bookNameProvider = bookNameProvider
        self.chapterLabelsProvider = chapterLabelsProvider
        self.onSelectionChange = onSelectionChange
    }
    
    public var body: some View {
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
                    ForEach(bookCodes, id: \.self) { bookCode in
                        Section(
                            header:
                                HStack(spacing: 8) {
                                    Text(bookNameProvider(bookCode) ?? bookCode)
                                        .font(.body)
                                        .foregroundColor(.black)
                                    Spacer(minLength: 4)
                                    Image(systemName: expandedBook == bookCode ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 14))
                                }
                                .contentShape(Rectangle())
                                .padding(.vertical, 0)
                                .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
                                .onTapGesture {
                                    withAnimation {
                                        expandedBook = expandedBook == bookCode ? nil : bookCode
                                    }
                                }
                                .textCase(nil)
                        ) {
                            if expandedBook == bookCode {
                                let chapters = chapterLabelsProvider(bookCode)
                                let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
                                LazyVGrid(columns: columns, spacing: 10) {
                                    ForEach(chapters.indices, id: \.self) { idx in
                                        Button(action: {
                                            isPresented = false
                                            onSelectionChange?(versionId, bookCode, idx + 1)
                                        }) {
                                            Text(chapters[idx])
                                                .font(.system(size: 14))
                                                .foregroundColor(.black)
                                                .frame(width: 56, height: 56)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .fill(Color(hex: "EDEBEC"))
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
                .listStyle(PlainListStyle())
            }
        }
    }
}

#Preview {
    // Create a sample for preview
    @State var expandedBook: String? = nil
    @State var isPresented = true
    
    let sampleBookCodes = ["GEN", "EXO", "LEV", "NUM", "DEU", "JOS", "JDG", "RUT", "1SA", "2SA", "JHN"]
    
    return BookAndChapterPickerView(
        expandedBook: $expandedBook,
        isPresented: $isPresented,
        bookCodes: sampleBookCodes,
        versionId: 1,
        bookNameProvider: { bookCode in
            switch bookCode {
            case "GEN": return "Genesis"
            case "EXO": return "Exodus"
            case "JHN": return "John"
            default: return bookCode
            }
        },
        chapterLabelsProvider: { _ in
            Array(1...21).map { String($0) }
        },
        onSelectionChange: { versionId, book, chapter in
            print("Selected: Version \(versionId), Book \(book), Chapter \(chapter)")
        }
    )
}
