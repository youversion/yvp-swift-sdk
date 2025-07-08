import SwiftUI

public struct LoginWithYouVersionButton: View {
    
    public enum Mode: String, CaseIterable {
        case full
        case compact
        case iconOnly
    }

    public enum ButtonShape {
        case capsule
        case rectangle
    }
    
    @Environment(\.colorScheme) var colorScheme
    private let shape: ButtonShape
    private let mode: Mode
    private let isStroked: Bool
    private let verticalPadding = CGFloat(12)
    private let horizontalPadding = CGFloat(20)
    private let onTap: () -> Void
    @ScaledMetric(relativeTo: .body) private var iconEdge: CGFloat = 24
    
    public init(shape: ButtonShape = .capsule,
                mode: Mode = .full,
                isStroked: Bool = true,
                onTap: @escaping () -> Void) {
        self.shape = shape
        self.mode = mode
        self.isStroked = isStroked
        self.onTap = onTap
    }
    
    private var strokeColor: Color {
        let colorGray25 = Color(red: 0x82 / 256, green: 0x80 / 256, blue: 0x80 / 256)
        let colorGray35 = Color(red: 0x47 / 256, green: 0x45 / 256, blue: 0x45 / 256)
        return colorScheme == .dark ? colorGray35 : colorGray25
    }
    
    private var bibleAppLogo: some View {
#if SWIFT_PACKAGE
        return Image("BibleAppLogo@4x", bundle: .module)
            .resizable()
            .frame(width: iconEdge, height: iconEdge)
#else
        return Image("BibleAppLogo@4x")
            .resizable()
            .frame(width: iconEdge, height: iconEdge)
#endif
    }
    
    private var localizedLoginText: Text {
        let fullText = NSLocalizedString(
            "Sign in with YouVersion",
            comment: "Login button text, 'YouVersion' must stay untranslated but may move position"
        )
        let brandName = "YouVersion"
        
        var attributed = AttributedString(fullText)
        if let range = attributed.range(of: brandName) {
            attributed[range].font = .body.bold()
        }
        
        return Text(attributed)
    }
    
    private var strokeWidth: CGFloat {
        isStroked ? 1.5 : 0
    }
    
    @ViewBuilder
    private var buttonContent: some View {
        switch mode {
        case .iconOnly:
            bibleAppLogo
                .padding(verticalPadding)
        case .full:
            HStack(spacing: 0) {
                bibleAppLogo
                    .padding(.trailing, 8)
                localizedLoginText
            }
            .padding(.vertical, verticalPadding)
            .padding(.horizontal, horizontalPadding)
        case .compact:
            HStack(spacing: 0) {
                bibleAppLogo
                    .padding(.trailing, 8)
                Text("Sign in")
            }
            .padding(.vertical, verticalPadding)
            .padding(.horizontal, horizontalPadding)
        }
    }
    
    public var body: some View {
        Button(action: onTap) {
            buttonContent
                .accessibilityLabel(Text("Sign in with YouVersion"))
                .accessibilityAddTraits(.isButton)
        }
        .buttonStyle(
            LoginWithYouVersionButtonStyle(
                shape: shape,
                strokeColor: strokeColor,
                strokeWidth: strokeWidth,
                colorScheme: colorScheme
            )
        )
    }
}

private struct LoginWithYouVersionButtonStyle: ButtonStyle {
    let shape: LoginWithYouVersionButton.ButtonShape
    let strokeColor: Color
    let strokeWidth: CGFloat
    let colorScheme: ColorScheme

    func makeBody(configuration: Configuration) -> some View {
        let content = configuration.label
            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
            .background(colorScheme == .dark ? Color.black : Color.white)
            .opacity(configuration.isPressed ? 0.8 : 1.0)

        if shape == .capsule {
            content
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(strokeColor, lineWidth: strokeWidth)
                )
        } else {
            content
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(strokeColor, lineWidth: strokeWidth)
                )
        }
    }
}

#Preview {
    buttonGrid
        .padding()
        .background(Color.green)
}

#if DEBUG
@MainActor
private var buttonGrid: some View {
    VStack {
        LoginWithYouVersionButton(mode: .full, isStroked: true, onTap: {})
        LoginWithYouVersionButton(mode: .full, isStroked: false, onTap: {})
        HStack {
            LoginWithYouVersionButton(mode: .compact, isStroked: true, onTap: {})
            LoginWithYouVersionButton(mode: .compact, isStroked: false, onTap: {})
        }
        LoginWithYouVersionButton(shape: .rectangle, mode: .full, isStroked: true, onTap: {})
        LoginWithYouVersionButton(shape: .rectangle, mode: .full, isStroked: false, onTap: {})
        HStack {
            LoginWithYouVersionButton(shape: .rectangle, mode: .compact, isStroked: true, onTap: {})
            LoginWithYouVersionButton(shape: .rectangle, mode: .compact, isStroked: false, onTap: {})
        }
        HStack {
            LoginWithYouVersionButton(shape: .rectangle, mode: .iconOnly, isStroked: true, onTap: {})
            LoginWithYouVersionButton(shape: .rectangle, mode: .iconOnly, isStroked: false, onTap: {})
        }
    }
}
#endif
