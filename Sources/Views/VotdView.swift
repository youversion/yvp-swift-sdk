import SwiftUI

public struct VotdView: View {
    @State private var votd: YouVersionVerseOfTheDay?
    
    public let backgroundUrl: String?
    public let minHeight: CGFloat?
    public let maxHeight: CGFloat?
    var lineLimit: Int?  // do we want this?
    
    public init(
        votd: YouVersionVerseOfTheDay? = nil,
        backgroundUrl: String? = nil,
        minHeight: CGFloat? = nil,
        maxHeight: CGFloat? = nil
    ) {
        self._votd = State(initialValue: votd)
        self.backgroundUrl = backgroundUrl
        self.minHeight = minHeight
        self.maxHeight = maxHeight
    }
    
    public var body: some View {
        Group {
            if let votd {
                text(votd: votd)
                    .padding()
                    .frame(minHeight: minHeight, maxHeight: maxHeight)
                    .background(
                        GeometryReader { geo in
                            if let backgroundUrl, let url = URL(string: backgroundUrl) {
                                votdBackground(url: url)
                                    .frame(width: geo.size.width, height: geo.size.height)
                                    .clipped()
                            }
                        }
                    )
            } else {
                ProgressView()
            }
        }
        .task {
            guard votd == nil else {
                return
            }
            
            do {
                votd = try await YouVersionAPI.verseOfTheDay(versionId: 111)
            } catch {
                print("VotdView: error loading votd: \(error)")
            }
        }
    }
    
    private func votdBackground(url: URL) -> some View {
        AsyncImage(url: url, transaction: Transaction(animation: .easeInOut)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            default:
                EmptyView()
            }
        }
    }
    
    private func text(votd: YouVersionVerseOfTheDay) -> some View {
        VStack(alignment: .leading) {
            Text("\(votd.reference) (\(votd.abbreviation))")
                .font(.title.bold())
                .lineLimit(1)
                .padding(.bottom, 16)
            Text(votd.text)
                .multilineTextAlignment(.leading)
                .font(.system(size: 24, design: .serif))
                .minimumScaleFactor(0.5)
                .lineLimit(lineLimit)
                .textSelection(.enabled)
                .padding(.bottom, 16)
            Text(votd.copyright)
                .font(.caption)
                .minimumScaleFactor(0.1)
        }
    }
}

#Preview {
    VStack {
        Spacer()
        VotdView(
            votd: YouVersionVerseOfTheDay(
                reference: "John 3:16",
                abbreviation: "NIV",
                text: "For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.",
                copyright: "The Holy Bible, New International Version® NIV®\nCopyright © 1973, 1978, 1984, 2011 by Biblica, Inc.®\nUsed by Permission of Biblica, Inc.® All rights reserved worldwide."
            ),
            backgroundUrl: "https://imageproxy.youversionapi.com/1500x/" +
                           "https://votd-background-images-prod.storage.googleapis.com/113.jpg",
            minHeight: 200,
            maxHeight: 450
        )
        Spacer()
    }
}
