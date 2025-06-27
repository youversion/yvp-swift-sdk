import SwiftUI

public struct VotdView: View {
    public let votdTitle: String
    public let votdText: String
    public let votdCopyright: String
    public let backgroundUrl: String?
    public let minHeight: CGFloat?
    public let maxHeight: CGFloat?
    public let dayNumber: Int? = 112
    var lineLimit: Int?  // do we want this?
    
    public init(votdTitle: String, votdText: String, votdCopyright: String) {
        self.votdTitle = votdTitle
        self.votdText = votdText
        self.votdCopyright = votdCopyright
        self.backgroundUrl = nil
        self.minHeight = nil
        self.maxHeight = nil
    }
    
    public init(
        votdTitle: String,
        votdText: String,
        votdCopyright: String,
        backgroundUrl: String? = nil,
        minHeight: CGFloat? = nil,
        maxHeight: CGFloat? = nil
    ) {
        self.votdTitle = votdTitle
        self.votdText = votdText
        self.votdCopyright = votdCopyright
        self.backgroundUrl = backgroundUrl
        self.minHeight = minHeight
        self.maxHeight = maxHeight
    }
    
    public var body: some View {
        basicText
            .padding()
            .foregroundColor(.white)
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
    
    var basicText: some View {
        VStack(alignment: .leading) {
            Text(votdTitle)
                .font(.title.bold())
                .lineLimit(1)
                .padding(.bottom, 16)
            Text(votdText)
                .multilineTextAlignment(.leading)
                .font(.system(size: 24, design: .serif))
                .minimumScaleFactor(0.5)
                .lineLimit(lineLimit)
                .textSelection(.enabled)
                .padding(.bottom, 16)
            Text(votdCopyright)
                .font(.caption)
                .minimumScaleFactor(0.1)
        }
    }
}

#Preview {
    VStack {
        Spacer()
        VotdView(
            votdTitle: "John 3:16 (NIV)",
            votdText: "For God so loved the world that he gave his one and only Son, that whoever believes in " +
                      "him shall not perish but have eternal life.",
            votdCopyright: "The Holy Bible, New International Version® NIV®\nCopyright © 1973, 1978, 1984, 2011 " +
                           "by Biblica, Inc.®\nUsed by Permission of Biblica, Inc.® All rights reserved worldwide.",
            backgroundUrl: "https://imageproxy.youversionapi.com/1500x/" +
                           "https://votd-background-images-prod.storage.googleapis.com/113.jpg",
            minHeight: 200,
            maxHeight: 450
        )
        Spacer()
    }
}
