//
//  ToastViewDemoView.swift
//  animation
//
//  Created on 1/21/26.

import SwiftUI

@available(iOS 26.0, *)
struct ToastDemoView: View {
    @State private var showToast1: Bool = false
    @State private var showToast2: Bool = false
    var body: some View {
        NavigationStack {
            List {
                Button("Show Toast1") {
                    showToast1.toggle()
                }
                .dynamicIslandToast(isPresented: $showToast1, value: .example1)

                Button("Show Toast2") {
                    showToast2.toggle()
                }
                .dynamicIslandToast(isPresented: $showToast2, value: .example2)
            }
            .navigationTitle("Dynamic Island Toast")
        }
    }
}

#Preview {
    if #available(iOS 26.0, *) {
        ToastDemoView()
    } else {
        // Fallback on earlier versions
    }
}
