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
    //var toc: Bool?
    var canonical: Bool?
    var human: String?
    //var usfm: String?
}

struct BibleBook: Decodable {
    //var text: Bool?
    //var audio: Bool?
    //var canon: String?
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
    //var secondary_language_tags: [String]?
}

struct BibleOffline: Decodable {
    //var require_email_agreement: Bool?
    //var agreement_version: Int?
    //var always_allow_updates: Bool?
    //var allow_redownload: Bool?
    //var url: String?
    //var platforms: ApiPlatforms?
    var build: BibleBuild?
    //var audio: Bool?
}

struct BibleVersionData: Decodable {
    var id: Int?
    //var audio: Bool?
    //var text: Bool?
    var local_title: String?
    //var title: String?
    var local_abbreviation: String?
    var abbreviation: String?
    var language: BibleLanguage?
    //var publisher: BiblePublisher?
    var offline: BibleOffline?
    var reader_footer: BibleTextAndHTML?
    var reader_footer_url: String?
    //var metadata_build: Int
    var copyright_short: BibleTextAndHTML?
    var copyright_long: BibleTextAndHTML?
    //ApiPlatforms platforms = 16;
    var books: [BibleBook]
    //var audio_count: Int?
    //var vrs: String?
}

struct BibleVersionResponse: Decodable {
    var data: BibleVersionData
}

struct BibleVersionObject: Decodable {
  var response: BibleVersionResponse
}
