//
//  CustomDragDropScrollView.swift
//  animation

import SwiftUI

struct CustomDragDropScrollDemoView: View {
    var body: some View {
        GeometryReader {
            let safeArea = $0.safeAreaInsets
            Image(.aiGrn)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .blur(radius: 40, opaque: true)
                .overlay {
                    Rectangle()
                        .fill(.blue.opacity(0.25))
                }
                .ignoresSafeArea()

            CustomDragDropScrollView(safeArea: safeArea)
        }
    }
}
struct CustomDragDropScrollView: View {
    var safeArea: EdgeInsets
    /// View Properties
    @State private var controls: [Control] = controlList
    @State private var selectedControl: Control?
    @State private var selectedControlFrame: CGRect = .zero
    @State private var selectedControlScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    /// ScrollView Properties
    @State private var scrollPosition: ScrollPosition = .init()
    @State private var currentScrollOffset: CGFloat = 0
    @State private var lastActiveScrollOffset: CGFloat = 0
    @State private var maximumScrollSize: CGFloat = 0
    @State private var topRegion: CGRect = .zero
    @State private var bottomRegion: CGRect = .zero
    @State private var scrollTimer: Timer?
    /// Optional Features
    @State private var hapticsTrigger: Bool = false
    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: Array(repeating: GridItem(), count: 2), spacing: 20) {
            ///LazyVStack(spacing: 20) { /// using list
                ForEach($controls) { $control in
                    ControlView(control: control)
                        .opacity(selectedControl?.id == control.id ? 0 : 1)
                        .onGeometryChange(for: CGRect.self) {
                            $0.frame(in: .global)
                        } action: { newValue in
                            if selectedControl?.id == control.id {
                                selectedControlFrame = newValue
                            }

                            control.frame = newValue
                        }
                        .gesture(customCombinedGesture(control))
                }
            }
            .padding(25)
        }
        .scrollPosition($scrollPosition)
        .onScrollGeometryChange(for: CGFloat.self, of: {
            $0.contentOffset.y + $0.contentInsets.top
        }, action: { _, newValue in
            currentScrollOffset = newValue
//            print(newValue, maximumScrollSize)
        })
        .onScrollGeometryChange(for: CGFloat.self, of: {
            $0.contentSize.height + $0.contentSize.height
        }, action: { _, newValue in
            currentScrollOffset = newValue
        })
        .overlay(alignment: .topLeading) {
            if let selectedControl {
                ControlView(control: selectedControl)
                    .frame(width: selectedControl.frame.width,
                           height: selectedControl.frame.height)
                    .scaleEffect(selectedControlScale)
                    .offset(
                        x: selectedControl.frame.minX,
                        y: selectedControlFrame.minY
                    )
                    .offset(offset)
                    .ignoresSafeArea()
                    .transition(.identity)
            }
        }
        // set top and bottom not scrollable region
        .overlay(alignment: .top) {
            Rectangle()
                .fill(.clear)
                .frame(height: 20 + safeArea.top)
                .onGeometryChange(for: CGRect.self, of: {
                    $0.frame(in: .global)
                }, action: { newValue in
                    topRegion = newValue
                })
                .offset(y: -safeArea.top)
                .allowsHitTesting(false)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.clear)
                .frame(height: 20 + safeArea.bottom)
                .onGeometryChange(for: CGRect.self, of: {
                    $0.frame(in: .global)
                }, action: { newValue in
                    bottomRegion = newValue
                })
                .offset(y: safeArea.bottom)
                .allowsHitTesting(false)
        }
        .allowsTightening(selectedControl == nil) /// avoid multiple gesture inteaction
        .sensoryFeedback(.impact, trigger: hapticsTrigger)
    }

    func customCombinedGesture(_ control: Control) -> some Gesture {
        LongPressGesture(minimumDuration: 0.25)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .global))
            .onChanged { value in
                switch value {
                case .second(let status, let value):
                    if status {
                        if selectedControl == nil {
                            selectedControl = control
                            selectedControlFrame = control.frame
                            lastActiveScrollOffset = currentScrollOffset
                            hapticsTrigger.toggle()

                            withAnimation(.smooth(duration: 0.25, extraBounce: 0)) {
                                selectedControlScale = 1.05
                            }
                        }
                        print("Long press Completed", value?.translation.height ?? 0)
                    }

                    if let value {
                        offset = value.translation
                        let location = value.location
                        checkAndScroll(location)
                    }
                default: ()
                }
            }.onEnded { _ in
                scrollTimer?.invalidate()

                withAnimation(.snappy(duration: 0.25, extraBounce: 0),
                    completionCriteria: .logicallyComplete
                ) {
                    /// Updating control frame with latest update
                    selectedControl?.frame = selectedControlFrame
                    selectedControlScale = 1.0
                    offset = .zero
                } completion: {
                    selectedControl = nil
                    scrollTimer = nil
                    lastActiveScrollOffset = 0
                }
            }
    }

    // use a timer to auto-scroll the content
    // when the dragging view falls on the top or bottom region
    func checkAndScroll(_ location: CGPoint) {
        let topStatus = topRegion.contains(location)
        let bottomStatus = bottomRegion.contains(location)

        if topStatus || bottomStatus {
            /// Initializing only once
            guard scrollTimer == nil else { return }
            scrollTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { _ in
                    if topStatus {
                        lastActiveScrollOffset = max(lastActiveScrollOffset - 10, 0)
                    } else {
                        lastActiveScrollOffset = min(lastActiveScrollOffset + 10, maximumScrollSize)
                    }

                    scrollPosition.scrollTo(y: lastActiveScrollOffset)

                    /// Swapping item if it falls on any item
                    checkAndSwapItems(location)
                })
        } else {
            /// Removing Timer
            scrollTimer?.invalidate()
            scrollTimer = nil

            checkAndSwapItems(location)
        }
    }

    private func checkAndSwapItems(_ location: CGPoint) {
        if let currentIndex = controls.firstIndex(where: { $0.id == selectedControl?.id }),
           let fallingIndex = controls.firstIndex(where: { $0.frame.contains(location)}) {
            withAnimation(.snappy(duration: 0.25, extraBounce: 0)) {
                (controls[currentIndex], controls[fallingIndex]) = (controls[fallingIndex], controls[currentIndex])
            }
        }
    }
}

private struct ControlView: View {
    var control: Control
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: control.symbol)
                .font(.title3)

            Text(control.title)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 15)
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        }
    }
}

#Preview {
    CustomDragDropScrollDemoView()
}
