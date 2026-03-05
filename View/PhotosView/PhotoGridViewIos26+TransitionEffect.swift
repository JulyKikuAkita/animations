//
//  PhotoGridViewIos26+TransitionEffect.swift
//  animation
//
//  Created on 3/4/26.
// Simulate Apple Photo app iOS26 transition animation
// Gesture: use customized pan gesture instead of drag gesture to work with scrollView also has the flexibility to fail the gesture in specific conditions
import SwiftUI

extension PhotoItem: PhotoProtocol {}

struct PhotoGridIOS26TransitionDemoView: View {
    var body: some View {
        NavigationStack {
            PhotoGridView(data: samplePhotoItems) { item in
                imageView(item)
            } detail: { item, isExpanded, _, _ in
                VStack {
                    if isExpanded { // avoid animation glitch
                        Rectangle()
                            .foregroundStyle(.clear)
                            .frame(height: 70)
                    }

                    imageView(item)

                    if isExpanded { // avoid animation glitch
                        Rectangle()
                            .foregroundStyle(.clear)
                            .frame(height: 70)
                    }
                }
            } overlay: { _, _, dragOffset, dismiss in
                if #available(iOS 26, *) {
                    overlayActionView(dragOffset: dragOffset, dismiss: dismiss)
                }

            } onSelectionChanged: { item in
                if let item {
                    print(item)
                }
            }
            .safeAreaPadding(15)
            .scrollIndicators(.hidden)
            .navigationTitle("Library")
        }
    }

    func imageView(_ item: PhotoItem) -> some View {
        Rectangle()
            .foregroundStyle(.clear)
            .overlay {
                if let image = item.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
    }

    @available(iOS 26, *)
    func overlayActionView(dragOffset: CGSize, dismiss: @escaping () -> Void) -> some View {
        let interactiveOpacity: CGFloat = 1 - min(abs(dragOffset.height / 30), 1)
        return VStack {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .frame(width: 20, height: 30)
                }
                .buttonStyle(.glass)

                Spacer(minLength: 0)

                Button {} label: {
                    Image(systemName: "ellipse")
                        .font(.title3)
                        .frame(width: 20, height: 30)
                }
                .buttonStyle(.glass)
            }

            Spacer(minLength: 0)

            HStack {
                Button {} label: {
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.title3)
                        .frame(width: 20, height: 30)
                }
                .buttonStyle(.glass)

                HStack {
                    Button {} label: {
                        Image(systemName: "suit.heart")
                            .font(.title3)
                            .padding(10)
                    }

                    Button {} label: {
                        Image(systemName: "info.circle")
                            .font(.title3)
                            .padding(10)
                    }

                    Button {} label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title3)
                            .padding(10)
                    }
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 10)
                .glassEffect(.regular.interactive(), in: .capsule)
                .frame(maxWidth: .infinity)

                Button {} label: {
                    Image(systemName: "trash")
                        .font(.title3)
                        .frame(width: 20, height: 30)
                }
                .buttonStyle(.glass)
            }
        }
        .padding(15)
        .compositingGroup()
        .opacity(interactiveOpacity)
    }
}

protocol PhotoProtocol: Hashable {
    var id: String { get }
}

private struct PhotoHeroEffectConfig<Element: PhotoProtocol> {
    var selectedItem: Element?
    var sourceLocation: CGRect = .zero
    var sourceScrollPosition: ScrollPosition = .init()
    var showFullScreenCover: Bool = false
}

struct PhotoGridView<Data: RandomAccessCollection, GridItem: View, Detail: View, Overlay: View>: View where Data.Element: PhotoProtocol {
    var spacing: CGFloat = 5
    var gridCount: Int = 3
    var gridItemHeight: CGFloat = 120
    var data: Data

    @ViewBuilder var gridItem: (Data.Element) -> GridItem
    @ViewBuilder var detail: (Data.Element, Bool, CGSize, @escaping () -> Void) -> Detail
    @ViewBuilder var overlay: (Data.Element?, Bool, CGSize, @escaping () -> Void) -> Overlay
    var onSelectionChanged: (Data.Element?) -> Void = { _ in }
    /// View Properties
    @State private var config: PhotoHeroEffectConfig<Data.Element> = .init()

    var body: some View {
        let gridItems = Array(repeating: SwiftUI.GridItem(spacing: spacing), count: gridCount)

        ScrollView(.vertical) {
            LazyVGrid(columns: gridItems, spacing: spacing) {
                ForEach(data, id: \.id) { item in
                    Rectangle()
                        .foregroundStyle(.clear)
                        .overlay {
                            GeometryReader {
                                let rect = $0.frame(in: .global)
                                let updatedRect: CGRect? = config.selectedItem == item ? rect : nil

                                gridItem(item)
                                    /// hiding the source view when enable hero effect animation
                                    .opacity(config.selectedItem == item ? 0 : 1)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .contentShape(.rect)
                                    .onTapGesture {
                                        /// Storing info and opening full screen hero view
                                        config.selectedItem = item
                                        config.sourceLocation = rect
                                        /// Opening full screen cover without animation
                                        withoutAnimation {
                                            config.showFullScreenCover = true
                                        }
                                    }
                                    .onChange(of: updatedRect) { _, newValue in
                                        if let newValue {
                                            config.sourceLocation = newValue
                                        }
                                    }
                            }
                        }
                        .frame(height: gridItemHeight)
                        .clipped()
                        .contentShape(.rect)
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition($config.sourceScrollPosition)
        .fullScreenCover(isPresented: $config.showFullScreenCover) {
            config.selectedItem = nil
        } content: {
            DetailPhotosView(config: $config, data: data, detail: detail, overlay: overlay)
        }
        /// publish selected item change along with the source scroll view position when updating in enlarged view
        .onChange(of: config.selectedItem) { oldValue, newValue in
            if let newValue, oldValue != nil {
                config.sourceScrollPosition.scrollTo(id: newValue.id)
            }
            onSelectionChanged(newValue)
        }
    }
}

private struct DetailPhotosView<Data: RandomAccessCollection, Detail: View, Overlay: View>: View where Data.Element: PhotoProtocol {
    @Binding var config: PhotoHeroEffectConfig<Data.Element>
    var data: Data
    @ViewBuilder var detail: (Data.Element, Bool, CGSize, @escaping () -> Void) -> Detail
    @ViewBuilder var overlay: (Data.Element?, Bool, CGSize, @escaping () -> Void) -> Overlay
    /// View Properties
    @State private var isExpanded: Bool = false
    @State private var viewSize: CGSize = .zero
    @State private var safeArea: EdgeInsets = .init()
    @State private var dragOffset: CGSize = .zero

    var animation: Animation {
        .interpolatingSpring(duration: 0.3, bounce: 0, initialVelocity: 0)
    }

    /// fadeout opacity for interactive gesture
    var interactiveOpacity: CGFloat {
        let opacityY = abs(dragOffset.height) / (viewSize.height * 0.3)
        return isExpanded ? (1 - opacityY) : 0
    }

    var body: some View {
        TabView(selection: $config.selectedItem) {
            ForEach(data, id: \.id) { item in
                let sourceFrame = config.sourceLocation

                detail(item, isExpanded, dragOffset, dismiss)
                    .frame(
                        width: isExpanded ? viewSize.width : sourceFrame.width,
                        height: isExpanded ? viewSize.height : sourceFrame.height,
                    )
                    .clipped()
                    .offset(x: isExpanded ? 0 : sourceFrame.minX,
                            y: isExpanded ? 0 : sourceFrame.minY)
                    .offset(dragOffset)
                    /// view coordinate system starts at top left
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: isExpanded ? .center : .topLeading
                    )
                    .tag(item)
                    .ignoresSafeArea()
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
        .contentShape(.rect)
        .gesture(PhotoScrollPanGesture { gesture in
            let state = gesture.state
            let translation = gesture.translation(in: gesture.view)

            if state == .began || state == .changed {
                dragOffset = .init(width: translation.x, height: translation.y)
            } else {
                if dragOffset.height > 50 {
                    dismiss()
                } else {
                    withAnimation(animation.speed(1.2)) {
                        dragOffset = .zero
                    }
                }
            }
        })
        .overlay {
            overlay(config.selectedItem, isExpanded, dragOffset, dismiss)
                .compositingGroup()
                .opacity(interactiveOpacity)
                .opacity(isExpanded ? 1 : 0)
        }
        .presentationBackground {
            Rectangle()
                .fill(.black)
                .opacity(interactiveOpacity)
                .opacity(isExpanded ? 1 : 0)
        }
        .allowsHitTesting(isExpanded)
        /// Others
        .onGeometryChange(for: CGSize.self, of: {
            $0.size
        }, action: { newValue in
            viewSize = newValue
        })
        .onGeometryChange(for: EdgeInsets.self, of: {
            $0.safeAreaInsets
        }, action: { newValue in
            safeArea = newValue
        })
        .task {
            guard !isExpanded else { return }
            withAnimation(animation) {
                isExpanded = true
            }
        }
    }

    func dismiss() {
        Task {
            withAnimation(animation.speed(1.2)) {
                dragOffset = .zero
                isExpanded = false
            }

            try? await Task.sleep(for: .seconds(0.3))
            withoutAnimation {
                config.showFullScreenCover = false
            }
        }
    }
}

private extension View {
    func withoutAnimation(_ result: @escaping () -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            result()
        }
    }
}

#Preview {
    PhotoGridIOS26TransitionDemoView()
}

/// MARK: - Interactive Dismiss Pan Gesture
///
/// Instead of using SwiftUI `DragGesture`, we use `UIPanGestureRecognizer`
/// for better flexibility. This allows us to explicitly fail the gesture
/// under specific conditions.
///
/// The gesture activates only when:
///
/// 1. The swipe direction is from top to bottom.
/// 2. If another gesture (such as a `UIScrollView` pan) is being recognized,
///    we check whether the scroll view's `contentOffset.y == 0`
///    (meaning it is scrolled to the top).
///    - If YES → allow dismiss gesture to proceed.
///    - If NO  → force this gesture to fail.
///
/// This design prevents gesture conflicts and keeps interactions smooth,
/// especially if the detail view is later wrapped in a `ZoomableScrollView`
/// or other scroll-based container.
///
private struct PhotoScrollPanGesture: UIGestureRecognizerRepresentable {
    /// Grid+PanGestureView.swift
    var handle: (UIPanGestureRecognizer) -> Void

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let gesture = UIPanGestureRecognizer()
        gesture.minimumNumberOfTouches = 1
        gesture.maximumNumberOfTouches = 1
        gesture.delegate = context.coordinator
        return gesture
    }

    func updateUIGestureRecognizer(_: UIPanGestureRecognizer, context _: Context) {}

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context _: Context) {
        handle(recognizer)
    }

    func makeCoordinator(converter _: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private func gestureRecognizer(_: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIPanGestureRecognizer) -> Bool {
            if let scrollView = otherGestureRecognizer.view as? UIScrollView {
                let contentOffset = scrollView.contentOffset
                return contentOffset.y <= 0
            }
            return false
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else { return false }
            let velocity = panGesture.velocity(in: panGesture.view)
            return velocity.y > abs(velocity.x)
        }
    }
}
