import UIKit

public struct BibleTextUIFonts {
    public let textFont: UIFont
    public let textFontItalic: UIFont
    public let verseNumFont: UIFont
    public let verseNumBaselineOffset: CGFloat
    public let verseNumOpacity: CGFloat = 1
    public let smallCaps: UIFont
    public let header: UIFont
    public let headerItalic: UIFont
    public let header2: UIFont
    public let header3: UIFont
    public let header4: UIFont
    public let footnote: UIFont

    public init(familyName: String, baseSize: CGFloat = UIFont.preferredFont(forTextStyle: .body).pointSize) {
        let baseFont = UIFont(name: familyName, size: baseSize)! //?? UIFont.systemFont(ofSize: baseSize)
        let larger = UIFont(name: familyName, size: baseSize * 1.2)! //?? UIFont.systemFont(ofSize: baseSize * 1.2)
        let largest = UIFont(name: familyName, size: baseSize * 1.4)! // ?? UIFont.systemFont(ofSize: baseSize * 1.4)
        
        textFont = baseFont
        textFontItalic = baseFont.withTraits(.traitItalic)
        verseNumFont = UIFont(name: familyName, size: baseSize * 0.7)!.withSmallCaps
            //.map { $0.withSmallCaps }
            //?? UIFont.systemFont(ofSize: baseSize * 0.7).withSmallCaps
        verseNumBaselineOffset = baseSize * 0.2
        smallCaps = baseFont.withSmallCaps
        header = largest.withTraits(.traitItalic)
        headerItalic = larger.withTraits(.traitItalic)
        header2 = larger.withTraits(.traitBold)
        header3 = larger
        header4 = larger
        footnote = UIFont(name: familyName, size: baseSize * 0.8)! // ?? UIFont.systemFont(ofSize: baseSize * 0.8)
    }
}

private extension UIFont {
    func withTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(traits) else {
            return self
        }
        return UIFont(descriptor: descriptor, size: pointSize)
    }

    var withSmallCaps: UIFont {
        // This doesn't work to make small caps for lowercase letters, so for now
        // in the code we call .uppercased() to get the right result.
        // Perhaps, revisit this later.
        //let upperCaseFeature = [
        //    UIFontDescriptor.FeatureKey.type : kUpperCaseType,
        //    UIFontDescriptor.FeatureKey.selector : kUpperCaseSmallCapsSelector
        //]
        let lowerCaseFeature = [
            UIFontDescriptor.FeatureKey.type: kLowerCaseType,
            UIFontDescriptor.FeatureKey.selector: kLowerCaseSmallCapsSelector
        ]
        let features = [/*upperCaseFeature,*/ lowerCaseFeature]
        let smallCapsDescriptor = fontDescriptor.addingAttributes([.featureSettings: features])
        return UIFont(descriptor: smallCapsDescriptor, size: pointSize * 0.80)
    }
}
