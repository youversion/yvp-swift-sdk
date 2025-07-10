import SwiftUI

public struct BibleVersionPickerView: View {
    let permittedVersions: [BibleVersionOverview]
    let currentBook: String
    let currentChapter: Int
    let onVersionSelected: (Int, String, Int) -> Void
    @Binding var isPresented: Bool
    
    public init(
        permittedVersions: [BibleVersionOverview],
        currentBook: String,
        currentChapter: Int,
        isPresented: Binding<Bool>,
        onVersionSelected: @escaping (Int, String, Int) -> Void
    ) {
        self.permittedVersions = permittedVersions
        self.currentBook = currentBook
        self.currentChapter = currentChapter
        self._isPresented = isPresented
        self.onVersionSelected = onVersionSelected
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text("Versions")
                    .font(.headline)
                    .foregroundColor(.black)
                Spacer()
            }
            .padding(.vertical, 16)
            
            Group {
                if permittedVersions.isEmpty {
                    ProgressView()
                } else {
                    List(permittedVersions, id: \.id) { v in
                        HStack(spacing: 12) {
                            // Rounded square with abbreviation
                            VStack(spacing: 0) {
                                let abbreviation = v.abbreviation ?? String(v.id)
                                let (letters, numbers) = splitAbbreviation(abbreviation)
                                
                                Text(letters)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.black)
                                    .lineLimit(1)
                                
                                if !numbers.isEmpty {
                                    Text(numbers)
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.black)
                                        .lineLimit(1)
                                }
                            }
                            .frame(width: 52, height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(hex: "F7EFED"))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(Color(hex: "DDDBDC"), lineWidth: 1)
                                    )
                            )
                            
                            // Version title
                            Text(v.title ?? v.abbreviation ?? String(v.id))
                                .font(.body)
                                .foregroundColor(.black)
                            
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isPresented = false
                            onVersionSelected(v.id, currentBook, currentChapter)
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                    .listStyle(PlainListStyle())
                }
            }
        }
    }
    
    // Helper function to split abbreviation into letters and trailing numbers
    private func splitAbbreviation(_ text: String) -> (letters: String, numbers: String) {
        let pattern = #"^(.*?)(\d+)$"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            let lettersRange = Range(match.range(at: 1), in: text)!
            let numbersRange = Range(match.range(at: 2), in: text)!
            return (String(text[lettersRange]), String(text[numbersRange]))
        }
        return (text, "")
    }
}

#Preview {
    @State var isPresented = true
    
    let sampleVersions = [
        BibleVersionOverview(id: 1, title: "King James Version", abbreviation: "KJV", language: "en"),
        BibleVersionOverview(id: 2, title: "New International Version", abbreviation: "NIV", language: "en"),
        BibleVersionOverview(id: 3, title: "English Standard Version", abbreviation: "ESV", language: "en")
    ]
    
    return BibleVersionPickerView(
        permittedVersions: sampleVersions,
        currentBook: "JHN",
        currentChapter: 3,
        isPresented: $isPresented
    ) { versionId, book, chapter in
        print("Selected version: \(versionId), book: \(book), chapter: \(chapter)")
    }
}
