//
//  TabView+Extension.swift
//  animation

import SwiftUI

// Custom TabView modifier
extension TabView {
    @ViewBuilder
    func tabSheet(initialHeight: CGFloat = 100, sheetCornerRadius: CGFloat = 15, @ViewBuilder content: @escaping () -> some View) -> some View {
        modifier(
            BottomSheetModifier(
                initialHeight: initialHeight,
                sheetCornerRadius: sheetCornerRadius,
                sheetView: content()
            )
        )
    }
}

/// Helper View modifier
private struct BottomSheetModifier<SheetContent: View>: ViewModifier {
    var initialHeight: CGFloat
    var sheetCornerRadius: CGFloat
    var sheetView: SheetContent
    /// View Properties
    @State private var showSheet: Bool = true
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showSheet, content: {
                VStack(spacing: 0) {
                    sheetView
                        .background(.regularMaterial)
                        .zIndex(0)

                    Divider()
                        .hidden()

                    Rectangle()
                        .fill(.clear)
                        .frame(height: 55) // tab bar height
                }
                .presentationDetents([.height(initialHeight), .medium, .fraction(0.99)]) // if use .large,instead of .fraction root view will scale
                .presentationCornerRadius(sheetCornerRadius)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                .presentationBackground(.clear)
                .interactiveDismissDisabled()
            })
    }
}
