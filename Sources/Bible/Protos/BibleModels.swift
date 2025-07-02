import Foundation

public struct BibleTextAndHTML: Decodable, Sendable {
    public let text: String?
    public let html: String?
}

public struct BiblePublisher: Decodable, Sendable {
    public let id: Int?
    public let name: String?
    public let description: String?
    public let url: String?
}

public struct BibleBookChapter: Decodable, Sendable {
    public let isCanonical: Bool?
    public let human: String?
    
    enum CodingKeys: String, CodingKey {
        case human
        case isCanonical = "canonical"
    }
}

public struct BibleBook: Decodable, Sendable {
    public let usfm: String?
    public let abbreviation: String?
    public let human: String?
    public let humanLong: String?
    public let chapters: [BibleBookChapter]?
    
    enum CodingKeys: String, CodingKey {
        case usfm, abbreviation, human, chapters
        case humanLong = "human_long"
    }
}

public struct BibleBuild: Decodable, Sendable {
    public let min: Int?
    public let max: Int?
}

public struct BibleLanguage: Decodable, Sendable {
    public let localName: String?
    public let name: String?
    public let textDirection: String?
    
    enum CodingKeys: String, CodingKey {
        case localName = "local_name"
        case name
        case textDirection = "text_direction"
    }
}

public struct BibleOffline: Decodable, Sendable {
    public let build: BibleBuild?
}

public struct BibleVersion: Decodable, Sendable {
    public let id: Int
    public let localizedTitle: String?
    public let localizedAbbreviation: String?
    public let abbreviation: String?
    public let language: BibleLanguage?
    public let offline: BibleOffline?
    public let readerFooter: BibleTextAndHTML?
    public let readerFooterUrl: String?
    public let copyrightShort: BibleTextAndHTML?
    public let copyrightLong: BibleTextAndHTML?
    public let books: [BibleBook]
    
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
    let data: BibleVersion
}

struct BibleVersionObject: Decodable {
  let response: BibleVersionResponse
}
