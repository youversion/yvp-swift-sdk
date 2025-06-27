import XCTest
@testable import YouVersionPlatform

final class BibleReferenceTests: XCTestCase {
    
    // MARK: - Test Initialization
    
    func testInitSingleVerse() {
        let ref = BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 1, verse: 1)
        
        XCTAssertEqual(ref.versionId, 1)
        XCTAssertEqual(ref.bookUSFM, "GEN")
        XCTAssertEqual(ref.chapterStart, 1)
        XCTAssertEqual(ref.chapterEnd, 1) // chapterEnd should be same as chapterStart for single verse
        XCTAssertEqual(ref.verseStart, 1)
        XCTAssertEqual(ref.verseEnd, 1) // verseEnd should be same as verseStart for single verse
    }
    
    func testInitVerseRange() {
        let ref = BibleReference(versionId: 1, bookUSFM: "PSA", chapterStart: 23, verseStart: 1, chapterEnd: 24, verseEnd: 2)
        
        XCTAssertEqual(ref.versionId, 1)
        XCTAssertEqual(ref.bookUSFM, "PSA")
        XCTAssertEqual(ref.chapterStart, 23)
        XCTAssertEqual(ref.chapterEnd, 24)
        XCTAssertEqual(ref.verseStart, 1)
        XCTAssertEqual(ref.verseEnd, 2)
    }
    
    // MARK: - Test isRange
    
    func testIsRange_SingleVerse() {
        let ref = BibleReference(versionId: 1, bookUSFM: "EXO", chapter: 3, verse: 14)
        XCTAssertFalse(ref.isRange)
    }
    
    func testIsRange_VerseRange() {
        let ref = BibleReference(versionId: 1, bookUSFM: "EXO", chapterStart: 3, verseStart: 14, chapterEnd: 3, verseEnd: 15)
        XCTAssertTrue(ref.isRange)
    }
    
    func testIsRange_ChapterRange() {
        let ref = BibleReference(versionId: 1, bookUSFM: "EXO", chapterStart: 3, verseStart: 1, chapterEnd: 4, verseEnd: 1)
        XCTAssertTrue(ref.isRange)
    }
    
    // MARK: - Test compare function
    
    func testCompare_SameReference() {
        let ref1 = BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 1, verse: 1)
        let ref2 = BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 1, verse: 1)
        
        XCTAssertEqual(BibleReference.compare(a: ref1, b: ref2), 0)
    }
    
    func testCompare_DifferentBooks() {
        // Note: Comparing different books is not reliable without knowing the canonical book order
        // This test just verifies the function doesn't crash with different book codes
        let genRef = BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 1, verse: 1)
        let exoRef = BibleReference(versionId: 1, bookUSFM: "EXO", chapter: 1, verse: 1)
        
        // Just verify the function can be called with different books
        // The actual comparison result is not validated
        _ = BibleReference.compare(a: genRef, b: exoRef)
        _ = BibleReference.compare(a: exoRef, b: genRef)
        
        // This test passes as long as the above lines don't crash
    }
    
    func testCompare_SameBookDifferentChapters() {
        let gen1 = BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 1, verse: 1)
        let gen2 = BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 2, verse: 1)
        
        XCTAssertEqual(BibleReference.compare(a: gen1, b: gen2), -1) // GEN 1 < GEN 2
        XCTAssertEqual(BibleReference.compare(a: gen2, b: gen1), 1)  // GEN 2 > GEN 1
    }
    
    func testCompare_SameChapterDifferentVerses() {
        let gen1_1 = BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 1, verse: 1)
        let gen1_2 = BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 1, verse: 2)
        
        XCTAssertEqual(BibleReference.compare(a: gen1_1, b: gen1_2), -1) // GEN 1:1 < GEN 1:2
        XCTAssertEqual(BibleReference.compare(a: gen1_2, b: gen1_1), 1)  // GEN 1:2 > GEN 1:1
    }
    
    func testCompare_Ranges() {
        let gen1_1to3 = BibleReference(versionId: 1, bookUSFM: "GEN", chapterStart: 1, verseStart: 1, chapterEnd: 1, verseEnd: 3)
        let gen1_2to4 = BibleReference(versionId: 1, bookUSFM: "GEN", chapterStart: 1, verseStart: 2, chapterEnd: 1, verseEnd: 4)
        
        // Compare based on starting verse first
        XCTAssertEqual(BibleReference.compare(a: gen1_1to3, b: gen1_2to4), -1)
        
        // Same starting verse, compare end verse
        let gen1_1to3_2 = BibleReference(versionId: 1, bookUSFM: "GEN", chapterStart: 1, verseStart: 1, chapterEnd: 1, verseEnd: 3)
        let gen1_1to4 = BibleReference(versionId: 1, bookUSFM: "GEN", chapterStart: 1, verseStart: 1, chapterEnd: 1, verseEnd: 4)
        
        XCTAssertEqual(BibleReference.compare(a: gen1_1to3_2, b: gen1_1to4), -1) // 1-3 < 1-4
    }
    
    // MARK: - Test Comparable conformance
    
    func testLessThan() {
        let gen1_1 = BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 1, verse: 1)
        let gen1_2 = BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 1, verse: 2)
        
        XCTAssertTrue(gen1_1 < gen1_2)
        XCTAssertFalse(gen1_2 < gen1_1)
    }
    
    func testSorting() {
        let refs = [
            BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 1, verse: 1),
            BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 4, verse: 3),
            BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 3, verse: 2),
            BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 2, verse: 1),
            BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 1, verse: 2)
        ]
        
        let sorted = refs.sorted()
        
        XCTAssertEqual(sorted[0].bookUSFM, "GEN")
        XCTAssertEqual(sorted[0].chapterStart, 1)
        XCTAssertEqual(sorted[0].verseStart, 1)
        
        XCTAssertEqual(sorted[1].bookUSFM, "GEN")
        XCTAssertEqual(sorted[1].chapterStart, 1)
        XCTAssertEqual(sorted[1].verseStart, 2)
        
        XCTAssertEqual(sorted[2].bookUSFM, "GEN")
        XCTAssertEqual(sorted[2].chapterStart, 2)
        XCTAssertEqual(sorted[2].verseStart, 1)
        
        XCTAssertEqual(sorted[3].bookUSFM, "GEN")
        XCTAssertEqual(sorted[3].chapterStart, 3)
        XCTAssertEqual(sorted[3].verseStart, 2)
        
        XCTAssertEqual(sorted[4].bookUSFM, "GEN")
        XCTAssertEqual(sorted[4].chapterStart, 4)
        XCTAssertEqual(sorted[4].verseStart, 3)
    }
    
    // MARK: - Test chapterUSFM
    
    func testChapterUSFM() {
        let ref = BibleReference(versionId: 1, bookUSFM: "gen", chapter: 1, verse: 1)
        XCTAssertEqual(ref.chapterUSFM, "GEN.1")
    }
    
    func testChapterUSFM_NilBook() {
        var ref = BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 1, verse: 1)
        ref.bookUSFM = nil
        XCTAssertNil(ref.chapterUSFM)
    }
    
    // MARK: - Test Edge Cases
    
    func testCompare_NilBooks() {
        var ref1 = BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 1, verse: 1)
        var ref2 = BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 1, verse: 1)
        
        ref1.bookUSFM = nil
        ref2.bookUSFM = nil
        
        // Two nil books should be considered equal
        XCTAssertEqual(BibleReference.compare(a: ref1, b: ref2), 0)
        
        // Nil book should be considered less than a non-nil book
        ref2.bookUSFM = "GEN"
        XCTAssertEqual(BibleReference.compare(a: ref1, b: ref2), -1)
        XCTAssertEqual(BibleReference.compare(a: ref2, b: ref1), 1)
    }
}
