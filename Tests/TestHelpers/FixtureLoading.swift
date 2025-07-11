
import Foundation

final class FixtureLoader: FixtureLoading {}

enum FixtureLoadingError: Error {
    case missingFile
    case decodingError
}

protocol FixtureLoading {}
extension FixtureLoading {

    func loadFixtureData(_ filename: String) throws -> Data {
        // Construct the URL for the fixtures directory.
        let bundle = Bundle.module
        guard let url = bundle.url(forResource: filename, withExtension: "json") else {
            throw FixtureLoadingError.missingFile
        }
        // Load the data from the file.
        return try Data(contentsOf: url)
    }

    func loadFixtureString(_ filename: String) throws -> String? {
        let data = try loadFixtureData(filename)

        guard let originalString = String(data: data, encoding: .utf8) else {
            throw FixtureLoadingError.decodingError
        }

        let trimmedString = originalString.filter { !"\n\t\r".contains($0) }
        return trimmedString
    }

    func decodeFixture<T: Decodable>(filename: String) throws -> T {
        let data = try loadFixtureData(filename)
        return try JSONDecoder().decode(T.self, from: data)
    }

}
