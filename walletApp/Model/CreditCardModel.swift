//
//  CreditCardModel.swift
//  walletApp

import SwiftUI

struct CreditCardModel: Identifiable {
    var id: String = UUID().uuidString
    var number: String
    var expires: String
    var color: Color
    
    /// Custom Matched Geometry IDs
    var jcbGeometryID: String {
        "JCB_\(id)"
    }
}

var cards: [CreditCardModel] = [
    .init(number: "**** **** **** 1234", expires: "11/27", color: .purple),
    .init(number: "**** **** **** 5678", expires: "08/25", color: .brown),
    .init(number: "**** **** **** 3679", expires: "02/29", color: .orange),
    .init(number: "**** **** **** 7691", expires: "01/30", color: .cyan),
]
