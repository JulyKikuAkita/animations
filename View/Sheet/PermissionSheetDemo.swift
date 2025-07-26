//
//  PermissionSheetDemo.swift
//  animation
//
//  Created on 7/25/25.

import SwiftUI

struct PermissionSheetDemo: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

extension View {
    func permisisonSheet(_ permission: [Permission]) -> some View {
        modifier(PermissionSheetViewModifier(permission: permission))
    }
}

private struct PermissionSheetViewModifier: ViewModifier {
    init(permission _: [Permission]) {}

    func body(content: Content) -> some View {
        content
    }
}

#Preview {
    PermissionSheetDemo()
}
