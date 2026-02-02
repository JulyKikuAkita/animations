//
//  DIRQScannerView.swift
//  animation
//
//  Created on 2/1/26.

import SwiftUI

struct DIRQScannerDemoView: View {
    @State private var showScanner: Bool = false
    var body: some View {
        NavigationStack {
            List {
                Button("Show Scanner") {
                    showScanner.toggle()
                }
            }
            .navigationTitle("QR Scanner")
            .qrscanner(isScanning: $showScanner) { _ in
            }
        }
    }
}

extension View {
    @ViewBuilder
    func qrscanner(isScanning: Binding<Bool>, onScan: @escaping (String) -> Void) -> some View {
        modifier(QRScannerViewModifier(isScanning: isScanning, onScan: onScan))
    }
}

private struct QRScannerViewModifier: ViewModifier {
    @Binding var isScanning: Bool
    var onScan: (String) -> Void
    /// Modifer Properties
    @State private var showFulllScreenCover: Bool = false
    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $showFulllScreenCover) {
                DIRQScannerView {
                    Task { @MainActor in
                        showFulllScreenCoverWithoutAnimation(false)
                    }
                } onScan: { code in
                    onScan(code)
                }
                .presentationBackground(.clear)
            }
            .onChange(of: isScanning) { _, newValue in
                if newValue {
                    showFulllScreenCoverWithoutAnimation(true)
                }
            }
    }

    private func showFulllScreenCoverWithoutAnimation(_ status: Bool) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            showFulllScreenCover = status
        }
    }
}

@available(iOS 26.0, *)
struct DIRQScannerView: View {
    var onClose: () -> Void
    var onScan: (String) -> Void
    /// View Properties
    @State private var isInitialized: Bool = false
    @State private var showContent: Bool = false
    @State private var isExpanding: Bool = false
    var body: some View {
        GeometryReader {
            let size = $0.size
            let safeArea = $0.safeAreaInsets

            /// Dynamic Island
            let haveDynamicIsland: Bool = safeArea.top >= 59
            let dynamicIslandWidth: CGFloat = 120
            let dynamicIslandHeight: CGFloat = 36

            let expandedWidth: CGFloat = size.width - 30
            let expandedHeight: CGFloat = expandedWidth

            ZStack(alignment: .top) {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .contentShape(.rect)
                    .onTapGesture {
                        toggle(false)
                    }
                /// Scanner Animated view
                ConcentricRectangle(
                    corners: .concentric(minimum: .fixed(30)),
                    isUniform: true
                )
                .fill(.black)
                .frame(width: isExpanding ? expandedWidth : dynamicIslandWidth,
                       height: isExpanding ? expandedHeight : dynamicIslandHeight)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea()
            .task {
                guard !isInitialized else { return }
                isInitialized = true
                showContent = true
                try? await Task.sleep(for: .seconds(0.05))
                toggle(true)
            }
        }
    }

    private func toggle(_ status: Bool) {
        withAnimation(.interpolatingSpring(duration: 0.3, bounce: 0, initialVelocity: 0)) {
            isExpanding = status
        }
    }
}
