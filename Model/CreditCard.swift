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

let creditCards: [CreditCard] = [
    .init(number: "1234", color: .purple),
    .init(number: "5678", color: .brown),
    .init(number: "0987", color: .blue),
    .init(number: "0756", color: .orange),
    .init(number: "3679", color: .black),
    .init(number: "4702", color: .cyan),
    .init(number: "7691", color: .pink),
]

struct PaymentType: Identifiable {
    var id: String = UUID().uuidString
    var cardBackground: String
    var title: String
    var cardCategory: CardCategory
    var cardType: CardType

    enum CardCategory: String {
        case debit = "DEBIT"
        case appleCash = "Apple Cash"
        case credit = "CREDIT"
    }

    enum CardType: String {
        case visa = "Visa"
        case masterCard = "Master Card"
        case amex = "Amex"
        case jcb = "JCB"
    }
}

let payments: [PaymentType] = [
    .init(cardBackground: "JCB", title: "Mars", cardCategory: .credit, cardType: .masterCard),
    .init(cardBackground: "Bitcoin", title: "Saturn", cardCategory: .credit, cardType: .amex),
    .init(cardBackground: "AI_pink", title: "Jupiter", cardCategory: .debit, cardType: .visa),
    .init(cardBackground: "AI_grn", title: "Nanachi", cardCategory: .appleCash, cardType: .jcb),
]
