import SwiftUI

public struct BibleTextFonts {
    var textFont: Font
    var textFontItalic: Font
    var verseNumFont: Font
    var verseNumBaselineOffset: CGFloat
    var verseNumOpacity: CGFloat
    var smallCaps: Font
    var header: Font
    var headerItalic: Font
    var header2: Font
    var header3: Font
    var header4: Font
    var footnote: Font

    init(familyName: String, baseSize: CGFloat = UIFont.preferredFont(forTextStyle: .body).pointSize) {
        let baseFont = Font.custom(familyName, size: baseSize)
        let larger = Font.custom(familyName, size: baseSize * 1.2)
        let largest = Font.custom(familyName, size: baseSize * 1.4)
        
        textFont = baseFont
        textFontItalic = baseFont.italic()
        verseNumFont = Font.custom(familyName, size: baseSize * 0.7).smallCaps()
        verseNumBaselineOffset = baseSize * 0.3
        verseNumOpacity = 0.7
        smallCaps = baseFont.smallCaps()
        header = largest.italic()
        headerItalic = larger.italic()
        header2 = larger.bold()
        header3 = larger
        header4 = larger
        footnote = Font.custom(familyName, size: baseSize * 0.8)
    }
}
