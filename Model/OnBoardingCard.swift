//
//  OnBoardingCard.swift
//  animation
//
//  Created on 7/8/25.

import SwiftUI

struct OnBoardingCard: Identifiable {
    var id: String = UUID().uuidString
    var symbol: String
    var title: String
    var subTitle: String
}
