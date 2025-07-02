import Foundation
import Testing
@testable import YouVersionPlatform

struct BibleVersionTests {
    
    static let version: BibleVersion = {
        let obj: BibleVersionObject = try! FixtureLoader().decodeFixture(filename: "bible_206")
        return obj.response.data
    }()
    
    @Test
    func deserialization() {
        #expect(BibleVersionTests.version.id == 206)
        #expect(BibleVersionTests.version.abbreviation == "engWEBUS")
        #expect(BibleVersionTests.version.localizedTitle == "World English Bible, American English Edition, without Strong's Numbers")
        #expect(BibleVersionTests.version.copyrightShort?.text == "PUBLIC DOMAIN (not copyrighted)")
    }
    
    @Test(arguments: [
        ("GEN", true),
        ("gen", true),
        ("jHn", true),
        ("jhn", true),
        ("rev", true),
        ("GAN", false),
        ("REEV", false),
        ("R", false)
    ])
    func bookUSFMValidation(usfm: String, isValid: Bool) {
        #expect(BibleVersionTests.version.isBookUSFMValid(usfm) == isValid)
    }
    
    @Test
    func bookLookup() throws {
        let book = try #require(BibleVersionTests.version.book(with: "GEN"))
        #expect(book.human == "Genesis")
    }
    
    @Test(arguments: [
        ("GEN", 50),
        ("PSA", 150),
        ("REV", 22)
    ])
    func numberOfChapters(bookUSFM: String, expectedNumber: Int) throws {
        let actual = BibleVersionTests.version.numberOfChaptersInBook(bookUSFM)
        #expect(actual == expectedNumber)
    }
}
