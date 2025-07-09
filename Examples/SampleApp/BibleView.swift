
import SwiftUI
import YouVersionPlatform

public struct BibleView: View {
    public var body: some View {
        FullReaderView(reference: BibleReference(versionId: 206, bookUSFM: "JHN", chapter: 1))
    }
}
