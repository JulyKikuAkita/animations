//
//  iOS26+bottomSheet.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//  iOS 18+ baseline; iOS 26 path adds `.glassEffect` chrome via
//  `if #available(iOS 26, *)` (lines ~108–113). Header comment was
//  previously misnamed `iOS26/iOS18 compatible BottomSheet.swift`
//  — fixed in this pass.
//
//  Inline tips (preserved):
//    • Use `onGeometryChange` to get the sheet's height.
//    • Adjust the floating toolbar's position + opacity from that.
//    • Use `safeAreaBottomInset` to start fading once the sheet
//      passes the centre detent.
//
//  Learning point
//  ──────────────
//  Apple-Maps-style bottom sheet over a `Map` view, with a
//  floating action toolbar (location button + search button) that
//  fades + slides as the sheet rises. The trick: the toolbar is
//  attached via `safeAreaInset(edge: .bottom)` to the Map, so its
//  position is REACTIVE to the sheet's measured height (read via
//  `onGeometryChange` on the sheet content). Once the sheet
//  passes the centre detent the toolbar fades to zero.
//
//  Key APIs
//  ────────
//  • `.sheet(isPresented:)` + `.presentationDetents([.height(...), .large], selection:)`
//    — multi-detent with programmatic selection.
//  • `.presentationBackgroundInteraction(.enabled)` — keeps the
//    Map interactive while the sheet is presented.
//  • `.onGeometryChange(for: CGFloat.self)` — measures sheet height
//    for toolbar fade math.
//  • `safeAreaInset(edge: .bottom)` on the Map — anchors the
//    toolbar above the sheet's lip.
//  • `.tryGlassEffect()` (project helper, line ~82) — applies
//    `.glassEffect` on iOS 26, no-op fallback otherwise.
//
//  How to apply
//  ────────────
//  Use as the template for any "Map + floating sheet + toolbar"
//  layout. The `safeAreaInset` + measured-sheet-height + fade
//  pattern generalises to other backgrounds (feeds, players,
//  dashboards).
//
//  See also
//  ────────
//  • iOS26ResizingSheet.swift — advanced YouTube-Shorts variant
//    that SHRINKS the underlying view rather than fading overlay
//    chrome.
//  • iOS26StyleFloatingSheet.swift — visual-polish wrapper that
//    composes the same chrome modifiers into one modifier.
//  • View/Map/View/CustomMapView.swift — sibling map demo with a
//    paged carousel instead of a bottom sheet.
//
import MapKit
import SwiftUI

struct BottomSheetiOS2618Demo: View {
    /// View Properties
    @State private var showBottomSheet: Bool = true
    @State private var sheetDent: PresentationDetent = .height(80)
    @State private var sheetHeight: CGFloat = 0
    @State private var animationDuration: CGFloat = 0
    @State private var toolbarOpacity: CGFloat = 1
    @State private var safeAreaBottomInset: CGFloat = 0

    var body: some View {
        Map(initialPosition: .region(.applePark))
            .sheet(isPresented: $showBottomSheet) {
                let safeInset = safeAreaBottomInset
                DummyBottomSheetView(sheetDent: $sheetDent)
                    // allow user to change sheet height between [80, 350]
                    .presentationDetents(
                        [.height(80), .height(350), .large],
                        selection: $sheetDent
                    )
                    .presentationBackgroundInteraction(.enabled)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onGeometryChange(for: CGFloat.self) { geometry in
                        max(min(geometry.size.height, 400 + safeInset), 0)
                    } action: { oldValue, newValue in
                        sheetHeight = min(newValue, 350 + safeInset)

                        /// apply to opacity, limit offset to 300 so opacity won't be 0
                        let progress = max(min((newValue - (350 + safeInset)) / 50, 1), 0)
                        toolbarOpacity = 1 - progress

                        /// calculating animation duration
                        let diff = abs(newValue - oldValue)
                        let duration = max(min(diff / 100, 0.3), 0)
                        animationDuration = duration
                    }
                    .ignoresSafeArea()
                    .interactiveDismissDisabled()
            }
            .overlay(alignment: .bottomTrailing) {
                bottomFloatingToolBar()
                    .padding(.trailing, 15)
                    .offset(y: safeAreaBottomInset - 10)
            }
            .onGeometryChange(for: CGFloat.self) {
                $0.safeAreaInsets.bottom
            } action: { newValue in
                safeAreaBottomInset = newValue
            }
    }

    func bottomFloatingToolBar() -> some View {
        var toolBarView: some View {
            VStack(spacing: 35) {
                Button {} label: {
                    Image(systemName: "car.fill")
                }

                Button {} label: {
                    Image(systemName: "location")
                }
            }
            .font(.title3)
            .foregroundStyle(.primary)
            .padding(.vertical, 20)
            .padding(.horizontal, 10)
            .background(.gray.opacity(0.7), in: .capsule)
            .clipShape(.capsule)
            .opacity(toolbarOpacity)
            .offset(y: -sheetHeight)
            .animation(.interpolatingSpring(duration: 0.3, bounce: 0, initialVelocity: 0), value: sheetHeight)
        }
        return toolBarView
            .tryGlassEffect(in: .circle)
    }
}

struct DummyBottomSheetView: View {
    @Binding var sheetDent: PresentationDetent
    /// View properties
    @State private var searchText: String = ""
    @FocusState var isFocused: Bool
    var body: some View {
        ScrollView(.vertical) {}
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack(spacing: 10) {
                    TextField("Search...", text: $searchText)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(.gray.opacity(0.25), in: .capsule)
                        .focused($isFocused)

                    Button {
                        if isFocused {
                            isFocused = false
                        } else {}
                    } label: {
                        ZStack {
                            if isFocused {
                                if #available(iOS 26.0, *) {
                                    closeIcon
                                        .tryGlassEffect(in: .circle)
                                } else {
                                    closeIcon
                                }
                            } else {
                                Text("T")
                                    .font(.title2.bold())
                                    .frame(width: 48, height: 48)
                                    .foregroundStyle(.white)
                                    .background(.gray, in: .circle)
                                    .transition(.blurReplace)
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .frame(height: 80)
                .padding(.top, 5)
                .animation(.interpolatingSpring(duration: 0.3, bounce: 0, initialVelocity: 0), value: isFocused)
                /// update sheet size when textField is focus
                .onChange(of: isFocused) { _, newValue in
                    sheetDent = newValue ? .large : .height(350)
                }
            }
    }

    var closeIcon: some View {
        Image(systemName: "xmark")
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
            .frame(width: 48, height: 48)
            .transition(.blurReplace)
    }
}

#Preview {
    BottomSheetiOS2618Demo()
}
