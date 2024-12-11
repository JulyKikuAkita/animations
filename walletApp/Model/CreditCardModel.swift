//
//  CreditCardModel.swift
//  walletApp

import SwiftUI

struct CreditCardModel: Identifiable, Hashable {
    var id: String = UUID().uuidString
    var name: String = ""
    var secretNumber: String
    var cvv: String = ""
    var month: String
    var year: String
    var color: Color
    
    var number: String {
        String(secretNumber.group(" ", count: 4).prefix(19))
    }
    
    var rawCardNumber: String {
        secretNumber.replacingOccurrences(of: " ", with: "")
    }
    
    var expires: String {
        "\(month)/\(year)"
    }
    
    /// Custom Matched Geometry IDs
    var jcbGeometryID: String {
        "JCB_\(id)"
    }
}

var cards: [CreditCardModel] = [
    .init(secretNumber: "1234123412341234", month: "11", year: "27", color: .black),
    .init(secretNumber: "5678123456785678", month: "08", year: "25", color: .brown),
    .init(secretNumber: "1234123412343679", month: "02", year: "29", color: .purple),
    .init(secretNumber: "1234123412347691", month: "10", year: "30", color: .cyan),
]
