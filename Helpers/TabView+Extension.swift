//
//  TabView+Extension.swift
//  animation

import SwiftUI
extension TabView {
    @ViewBuilder
    func tabSheet<SheetContent: View>(initialHeight: CGFloat = 100, sheetCornerRadius: CGFloat = 15, @ViewBuilder content: @escaping () -> SheetContent) -> some View {
        self
            .modifier(
                BottomSheetModifier(
                    initialHeight: initialHeight,
                    sheetCornerRadius: sheetCornerRadius,
                    sheetView: content()
                )
            )
    }
}

/// Helper View modifier
fileprivate struct BottomSheetModifier<SheetContent: View>: ViewModifier {
    var initialHeight: CGFloat
    var sheetCornerRadius: CGFloat
    var sheetView: SheetContent
    /// View Properties
    @State private var showSheet: Bool = true
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showSheet, content: {
                sheetView
                    .presentationDetents([.height(initialHeight), .medium, .large])
                    .presentationCornerRadius(sheetCornerRadius)
                    .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                    .interactiveDismissDisabled()
            })
    }
}
