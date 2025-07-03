
import SwiftUI
import YouVersionPlatform

public struct BibleView: View {
    public var body: some View {
        ScrollView {
            BibleTextView(
                BibleReference(versionId: 111, bookUSFM: "EXO", chapterStart: 12, verseStart: 1, chapterEnd: 12, verseEnd: 15)
            )
            .padding(.horizontal, 32)
        }
    }
}
