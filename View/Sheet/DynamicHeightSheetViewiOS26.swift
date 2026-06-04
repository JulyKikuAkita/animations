//
//  DynamicHeightSheetViewiOS26.swift
//  animation
//
//  Created on 8/31/2025
//  Standalone demo (not wired into the app's demo browser; preview-only).
//  iOS 26+ — `onGeometryChange`-driven detent updates inside a
//  custom `Animatable` modifier.
//
//  Learning point
//  ──────────────
//  Sheet whose presentation detent ANIMATES SMOOTHLY as the inner
//  content's height changes (e.g. a Picker reveals padding for
//  its selection). The trick is to NOT use static `.height(...)`
//  detents — instead a custom `Animatable` `SheetHeightModifier`
//  reads the content's measured height via `onGeometryChange` and
//  publishes it to a Binding that drives the detent.
//
//  Why a custom Animatable modifier?
//  ─────────────────────────────────
//  `.presentationDetents` accepts a static set; switching between
//  set members is a hard cut. To get continuous interpolation,
//  the modifier needs `Animatable` so SwiftUI can interpolate
//  `animatableData` (the height) at frame rate. Without
//  `Animatable`, the height jumps step-by-step.
//
//  Key APIs
//  ────────
//  • `.onGeometryChange(for: CGFloat.self)` (iOS 26) — measures
//    the live content height.
//  • Custom `Animatable` modifier — interpolates the height as a
//    CGFloat so the detent updates smoothly.
//  • `.presentationDetents([.height(...)])` — driven by the
//    measured value via Binding.
//  • `.smooth(duration:extraBounce:)` animation curve.
//
//  How to apply
//  ────────────
//  Use whenever a sheet's content has variable size and you don't
//  want the user to see "snap" between detents (filter sheets that
//  expand on more options, edit forms with collapsible fields).
//  For multi-step sheets that all fit one detent, see
//  [[DynamicFloatingSheetsiOS18View]] — different problem.
//
//  See also
//  ────────
//  • DynamicFloatingSheetsiOS18View.swift — wrapped by this demo
//    as one of the sample sheet bodies.
//  • DynamicSheetView.swift — pre-iOS-26 baseline using custom
//    PreferenceKeys instead of `onGeometryChange`.
//
import SwiftUI

struct DynamicHeightSheetiOS26DemoView: View {
    var body: some View {
        NavigationStack {
            DynamicHeightSheetView()
        }
    }
}

private enum Padding: String, CaseIterable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    var value: CGFloat {
        switch self {
        case .small:
            50
        case .medium:
            100
        case .large:
            450
        }
    }
}

struct DynamicHeightSheetView: View {
    /// View Properties
    @State private var showSheet: Bool = false
    @State private var showDynamicFloatingSheet: Bool = false
    @State private var showFixedHeightFloatingSheet: Bool = false
    @State private var sheetHeight: CGFloat = .zero
    @State private var padding: Padding = .small

    var body: some View {
        NavigationStack {
            List {
                Button("Show Sheet") {
                    showSheet.toggle()
                }

                Button("Show DynamicFloatingSheet") {
                    showDynamicFloatingSheet.toggle()
                }

                Button("Show FixedHeightFloatingSheet") {
                    showFixedHeightFloatingSheet.toggle()
                }
            }
            .navigationTitle("Dynamic Height Sheet")
        }
        .sheet(isPresented: $showSheet) {
            DynamicSheetiOS26(
                /// avoid using bouncy animations; smooth or snappy works best for this sheet height update
                animation: .smooth(duration: 0.35, extraBounce: 0)
            ) {
                VStack(spacing: 15) {
                    Text("New iOS 26 Dynamic Sheet API Demo")
                        .font(.callout)
                        .fontWeight(.medium)

                    Picker("", selection: $padding) {
                        ForEach(Padding.allCases, id: \.rawValue) {
                            Text($0.rawValue)
                                .tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, 30)
                .padding(.vertical, padding.value)
            }
        }
        .sheet(isPresented: $showDynamicFloatingSheet) {
            DynamicSheetiOS26(animation: .smooth(duration: 0.35)) {
                DynamicFloatingSheetsiOS18View()
            }
        }
        /// demo not wrapp by DynamicSheetiOS26 view modifier
        .sheet(isPresented: $showFixedHeightFloatingSheet) {
            DynamicFloatingSheetsiOS18View()
        }
    }
}

#Preview {
    DynamicHeightSheetiOS26DemoView()
}

struct DynamicSheetiOS26<Content: View>: View {
    var animation: Animation
    @ViewBuilder var content: Content
    @State private var sheetHeight: CGFloat = .zero

    var body: some View {
        ZStack {
            content
                // Tip: `.fixedSize(vertical: true)` lets the content claim its
                // intrinsic height instead of being stretched by the sheet —
                // essential for accurate height measurement.
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGSize.self) {
                    $0.size
                } action: { newValue in
                    if sheetHeight == .zero {
                        // First measurement: set without animation so the sheet
                        // doesn't animate up from 0 on initial present.
                        sheetHeight = min(newValue.height, windowSize.height - 110)
                    } else {
                        // Subsequent measurements: animate. The 110pt cap keeps
                        // the sheet below the status-bar / nav-bar so it never
                        // overlaps system chrome.
                        withAnimation(animation) {
                            sheetHeight = min(newValue.height, windowSize.height - 110)
                        }
                    }
                }
        }
        // Note: setting `.presentationDetents([.height(x)])` directly does NOT
        // animate when x changes — SwiftUI snaps. The `Animatable` modifier
        // below is the workaround (interpolates `height` at frame rate).
        .modifier(SheetHeightModifier(height: sheetHeight))
    }

    var windowSize: CGSize {
        if let size = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen.bounds.size {
            return size
        }
        return .zero
    }
}

/// Tip: this is the core trick.
/// Conforming to `Animatable` and exposing `height` as `animatableData` lets
/// SwiftUI interpolate the value over time. Inside `body`, the recomputed
/// `.presentationDetents([.height(height)])` is reapplied each frame, so the
/// detent updates smoothly instead of snapping. Without `Animatable`, even
/// `withAnimation { ... }` produces a hard step.
private struct SheetHeightModifier: ViewModifier, Animatable {
    var height: CGFloat
    var animatableData: CGFloat {
        get { height }
        set { height = newValue }
    }

    func body(content: Content) -> some View {
        content
            .presentationDetents(height == .zero ? [.medium] : [.height(height)])
    }
}
