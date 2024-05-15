//
//  View+Extension.swift
//  MyMint

import SwiftUI

extension View {
    @ViewBuilder
    func hSpacing(_ alignment: Alignment = .center) -> some View {
        self
            .frame(maxWidth: .infinity, alignment: alignment)
    }
    
    @ViewBuilder
    func vSpacing(_ alignment: Alignment = .center) -> some View {
        self
            .frame(maxHeight: .infinity, alignment: alignment)
    }
    
    var safeArea: UIEdgeInsets {
        if let windowScene = (UIApplication.shared.connectedScenes.first as? UIWindowScene) {
            return windowScene.keyWindow?.safeAreaInsets ?? .zero
        }
        return .zero
    }
    
    func format(data: Date, format: String) -> String {
        return ""
        // https://www.youtube.com/watch?v=TXJF8fkOp4c&list=PLimqJDzPI-H88PbxlOtNPkD0n0n-q-__z&index=3
        //   10:19
    }
}
