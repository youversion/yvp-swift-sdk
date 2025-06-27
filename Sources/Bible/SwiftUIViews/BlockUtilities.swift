import UIKit

// Utility functions, mostly for use by BibleTextView

func characterIndex(
    for location: CGPoint,
    firstLineHeadIndent: Int,
    lineSpacing: CGFloat?,
    text: NSAttributedString,
    size: CGSize
) -> Int? {
    // TODO this indentHack is a source of misalignment between SwiftUI and UIKit.
    // Not sure there's a perfect solution.
    let theText = NSMutableAttributedString() //indentHack(firstLineHeadIndent))
    theText.append(text)
    
    if let lineSpacing {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        // block.headIndent is already handled by the Text widget's padding
        theText.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: NSRange(location: 0, length: theText.length)
        )
    }
    
    let layoutManager = NSLayoutManager()
    let textContainer = NSTextContainer(size: size)
    let textStorage = NSTextStorage(attributedString: theText)
    textStorage.addLayoutManager(layoutManager)
    textContainer.lineFragmentPadding = 0.0
    textContainer.lineBreakMode = .byWordWrapping
    textContainer.maximumNumberOfLines = 0
    layoutManager.addTextContainer(textContainer)
    
    return layoutManager.characterIndex(
        for: location,
        in: textContainer,
        fractionOfDistanceBetweenInsertionPoints: nil
    )
}

func verseAtIndex(_ characterIndex: Int, from block: BibleTextBlock) -> Int? {
    let verseOffsets = block.verseOffsets
    guard !verseOffsets.isEmpty else {
        return nil
    }
    
    guard verseOffsets.count % 2 == 0 else {
        //print("Warning: verseOffsets array is invalid. Cannot determine verse.")
        return nil
    }
    
    for i in stride(from: 0, to: verseOffsets.count, by: 2) {
        let verseNum = verseOffsets[i + 1]
        let nextCharOffset = (i + 2 < verseOffsets.count) ? verseOffsets[i + 2] : Int.max
        if characterIndex < nextCharOffset {
            return verseNum
        }
    }
    return nil
}
