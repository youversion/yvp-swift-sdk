import SwiftUI
import AuthenticationServices

/// Helper to detect scroll offset in ScrollView
struct ScrollOffsetPreferenceKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue: Value { .zero }
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = nextValue()
    }
}

public struct FullReaderView: View {
    @State var reference: BibleReference
    @State private var contextProvider = ContextProvider()

    let textOptions = BibleTextOptions(fontFamily: "Georgia", fontSize: 18)
    let highlightColor = "fffeca"

    @State private var highlights: [BibleHighlight]?
    @StateObject private var versionRepository = BibleVersionRepository()
    @State private var version: BibleVersion?
    @State private var isVersionLoaded = false

    @State private var showChrome = true
    @State private var lastScrollOffset: CGFloat = 0
    @State private var isUserScrolling = false

    public init(reference: BibleReference, version: BibleVersion? = nil) {
        self._reference = State(initialValue: reference)
        self.version = version
        self.isVersionLoaded = version != nil
    }

    public var body: some View {
        ZStack {
            VStack {
                headerWithAvatar
                Divider()
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        GeometryReader { geo in
                            Color.clear
                                .preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .named("scrollView")).minY)
                        }
                        .frame(height: 0)
                        if isVersionLoaded, let version = version {
                            VStack {
                                Text(version.bookName(reference.bookUSFM) ?? reference.bookUSFM ?? "?")
                                    .font(Font.custom(textOptions.fontFamily, size: textOptions.fontSize))
                                Text(String(reference.chapter))
                                    .font(Font.custom(textOptions.fontFamily, size: textOptions.fontSize * 2.5))
                                    .fontWeight(.bold)
                                    .padding(.bottom)
                                BibleTextView(reference,
                                              options: textOptions,
                                              highlights: highlights ?? [],
                                              onVerseTap: { data, _ in
                                    handleVerseTap(chapter: data.chapter, verse: data.verse)
                                })
                            }
                            .padding()
                        } else {
                            ProgressView()
                                .padding(.vertical, 48)
                        }
                        GeometryReader { geo in
                            Color.clear
                                .preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .named("scrollView")).maxY)
                        }
                        .frame(height: 0)
                    }
                    .coordinateSpace(name: "scrollView")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        Task { @MainActor in
                            handleScroll(offset: value)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            // Floating chapter navigation buttons (chrome)
            if showChrome {
                HStack {
                    Button(action: {
                        goToPreviousChapter()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .shadow(radius: 2)
                                .frame(width: 42, height: 42)
                            Image(systemName: "chevron.left")
                                .foregroundColor(.black)
                                .font(.system(size: 16, weight: .medium))
                        }
                    }
                    Spacer()
                    Button(action: {
                        goToNextChapter()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .shadow(radius: 2)
                                .frame(width: 42, height: 42)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.black)
                                .font(.system(size: 16, weight: .medium))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .allowsHitTesting(isVersionLoaded) // Only allow interaction when loaded
                .opacity(isVersionLoaded ? 1 : 0.5)
                .animation(.easeInOut(duration: 0.1), value: showChrome)
            }
        }
        .task {
            if !isVersionLoaded {
                do {
                    version = try await versionRepository.version(withId: reference.versionId)
                    isVersionLoaded = true
                } catch {
                    print("Error loading default version: \(error)")
                }
            }
        }
        .onChange(of: isVersionLoaded) {
            // No need to update reference, it's passed in
        }
    }
    // MARK: - Chapter navigation

    private func goToPreviousChapter() {
        guard reference.chapter > 1 else { return }
        reference = BibleReference(versionId: reference.versionId, bookUSFM: reference.bookUSFM, chapter: reference.chapter - 1)
        highlights = []
    }

    private func goToNextChapter() {
        // This assumes you have a way to determine the max chapter for the book. Replace 150 with actual max if available.
        let maxChapter = 150 // TODO: Replace with actual max chapter for the book
        guard reference.chapter < maxChapter else { return }
        reference = BibleReference(versionId: reference.versionId, bookUSFM: reference.bookUSFM, chapter: reference.chapter + 1)
        highlights = []
    }

    // MARK: - Helper views

    var headerWithAvatar: some View {
        HStack {
            if isVersionLoaded, let version = version {
                BibleReaderHeaderView(version: version,
                                     book: reference.bookUSFM,
                                     chapter: reference.chapter,
                                     onSelectionChange: { v, b, c in
                    Task {
                        do {
                            if self.version?.id != v {
                                self.version = try await versionRepository.version(withId: v)
                                self.isVersionLoaded = true
                            }
                            self.reference = BibleReference(versionId: v, bookUSFM: b, chapter: c)
                            self.highlights = []
                        } catch {
                            print("Error loading version/chapter: \(error)")
                        }
                    }
                })
                .padding(.leading)
            }
            Spacer()
        }
    }

    // MARK: - Tap handlers

    // MARK: - Scroll handling
    private func handleScroll(offset: CGFloat) {
        // Hide chrome when scrolling up, show when scrolling down or at top
        let threshold: CGFloat = 10
        if offset <= 0 {
            // At the very top
            withAnimation(.easeInOut(duration: 0.1)) { showChrome = true }
        } else if abs(offset - lastScrollOffset) >= threshold {
            if offset < lastScrollOffset - threshold {
                // Scrolling up
                withAnimation(.easeInOut(duration: 0.1)) { showChrome = false }
            } else if offset > lastScrollOffset + threshold {
                // Scrolling down
                withAnimation(.easeInOut(duration: 0.1)) { showChrome = true }
            }
        }
        lastScrollOffset = offset
    }

    func handleVerseTap(chapter: Int, verse: Int) {
        guard let version = version else { return }
        let h = BibleHighlight(versionId: version.id,
                               chapter: chapter,
                               verse: verse,
                               color: highlightColor)

        if var highlights = self.highlights,
            let index = highlights.firstIndex(where: { $0.versionId == h.versionId &&
                $0.chapter == h.chapter &&
                $0.verse == h.verse }) {
            if highlights[index].color == h.color {
                highlights.remove(at: index)
                self.highlights = highlights
            } else {
                //self.highlights![index].color = h.color
            }
        } else {
            self.highlights?.append(h)
        }
    }

    class ContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
        func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = scene.windows.first else {
                return ASPresentationAnchor()
            }
            return window
        }
    }
}

#Preview {
    FullReaderView(reference: BibleReference(versionId: 206, bookUSFM: "JHN", chapter: 4))
}
