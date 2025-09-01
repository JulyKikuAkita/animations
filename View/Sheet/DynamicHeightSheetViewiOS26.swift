//
//  DynamicHeightSheetDemoView.swift
//  animation
//
//  Created on 8/31/2025
// iOS 26 API
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
                /// avoid using bouncy animations; smooth or snappy works best for this sheet height udpate
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
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGSize.self) {
                    $0.size
                } action: { newValue in
                    if sheetHeight == .zero {
                        /// set large size as windowSize - 110 to smooth animation transtion
                        sheetHeight = min(newValue.height, windowSize.height - 110)
                    } else {
                        ///  we can use animatable protocol with SheetHeightModifier
                        withAnimation(animation) {
                            sheetHeight = min(newValue.height, windowSize.height - 110)
                        }
                    }
                }
        }
        // Note: sheet height with presentation detens has no default animation,
        // .presentationDetents(sheetHeight == .zero ? [.medium] : [.height(sheetHeight)])
        .modifier(SheetHeightModifier(height: sheetHeight))
    }

    var windowSize: CGSize {
        if let size = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen.bounds.size {
            return size
        }
        return .zero
    }
}

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
