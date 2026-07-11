//
//  MorphingRefreshView.swift
//  animation
//
//  Created on 7/11/26.

import SwiftUI

struct MorphingRefreshDemoView: View {
    var body: some View {
        List {
            DummyMessagesView()
        }
        .morphingRefreshable {
            try? await Task.sleep(for: .seconds(2))
        }
    }
}

#Preview {
    MorphingRefreshDemoView()
}
