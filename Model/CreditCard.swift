//
//  CreditCard.swift
//  animation

import SwiftUI

struct CreditCard: Identifiable {
    var id: UUID = .init()
    var number: String
    var name: String = "Nanachi"
    var date: String = "12/24"
    var color: Color
}

var creditCards: [CreditCard] = [
    .init(number: "1234", color: .purple),
    .init(number: "5678", color: .brown),
    .init(number: "0987", color: .blue),
    .init(number: "0756", color: .orange),
    .init(number: "3679", color: .black),
    .init(number: "4702", color: .cyan),
    .init(number: "7691", color: .pink)
]
