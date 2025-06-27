import Foundation

struct BibleTextAndHTML: Decodable {
    let text: String?
    let html: String?
}

struct BiblePublisher: Decodable {
    let id: Int?
    let name: String?
    let description: String?
    let url: String?
}

struct BibleBookChapter: Decodable {
    let isCanonical: Bool?
    let human: String?
    
    enum CodingKeys: String, CodingKey {
        case human
        case isCanonical = "canonical"
    }
}

struct BibleBook: Decodable {
    let usfm: String?
    let abbreviation: String?
    let human: String?
    let humanLong: String?
    let chapters: [BibleBookChapter]?
    
    enum CodingKeys: String, CodingKey {
        case usfm, abbreviation, human, chapters
        case humanLong = "human_long"
    }
}

struct BibleBuild: Decodable {
    let min: Int?
    let max: Int?
}

struct BibleLanguage: Decodable {
    let localName: String?
    let name: String?
    //let language_tag: String?
    //let iso_639_1: String?
    //let iso_639_3: String?
    let textDirection: String?
    
    enum CodingKeys: String, CodingKey {
        case localName = "local_name"
        case name
        case textDirection = "text_direction"
    }
}

struct BibleOffline: Decodable {
    let build: BibleBuild?
}

struct BibleVersionData: Decodable {
    let id: Int?
    let localizedTitle: String?
    let localizedAbbreviation: String?
    let abbreviation: String?
    let language: BibleLanguage?
    let offline: BibleOffline?
    let readerFooter: BibleTextAndHTML?
    let readerFooterUrl: String?
    let copyrightShort: BibleTextAndHTML?
    let copyrightLong: BibleTextAndHTML?
    let books: [BibleBook]
    
    enum CodingKeys: String, CodingKey {
        case id
        case localizedTitle = "local_title"
        case localizedAbbreviation = "local_abbreviation"
        case abbreviation
        case language
        case offline
        case readerFooter = "reader_footer"
        case readerFooterUrl = "reader_footer_url"
        case copyrightShort = "copyright_short"
        case copyrightLong = "copyright_long"
        case books
    }
}

struct BibleVersionResponse: Decodable {
    let data: BibleVersionData
}

struct BibleVersionObject: Decodable {
  let response: BibleVersionResponse
}
