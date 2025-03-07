//
//  DynamicFloatingSheetsiOS18View.swift
//  animation

import SwiftUI

struct DynamicFloatingSheetsiOS18ViewDemo: View {
    /// View Properties
    @State private var show: Bool = false

    var body: some View {
        Button("Show Style1") {
            show.toggle()
        }
        .systemTrayView($show) {
            Text("Drag me up")
                .frame(maxWidth: .infinity)
                .frame(height: 300)
        }
    }
}

#Preview {
    DynamicFloatingSheetsiOS18ViewDemo()
}
