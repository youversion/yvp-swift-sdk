import XCTest

@MainActor
class InterpretBlockClassesTests: XCTestCase {
    private func makeFonts() -> DoubleBibleTextFonts {
        return DoubleBibleTextFonts()
    }

    private func runOriginal(classes: [String], renderHeadlines: Bool = true) -> (StateDown, StateUp, Int) {
        var sd = StateDown()
        var su = StateUp()
        var mt = 0
        let fonts = makeFonts()
        let stateIn = StateIn(renderHeadlines: renderHeadlines, fonts: fonts)
        interpretBlockClassesOriginal(classes, stateIn: stateIn, stateDown: &sd, stateUp: &su, marginTop: &mt)
        return (sd, su, mt)
    }

    private func runNew(classes: [String], renderHeadlines: Bool = true) -> (StateDown, StateUp, Int) {
        var sd = StateDown()
        var su = StateUp()
        var mt = 0
        let fonts = makeFonts()
        let stateIn = StateIn(renderHeadlines: renderHeadlines, fonts: fonts)
        interpretBlockClassesNew(classes, stateIn: stateIn, stateDown: &sd, stateUp: &su, marginTop: &mt)
        return (sd, su, mt)
    }

    func testIndividualClasses() {
        let classes = ["p","m","nb","pr","qr","pc","qc","mi","d","pi","pi1","pi2","pi3","iq","iq1","q","q1","qm","qm1","li1","iq2","q2","qm2","li2","iq3","q3","qm3","li3","iq4","q4","qm4","li4","pm","pmo","pmc","pmr"]
        for c in classes {
            let r1 = runOriginal(classes: [c])
            let r2 = runNew(classes: [c])
            XCTAssertEqual(r1.0, r2.0, "StateDown mismatch for \(c)")
            XCTAssertEqual(r1.1, r2.1, "StateUp mismatch for \(c)")
            XCTAssertEqual(r1.2, r2.2, "marginTop mismatch for \(c)")
        }
    }

    func testHeaderCombinations() {
        let combos = [
            ["yv-h","ms"],
            ["yv-h","ms1"],
            ["yv-h","mr"],
            ["yv-h","s2"],
            ["yv-h","s3"],
            ["yv-h","s4"],
            ["yv-h","sp"],
            ["yv-h","r"],
            ["yv-h","sr"],
            ["yvh","ms"],
        ]
        for combo in combos {
            let r1 = runOriginal(classes: combo, renderHeadlines: false)
            let r2 = runNew(classes: combo, renderHeadlines: false)
            XCTAssertEqual(r1.0, r2.0, "StateDown mismatch for \(combo)")
            XCTAssertEqual(r1.1, r2.1, "StateUp mismatch for \(combo)")
            XCTAssertEqual(r1.2, r2.2, "marginTop mismatch for \(combo)")
        }
    }
}
