//
//  iOS26SegmentedTabBar.swift
//  animation
//
//  Created on 6/30/25.
#if canImport(FoundationModels)
    import SwiftUI

    @available(iOS 26.0, *)
    struct SegmentedTabBariOS26Demo: View {
        @State private var tabs: [SegmentedTabLocal] = [
            .init(id: 0, title: "TIME LAPSE"),
            .init(id: 1, title: "SLO-MO"),
            .init(id: 2, title: "PHOTO"),
            .init(id: 3, title: "VIDEO"),
            .init(id: 4, title: "PORTRAIT"),
            .init(id: 5, title: "PANO"),
        ]
        @State private var isSegmentedGestureActive: Bool = false

        /// Mock of camera UI
        var body: some View {
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(.black)
                    .backgroundExtensionEffect()

                Rectangle()
                    .fill(.gray.opacity(0.1))
                    .frame(height: 200)
                    .overlay {
                        VStack(spacing: 15) {
                            Circle()
                                .fill(.white)
                                .frame(width: 80, height: 80)

                            Spacer(minLength: 0)

                            /// custom segmented control
                            HStack(spacing: 20) {
                                Button {} label: {
                                    Circle()
                                        .fill(.gray.opacity(0.3))
                                        .frame(width: 50, height: 50)
                                }
                                .offset(x: isSegmentedGestureActive ? -100 : 0)

                                SegmentedControliOS26(initialIndex: 2,
                                                      horiztontalPadding: 70,
                                                      tabs: $tabs)
                                { _ in

                                } gestureStatus: { isActive in
                                    isSegmentedGestureActive = isActive
                                }

                                Button {} label: {
                                    Circle()
                                        .fill(.gray.opacity(0.3))
                                        .frame(width: 50, height: 50)
                                        .overlay {
                                            Image(systemName: "arrow.trianglehead.2.counterclockwise.rotate.90")
                                                .foregroundStyle(.white)
                                        }
                                }
                                .offset(x: isSegmentedGestureActive ? 100 : 0)
                            }
                            .padding(.horizontal, 30)
                        }
                        .padding(.vertical, 20)
                    }
            }
        }
    }

    @available(iOS 26.0, *)
    struct SegmentedControliOS26: View {
        var initialIndex: Int
        var horiztontalPadding: CGFloat = .zero

        @Binding var tabs: [SegmentedTabLocal]
        var onTabSelection: (Int) -> Void
        var gestureStatus: (Bool) -> Void = { _ in }
        /// View properties
        @State private var activeIndex: Int?
        @State private var centerPadding: CGFloat = 0
        /// Gesture Properties
        @State private var dragOffset: CGFloat = 0
        @State private var lastDrag: CGFloat?
        @GestureState private var isActive: Bool = false

        var body: some View {
            GeometryReader {
                let size = $0.size
                tabsScrollView(size: size)

                /// option 1
                if let activeIndex {
                    selectedTabSegmentStyle(tab: tabs[activeIndex])
                }

                /// option: 2
//            indicatorScrollView(size: size)
//                .frame(width: centerPadding, height: 45)
//                .clipShape(.capsule)
//                .glassEffect()
//                .frame(maxWidth:.infinity, maxHeight: .infinity)
//                .sensoryFeedback(.selection, trigger: activeIndex)
            }
            .frame(height: 50)
            .contentShape(.rect)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($isActive, body: { _, out, _ in
                        out = true
                    })
                    .onChanged { value in
                        if let lastDrag {
                            let xOffset = value.translation.width + lastDrag
                            dragOffset = xOffset

                            let index = Int(dragOffset / 50)
                            let cappedIndex = max(0, min(tabs.count - 1, index))
                            guard activeIndex != cappedIndex else { return }
                            withAnimation(.interpolatingSpring(duration: 0.3, bounce: 0, initialVelocity: 0)) {
                                activeIndex = cappedIndex
                                centerPadding = tabs[cappedIndex].size.width
                            }
                            onTabSelection(cappedIndex)
                        } else {
                            lastDrag = dragOffset
                        }
                    }.onEnded { _ in
                        lastDrag = nil
                        if activeIndex == 0 {
                            dragOffset = 0
                        }

                        if activeIndex == tabs.count - 1 {
                            dragOffset = (CGFloat(tabs.count - 1) * 50) + 25
                        }
                    }
            )
            .onChange(of: isActive) { _, newValue in
                withAnimation(.interpolatingSpring(duration: 0.3,
                                                   bounce: 0,
                                                   initialVelocity: 0))
                {
                    gestureStatus(newValue)
                }
            }
            .task {
                guard activeIndex == nil else { return }
                setupInitialIndex()
            }
        }

        private func tabsScrollView(size: CGSize) -> some View {
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach($tabs) { $tab in
                        Text(tab.title)
                            .foregroundStyle(activeIndex == tab.id ? .clear : .white)
                            .padding(.horizontal, 15)
                            .frame(height: 45)
                            .frame(maxHeight: .infinity)
                            .onGeometryChange(for: CGSize.self) {
                                $0.size
                            } action: { newValue in
                                tab.size = newValue
                            }
                    }
                }
                .scrollTargetLayout()
            }
            .safeAreaPadding(.horizontal, (size.width - centerPadding) / 2)
            .scrollPosition(id: $activeIndex, anchor: .center)
            .scrollDisabled(true)
            .scrollClipDisabled()
            .scrollIndicators(.hidden)
            .background {
                Capsule()
                    .fill(.gray.opacity(0.3))
                    .padding(.horizontal, isActive ? -horiztontalPadding : 0)
            }
            .mask {
                Capsule()
                    .padding(.horizontal, isActive ? -horiztontalPadding : 0)
            }
            .animation(.interpolatingSpring(duration: 0.3,
                                            bounce: 0,
                                            initialVelocity: 0), value: isActive)
        }

        /// selected segment style option2
        func indicatorScrollView(size _: CGSize) -> some View {
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(tabs) { tab in
                        Text(tab.title)
                            .foregroundStyle(.yellow)
                            .padding(.horizontal, 15)
                            .frame(height: 45)
                            .frame(maxHeight: .infinity)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $activeIndex, anchor: .center)
            .scrollDisabled(true)
            .scrollClipDisabled()
            .scrollIndicators(.hidden)
        }

        /// selected segment style option1
        func selectedTabSegmentStyle(tab: SegmentedTabLocal) -> some View {
            Text(tab.title)
                .foregroundStyle(.yellow)
                .padding(.horizontal, 15)
                .frame(height: 45)
                .glassEffect()
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .center
                )
                .allowsHitTesting(false)
        }

        private func setupInitialIndex() {
            activeIndex = initialIndex
            centerPadding = tabs[initialIndex].size.width
            dragOffset = CGFloat(initialIndex * 50) + 25
        }
    }

    struct SegmentedTabLocal: Identifiable {
        let id: Int
        let title: String
        var size: CGSize = .zero
    }

    @available(iOS 26.0, *)
    #Preview {
        SegmentedTabBariOS26Demo()
    }
#endif
