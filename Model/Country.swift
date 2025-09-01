//
//  Card.swift
//  animation
// decode CountrCodes.json file
import SwiftUI

struct Country: Identifiable, Hashable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var dialCode: String
    var code: String

    enum CodingKeys: String, CodingKey {
        case name
        case dialCode = "dial_code"
        case code
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        code = try container.decode(String.self, forKey: .code)
        dialCode = try container.decodeIfPresent(String.self, forKey: .dialCode) ?? ""
    }

    static func getCountries() -> [Self] {
        guard let path = Bundle.main.path(forResource: "CountryCodes", ofType: "json") else {
            debugPrint("JSON file not found in bundle")
            return []
        }
        let url = URL(filePath: path)
        do {
            let jsonData = try Data(contentsOf: url)
            let countries = try JSONDecoder().decode([Country].self, from: jsonData)
            return countries
        } catch {
            debugPrint("Failed to decode CountryCodes.json:", error)
            return []
        }
    }
}
