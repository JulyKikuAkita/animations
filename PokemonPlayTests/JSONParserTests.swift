//
//  JSONParserTests.swift
//  PokemonPlayTests
//
//  Created on 5/25/25.

import Foundation
@testable import PokemonPlay
import XCTest

final class JSONParserTests: XCTestCase {
    func testConvertSimpleDictionary() {
        let input: [String: Any] = [
            "name": "bulbasaur",
            "hp": 45,
            "is_legendary": false,
            "types": ["grass", "poison"],
        ]

        let jsonValue = convertToJSONValue(input)

        guard case let .object(dict) = jsonValue else {
            XCTFail("Expected object at top level")
            return
        }

        XCTAssertEqual(dict["name"], .string("bulbasaur"))
        XCTAssertEqual(dict["hp"], .number(45))
        XCTAssertEqual(dict["is_legendary"], .bool(false))

        if case let .array(types)? = dict["types"] {
            XCTAssertEqual(types.count, 2)
            XCTAssertEqual(types[0], .string("grass"))
        } else {
            XCTFail("Expected array for types")
        }
    }

    func testWrapAsDomainConfig() {
        let original = ["a": 1, "b": 2]
        let wrapped = wrapAsDomainConfig(name: "test", original: original)

        guard let domain = wrapped["domain"] as? [String: Any],
              let config = domain["config"] as? [String: Any],
              let testNode = config["test"] as? [String: Any]
        else {
            XCTFail("Failed to wrap structure")
            return
        }

        XCTAssertEqual(testNode["a"] as? Int, 1)
        XCTAssertEqual(testNode["b"] as? Int, 2)
    }
}
