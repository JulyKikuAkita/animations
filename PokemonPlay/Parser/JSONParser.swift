//
//  JSONParser.swift
//  PokemonPlay
//
//  Created on 5/25/25.

import Foundation

func convertToJSONValue(_ any: Any) -> JSONValue {
    switch any {
    case let str as String: return .string(str)
    case let num as NSNumber:
        if CFGetTypeID(num) == CFBooleanGetTypeID() {
            return .bool(num.boolValue)
        } else {
            return .number(num.doubleValue)
        }
    case let dict as [String: Any]:
        let mapped = dict.mapValues { convertToJSONValue($0) }
        return .object(mapped)
    case let array as [Any]:
        return .array(array.map { convertToJSONValue($0) })
    default:
        return .null
    }
}

// Use decoder
func decodePokemon<T: Decodable>(_: T.Type, from node: JSONNode) -> T? {
    guard case let .object(dict) = node.value else { return nil }

    let anyValue = dict.mapValues { $0.rawValue() }

    guard JSONSerialization.isValidJSONObject(anyValue),
          let data = try? JSONSerialization.data(withJSONObject: anyValue)
    else {
        return nil
    }

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase // swift use Camel but raw json is snake cae

    return try? decoder.decode(T.self, from: data)
}
