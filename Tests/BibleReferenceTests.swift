@testable import YouVersionPlatform
import Testing

// MARK: - Test Initialization

@Test
func testInitSingleVerse() {
    let ref = BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 1, verse: 1)
    
    #expect(ref.versionId == 1)
    #expect(ref.bookUSFM == "GEN")
    #expect(ref.chapterStart == 1)
    #expect(ref.chapterEnd == 1) // chapterEnd should be same as chapterStart for single verse
    #expect(ref.verseStart == 1)
    #expect(ref.verseEnd == 1) // verseEnd should be same as verseStart for single verse
}

@Test
func testInitVerseRange() {
    let ref = BibleReference(versionId: 1, bookUSFM: "PSA", chapterStart: 23, verseStart: 1, chapterEnd: 24, verseEnd: 2)
    
    #expect(ref.versionId == 1)
    #expect(ref.bookUSFM == "PSA")
    #expect(ref.chapterStart == 23)
    #expect(ref.chapterEnd == 24)
    #expect(ref.verseStart == 1)
    #expect(ref.verseEnd == 2)
}

// MARK: - Test isRange

@Test
func testIsRange_SingleVerse() {
    let ref = BibleReference(versionId: 1, bookUSFM: "EXO", chapter: 3, verse: 14)
    #expect(!ref.isRange)
}

@Test
func testIsRange_VerseRange() {
    let ref = BibleReference(versionId: 1, bookUSFM: "EXO", chapterStart: 3, verseStart: 14, chapterEnd: 3, verseEnd: 15)
    #expect(ref.isRange)
}

@Test
func testIsRange_ChapterRange() {
    let ref = BibleReference(versionId: 1, bookUSFM: "EXO", chapterStart: 3, verseStart: 1, chapterEnd: 4, verseEnd: 1)
    #expect(ref.isRange)
}

// MARK: - Test compare function

@Test
func testCompare_SameReference() {
    let ref1 = BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 1, verse: 1)
    let ref2 = BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 1, verse: 1)
    
    #expect(ref1 == ref2)
}

@Test
func testCompare_DifferentBooks() {
    // Note: Comparing different books is not reliable without knowing the canonical book order
    // This test just verifies the function doesn't crash with different book usfms
    let genRef = BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 1, verse: 1)
    let exoRef = BibleReference(versionId: 1, bookUSFM: "EXO", chapter: 1, verse: 1)
    
    // Just verify the function can be called with different books
    // The actual comparison result is not validated
    _ = BibleReference.compare(a: genRef, b: exoRef)
    _ = BibleReference.compare(a: exoRef, b: genRef)
    
    // This test passes as long as the above lines don't crash
}

@Test
func testCompare_SameBookDifferentChapters() {
    let gen1 = BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 1, verse: 1)
    let gen2 = BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 2, verse: 1)
    
    #expect(gen1 < gen2)
    #expect(BibleReference.compare(a: gen1, b: gen2) == -1) // GEN 1 < GEN 2
    #expect(BibleReference.compare(a: gen2, b: gen1) == 1)  // GEN 2 > GEN 1
}

@Test
func testCompare_SameChapterDifferentVerses() {
    let gen1_1 = BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 1, verse: 1)
    let gen1_2 = BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 1, verse: 2)
    
    #expect(gen1_1 < gen1_2)
    #expect(gen1_2 > gen1_1)
}

@Test
func testCompare_Ranges() {
    let gen1_1to3 = BibleReference(versionId: 1, bookUSFM: "GEN", chapterStart: 1, verseStart: 1, chapterEnd: 1, verseEnd: 3)
    let gen1_2to4 = BibleReference(versionId: 1, bookUSFM: "GEN", chapterStart: 1, verseStart: 2, chapterEnd: 1, verseEnd: 4)
    
    // Compare based on starting verse first
    #expect(gen1_1to3 < gen1_2to4)
    
    // Same starting verse, compare end verse
    let gen1_1to3_2 = BibleReference(versionId: 1, bookUSFM: "GEN", chapterStart: 1, verseStart: 1, chapterEnd: 1, verseEnd: 3)
    let gen1_1to4 = BibleReference(versionId: 1, bookUSFM: "GEN", chapterStart: 1, verseStart: 1, chapterEnd: 1, verseEnd: 4)
    
    #expect(gen1_1to3_2 < gen1_1to4)    // 1-3 < 1-4
}

@Test
func testSorting() {
    let refs = [
        BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 1, verse: 1),
        BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 4, verse: 3),
        BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 3, verse: 2),
        BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 2, verse: 1),
        BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 1, verse: 2)
    ]
    
    let sorted = refs.sorted()
    
    #expect(sorted[0].bookUSFM == "GEN")
    #expect(sorted[0].chapterStart == 1)
    #expect(sorted[0].verseStart == 1)
    
    #expect(sorted[1].bookUSFM == "GEN")
    #expect(sorted[1].chapterStart == 1)
    #expect(sorted[1].verseStart == 2)
    
    #expect(sorted[2].bookUSFM == "GEN")
    #expect(sorted[2].chapterStart == 2)
    #expect(sorted[2].verseStart == 1)
    
    #expect(sorted[3].bookUSFM == "GEN")
    #expect(sorted[3].chapterStart == 3)
    #expect(sorted[3].verseStart == 2)
    
    #expect(sorted[4].bookUSFM == "GEN")
    #expect(sorted[4].chapterStart == 4)
    #expect(sorted[4].verseStart == 3)
}

// MARK: - Test chapterUSFM

@Test
func testChapterUSFM() {
    let ref = BibleReference(versionId: 1, bookUSFM: "gen", chapter: 1, verse: 1)
    #expect(ref.chapterUSFM == "GEN.1")
}

@Test
func testChapterUSFM_NilBook() {
    var ref = BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 1, verse: 1)
    ref.bookUSFM = nil
    #expect(ref.chapterUSFM == nil)
}

// MARK: - Test Edge Cases

@Test
func testCompare_NilBooks() {
    var ref1 = BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 1, verse: 1)
    var ref2 = BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 1, verse: 1)
    
    ref1.bookUSFM = nil
    ref2.bookUSFM = nil
    
    // Two nil books should be considered equal
    #expect(ref1 == ref2)
    
    // Nil book should be considered less than a non-nil book
    ref2.bookUSFM = "GEN"
    #expect(ref2 > ref1)
}
