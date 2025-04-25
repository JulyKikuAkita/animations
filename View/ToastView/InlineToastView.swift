//
//  InlineToastView.swift
//  animation
//

import SwiftUI

extension View {
    func inlineToast(
        config: InlineToastConfig,
        isPresented _: Bool
    ) -> some View {
        VStack(spacing: 10) {
            if config.anchor == .bottom {
                self.compositingGroup()
            }

            if config.anchor == .top {
                self.compositingGroup()
            }
        }
    }
}

struct InlineToastConfig {
    var icon: String
    var title: String
    var subtitle: String
    var tint: Color
    var anchor: InlineToastAnchor = .top
    var actionIcon: String
    var actionHandler: () -> Void = {}

    enum InlineToastAnchor {
        case top, bottom
    }
}

struct InlineToastView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    InlineToastView()
}
