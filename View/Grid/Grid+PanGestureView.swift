//
//  Grid+PanGestureView.swift
//  animation
//  iOS 18
// Using UIKit pan gesture as SwiftUI gesture support still not perform well
// 
import SwiftUI

struct GridColorBlockDemoView: View {
    var body: some View {
        GridColorBlockView()
    }
}

struct GridColorBlockView: View {
    /// View properties
    @State private var items: [ColorItem] = []
    @State private var isSelectionEnabled: Bool = false
    @State private var panGesture: UIPanGestureRecognizer?
    @State private var properties: SelectionProperties = .init()
    @State private var scrollProperties: ScrollProperties = .init()

    var body: some View {
            ScrollView(.vertical) {
                VStack(spacing: 20) {
                    Text("Grid View")
                        .font(.title.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay(alignment: .trailing) {
                            Button(isSelectionEnabled ? "Cancel" : "Select") {
                                isSelectionEnabled.toggle()
                                
                                if !isSelectionEnabled {
                                    properties = .init()
                                }
                            }
                            .font(.caption)
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.capsule)
                        }
                    
                    LazyVGrid(columns: Array(repeating: GridItem(), count: 4)) {
                        ForEach($items) { $item in
                            ItemCardView($item)
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .safeAreaPadding(15)
            .scrollPosition($scrollProperties.position)
            .overlay(alignment: .top) {
                ScrollDetectionRegion()
            }
            .overlay(alignment: .bottom) {
                ScrollDetectionRegion(false)
            }
            .onAppear(perform: createRandomColor)
            .onChange(of: isSelectionEnabled, { oldValue, newValue in
                panGesture?.isEnabled = newValue
            })
            .onScrollGeometryChange(
                for: CGFloat.self,
                of: { $0.contentOffset
                    .y + $0.contentInsets.top },
                action: { oldValue, newValue in
                    scrollProperties.currentScrollOffset = newValue
            })
        /// autoScroll when selection hit top or bottom at the specific range in the onScrollGeometryChange
            .onChange(of: scrollProperties.direction, { oldValue, newValue in
                 if newValue != .none {
                     guard scrollProperties.timer == nil else { return }
                     scrollProperties.manualScrollOffset = scrollProperties.currentScrollOffset
                     
                     scrollProperties.timer = Timer
                         .scheduledTimer(
                            withTimeInterval: 0.01,
                            repeats: true,
                            block: { _ in
                                if newValue == .up {
                                    scrollProperties.manualScrollOffset += 3
                                }
                                
                                if newValue == .down {
                                    scrollProperties.manualScrollOffset -= 3
                                }
                                scrollProperties.position.scrollTo(y: scrollProperties.manualScrollOffset)
                            })
                     
                                scrollProperties.timer?.fire()
                            } else {
                                resetScrollTimer()
                            }
            })
            .gesture(
                PanGesture(handle: { gesture in
                    if panGesture == nil {
                        panGesture = gesture
                        gesture.isEnabled = isSelectionEnabled
                    }
                    let state = gesture.state
                    
                    if state == .began || state == .changed {
                        onGestureChange(gesture)
                    } else {
                        onGestureEnded(gesture)
                    }
                })
            )
    }
    
    @ViewBuilder
    func ItemCardView(_ binding: Binding<ColorItem>) -> some View {
        let item = binding.wrappedValue
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            RoundedRectangle(cornerRadius: 10)
                .fill(item.color.gradient)
                .frame(height: 80)
                .onGeometryChange(for: CGRect.self) {
                    $0.frame(in: .global)
                } action: { newValue in
                    binding.wrappedValue.location = newValue
                }
                .overlay(alignment: .topLeading) {
                    if properties.selectedIndices.contains(index) &&
                        !properties.toBeDeletedIndices.contains(index) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.black, .white)
                            .padding(5)
                    }
                }
                .overlay { // UIUpdate for tap/unTap selection
                    if isSelectionEnabled {
                        Rectangle()
                            .foregroundStyle(.clear)
                            .contentShape(.rect)
                            .onTapGesture {
                                if properties.selectedIndices.contains(index) {
                                    properties.selectedIndices.removeAll(where: { $0 == index })
                                } else {
                                    properties.selectedIndices.append(index)
                                }
                                
                                properties.previousIndices = properties.selectedIndices
                            }
                            .transition(.identity)
                    }
                }
            
        }
       
    }
    
    @ViewBuilder
    func ScrollDetectionRegion(_ isTop: Bool = true) -> some View {
        Rectangle()
            .foregroundStyle(.clear)
            .frame(height: 100)
            .ignoresSafeArea()
            .onGeometryChange(for: CGRect.self) {
                $0.frame(in: .global)
            } action: { newValue in
                if isTop {
                    scrollProperties.topRegion = newValue
                } else {
                    scrollProperties.bottomRegion = newValue
                }
            }
    }
    
    private func onGestureChange(_ gesture: UIPanGestureRecognizer) {
        let position = gesture.location(in: gesture.view)
        if let fallingIndex = items.firstIndex(where: { $0.location.contains(position) }) {
            if properties.start == nil {
                properties.start = fallingIndex
                properties.isDeleteDrag = properties.previousIndices
                    .contains(fallingIndex)
            }
            
            properties.end = fallingIndex
            
            if let start = properties.start, let end = properties.end {
                let indices = (start > end ? end...start : start...end).compactMap({ $0 })
                if properties.isDeleteDrag {
                    properties.toBeDeletedIndices =  Set(
                        properties.previousIndices
                    )
                        .intersection(indices).compactMap({ $0 })
                } else {
                    properties.selectedIndices = Set(properties.previousIndices)
                        .union(indices).compactMap({ $0 })

                }
            }
            
            scrollProperties.direction = scrollProperties.topRegion
                .contains(position) ? .down :  scrollProperties.bottomRegion
                .contains(position) ? .up : .none
        }
    }
    
    private func onGestureEnded(_ gesture: UIPanGestureRecognizer) {
        for index in properties.toBeDeletedIndices {
            properties.selectedIndices.removeAll(where: { $0 == index })
        }
        properties.toBeDeletedIndices = []
        
        properties.previousIndices = properties.selectedIndices
        properties.start = nil
        properties.end = nil
        properties.isDeleteDrag = false
        
        resetScrollTimer()
    }

    
    private func createRandomColor() {
        guard items.isEmpty else { return }
        let colors: [Color] = [.red, .blue, .purple, .yellow, .black, .indigo, .cyan, .brown, .mint, .orange]

        for _ in 0...4 {
            let sampleItems = colors.shuffled().compactMap({ ColorItem(color: $0) })
            items.append(contentsOf: sampleItems)
        }
    }
    
    private func resetScrollTimer() {
        scrollProperties.manualScrollOffset = 0
        scrollProperties.timer?.invalidate()
        scrollProperties.timer = nil
        scrollProperties.direction = .none
    }
    
    struct SelectionProperties {
        var start: Int?
        var end: Int?
        var selectedIndices: [Int] = []
        var previousIndices: [Int] = []
        var toBeDeletedIndices: [Int] = []
        var isDeleteDrag: Bool = false
    }
    
    struct ScrollProperties {
        var position: ScrollPosition = .init()
        var currentScrollOffset: CGFloat = 0
        var manualScrollOffset: CGFloat = 0
        var timer: Timer?
        var direction: ScrollDirection = .none
        /// Regions
        var topRegion: CGRect = .zero
        var bottomRegion: CGRect = .zero
    }
    
    enum ScrollDirection {
        case up, down, none
    }
}

/// Custom UIKit Gesture -> move to Gesture + PanGesture file
//struct PanGesture: UIGestureRecognizerRepresentable {
//    var handle: (UIPanGestureRecognizer) -> ()
//    
//    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
//        return UIPanGestureRecognizer()
//    }
//    
//    func updateUIGestureRecognizer(
//        _ recognizer: UIPanGestureRecognizer,
//        context: Context
//    ) {}
//    
//    func handleUIGestureRecognizerAction(
//        _ recognizer: UIPanGestureRecognizer,
//        context: Context
//    ) {
//        handle(recognizer)
//    }
//}


#Preview {
    GridColorBlockDemoView()
}
