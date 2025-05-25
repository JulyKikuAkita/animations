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
