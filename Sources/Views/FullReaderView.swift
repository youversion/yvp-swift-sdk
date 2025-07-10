import SwiftUI
import AuthenticationServices
import Foundation

/// Helper to detect scroll offset in ScrollView
struct ScrollOffsetPreferenceKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue: Value { .zero }
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = nextValue()
    }
}


public struct FullReaderView: View {
    @StateObject private var viewModel: FullReaderViewModel
    @State private var contextProvider = ContextProvider()

    public init(reference: BibleReference, version: BibleVersion? = nil) {
        _viewModel = StateObject(wrappedValue: FullReaderViewModel(reference: reference, version: version))
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
                        if viewModel.isVersionLoaded, let version = viewModel.version {
                            VStack {
                                Text(version.bookName(viewModel.reference.bookUSFM) ?? viewModel.reference.bookUSFM ?? "?")
                                    .font(Font.custom(viewModel.textOptions.fontFamily, size: viewModel.textOptions.fontSize))
                                Text(String(viewModel.reference.chapter))
                                    .font(Font.custom(viewModel.textOptions.fontFamily, size: viewModel.textOptions.fontSize * 2.5))
                                    .fontWeight(.bold)
                                    .padding(.bottom)
                                BibleTextView(viewModel.reference,
                                              options: viewModel.textOptions,
                                              highlights: viewModel.highlights ?? [],
                                              onVerseTap: { data, _ in
                                    viewModel.handleVerseTap(chapter: data.chapter, verse: data.verse)
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
                            viewModel.handleScroll(offset: value)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            // Floating chapter navigation buttons (chrome)
            HStack {
                Button(action: {
                    viewModel.goToPreviousChapter()
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
                    viewModel.goToNextChapter()
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
            .allowsHitTesting(viewModel.isVersionLoaded && viewModel.showChrome)
            .opacity(viewModel.isVersionLoaded ? 1 : 0.5)
            .offset(y: viewModel.showChrome ? 0 : 100)
            .animation(.easeInOut(duration: 0.3), value: viewModel.showChrome)
        }
        .task {
            Task { @MainActor in
                await viewModel.loadVersionIfNeeded()
            }
        }
        .onChange(of: viewModel.isVersionLoaded) {
            // No need to update reference, it's passed in
        }
    }

    // MARK: - Helper views
    var headerWithAvatar: some View {
        HStack {
            if viewModel.isVersionLoaded, let version = viewModel.version {
                BibleReaderHeaderView(version: version,
                                     book: viewModel.reference.bookUSFM,
                                     chapter: viewModel.reference.chapter,
                                     onSelectionChange: { v, b, c in
                    Task {
                        await viewModel.onHeaderSelectionChange(v: v, b: b, c: c)
                    }
                })
                .padding(.leading)
            }
            Spacer()
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
