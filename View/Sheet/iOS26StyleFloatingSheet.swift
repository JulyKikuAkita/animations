//
//  iOS26 Style sheet.swift
//  animation
//
import MapKit
import SwiftUI

struct FloatingSheetIOS26StyleDemo: View {
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
