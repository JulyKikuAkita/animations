//
//  JSONValue.swift
//  PokemonPlay

import Foundation

enum JSONValue: Identifiable, Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case null
    case array([JSONValue])
    case object([String: JSONValue])

    var id: UUID { UUID() }

    var children: [JSONNode]? {
        switch self {
        case let .array(values):
            values.enumerated().map { index, value in
                JSONNode(key: "[\(index)]", value: value)
            }
        case let .object(dict):
            dict.map { key, value in
                JSONNode(key: key, value: value)
            }
        default:
            nil
        }
    }

    var display: String {
        switch self {
        case let .string(val): "\"\(val)\""
        case let .number(val): String(val)
        case let .bool(val): String(val)
        case .null: "null"
        case .array: "[...]"
        case .object: "{...}"
        }
    }

    // equatable conformance
//    static func == (lhs: JSONValue, rhs: JSONValue) -> Bool {
//        switch (lhs, rhs) {
//        case let (.string(l), .string(r)): l == r
//        case let (.number(l), .number(r)): l == r
//        case let (.bool(l), .bool(r)): l == r
//        case (.null, .null): true
//        case let (.array(l), .array(r)): l == r
//        case let (.object(l), .object(r)): l == r
//        default: false
//        }
//    }
}

struct JSONNode: Identifiable {
    let id = UUID()
    let key: String
    let value: JSONValue
}

/// for codable
extension JSONValue {
    func rawValue() -> Any {
        switch self {
        case let .string(str): str
        case let .number(num): num
        case let .bool(bool): bool
        case .null: NSNull()
        case let .array(arr): arr.map { $0.rawValue() }
        case let .object(dict): dict.mapValues { $0.rawValue() }
        }
    }
}
