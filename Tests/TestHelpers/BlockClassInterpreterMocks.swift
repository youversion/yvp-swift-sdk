import Foundation

// Simple stand-ins for SwiftUI types
enum MockTextAlignment: Equatable {
    case leading, center, trailing
}

struct MockFont: Equatable {
    let name: String
}

struct MockUIFontSet {
    var textFont: MockFont = MockFont(name: "uiText")
    var header: MockFont = MockFont(name: "uiHeader")
    var headerItalic: MockFont = MockFont(name: "uiHeaderItalic")
    var header2: MockFont = MockFont(name: "uiHeader2")
    var header3: MockFont = MockFont(name: "uiHeader3")
    var header4: MockFont = MockFont(name: "uiHeader4")
    var footnote: MockFont = MockFont(name: "uiFootnote")
    var smallCaps: MockFont = MockFont(name: "uiSmallCaps")
    var textFontItalic: MockFont = MockFont(name: "uiItalic")
}

struct MockFonts {
    var textFont: MockFont = MockFont(name: "text")
    var header: MockFont = MockFont(name: "header")
    var headerItalic: MockFont = MockFont(name: "headerItalic")
    var header2: MockFont = MockFont(name: "header2")
    var header3: MockFont = MockFont(name: "header3")
    var header4: MockFont = MockFont(name: "header4")
    var footnote: MockFont = MockFont(name: "footnote")
    var smallCaps: MockFont = MockFont(name: "smallCaps")
    var textFontItalic: MockFont = MockFont(name: "italic")
}

struct DoubleBibleTextFonts {
    var one: MockUIFontSet = MockUIFontSet()
    var two: MockFonts = MockFonts()
}

struct DoubleFont: Equatable {
    var one: MockFont
    var two: MockFont
}

struct StateIn {
    var renderHeadlines: Bool = true
    var fonts: DoubleBibleTextFonts = DoubleBibleTextFonts()
}

struct StateDown: Equatable {
    var woc: Bool = false
    var smallcaps: Bool = false
    var alignment: MockTextAlignment = .leading
    var currentFont: DoubleFont = DoubleFont(one: MockFont(name: "default1"), two: MockFont(name: "default2"))
}

struct StateUp: Equatable {
    var rendering: Bool = true
    var isLineEmpty: Bool = true
    var firstLineHeadIndent: Int = 0
    var headIndent: Int = 0
}

// Original function copied from production code with simplified types
func interpretBlockClassesOriginal(_ classes: [String], stateIn: StateIn, stateDown: inout StateDown, stateUp: inout StateUp, marginTop: inout Int) {
    let indentStep = 1
    let fonts = stateIn.fonts
    for c in classes {
        if c == "p" {
            stateUp.firstLineHeadIndent = indentStep * 2
            stateUp.headIndent = 0
        } else if c == "m" || c == "nb" {
            stateUp.firstLineHeadIndent = 0
            stateUp.headIndent = 0
        } else if c == "pr" || c == "qr" {
            stateDown.alignment = .trailing
        } else if c == "pc" || c == "qc" {
            stateDown.alignment = .center
            stateDown.smallcaps = true
        } else if c == "mi" {
            stateUp.firstLineHeadIndent = 0
            stateUp.headIndent = 2
        } else if c == "d" {
            stateDown.currentFont = DoubleFont(one: fonts.one.headerItalic, two: fonts.two.headerItalic)
            if !stateIn.renderHeadlines { stateUp.rendering = false }
        } else if ["pi", "pi1"].contains(c) {
            stateUp.firstLineHeadIndent = indentStep
            stateUp.headIndent = 0
        } else if ["pi2"].contains(c) {
            stateUp.firstLineHeadIndent = indentStep * 2
            stateUp.headIndent = indentStep
        } else if ["pi3"].contains(c) {
            stateUp.firstLineHeadIndent = indentStep * 4
            stateUp.headIndent = indentStep * 3
        } else if ["iq", "iq1", "q", "q1", "qm", "qm1", "li1"].contains(c) {
            stateUp.firstLineHeadIndent = 0
            stateUp.headIndent = indentStep * 2
        } else if ["iq2", "q2", "qm2", "li2"].contains(c) {
            stateUp.firstLineHeadIndent = 0
            stateUp.headIndent = indentStep * 4
        } else if ["iq3", "q3", "qm3", "li3"].contains(c) {
            stateUp.firstLineHeadIndent = 0
            stateUp.headIndent = indentStep * 5
        } else if ["iq4", "q4", "qm4", "li4"].contains(c) {
            stateUp.firstLineHeadIndent = 0
            stateUp.headIndent = indentStep * 6
        } else if ["pm", "pmo", "pmc", "pmr"].contains(c) {
            stateUp.firstLineHeadIndent = 0
            stateUp.headIndent = indentStep * 2
        } else if (c == "yv-h") || (c == "yvh") {
            if classes.contains("ms") || classes.contains("ms1") { stateDown.currentFont = DoubleFont(one: fonts.one.header, two: fonts.two.header) }
            else if classes.contains("mr") { stateDown.currentFont = DoubleFont(one: fonts.one.headerItalic, two: fonts.two.headerItalic) }
            else if classes.contains("s2") || classes.contains("ms2") { stateDown.currentFont = DoubleFont(one: fonts.one.header2, two: fonts.two.header2) }
            else if classes.contains("s3") || classes.contains("ms3") { stateDown.currentFont = DoubleFont(one: fonts.one.header3, two: fonts.two.header3) }
            else if classes.contains("s4") || classes.contains("ms4") { stateDown.currentFont = DoubleFont(one: fonts.one.header4, two: fonts.two.header4) }
            else if classes.contains("sp") || classes.contains("r") || classes.contains("sr") {
                stateDown.currentFont = DoubleFont(one: fonts.one.headerItalic, two: fonts.two.headerItalic)
            }
            else {  stateDown.currentFont = DoubleFont(one: fonts.one.header, two: fonts.two.header) }
            marginTop = 2
            stateUp.firstLineHeadIndent = 0
            if !stateIn.renderHeadlines { stateUp.rendering = false }
        } else {
            let ignore = ["s1", "b", "lh", "li", "li1", "li2", "li3", "li4", "lf", "mr", "ms", "ms1", "ms2", "ms3", "ms4", "s2", "s3", "s4", "sp", "iex", "ms1", "qa", "r", "sr", "po"]
            if !ignore.contains(c) {
                print("interpretBlockClasses: unexpected \(c)")
            }
        }
    }
}

// Dictionary-driven version under test
private typealias BlockAction = (_ classes: [String], _ stateIn: StateIn, _ stateDown: inout StateDown, _ stateUp: inout StateUp, _ marginTop: inout Int) -> Void

@MainActor
private let classActions: [String: BlockAction] = {
    let indentStep = 1
    var actions: [String: BlockAction] = [:]
    func add(_ names: [String], action: @escaping BlockAction) { for n in names { actions[n] = action } }

    add(["p"], action: { _,_,_,su,_ in su.firstLineHeadIndent = indentStep * 2; su.headIndent = 0 })
    add(["m", "nb"], action: { _,_,_,su,_ in su.firstLineHeadIndent = 0; su.headIndent = 0 })
    add(["pr", "qr"], action: { _,_,sd,_,_ in sd.alignment = .trailing })
    add(["pc", "qc"], action: { _,_,sd,_,_ in sd.alignment = .center; sd.smallcaps = true })
    add(["mi"], action: { _,_,_,su,_ in su.firstLineHeadIndent = 0; su.headIndent = 2 })
    add(["pi", "pi1"], action: { _,_,_,su,_ in su.firstLineHeadIndent = indentStep; su.headIndent = 0 })
    add(["pi2"], action: { _,_,_,su,_ in su.firstLineHeadIndent = indentStep * 2; su.headIndent = indentStep })
    add(["pi3"], action: { _,_,_,su,_ in su.firstLineHeadIndent = indentStep * 4; su.headIndent = indentStep * 3 })
    add(["iq", "iq1", "q", "q1", "qm", "qm1", "li1"], action: { _,_,_,su,_ in su.firstLineHeadIndent = 0; su.headIndent = indentStep * 2 })
    add(["iq2", "q2", "qm2", "li2"], action: { _,_,_,su,_ in su.firstLineHeadIndent = 0; su.headIndent = indentStep * 4 })
    add(["iq3", "q3", "qm3", "li3"], action: { _,_,_,su,_ in su.firstLineHeadIndent = 0; su.headIndent = indentStep * 5 })
    add(["iq4", "q4", "qm4", "li4"], action: { _,_,_,su,_ in su.firstLineHeadIndent = 0; su.headIndent = indentStep * 6 })
    add(["pm", "pmo", "pmc", "pmr"], action: { _,_,_,su,_ in su.firstLineHeadIndent = 0; su.headIndent = indentStep * 2 })
    return actions
}()

@MainActor
func interpretBlockClassesNew(_ classes: [String], stateIn: StateIn, stateDown: inout StateDown, stateUp: inout StateUp, marginTop: inout Int) {
    let fonts = stateIn.fonts
    for c in classes {
        if let action = classActions[c] {
            action(classes, stateIn, &stateDown, &stateUp, &marginTop)
            continue
        }
        switch c {
        case "d":
            stateDown.currentFont = DoubleFont(one: fonts.one.headerItalic, two: fonts.two.headerItalic)
            if !stateIn.renderHeadlines { stateUp.rendering = false }
        case "yv-h", "yvh":
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
                stateDown.currentFont = DoubleFont(one: fonts.one.header, two: fonts.two.header)
            }
            marginTop = 2
            stateUp.firstLineHeadIndent = 0
            if !stateIn.renderHeadlines { stateUp.rendering = false }
        default:
            let ignore = ["s1", "b", "lh", "li", "li1", "li2", "li3", "li4", "lf", "mr", "ms", "ms1", "ms2", "ms3", "ms4", "s2", "s3", "s4", "sp", "iex", "ms1", "qa", "r", "sr", "po"]
            if !ignore.contains(c) {
                print("interpretBlockClasses: unexpected \(c)")
            }
        }
    }
}

