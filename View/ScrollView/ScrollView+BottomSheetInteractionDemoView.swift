//
//  ScrollView+BottomSheetInteractionDemoView.swift
//  animation
//
//  Created on 10/30/25.

import SwiftUI

struct ScrollViewBottomSheetInteractionDemoView: View {
    var body: some View {
        CustomScrollView { _ in
            dummyContent()
        } sheetContent: { _ in
            dummyContent()
        } bottomBar: { _ in
            bottomBar()
                .padding(.bottom, 10)
        }
    }

    func bottomBar() -> some View {
        Text("Home View")
            .fontWeight(.medium)
            .padding(.vertical, 10)
            .padding(.horizontal, 15)
            .background(.ultraThinMaterial, in: .capsule)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .leading) {
                HStack {
                    Button {} label: {
                        Image(systemName: "xmark")
                            .fontWeight(.medium)
                            .frame(width: 45, height: 45)
                            .foregroundStyle(.primary)
                            .background(.ultraThinMaterial, in: .circle)
                    }
                    Spacer()
                    Button {} label: {
                        Image(systemName: "ellipsis")
                            .fontWeight(.medium)
                            .frame(width: 45, height: 45)
                            .foregroundStyle(.primary)
                            .background(.ultraThinMaterial, in: .circle)
                    }
                }.padding(.horizontal, 15)
            }
    }

    func dummyContent() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Home")
                .font(.title.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(paragraphedDummyDescription)
                .font(.callout)
                .multilineTextAlignment(.leading)

            Text(shortDummyDescription)
                .font(.callout)
                .multilineTextAlignment(.leading)
                .padding(.top, 10)
        }
        .padding(15)
//        .padding(.bottom, 500)
    }
}

struct CustomScrollView<ScrollContent: View, SheetContent: View, BottomBar: View>: View {
    @ViewBuilder var scrollContent: (_ progress: CGFloat) -> ScrollContent
    @ViewBuilder var sheetContent: (_ progress: CGFloat) -> SheetContent
    @ViewBuilder var bottomBar: (_ progress: CGFloat) -> BottomBar
    /// View Properties
    /// to minimize/expands when the main scroll direction changes
    @State private var sheetHeight: CGFloat = 150
    @State private var storedSheetHeight: CGFloat = 0
    @State private var storedTranslation: CGFloat = 0
    @State private var isScrolledUp: Bool = false
    @State private var isElligibleForGesture: Bool = false

    /// move the entire sheet up/down
    @State private var sheetOffset: CGFloat = 0
    @State private var storedSheetOffset: CGFloat = 0
    /// Other Properties
    @State private var sheetScrollPosition: ScrollPosition = .init()
    @State private var isSheetScrollDisabled: Bool = false
    @State private var sheetScrollOffset: CGFloat = 0

    var body: some View {
        GeometryReader {
            let size = $0.size
            let safeArea = $0.safeAreaInsets
            let progress: CGFloat = min(max(-sheetOffset / (size.height - sheetHeight), 0), 1)
            let scale = 1 - (progress * 0.1)
            let sheetShape = UnevenRoundedRectangle(
                topLeadingRadius: 30,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 30
            )

            ZStack(alignment: .bottom) {
                /// Black background for sheet scaling effect
                Rectangle()
                    .fill(.black).ignoresSafeArea(.all)

                /// Main ScrollView
                ScrollView(.vertical) {
                    scrollContent(progress)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onScrollGeometryChange(for: Bool.self, of: {
                    $0.contentSize.height > ($0.containerSize.height - sheetHeight)
                }, action: { _, newValue in
                    isElligibleForGesture = newValue
                })
                .safeAreaPadding(.top, safeArea.top)
                .safeAreaPadding(.bottom, maximumSheetHeight)
                .background {
                    let cornerRadius = 30 + (15 * progress)
                    UnevenRoundedRectangle(
                        topLeadingRadius: cornerRadius,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: cornerRadius
                    )
                    .fill(.background)
                    .padding(.top, -safeArea.top)
                }
                .scrollClipDisabled()
                .contentShape(.rect)
                .gesture(CustomGesture {
                    handleMainGesture($0)
                })
                .scaleEffect(scale, anchor: .bottom)
                .ignoresSafeArea(.all, edges: .top)

                /// Bottom Sheet
                ScrollView(.vertical) {
                    sheetContent(progress)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                /// Starting content after the drag indicator
                .safeAreaPadding(.top, 30)
                .scrollPosition($sheetScrollPosition)
                .scrollDisabled(isSheetScrollDisabled || sheetOffset == 0)
                .onScrollGeometryChange(for: CGFloat.self, of: {
                    $0.contentOffset.y + $0.contentInsets.top
                }, action: { _, newValue in
                    sheetScrollOffset = newValue
                })
                .scrollClipDisabled()
                .mask {
                    sheetShape
                        .padding(.top, -safeArea.top * progress)
                }
                .background {
                    sheetShape
                        .fill(.background)
                        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: -5)
                        .padding(.top, -safeArea.top * progress)
                        .padding(.bottom, -safeArea.bottom)
                }
                /// Drag indicator
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(.gray.opacity(0.4))
                        .frame(width: 35, height: 6)
                        .frame(height: 25, alignment: .bottom)
                        .contentShape(.rect)
                        .gesture(CustomGesture {
                            let state = $0.state
                            if state == .began || state == .changed { isSheetScrollDisabled = true }
                            else { isSheetScrollDisabled = false }
                        })
                }
                .contentShape(.rect)
                .offset(y: size.height - sheetHeight)
                .offset(y: sheetOffset)
                .gesture(CustomGesture {
                    handleSheetGesture($0, size: size)
                })
                /// disable gesture to drag the sheet on bottom bar
                .background(alignment: .top) {
                    bottomBar(progress)
                        .visualEffect { content, proxy in
                            content
                                .offset(y: -(proxy.size.height + 5))
                        }
                        .offset(y: size.height - sheetHeight)
                        .offset(y: sheetOffset)
                }
            }
        }
        /// Removing all toolbars
        .toolbarVisibility(.hidden, for: .navigationBar)
        .toolbarVisibility(.hidden, for: .tabBar)
    }

    private func handleMainGesture(_ gesture: UIPanGestureRecognizer) {
        let state = gesture.state
        let translation = gesture.translation(in: gesture.view).y
        let velocity = gesture.velocity(in: gesture.view).y / 10

        switch state {
        case .began:
            updateMainTranslation(value: -translation)
        case .changed:
            /// Checking drag direction and updating the stored properties
            if velocity < 0 {
                if !isScrolledUp { updateMainTranslation(value: -translation) }
                isScrolledUp = true
            } else {
                if isScrolledUp { updateMainTranslation(value: -translation) }
                isScrolledUp = false
            }

            /// Updating sheet height
            let offset = storedTranslation + translation
            sheetHeight = min(max(storedSheetHeight + offset, minimumSheetHeight), maximumSheetHeight)
        case .ended, .failed, .cancelled:
            /// Resetting to either min or max height
            updateMainTranslation(true, value: 0)

            withAnimation(animation) {
                if (sheetHeight + velocity) < 110, isElligibleForGesture {
                    sheetHeight = minimumSheetHeight
                } else {
                    sheetHeight = maximumSheetHeight
                }
            }
        default: ()
        }
    }

    private func updateMainTranslation(_ reset: Bool = false, value: CGFloat) {
        if reset {
            storedSheetHeight = 0
            storedTranslation = 0
            isScrolledUp = false
        } else {
            storedSheetHeight = sheetHeight
            storedTranslation = value
        }
    }

    private func handleSheetGesture(_ gesture: UIPanGestureRecognizer, size: CGSize) {
        let state = gesture.state
        let translation = gesture.translation(in: gesture.view).y
        let velocity = gesture.velocity(in: gesture.view).y / 5
        let threshold: CGFloat = 3 /// check gesture activation
        switch state {
        case .began:
            if sheetScrollOffset <= threshold, velocity < 0, sheetOffset == 0 {
                /// sheet is not expanded
                isSheetScrollDisabled = true
            }

            if sheetScrollOffset <= threshold, velocity > 0, storedSheetOffset != 0 {
                /// sheet is fully expanded and user drags down from top:
                /// let the container (sheet) handle the gesture so it can collapse
                isSheetScrollDisabled = true
            }
        case .changed:
            guard isSheetScrollDisabled else { return }
            sheetOffset = -min(max(-translation + storedSheetHeight, 0), size.height - sheetHeight)
        case .ended, .failed, .cancelled:
            guard isSheetScrollDisabled else { return }

            withAnimation(animation) {
                if -(sheetOffset + velocity) > (size.height / 3) {
                    /// Fully Expanded
                    sheetOffset = -(size.height - sheetHeight)
                } else {
                    /// Reset to initial
                    sheetOffset = 0
                    sheetScrollPosition.scrollTo(y: 0)
                }
            }
            storedSheetOffset = -sheetOffset
            isSheetScrollDisabled = false
        default: ()
        }
    }

    var maximumSheetHeight: CGFloat {
        150
    }

    var minimumSheetHeight: CGFloat {
        70
    }

    var animation: Animation {
        .snappy(duration: 0.3, extraBounce: 0)
    }
}

#Preview {
    ScrollViewBottomSheetInteractionDemoView()
}

private struct CustomGesture: UIGestureRecognizerRepresentable {
    var handle: (UIPanGestureRecognizer) -> Void
    func makeCoordinator(converter _: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let gesture = UIPanGestureRecognizer()
        gesture.delegate = context.coordinator
        return gesture
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context _: Context) {
        handle(recognizer)
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizer(_: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool
        {
            true
        }
    }
}
