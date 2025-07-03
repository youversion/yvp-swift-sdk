
import SwiftUI
import YouVersionPlatform

public struct BibleView: View {
    public var body: some View {
        ScrollView {
            BibleTextView(
                BibleReference(versionId: 111, bookUSFM: "JHN", chapter: 2)
            )
            .padding(.horizontal, 32)
        }
    }
}
