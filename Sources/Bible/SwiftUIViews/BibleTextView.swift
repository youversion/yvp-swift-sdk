import SwiftUI

public struct BibleTextView: View {

    public typealias VerseTapAction = (BibleVerseData, CGPoint) -> Void

    private let reference: BibleReference
    private let options: BibleTextOptions
    private let highlights: [BibleHighlight]
    private let onVerseTap: VerseTapAction?
    private let fonts: BibleTextFonts
    private let uiFonts: BibleTextUIFonts
    private let rtl = false
    @State private var blocks: [BibleTextBlock]
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
        self.blocks = []
    }

    public var body: some View {
        VStack(alignment: rtl ? .trailing : .leading) {
            if blocks.isEmpty {
                Spacer()
            } else {
                ForEach(blocks, id: \.id) { block in
                    renderView(for: block)
                }
            }
        }
        .task { await loadBlocks() }
        .onChange(of: reference) { Task { await loadBlocks() } }
        .coordinateSpace(name: "BibleTextView")
    }
    
    private func loadBlocks() async {
        blocks = await BibleVersionRendering.textBlocksAsync(
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
        guard !verseOffsets.isEmpty, !highlights.isEmpty else {
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

    private func renderView(for block: BibleTextBlock) -> some View {
        Group {
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
    }

    // This is necessary because SwiftUI's AttributedString doesn't have a
    // ParagraphStyle or any other way to specify .firstLineHeadIndent.
    // NSAttributedString has paragraphStyle.firstLineHeadIndent which would be ideal.
    private func indentHack(_ indent: Int) -> AttributedString {
        let nbsp = "\u{00a0}"
        return AttributedString(String(repeating: nbsp, count: min(max(indent, 0), 4)))
    }

    private func rememberGeometry(_ val: UUID, frame: CGRect) {
        Task {
            ourFrames[val] = frame
        }
    }

    private func emitTextBlock(_ block: BibleTextBlock) -> some View {
        let align = block.alignment
        let indent = indentHack(block.firstLineHeadIndent)
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
                    rememberGeometry(blockId, frame: geo.frame(in: .named("BibleTextView")))
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

    // so that the Grid has an Hashable, Identifiable list to work with
    struct TableCellString: Hashable, Identifiable {
        let id = UUID()  // for Identifiable
        let string: AttributedString
    }
    struct TableRowStrings: Hashable, Identifiable {
        let id = UUID()  // for Identifiable
        let strings: [TableCellString]
    }

    // MARK: - Utilities
    private func findBlockById(_ id: UUID) -> BibleTextBlock? {
        blocks.first { $0.id == id }
    }

    private func verseNumFromPoint(pointInView: CGPoint,
                                   blockId: UUID,
                                   blockText: NSAttributedString,
                                   extraChars: Int) -> Int? {
        guard let ourFrame = ourFrames[blockId] else {
            return nil
        }
        guard let block = findBlockById(blockId) else {
            return nil
        }
        guard let i = characterIndex(
            for: pointInView,
            firstLineHeadIndent: block.firstLineHeadIndent,
            lineSpacing: options.lineSpacing,
            text: block.text.one,
            size: ourFrame.size
        ) else {
            return nil
        }
        guard let verse = verseAtIndex(i - extraChars, from: block) else {
            return nil
        }
        return verse
    }

    private func handleTap(at pointInView: CGPoint,
                           blockId: UUID,
                           blockText: NSAttributedString,
                           extraChars: Int = 0) {
        if let verse = verseNumFromPoint(
            pointInView: pointInView,
            blockId: blockId,
            blockText: blockText,
            extraChars: extraChars
        ) {
            if let ourFrame = ourFrames[blockId],
               let block = findBlockById(blockId) {
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
    public var fontFamily: String
    public var fontSize: CGFloat
    public var lineSpacing: CGFloat?
    public var paragraphSpacing: CGFloat?
    public var textColor: Color?
    public var wocColor = Color(red: 1, green: 0x3d / 256, blue: 0x4d / 256)  // YouVersion red. F04C59 in dark mode.
    public var footnoteMode: BibleTextFootnoteMode = .none
    public var footnoteMarker: DoubleAttributedString?

    public init(fontFamily: String = "Times New Roman",
                fontSize: CGFloat = 16,
                lineSpacing: CGFloat? = nil,
                paragraphSpacing: CGFloat? = nil,
                textColor: Color? = nil,
                wocColor: Color = Color(red: 1, green: 0x3d / 256, blue: 0x4d / 256),
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
