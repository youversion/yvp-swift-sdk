
import SwiftUI
import YouVersionPlatform

public struct BibleView: View {
    public var body: some View {
        ScrollView {
            BibleTextView(
                BibleReference(versionId: 111, bookUSFM: "JHN", chapter: 3, verse: 16)
            )
            .padding(.horizontal, 32)
        }
    }
}
