import SwiftUI

public struct BibleTextView: View {

    public typealias VerseTapAction = (BibleVerseData, CGPoint) -> Void

    private let reference: BibleReference
    private let options: BibleTextOptions
    private let highlights: [BibleHighlight]
    private let onVerseTap: VerseTapAction?
    private let fonts: BibleTextFonts
    private let uiFonts: BibleTextUIFonts
    private let isRightToLeft = false
    @State private var blocks: [BibleTextBlock] = []
    @State private var ourFrames: [UUID: CGRect] = [:]  // actual frames of each UI widget holding tappable text
    @Environment(\.colorScheme) var colorScheme  // for detecting when the user switches in/out of dark mode

    public init(
        _ reference: BibleReference,
        options: BibleTextOptions? = nil,
        highlights: [BibleHighlight] = [],
        onVerseTap: VerseTapAction? = nil
    ) {
        self.reference = reference
        let theOptions = options ?? BibleTextOptions()
        self.options = theOptions
        self.highlights = highlights
        self.onVerseTap = onVerseTap
        self.fonts = BibleTextFonts(familyName: theOptions.fontFamily, baseSize: theOptions.fontSize)
        self.uiFonts = BibleTextUIFonts(familyName: theOptions.fontFamily, baseSize: theOptions.fontSize)
    }

    public var body: some View {
        VStack(alignment: isRightToLeft ? .trailing : .leading) {
            if blocks.isEmpty {
                Spacer()
            } else {
                ForEach(blocks, id: \.id) { block in
                    view(for: block)
                }
            }
        }
        .task(id: reference) {
            await loadBlocks()
        }
        .coordinateSpace(name: "BibleTextView")
    }
    
    private func loadBlocks() async {
        blocks = await BibleVersionRendering.textBlocks(
            reference,
            renderFootnotes: options.footnoteMode != .none,
            footnoteMarker: options.footnoteMarker,
            wocColor: options.wocColor,
            fonts: fonts,
            uiFonts: uiFonts
        )
    }

    private func addHighlight(_ block: BibleTextBlock) -> BibleTextBlock {
        let verseOffsets = block.verseOffsets

        // Skip if there are no verse offsets or highlights
        guard !verseOffsets.isEmpty && !highlights.isEmpty else {
            return block
        }

        let highlightedBlock = block
        let opacity = colorScheme == .dark ? 0.35 : 1.0
        for highlight in highlights where highlight.chapter == block.chapter {
            // Find all verse ranges that match the highlight's verse
            for i in stride(from: 0, to: verseOffsets.count, by: 2) {
                let verseNum = verseOffsets[i + 1]
                if verseNum == highlight.verse {
                    var str = block.text.two
                    let offset = verseOffsets[i]
                    let nextOffset = (i + 2 < verseOffsets.count) ? verseOffsets[i + 2] : str.characters.count

                    let startIndex = str.characters.index(str.startIndex, offsetBy: offset)
                    let endIndex = str.characters.index(str.startIndex, offsetBy: nextOffset)

                    str[startIndex..<endIndex].backgroundColor = Color(hex: highlight.color).opacity(opacity)
                    highlightedBlock.text.two = str
                }
            }
        }

        return highlightedBlock
    }
    
    @ViewBuilder
    private func view(for block: BibleTextBlock) -> some View {
        if block.rows.isEmpty {
            let theView = emitTextBlock(addHighlight(block))
            if block.alignment == .leading {
                theView
            } else {
                HStack {
                    Spacer()
                    theView
                    if block.alignment == .center {
                        Spacer()
                    }
                }
            }
        } else {
            emitTableRows(block.rows)
        }
    }

    // This hack is necessary because AttributedString doesn't have a
    // ParagraphStyle or any other way to specify .firstLineHeadIndent.
    // NSAttributedString has paragraphStyle.firstLineHeadIndent which would be ideal.
    private func indentString(_ indent: Int) -> AttributedString {
        let nbsp = "\u{00a0}"
        return AttributedString(String(repeating: nbsp, count: min(max(indent, 0), 4)))
    }

    private func cacheFrame(_ frame: CGRect, forId id: UUID) {
        Task {
            ourFrames[id] = frame
        }
    }

    private func emitTextBlock(_ block: BibleTextBlock) -> some View {
        let align = block.alignment
        let indent = indentString(block.firstLineHeadIndent)
        let txt = Text(indent + block.text.two)
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(align)
            .if(options.textColor != nil) { view in
                view.foregroundStyle(options.textColor!)
            }.if(options.textColor == nil) { view in
                view.foregroundStyle(HierarchicalShapeStyle.primary)
            }
            .padding(.leading, CGFloat(8 * block.headIndent))
            .padding(.top, block.marginTop)
            .padding(.bottom, options.paragraphSpacing)
            .if(options.lineSpacing != nil) { view in
                view.lineSpacing(options.lineSpacing!)
            }
        // these are copied to avoid capturing "block" below.
        let blockId = block.id
        let blockText = block.text.one
        return txt
            .onTapGesture {point in
                handleTap(at: point, blockId: blockId, blockText: blockText, extraChars: indent.characters.count)
            }
            // This overlay is the way to capture the final size of our view. That's needed
            // in order for tap handling to determine where in the text the user tapped.
            .overlay(
                GeometryReader { geo in
                    cacheFrame(geo.frame(in: .named("BibleTextView")), forId: blockId)
                    return Color.clear
                }
            )
    }

    private func emitTableRows(_ doubleRows: [[DoubleAttributedString]]) -> some View {
        let rows: [[AttributedString]] = doubleRows.map { row in row.map { $0.two } }

        // make sure each row has the same number of cells
        let numCols = rows.map({ $0.count }).max() ?? 0

        let theRows = rows.map { cells in
            var modCells = cells  // copy so we can change it
            while modCells.count < numCols {
                modCells.append(AttributedString(""))
            }
            return TableRowStrings(strings: modCells.map { str in TableCellString(string: str) })
        }

        return Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 15, verticalSpacing: 10) {
            ForEach(theRows, id: \.self) { row in
                GridRow {
                    ForEach(row.strings, id: \.self) { cell in
                        Text(cell.string)
                            .fixedSize(horizontal: false, vertical: true)
                            .gridColumnAlignment(.leading)
                    }
                }
            }
        }
        .padding()
    }

    // so that the Grid has a Hashable, Identifiable list to work with
    private struct TableCellString: Hashable, Identifiable {
        let id = UUID()  // for Identifiable
        let string: AttributedString
    }
    
    private struct TableRowStrings: Hashable, Identifiable {
        let id = UUID()  // for Identifiable
        let strings: [TableCellString]
    }

    // MARK: - Utilities
    private func block(with id: UUID) -> BibleTextBlock? {
        blocks.first { $0.id == id }
    }

    private func verseNumFromPoint(pointInView: CGPoint,
                                   blockId: UUID,
                                   blockText: NSAttributedString,
                                   extraChars: Int) -> Int? {
        guard let ourFrame = ourFrames[blockId],
              let block = block(with: blockId),
              let i = characterIndex(
                for: pointInView,
                firstLineHeadIndent: block.firstLineHeadIndent,
                lineSpacing: options.lineSpacing,
                text: block.text.one,
                size: ourFrame.size
              ) else {
            return nil
        }
        return verseAtIndex(i - extraChars, from: block)
    }

    private func handleTap(at pointInView: CGPoint,
                           blockId: UUID,
                           blockText: NSAttributedString,
                           extraChars: Int = 0) {
        guard let verse = verseNumFromPoint(
            pointInView: pointInView,
            blockId: blockId,
            blockText: blockText,
            extraChars: extraChars
        ),
              let ourFrame = ourFrames[blockId],
              let block = block(with: blockId) else {
            return
        }
        
        let pointInSelf = CGPoint(
            x: pointInView.x + ourFrame.origin.x,
            y: pointInView.y + ourFrame.origin.y
        )
        let info = BibleVerseData(
            chapter: block.chapter,
            verse: verse,
            footnotes: block.footnotes.map({ double in double.two })
        )
        onVerseTap?(info, pointInSelf)
    }

}

public struct BibleVerseData {
    public let chapter: Int
    public let verse: Int
    public let footnotes: [AttributedString]
}

public enum BibleTextFootnoteMode {
    case none
    case inline
    case marker
}

public struct BibleTextOptions {
    public let fontFamily: String
    public let fontSize: CGFloat
    public let lineSpacing: CGFloat?
    public let paragraphSpacing: CGFloat?
    public let textColor: Color?
    public let wocColor: Color
    public let footnoteMode: BibleTextFootnoteMode
    public let footnoteMarker: DoubleAttributedString?

    public init(fontFamily: String = "Times New Roman",
                fontSize: CGFloat = 16,
                lineSpacing: CGFloat? = nil,
                paragraphSpacing: CGFloat? = nil,
                textColor: Color? = nil,
                wocColor: Color = Color(red: 1, green: 0x3d / 256, blue: 0x4d / 256),   // YouVersion red. F04C59 in dark mode.
                footnoteMode: BibleTextFootnoteMode = .none,
                footnoteMarker: DoubleAttributedString? = nil) {
        self.fontFamily = fontFamily
        self.fontSize = fontSize
        self.lineSpacing = lineSpacing ?? fontSize / 2
        self.paragraphSpacing = paragraphSpacing ?? fontSize / 2
        self.textColor = textColor
        self.wocColor = wocColor
        self.footnoteMode = footnoteMode
        self.footnoteMarker = footnoteMarker
    }
}
