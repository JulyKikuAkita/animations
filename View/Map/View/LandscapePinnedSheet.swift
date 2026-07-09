//
//  LandscapePinnedSheet.swift
//  animation
//
//  Created on 7/8/26.
//  Standalone demo (not wired into the app's demo browser; preview-only).
//
//  Learning point
//  ──────────────
//  Apple-Maps-style sheet that stays pinned as a floating card on the
//  leading edge on wide screens (landscape iPad / large iPhone), but
//  behaves as a normal full-width bottom sheet on compact screens.
//  Pairs with `adaptiveSheet(_:isActive:)` in View+Sheet.swift, which
//  does the UIKit-level width pinning.
//
//  Why `onGeometryChange` instead of `horizontalSizeClass`
//  ───────────────────────────────────────────────────────
//  `horizontalSizeClass` is too coarse — an iPad in landscape and a
//  Split-View pane can report the same class, and a large iPhone in
//  landscape stays `.compact`. Measuring the actual container width
//  (`> 600`) reflects the real space available, so the layout tracks
//  window resizing / multitasking rather than device idiom.
//
//  Detent choreography
//  ───────────────────
//  On the size crossover the `action:` closure re-picks the selected
//  detent so the sheet lands in a sensible position for the new width
//  instead of snapping to whatever fraction was valid before. The
//  detent *set* itself also swaps (see `SheetView.detents`) because a
//  0.45 fraction reads well full-width but not as a narrow card.
//
//  Key APIs
//  ────────
//  • `.onGeometryChange(for:action:)` — iOS 18+ width observation
//    without an explicit `GeometryReader` wrapper.
//  • `.presentationDetents(_:selection:)` — programmatic detent binding
//    so code (not just drags) can move the sheet.
//  • `.presentationBackgroundInteraction(.enabled)` — lets the map
//    stay pannable while the sheet is up (the Apple Maps feel).
//  • `.presentationCompactAdaptation(.none)` — stops the sheet from
//    auto-promoting to a fullscreen cover in compact width.
//  • `.interactiveDismissDisabled()` — the sheet is persistent chrome,
//    not a dismissible modal.
//
//  How to apply
//  ────────────
//  Reuse for any "persistent info panel over a canvas" UX (maps,
//  editors, dashboards) that should float beside content on wide
//  screens and dock to the bottom on narrow ones.
//

import MapKit
import SwiftUI

struct LandscapePinnedDemoView: View {
    @State private var showSheet: Bool = true
    @State private var isLargeScreen: Bool = false
    @State private var detent: PresentationDetent = .height(85)
    var body: some View {
        Map(initialPosition: .region(.applePark))
            .sheet(isPresented: $showSheet) {
                SheetView(isLargeScreen: $isLargeScreen, detent: $detent)
            }
            .onGeometryChange(for: Bool.self) {
                $0.size.width > 600
            } action: { newValue in
                /// default value
                if detent != .height(85), newValue {
                    detent = .fraction(0.97)
                } else if detent == .fraction(0.97), !newValue {
                    detent = .fraction(0.45)
                } else {
                    detent = .height(85)
                }
                isLargeScreen = newValue
            }
    }
}

struct SheetView: View {
    @Binding var isLargeScreen: Bool
    @Binding var detent: PresentationDetent
    var body: some View {
        Text("Hello, I'm Sheet!")
            .presentationDetents(detents, selection: $detent)
            .presentationBackgroundInteraction(.enabled)
            .presentationCompactAdaptation(.none)
            .interactiveDismissDisabled()
            .presentationCornerRadius(cornerRadius)
            .adaptiveSheet(400, isActive: isLargeScreen)
    }

    private var detents: Set<PresentationDetent> {
        if isLargeScreen {
            return [.height(85), .fraction(0.96)]
        }
        return [.height(85), .fraction(0.45), .large]
    }

    private var cornerRadius: CGFloat? {
        if isLargeScreen { return 35 }
        return nil
    }
}

#Preview {
    LandscapePinnedDemoView()
}
