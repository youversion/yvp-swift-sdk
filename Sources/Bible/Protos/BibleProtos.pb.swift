import Foundation

struct BibleTextAndHTML: Decodable {
    var text: String?
    var html: String?
}

struct BiblePublisher: Decodable {
    var id: Int?
    var name: String?
    var description: String?
    var url: String?
}

struct BibleBookChapter: Decodable {
    var canonical: Bool?
    var human: String?
}

struct BibleBook: Decodable {
    var usfm: String?
    var abbreviation: String?
    var human: String?
    var human_long: String?
    var chapters: [BibleBookChapter]?
}

struct BibleBuild: Decodable {
    var min: Int?
    var max: Int?
}

struct BibleLanguage: Decodable {
    var local_name: String?
    var name: String?
    //var language_tag: String?
    //var iso_639_1: String?
    //var iso_639_3: String?
    var text_direction: String?
}

struct BibleOffline: Decodable {
    var build: BibleBuild?
}

struct BibleVersionData: Decodable {
    var id: Int?
    var local_title: String?
    var local_abbreviation: String?
    var abbreviation: String?
    var language: BibleLanguage?
    var offline: BibleOffline?
    var reader_footer: BibleTextAndHTML?
    var reader_footer_url: String?
    var copyright_short: BibleTextAndHTML?
    var copyright_long: BibleTextAndHTML?
    var books: [BibleBook]
    //var vrs: String?
}

struct BibleVersionResponse: Decodable {
    var data: BibleVersionData
}

struct BibleVersionObject: Decodable {
  var response: BibleVersionResponse
}
