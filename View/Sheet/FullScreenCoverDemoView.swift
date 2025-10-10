//
//  FullScreenCoverDemoView.swift
//  animation
//
//  Created on 10/9/25.

import SwiftUI

@available(iOS 26.0, *)
struct FullScreenCoverDemoView: View {
    @State private var showSheet: Bool = false
    @Namespace private var animation
    var body: some View {
        NavigationStack {
            List {
                Button("Show Sheet") {
                    showSheet.toggle()
                }
                .matchedTransitionSource(id: "SHEET", in: animation)
            }
            .navigationTitle("FullScreen Sheet")
        }
        .fullScreenSheet(ignoreSafeArea: true,
                         isPresented: $showSheet)
        { safeArea in
            List {
                ForEach(1 ... 30, id: \.self) { index in
                    Text("\(index). Hello world")
                        .font(.title3)
                        .fontWeight(.medium)
                        .monospaced()
                        .foregroundStyle(.white)
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .safeAreaPadding(.top, safeArea.top)
            /// zoom transition
//            .navigationTransition(.zoom(sourceID: "SHEET", in: animation))
        } background: {
            ConcentricRectangle()
                .fill(Color.brown.gradient)
        }
    }
}

@available(iOS 26.0, *)
extension View {
    func fullScreenSheet(
        ignoreSafeArea: Bool = false,
        showsDragIndicator _: Bool = true,
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping (UIEdgeInsets) -> some View,
        @ViewBuilder background: @escaping () -> some View
    ) -> some View {
        fullScreenCover(isPresented: isPresented) {
            FullScreenSheet(
                ignoreSafeArea: ignoreSafeArea,
                content: content,
                background: background
            )
        }
    }
}

@available(iOS 26.0, *)
private struct FullScreenSheet<Content: View, Background: View>: View {
    var ignoreSafeArea: Bool
    @ViewBuilder var content: (UIEdgeInsets) -> Content
    @ViewBuilder var background: Background
    /// View Properties
    @Environment(\.dismiss) var dismiss
    @State private var offset: CGFloat = .zero
    @State private var scrollDisabled: Bool = false
    var body: some View {
        content(safeArea)
            .scrollDisabled(scrollDisabled)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(.rect)
            .offset(y: offset)
            .gesture(
                SimplePanCustomGesture { gesture in
                    let state = gesture.state
                    let halfHeight = windowSize.height / 2
                    let translation = min(
                        max(gesture.translation(in: gesture.view).y, 0),
                        windowSize.height
                    )
                    let velocity = min(
                        max(gesture.velocity(in: gesture.view).y, 0),
                        halfHeight
                    )

                    switch state {
                    case .began:
                        scrollDisabled = true
                        offset = translation
                    case .changed:
                        guard scrollDisabled else { return }
                        offset = translation
                    case .ended, .cancelled, .failed:
                        /// disable interaction until animation ends
                        gesture.isEnabled = false
                        if (translation + velocity) > halfHeight {
                            withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                                offset = windowSize.height
                            }

                            Task {
                                try? await Task.sleep(for: .seconds(0.3))
                                /// dismiss() comes with animation but we don't need it here
                                ///  so use transation to remove the animation
                                ///  to make move down gesture more repsonsive
                                var transaction = Transaction()
                                transaction.disablesAnimations = true
                                withTransaction(transaction) {
                                    dismiss()
                                }
                            }
                        } else {
                            withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                                offset = 0
                            }
                            Task {
                                try? await Task.sleep(for: .seconds(0.3))
                                scrollDisabled = false
                                gesture.isEnabled = true
                            }
                        }
                    default: ()
                    }
                }
            )
            .presentationBackground {
                background
                    /// sync background with gesture
                    .offset(y: offset)
            }
            .ignoresSafeArea(.container, edges: ignoreSafeArea ? .all : [])
    }

    var windowSize: CGSize {
        if let window = (
            UIApplication.shared.connectedScenes.first as? UIWindowScene
        )?.keyWindow {
            return window.screen.bounds.size
        }
        return .zero
    }

    var safeArea: UIEdgeInsets {
        if let window = (
            UIApplication.shared.connectedScenes.first as? UIWindowScene
        )?.keyWindow {
            return window.safeAreaInsets
        }
        return .zero
    }
}

@available(iOS 26.0, *)
#Preview {
    FullScreenCoverDemoView()
}
