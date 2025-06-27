import SwiftUI

struct BibleVersionRendering {

    public static func plainTextOf(_ reference: BibleReference) -> String {
        // the fonts aren't used in this case, but are required.
        let familyName = "Times New Roman"
        let uiFonts = BibleTextUIFonts(familyName: familyName)
        let blocks = textBlocks(
            reference,
            renderVerseNumbers: false,
            renderHeadlines: false,
            renderFootnotes: false,
            fonts: BibleTextFonts(familyName: familyName),
            uiFonts: uiFonts
        )

        return blocks.map { String($0.text.characters) }.joined(separator: "\n")
    }

    // If not all chapters are available, this returns an empty array.
    // Marked as @MainActor due to NSMutableAttributedStrings in BibleTextBlocks.
    @MainActor
    static func textBlocksAsync(
        _ reference: BibleReference,
        renderVerseNumbers: Bool = true,
        renderHeadlines: Bool = true,
        renderFootnotes: Bool = false,
        footnoteMarker: DoubleAttributedString? = nil,
        wocColor: Color = Color.red,
        fonts: BibleTextFonts,
        uiFonts: BibleTextUIFonts
    ) async -> [BibleTextBlock] {
        // The normal textBlocks() is sync, so it won't fetch from the server.
        // So, ensure that every chapter needed is available. This warms the cache up!
        guard let book = reference.bookUSFM else {
            return []
        }
        var c = reference.chapterStart
        while c <= reference.chapterEnd {
            let chapterRef = BibleReference(versionId: reference.versionId, bookUSFM: book, chapter: c, verse: 1)
            let data = await BibleVersionCache.chapter(reference: chapterRef)
            if data == nil {
                return []
            }
            c += 1
        }
        return textBlocks(
            reference,
            renderVerseNumbers: renderVerseNumbers,
            renderHeadlines: renderHeadlines,
            renderFootnotes: renderFootnotes,
            footnoteMarker: footnoteMarker,
            wocColor: wocColor,
            fonts: fonts,
            uiFonts: uiFonts
        )
    }
    
    static func textBlocks(
        _ reference: BibleReference,
        renderVerseNumbers: Bool = true,
        renderHeadlines: Bool = true,
        renderFootnotes: Bool = false,
        footnoteMarker: DoubleAttributedString? = nil,
        wocColor: Color = Color.red,
        fonts: BibleTextFonts,
        uiFonts: BibleTextUIFonts
    ) -> [BibleTextBlock] {
        guard let book = reference.bookUSFM else {
            return []
        }
        var ret: [BibleTextBlock] = []
        var c = reference.chapterStart
        var v = reference.verseStart
        var v2 = reference.verseEnd
        while c <= reference.chapterEnd {
            if c == reference.chapterEnd && reference.verseEnd > 0 {
                v2 = reference.verseEnd
            } else {
                v2 = 999
            }
            let chapterRef = BibleReference(versionId: reference.versionId, bookUSFM: book, chapter: c, verse: 1)
            if let data = BibleVersionCache.chapterFromCache(reference: chapterRef) {
                let doubleFonts = DoubleBibleTextFonts(one: uiFonts, two: fonts)
                let marker = footnoteMarker
                if marker != nil {
                    marker!.setFont(DoubleFont(one: doubleFonts.one.footnote, two: doubleFonts.two.footnote))
                }
                let stateIn = StateIn(
                    fromVerse: v,
                    toVerse: v2,
                    renderVerseNumbers: renderVerseNumbers,
                    renderHeadlines: renderHeadlines,
                    renderFootnotes: renderFootnotes,
                    footnoteMarker: marker,
                    wocColor: wocColor,
                    fonts: doubleFonts
                )
                let stateDown = StateDown(
                    woc: false,
                    smallcaps: false,
                    alignment: .leading,
                    currentFont: DoubleFont(one: stateIn.fonts.one.textFont, two: stateIn.fonts.two.textFont)
                )
                var stateUp = StateUp(
                    rendering: (c == reference.chapterStart && reference.verseStart <= 1),
                    lineIsEmpty: true,
                    firstLineHeadIndent: 0,
                    headIndent: 0,
                    chapter: c,
                    verse: 0
                )
                
                handleNodeBlock(
                    node: data.root,
                    stateIn: stateIn, stateDown: stateDown, stateUp: &stateUp,
                    ret: &ret
                )
            }
            c += 1
            v = 0
        }
        return ret
    }

    private static func handleBlockKid(
        _ node: Youversion_Red_Biblecontent_Api_Model_Youversion_ApiNode,
        stateIn: StateIn,
        stateDown parentStateDown: StateDown,
        stateUp: inout StateUp
    ) {
        var stateDown = parentStateDown
        if node.type != .span && node.type != .text {
            assertionFailed("handleBlockKid: unexpected:", type: node.type)
        }

        interpretTextAttr(node, stateIn: stateIn, stateDown: &stateDown, stateUp: &stateUp)

        if stateUp.rendering && !node.text.isEmpty {
            var txt = DoubleAttributedString(stateDown.smallcaps ? node.text.uppercased() : node.text)
            if node.text == "  " {
                // It feels odd for us to do this check, but extra spaces are present in the source,
                // after footnotes e.g. NIV Acts 1:4, and at ends of some verses e.g. Acts 1:7.
                // The concept is/was HTML, which does this collapsing internally.
                txt = DoubleAttributedString(" ")
            }
            txt.setFont(stateDown.currentFont)
            if stateDown.woc {
                txt.setColor(stateIn.wocColor)
            }
            stateUp.append(txt)
        }

        if stateUp.rendering &&
            (node.classes.contains("yv-vlbl") || node.classes.contains("vlbl"))
            && node.children.count == 1 && node.children.first?.type == .text {
            if let t = node.children.first?.text {
                if stateIn.renderVerseNumbers {
                    let maybeSpace = stateUp.lineIsEmpty ? "" : " "
                    let vn = DoubleAttributedString(maybeSpace + "\(t)\u{00a0}")  // nonbreaking space
                    vn.setFont(DoubleFont(one: stateIn.fonts.one.verseNumFont, two: stateIn.fonts.two.verseNumFont))
                    vn.setBaselineOffset(stateIn.fonts.one.verseNumBaselineOffset)
                    vn.setColor(Color.primary.opacity(stateIn.fonts.two.verseNumOpacity))
                    stateUp.append(vn)
                }
            }
        } else if node.classes.contains("rq") {
            // a cross-reference, e.g. NIrV (#110) Revelation 19:15. Not really a footnote; something different.
        } else if node.classes.contains("yv-n") && node.classes.contains("f") {
            if stateUp.rendering && stateIn.renderFootnotes {
                handleFootnoteNode(node, stateIn: stateIn, stateDown: stateDown, stateUp: &stateUp)
            }
        } else if node.classes.contains("yv-n") && node.classes.contains("x") {
            // cross-reference; present e.g. in ESV
        } else {
            for kid in node.children {
                handleBlockKid(kid, stateIn: stateIn, stateDown: stateDown, stateUp: &stateUp)
                stateUp.lineIsEmpty = false  // TODO: this line has existed for a while. Should it?
            }
        }
    }

    private static func handleFootnoteNode(
        _ node: Youversion_Red_Biblecontent_Api_Model_Youversion_ApiNode,
        stateIn: StateIn,
        stateDown parentStateDown: StateDown,
        stateUp: inout StateUp
    ) {
        var stateDown = parentStateDown
        if let marker = stateIn.footnoteMarker {
            stateUp.append(marker)
            // now, collect the text of the footnotes into footState
            var footState = StateUp(rendering: true, chapter: stateUp.chapter, verse: stateUp.verse)
            stateDown.currentFont = DoubleFont(one: stateIn.fonts.one.footnote, two: stateIn.fonts.two.footnote)
            for kid in node.children {
                handleBlockKid(kid, stateIn: stateIn, stateDown: stateDown, stateUp: &footState)
            }
            stateUp.footnotes.append(footState.text)
        } else {
            for kid in node.children {
                stateDown.currentFont = DoubleFont(one: stateIn.fonts.one.footnote, two: stateIn.fonts.two.footnote)
                handleBlockKid(kid, stateIn: stateIn, stateDown: stateDown, stateUp: &stateUp)
            }
            // TODO: add a space here? Maybe only if it doesn't already end with whitespace?
        }
        stateUp.lineIsEmpty = false  // TODO: this line has existed for a while. Should it?
    }

    private static func handleNodeCell(
        node: Youversion_Red_Biblecontent_Api_Model_Youversion_ApiNode,
        stateIn: StateIn,
        stateDown parentStateDown: StateDown,
        stateUp: inout StateUp
    ) {
        var stateDown = parentStateDown
        for kid in node.children {
            if kid.type == .span || kid.type == .text {
                stateDown.currentFont = DoubleFont(one: stateIn.fonts.one.textFont, two: stateIn.fonts.two.textFont)
                handleBlockKid(kid, stateIn: stateIn, stateDown: stateDown, stateUp: &stateUp)
                // handleBlockKid puts its result into stateUp.text
            } else {
                assertionFailed("unexpected child of cell: ", type: kid.type)
            }
        }
    }

    private static func handleNodeRow(
        node: Youversion_Red_Biblecontent_Api_Model_Youversion_ApiNode,
        stateIn: StateIn,
        stateDown parentStateDown: StateDown,
        stateUp: inout StateUp
    ) -> [DoubleAttributedString] {
        let stateDown = parentStateDown
        var thisRow: [DoubleAttributedString] = []
        for kid in node.children {
            if kid.type == .cell {
                handleNodeCell(node: kid, stateIn: stateIn, stateDown: stateDown, stateUp: &stateUp)
                if stateUp.rendering {
                    stateUp.text.trimTrailingWhitespaceAndNewlines()
                    thisRow.append(stateUp.text)
                    stateUp.clearText()
                }
            } else {
                assertionFailed("unexpected child of row: ", type: kid.type)
            }
        }
        return thisRow
    }

    private static func handleNodeTable(
        node: Youversion_Red_Biblecontent_Api_Model_Youversion_ApiNode,
        stateIn: StateIn,
        stateDown parentStateDown: StateDown,
        stateUp: inout StateUp,
        ret: inout [BibleTextBlock]
    ) {
        let stateDown = parentStateDown
        var rows: [[DoubleAttributedString]] = []

        if !node.classes.isEmpty {
            assertionFailed("unexpected classes for this table: ", string: "\(node.classes)")
        }
        for kid in node.children {
            if kid.type == .row {
                let row = handleNodeRow(node: kid, stateIn: stateIn, stateDown: stateDown, stateUp: &stateUp)
                if !row.isEmpty {
                    rows.append(row)
                }
            } else {
                assertionFailed("unexpected child of table: ", type: kid.type)
            }
        }
        if !rows.isEmpty {
            ret.append(
                BibleTextBlock(
                    text: DoubleAttributedString(),
                    chapter: stateUp.chapter,
                    verseOffsets: stateUp.verseOffsets,
                    firstLineHeadIndent: 0, headIndent: 0, marginTop: 10,
                    alignment: .leading,
                    footnotes: stateUp.footnotes,
                    rows: rows
                )
            )
        }
    }

    private static func handleNodeBlock(
        node: Youversion_Red_Biblecontent_Api_Model_Youversion_ApiNode,
        stateIn: StateIn,
        stateDown parentStateDown: StateDown,
        stateUp: inout StateUp,
        ret: inout [BibleTextBlock]
    ) {
        var stateDown = parentStateDown
        var marginTop: CGFloat = 0
        let fonts = stateIn.fonts
        stateDown.currentFont = DoubleFont(one: fonts.one.textFont, two: fonts.two.textFont)

        if node.type != .block {  // TODO maybe just bail if it's not a block. Or assert.
            assertionFailed("unexpected: handleNodeBlock was given: ", type: node.type)
            return
        }
        if node.classes.contains("cl") {
            // "cl" means: Chapter label used for versions that add a word such
            // as "Chapter"... we show that another way in our UI.
            return
        }

        interpretBlockClasses(
            node.classes,
            stateIn: stateIn,
            stateDown: &stateDown, stateUp: &stateUp,
            marginTop: &marginTop
        )

        for kid in node.children {
            // types: block, span, text. Table, row, cell.
            if kid.type == .block || kid.type == .table {
                if !stateUp.text.isEmpty {
                    if stateUp.rendering {
                        ret.append(createBlock(stateDown: stateDown, stateUp: &stateUp, marginTop: marginTop))
                    }
                    stateUp.clearText()
                }
                if kid.type == .block {
                    handleNodeBlock(node: kid, stateIn: stateIn, stateDown: stateDown, stateUp: &stateUp, ret: &ret)
                } else if kid.type == .table {
                    handleNodeTable(node: kid, stateIn: stateIn, stateDown: stateDown, stateUp: &stateUp, ret: &ret)
                }
            } else {
                if kid.type == .span && kid.classes.contains("qs") {  // Selah. Force a line break and right-alignment.
                    if !stateUp.text.isEmpty {
                        if stateUp.rendering {
                            ret.append(createBlock(stateDown: stateDown, stateUp: &stateUp, marginTop: marginTop))
                            stateUp.clearText()
                            //stateDown.marginTop = marginTop  // TODO
                            handleBlockKid(kid, stateIn: stateIn, stateDown: stateDown, stateUp: &stateUp)
                            var tmpStateDown = stateDown
                            tmpStateDown.alignment = .trailing
                            ret.append(createBlock(stateDown: tmpStateDown, stateUp: &stateUp, marginTop: marginTop))
                        }
                        stateUp.clearText()
                    }
                } else {
                    handleBlockKid(kid, stateIn: stateIn, stateDown: stateDown, stateUp: &stateUp)
                }
            }
        }
        if !stateUp.text.isEmpty {
            ret.append(createBlock(stateDown: stateDown, stateUp: &stateUp, marginTop: marginTop))
            stateUp.clearText()
        }
    }

    private static func createBlock(
        stateDown: StateDown,
        stateUp: inout StateUp,
        marginTop: CGFloat
    ) -> BibleTextBlock {
        let block = BibleTextBlock(
            text: stateUp.text,
            chapter: stateUp.chapter,
            verseOffsets: stateUp.verseOffsets,
            firstLineHeadIndent: stateUp.firstLineHeadIndent,
            headIndent: stateUp.headIndent,
            marginTop: marginTop,
            alignment: stateDown.alignment,
            footnotes: stateUp.footnotes
        )
        stateUp.footnotes.removeAll()
        return block
    }

    private static func interpretBlockClasses(
        _ classes: [String],
        stateIn: StateIn,
        stateDown: inout StateDown,
        stateUp: inout StateUp,
        marginTop: inout CGFloat
    ) {
        let fonts = stateIn.fonts
        let indentStep = 1
        let ignoredTags = [  // things we don't currently care about:
            "s1",  // Change line-height to 1em. Co-occurrs with "yv-h".
            "b",   // Poetry text stanza break (e.g. stanza break)
            "lh",  // A list header (introductory remark)
            "li",  // A list entry, level 1 (if single level)
            "li1", // A list entry, level 1 (if multiple levels)
            "li2", // A list entry, level 2
            "li3", // A list entry, level 3
            "li4", // A list entry, level 4
            "lf",  // List footer (introductory remark)
            "mr", "ms", "ms1", "ms2", "ms3", "ms4", "s2", "s3", "s4", "sp",  // handled inside yv-h
            "iex", // see John 7:52
            "ms1",
            "qa",
            "r",
            "sr",
            "po"
        ]

        for c in classes {
            switch c {

            case "p":
                stateUp.firstLineHeadIndent = indentStep * 2
                stateUp.headIndent = 0

            case "m", "nb":
                stateUp.firstLineHeadIndent = 0
                stateUp.headIndent = 0

            case "pr", "qr":
                stateDown.alignment = .trailing

            case "pc", "qc":
                stateDown.alignment = .center
                stateDown.smallcaps = true

            case "mi":
                stateUp.firstLineHeadIndent = 0
                stateUp.headIndent = 2

            case "pi", "pi1":
                stateUp.firstLineHeadIndent = indentStep
                stateUp.headIndent = 0

            case "pi2":
                stateUp.firstLineHeadIndent = indentStep * 2
                stateUp.headIndent = indentStep

            case "pi3":
                stateUp.firstLineHeadIndent = indentStep * 4
                stateUp.headIndent = indentStep * 3

            case "iq", "iq1", "q", "q1", "qm", "qm1", "li1":
                // Here we should indent all but the first line. Well, we can't do that yet. Indent it all.
                stateUp.firstLineHeadIndent = 0
                stateUp.headIndent = indentStep * 2

            case "iq2", "q2", "qm2", "li2":
                stateUp.firstLineHeadIndent = 0
                stateUp.headIndent = indentStep * 4

            case "iq3", "q3", "qm3", "li3":
                stateUp.firstLineHeadIndent = 0
                stateUp.headIndent = indentStep * 5

            case "iq4", "q4", "qm4", "li4":
                stateUp.firstLineHeadIndent = 0
                stateUp.headIndent = indentStep * 6

            case "pm", "pmo", "pmc", "pmr":
                stateUp.firstLineHeadIndent = 0
                stateUp.headIndent = indentStep * 2

            case "d":  // "d" # A Hebrew text heading, to provide description (e.g. Psalms)
                stateDown.currentFont = DoubleFont(one: fonts.one.headerItalic, two: fonts.two.headerItalic)
                if !stateIn.renderHeadlines { stateUp.rendering = false }

            case "yv-h", "yvh":  // yv-h meaning header
                if classes.contains("ms") || classes.contains("ms1") {
                    stateDown.currentFont = DoubleFont(one: fonts.one.header, two: fonts.two.header)
                } else if classes.contains("mr") {
                    stateDown.currentFont = DoubleFont(one: fonts.one.headerItalic, two: fonts.two.headerItalic)
                } else if classes.contains("s2") || classes.contains("ms2") {
                    stateDown.currentFont = DoubleFont(one: fonts.one.header2, two: fonts.two.header2)
                } else if classes.contains("s3") || classes.contains("ms3") {
                    stateDown.currentFont = DoubleFont(one: fonts.one.header3, two: fonts.two.header3)
                } else if classes.contains("s4") || classes.contains("ms4") {
                    stateDown.currentFont = DoubleFont(one: fonts.one.header4, two: fonts.two.header4)
                } else if classes.contains("sp") || classes.contains("r") || classes.contains("sr") {
                    stateDown.currentFont = DoubleFont(one: fonts.one.headerItalic, two: fonts.two.headerItalic)
                } else {
                    // includes "s1" and "qa" by default; that's appropriate
                    stateDown.currentFont = DoubleFont(one: fonts.one.header, two: fonts.two.header)
                }
                marginTop = 2
                stateUp.firstLineHeadIndent = 0
                if !stateIn.renderHeadlines { stateUp.rendering = false }

            default:
                if !ignoredTags.contains(c) {
                    assertionFailed("interpreting block classes: unexpected ", string: c)
                }
            }
        }
    }

    private static func interpretTextAttr(
        _ node: Youversion_Red_Biblecontent_Api_Model_Youversion_ApiNode,
        stateIn: StateIn,
        stateDown: inout StateDown,
        stateUp: inout StateUp
    ) {
        let fonts = stateIn.fonts
        // this is a weird place to do this, but the tag is on a block, and block classes don't usually change fonts, so...
        if stateDown.smallcaps {
            stateDown.currentFont = DoubleFont(one: fonts.one.smallCaps, two: fonts.two.smallCaps)
        }

        for c in node.classes {
            if c == "wj" {
                stateDown.woc = true
            } else if c == "yv-v" || c == "verse" {  // (invisible) start of a verse.
                if let v = node.attributes["v"] {
                    if let vi = Int(v) {
                        stateUp.verse = vi
                        stateUp.rendering = (vi >= stateIn.fromVerse) && (vi <= stateIn.toVerse)
                    }
                }
            } else if node.classes.contains("nd") || node.classes.contains("sc") {
                stateDown.currentFont = DoubleFont(one: fonts.one.smallCaps, two: fonts.two.smallCaps)
                stateDown.smallcaps = true
            } else if node.classes.contains("tl") || node.classes.contains("it") || node.classes.contains("add") {
                stateDown.currentFont = DoubleFont(one: fonts.one.textFontItalic, two: fonts.two.textFontItalic)
            } else if node.classes.contains("qs") || node.classes.contains("qt") {
                stateDown.currentFont = DoubleFont(one: fonts.one.textFontItalic, two: fonts.two.textFontItalic)
            } else {
                if !["yv-v", "verse", "yv-vlbl", "vlbl", "yv-n", "f", "fr", "ft",
                     "qs", "sc", "nd", "cl", "w", "litl", "rq", "x"].contains(c) {
                    assertionFailed("interpretTextAttr: unexpected ", string: c)
                }
            }
        }
    }

    // TODO optimise, if it's worthwhile. Calculate a range and make one new string, not several.
    private static func trimTrailingWhitespaceAndNewlines(_ attributedString: AttributedString) -> AttributedString {
        var localCopy = attributedString
        while let lastCharacter = localCopy.characters.last, lastCharacter.isWhitespace {
            localCopy = AttributedString(localCopy.characters.dropLast())
        }
        return localCopy
    }

    private static func assertionFailed(
        _ message: String,
        string: String? = nil,
        type: Youversion_Red_Biblecontent_Api_Model_Youversion_ApiNodeType? = nil
    ) {
#if false
        // enable this for debugging/tracing this rendering code
        if let type {
            print(message + (string ?? "") + "\(type)")
        } else {
            print(message + (string ?? ""))
        }
#endif
    }

    // input parameters to the rendering; read-only while walking the node structure.
    private struct StateIn {
        var fromVerse: Int  // in the chapter, the lowest number verse to render. Could be 0.
        var toVerse: Int  // in the chapter, the highest number verse to render. Could be 999.
        var renderVerseNumbers: Bool
        var renderHeadlines: Bool
        var renderFootnotes: Bool
        var footnoteMarker: DoubleAttributedString?  // shown when renderFootnotes is true. If nil, they render inline.
        var wocColor: Color
        var fonts: DoubleBibleTextFonts
    }

    // As we walk the node structure, these are attributes which
    // child nodes change, but do not pass up to their parent node.
    private struct StateDown {
        var woc = false
        var smallcaps = false
        var alignment = TextAlignment.leading
        var currentFont: DoubleFont
    }

    // As we walk the node structure, these are attributes which
    // child nodes change and pass up to their parent node.
    private struct StateUp {
        var rendering: Bool
        var lineIsEmpty = true  // have we not seen text in the current block yet?
        var firstLineHeadIndent = 0
        var headIndent = 0
        var chapter: Int
        var verse: Int
        var text = DoubleAttributedString()
        var verseOffsets: [Int] = [] // conceptually it's an [Int: Int] but they're just appended
        var footnotes: [DoubleAttributedString] = []

        mutating func append(_ newText: DoubleAttributedString) {
            verseOffsets.append(text.one.length)
            verseOffsets.append(verse)
            if !newText.isEmpty {
                text += newText
                lineIsEmpty = false
            }
        }

        mutating func clearText() {
            text = DoubleAttributedString()
            verseOffsets.removeAll()
            lineIsEmpty = true
        }
    }

}

public class DoubleAttributedString: Equatable, Hashable {
    var one: NSMutableAttributedString
    var two: AttributedString

    public init() {
        one = NSMutableAttributedString()
        two = AttributedString()
    }

    public init(_ string: String) {
        one = NSMutableAttributedString(string: string)
        two = AttributedString(string)
    }

    static func +(lhs: DoubleAttributedString, rhs: DoubleAttributedString) -> DoubleAttributedString { //swiftlint:disable:this operator_whitespace
        let result = DoubleAttributedString()
        result.one = NSMutableAttributedString(attributedString: lhs.one)
        result.one.append(rhs.one)
        result.two = lhs.two + rhs.two
        return result
    }

    static func += (lhs: inout DoubleAttributedString, rhs: DoubleAttributedString) {
        lhs = lhs + rhs
    }

    public static func == (lhs: DoubleAttributedString, rhs: DoubleAttributedString) -> Bool {
        lhs.one.string == rhs.one.string
    }

    public func hash(into hasher: inout Hasher) {
        two.hash(into: &hasher)
    }

    var characters: String {
        String(two.characters)
    }

    var isEmpty: Bool {
        two.characters.isEmpty
    }

    @discardableResult
    public func setFont(_ font: DoubleFont) -> DoubleAttributedString {
        one.addAttributes([.font: font.one], range: NSRange(location: 0, length: one.length))
        two.font = font.two
        return self
    }

    @discardableResult
    public func setFont(_ font: Font, uiFont: UIFont) -> DoubleAttributedString {
        one.addAttributes([.font: uiFont], range: NSRange(location: 0, length: one.length))
        two.font = font
        return self
    }

    @discardableResult
    public func setColor(_ color: Color) -> DoubleAttributedString {
        one.addAttributes([.foregroundColor: UIColor(color)], range: NSRange(location: 0, length: one.length))
        var ac = AttributeContainer()
        ac.foregroundColor = color
        two.mergeAttributes(ac)
        return self
    }

    @discardableResult
    public func setBaselineOffset(_ offset: CGFloat) -> DoubleAttributedString {
        one.addAttribute(.baselineOffset, value: offset, range: NSRange(location: 0, length: one.length))
        two.baselineOffset = offset
        return self
    }

    func trimTrailingWhitespaceAndNewlines() {
        let str = one.string
        if let range = str.range(of: "\\s+$", options: .regularExpression) {
            let nsRange = NSRange(range, in: str)
            one.replaceCharacters(in: nsRange, with: "")
        }

        var trimmed = two
        while let last = trimmed.characters.last, last.isWhitespace {
            trimmed = AttributedString(trimmed.characters.dropLast())
        }
        two = trimmed
    }
}

struct BibleTextBlock: Identifiable {
    let id = UUID()
    let text: DoubleAttributedString
    let chapter: Int
    let verseOffsets: [Int]
    let rows: [[DoubleAttributedString]]  // If it's a table, these are present instead of "text".
    let firstLineHeadIndent: Int  // The indentation of the first line of the paragraph. Always >= 0.
    let headIndent: Int  // The indentation of the paragraph’s lines other than the first. Always >= 0.
    //let tailIndent: Int  // If positive, this value is the distance from the leading margin (for example,
    //the left margin in left-to-right text). If 0 or negative, it’s the distance from the trailing margin.
    let marginTop: CGFloat
    let alignment: TextAlignment
    let footnotes: [DoubleAttributedString]

    init(text: DoubleAttributedString,
         chapter: Int, verseOffsets: [Int],
         firstLineHeadIndent: Int, headIndent: Int, marginTop: CGFloat, alignment: TextAlignment,
         footnotes: [DoubleAttributedString],
         rows: [[DoubleAttributedString]] = []) {
        self.text = text
        self.chapter = chapter
        self.verseOffsets = verseOffsets
        self.firstLineHeadIndent = firstLineHeadIndent
        self.headIndent = headIndent
        self.marginTop = marginTop
        self.alignment = alignment
        self.footnotes = footnotes
        self.rows = rows
    }

}

public struct DoubleBibleTextFonts {
    let one: BibleTextUIFonts
    let two: BibleTextFonts
}

public struct DoubleFont {
    let one: UIFont
    let two: Font
}
