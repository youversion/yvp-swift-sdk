import SwiftUI

public struct LoginWithYouVersionButton: View {
    
    public enum Mode: String, CaseIterable {
        case full
        case compact
        case iconOnly
    }

    public enum Shape {
        case button
        case rectangle
    }
    
    @Environment(\.colorScheme) var colorScheme
    @State private var shape: Shape = .button
    @State private var mode: Mode = .full
    @State private var stroked = true
    private let verticalPadding = CGFloat(12)
    private let horizontalPadding = CGFloat(20)
    private let strokeWidth = CGFloat(1.5)
    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 24
    let onTap: () -> Void
    
    public init(shape: Shape = .button,
                mode: Mode = .full,
                stroked: Bool = true,
                onTap: @escaping () -> Void) {
        self.shape = shape
        self.mode = mode
        self.stroked = stroked
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
            .frame(width: iconSize, height: iconSize)
#else
        return Image("BibleAppLogo@4x")
            .resizable()
            .frame(width: iconSize, height: iconSize)
#endif
    }
    
    func cornerRadius(_ shape: Shape? = nil) -> CGFloat {
        switch shape ?? self.shape {
        case .button: 40
        case .rectangle: 4
        }
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
    
    private func textOrEmpty(_ txt: String) -> Text {
        txt.isEmpty ? Text("") : Text(txt)
    }
    
    public var body: some View {
        Button(action: onTap) {
            switch mode {
            case .iconOnly:
                HStack(spacing: 0) {
                    bibleAppLogo
                        .padding(verticalPadding)  // it's deliberate that we're not using horizontalPadding here
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .background(colorScheme == .dark ? Color.black : Color.white)
                        .cornerRadius(cornerRadius(.rectangle))
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius()))
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius())
                                .stroke(strokeColor, lineWidth: stroked ? strokeWidth : 0)
                        )
                }
            case .full:
                HStack(spacing: 0) {
                    bibleAppLogo
                        .padding(.trailing, 8)
                    localizedLoginText
                }
                .padding(.vertical, verticalPadding)
                .padding(.horizontal, horizontalPadding)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .background(colorScheme == .dark ? Color.black : Color.white)
                .cornerRadius(cornerRadius())
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius()))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius())
                        .stroke(strokeColor, lineWidth: stroked ? strokeWidth : 0)
                )
            case .compact:
                HStack(spacing: 0) {
                    bibleAppLogo
                        .padding(.trailing, 8)
                    Text("Sign in")
                }
                .padding(.vertical, verticalPadding)
                .padding(.horizontal, horizontalPadding)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .background(colorScheme == .dark ? Color.black : Color.white)
                .cornerRadius(cornerRadius())
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius()))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius())
                        .stroke(strokeColor, lineWidth: stroked ? strokeWidth : 0)
                )
            }
        }
    }
}

struct LoginWithYouVersionButton_Previews: PreviewProvider {
    
    static var previews: some View {
        Group {
            VStack {
                buttonGrid
                    .environment(\.colorScheme, .light)
                buttonGrid
                    .environment(\.colorScheme, .dark)
            }
            .padding()
            .background(content: { Color.green })
        }
    }
    
    static var buttonGrid: some View {
        VStack {
            VStack {
                LoginWithYouVersionButton(mode: .full, stroked: true, onTap: {})
                LoginWithYouVersionButton(mode: .full, stroked: false, onTap: {})
                HStack {
                    LoginWithYouVersionButton(mode: .compact, stroked: true, onTap: {})
                    LoginWithYouVersionButton(mode: .compact, stroked: false, onTap: {})
                }
                LoginWithYouVersionButton(shape: .rectangle, mode: .full, stroked: true, onTap: {})
                LoginWithYouVersionButton(shape: .rectangle, mode: .full, stroked: false, onTap: {})
                HStack {
                    LoginWithYouVersionButton(shape: .rectangle, mode: .compact, stroked: true, onTap: {})
                    LoginWithYouVersionButton(shape: .rectangle, mode: .compact, stroked: false, onTap: {})
                }
                HStack {
                    LoginWithYouVersionButton(shape: .rectangle, mode: .iconOnly, stroked: true, onTap: {})
                    LoginWithYouVersionButton(shape: .rectangle, mode: .iconOnly, stroked: false, onTap: {})
                }
            }
        }
    }
}
