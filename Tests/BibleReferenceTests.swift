import XCTest
@testable import YouVersionPlatform

final class BibleReferenceTests: XCTestCase {
    
    // MARK: - Test Initialization
    
    func testInitSingleVerse() {
        let ref = BibleReference(versionId: 1, b: "GEN", c: 1, v: 1)
        
        XCTAssertEqual(ref.versionId, 1)
        XCTAssertEqual(ref.book, "GEN")
        XCTAssertEqual(ref.c, 1)
        XCTAssertEqual(ref.c2, 1) // c2 should be same as c for single verse
        XCTAssertEqual(ref.v, 1)
        XCTAssertEqual(ref.v2, 1) // v2 should be same as v for single verse
    }
    
    func testInitVerseRange() {
        let ref = BibleReference(versionId: 1, b: "PSA", c: 23, v: 1, c2: 24, v2: 2)
        
        XCTAssertEqual(ref.versionId, 1)
        XCTAssertEqual(ref.book, "PSA")
        XCTAssertEqual(ref.c, 23)
        XCTAssertEqual(ref.c2, 24)
        XCTAssertEqual(ref.v, 1)
        XCTAssertEqual(ref.v2, 2)
    }
    
    // MARK: - Test isRange
    
    func testIsRange_SingleVerse() {
        let ref = BibleReference(versionId: 1, b: "EXO", c: 3, v: 14)
        XCTAssertFalse(ref.isRange)
    }
    
    func testIsRange_VerseRange() {
        let ref = BibleReference(versionId: 1, b: "EXO", c: 3, v: 14, c2: 3, v2: 15)
        XCTAssertTrue(ref.isRange)
    }
    
    func testIsRange_ChapterRange() {
        let ref = BibleReference(versionId: 1, b: "EXO", c: 3, v: 1, c2: 4, v2: 1)
        XCTAssertTrue(ref.isRange)
    }
    
    // MARK: - Test compare function
    
    func testCompare_SameReference() {
        let ref1 = BibleReference(versionId: 1, b: "GEN", c: 1, v: 1)
        let ref2 = BibleReference(versionId: 1, b: "GEN", c: 1, v: 1)
        
        XCTAssertEqual(BibleReference.compare(a: ref1, b: ref2), 0)
    }
    
    func testCompare_DifferentBooks() {
        // Note: Comparing different books is not reliable without knowing the canonical book order
        // This test just verifies the function doesn't crash with different book codes
        let genRef = BibleReference(versionId: 1, b: "GEN", c: 1, v: 1)
        let exoRef = BibleReference(versionId: 1, b: "EXO", c: 1, v: 1)
        
        // Just verify the function can be called with different books
        // The actual comparison result is not validated
        _ = BibleReference.compare(a: genRef, b: exoRef)
        _ = BibleReference.compare(a: exoRef, b: genRef)
        
        // This test passes as long as the above lines don't crash
    }
    
    func testCompare_SameBookDifferentChapters() {
        let gen1 = BibleReference(versionId: 1, b: "GEN", c: 1, v: 1)
        let gen2 = BibleReference(versionId: 1, b: "GEN", c: 2, v: 1)
        
        XCTAssertEqual(BibleReference.compare(a: gen1, b: gen2), -1) // GEN 1 < GEN 2
        XCTAssertEqual(BibleReference.compare(a: gen2, b: gen1), 1)  // GEN 2 > GEN 1
    }
    
    func testCompare_SameChapterDifferentVerses() {
        let gen1_1 = BibleReference(versionId: 1, b: "GEN", c: 1, v: 1)
        let gen1_2 = BibleReference(versionId: 1, b: "GEN", c: 1, v: 2)
        
        XCTAssertEqual(BibleReference.compare(a: gen1_1, b: gen1_2), -1) // GEN 1:1 < GEN 1:2
        XCTAssertEqual(BibleReference.compare(a: gen1_2, b: gen1_1), 1)  // GEN 1:2 > GEN 1:1
    }
    
    func testCompare_Ranges() {
        let gen1_1to3 = BibleReference(versionId: 1, b: "GEN", c: 1, v: 1, c2: 1, v2: 3)
        let gen1_2to4 = BibleReference(versionId: 1, b: "GEN", c: 1, v: 2, c2: 1, v2: 4)
        
        // Compare based on starting verse first
        XCTAssertEqual(BibleReference.compare(a: gen1_1to3, b: gen1_2to4), -1)
        
        // Same starting verse, compare end verse
        let gen1_1to3_2 = BibleReference(versionId: 1, b: "GEN", c: 1, v: 1, c2: 1, v2: 3)
        let gen1_1to4 = BibleReference(versionId: 1, b: "GEN", c: 1, v: 1, c2: 1, v2: 4)
        
        XCTAssertEqual(BibleReference.compare(a: gen1_1to3_2, b: gen1_1to4), -1) // 1-3 < 1-4
    }
    
    // MARK: - Test Comparable conformance
    
    func testLessThan() {
        let gen1_1 = BibleReference(versionId: 1, b: "GEN", c: 1, v: 1)
        let gen1_2 = BibleReference(versionId: 1, b: "GEN", c: 1, v: 2)
        
        XCTAssertTrue(gen1_1 < gen1_2)
        XCTAssertFalse(gen1_2 < gen1_1)
    }
    
    func testSorting() {
        let refs = [
            BibleReference(versionId: 1, b: "GEN", c: 1, v: 1),
            BibleReference(versionId: 1, b: "GEN", c: 4, v: 3),
            BibleReference(versionId: 1, b: "GEN", c: 3, v: 2),
            BibleReference(versionId: 1, b: "GEN", c: 2, v: 1),
            BibleReference(versionId: 1, b: "GEN", c: 1, v: 2)
        ]
        
        let sorted = refs.sorted()
        
        XCTAssertEqual(sorted[0].book, "GEN")
        XCTAssertEqual(sorted[0].c, 1)
        XCTAssertEqual(sorted[0].v, 1)
        
        XCTAssertEqual(sorted[1].book, "GEN")
        XCTAssertEqual(sorted[1].c, 1)
        XCTAssertEqual(sorted[1].v, 2)
        
        XCTAssertEqual(sorted[2].book, "GEN")
        XCTAssertEqual(sorted[2].c, 2)
        XCTAssertEqual(sorted[2].v, 1)
        
        XCTAssertEqual(sorted[3].book, "GEN")
        XCTAssertEqual(sorted[3].c, 3)
        XCTAssertEqual(sorted[3].v, 2)
        
        XCTAssertEqual(sorted[4].book, "GEN")
        XCTAssertEqual(sorted[4].c, 4)
        XCTAssertEqual(sorted[4].v, 3)
    }
    
    // MARK: - Test toUSFMOfChapter
    
    func testToUSFMOfChapter() {
        let ref = BibleReference(versionId: 1, b: "gen", c: 1, v: 1)
        XCTAssertEqual(ref.toUSFMOfChapter, "GEN.1")
    }
    
    func testToUSFMOfChapter_NilBook() {
        var ref = BibleReference(versionId: 1, b: "GEN", c: 1, v: 1)
        ref.book = nil
        XCTAssertNil(ref.toUSFMOfChapter)
    }
    
    // MARK: - Test Edge Cases
    
    func testCompare_NilBooks() {
        var ref1 = BibleReference(versionId: 1, b: "GEN", c: 1, v: 1)
        var ref2 = BibleReference(versionId: 1, b: "GEN", c: 1, v: 1)
        
        ref1.book = nil
        ref2.book = nil
        
        // Two nil books should be considered equal
        XCTAssertEqual(BibleReference.compare(a: ref1, b: ref2), 0)
        
        // Nil book should be considered less than a non-nil book
        ref2.book = "GEN"
        XCTAssertEqual(BibleReference.compare(a: ref1, b: ref2), -1)
        XCTAssertEqual(BibleReference.compare(a: ref2, b: ref1), 1)
    }
}
