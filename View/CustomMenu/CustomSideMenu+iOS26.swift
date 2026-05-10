//
//  CustomSideMenu+iOS26.swift
//  animation
//
//  Created on 5/9/26.
// Twitter/X app side menu
import SwiftUI

struct CustomIOS26SideMenuDemoView: View {
    @State private var activeTab: Int = 0
    @State private var navigationPath: NavigationPath = .init()
    @State private var isExpanded: Bool = false
    var body: some View {
        let isMenuEnabled = navigationPath.isEmpty
        CustomIOS26SideMenu(isEnabled: isMenuEnabled, isExpanded: $isExpanded) { _ in
            VStack {
                DummySideBar()

                Button {
                    isExpanded = false
                    navigationPath.append("Settings")
                } label: {
                    Text("Go to Settings")
                }
                .padding(.top, 15)
            }
        } content: { _ in
            NavigationStack(path: $navigationPath) {
                TabView(selection: $activeTab) {
                    Tab("Home", systemImage: "house", value: 0) {
                        ScrollView(.vertical) {
                            VStack(spacing: 10) {
                                NavigationLink(value: "Detail View") {
                                    Rectangle()
                                        .fill(.indigo)
                                        .frame(height: 45)
                                }

                                ScrollView(.horizontal) {
                                    HStack(spacing: 0) {
                                        Rectangle()
                                            .fill(.red)
                                            .containerRelativeFrame(
                                                .horizontal
                                            )
                                        Rectangle()
                                            .fill(.gray)
                                            .containerRelativeFrame(
                                                .horizontal
                                            )
                                    }
                                }
                                .scrollTargetBehavior(.paging)
                                .frame(height: 220)
                            }
                        }
                    }
                    Tab("Search", systemImage: "magnifyingglass", value: 1) {}
                    Tab("Notifications", systemImage: "bell", value: 2) {}
                    Tab("Profiles", systemImage: "person", value: 3) {}
                }
                .toolbarVisibility(.hidden, for: .navigationBar)
                .navigationDestination(for: String.self) { value in
                    Text("Demo").navigationTitle(value)
                }
            }
        }
    }
}

struct CustomIOS26SideMenu<MenuContent: View, Content: View>: View {
    // enable or disable side menu gesture
    var isEnabled: Bool = true
    @Binding var isExpanded: Bool
    var sideBarWidth: CGFloat = 280

    @ViewBuilder var menuContent: (_ progress: CGFloat) -> MenuContent
    @ViewBuilder var content: (_ progress: CGFloat) -> Content
    /// View Properties
    @State private var progress: CGFloat = 0
    @State private var xOffset: CGFloat = 0
    @State private var haptics: Bool = false
    var body: some View {
        ZStack(alignment: .leading) {
            menuContent(progress)
                .frame(width: sideBarWidth)
                .frame(maxHeight: .infinity)
                .opacity(progress)
                .scaleEffect(0.95 + (0.05 * progress))

            content(progress)
                .containerRelativeFrame(.horizontal)
                .frame(maxHeight: .infinity)
                .background {
                    backgroundShape
                        .fill(.background)
                        .ignoresSafeArea()
                }
                .overlay {
                    backgroundShape
                        .fill(.tertiary)
                        .stroke(.fill.secondary, lineWidth: 1)
                        .ignoresSafeArea()
                        .contentShape(.rect)
                        .onTapGesture {
                            withAnimation(animation) {
                                dismissMenu()
                            }
                        }
                        .opacity(progress)
                }
                .mask {
                    backgroundShape
                        .ignoresSafeArea()
                }
                .compositingGroup()
                .shadow(color: .black.opacity(0.06 * progress), radius: 5, x: -10, y: 0)
                .offset(x: xOffset)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(.rect)
        .gesture(
            CustomSideMenuGesture(isEnabled: isEnabled, isExpanded: $isExpanded) { gesture in
                let state = gesture.state
                let translation = gesture.translation(in: gesture.view).x +
                    (isExpanded ? sideBarWidth : 0)
                let velocity = gesture.velocity(in: gesture.view).x / 5

                if state == .began || state == .changed {
                    xOffset = translation.clamped(to: 0 ... sideBarWidth)
                    progress = xOffset / sideBarWidth
                } else {
                    withAnimation(animation) {
                        if (xOffset + velocity) > (sideBarWidth / 2) {
                            expandMenu()
                        } else {
                            dismissMenu()
                        }
                    }
                }
            }
        )
        .sensoryFeedback(.impact(weight: .light), trigger: haptics)
        .onChange(of: isExpanded) { _, newValue in
            withAnimation(animation) {
                if newValue, progress != 1 {
                    expandMenu()
                }

                if !newValue, progress != 0 {
                    dismissMenu()
                }
            }
        }
    }

    func expandMenu() {
        if !isExpanded { haptics.toggle() }
        /// Expand
        xOffset = sideBarWidth
        progress = 1
        isExpanded = false
    }

    func dismissMenu() {
        if isExpanded { haptics.toggle() }

        /// Reset
        xOffset = 0
        progress = 0
        isExpanded = false
    }

    var backgroundShape: some Shape {
        if #available(iOS 26, *) {
            ConcentricRectangle(corners: .concentric, isUniform: true)
        } else {
            RoundedRectangle(cornerRadius: 45)
        }
    }

    var animation: Animation {
        .interactiveSpring(duration: 0.2, extraBounce: 0.02)
    }
}

/// Benefit of using pan gesture over drag gesture:
/// pan gesture can customize conditions say if baseView has HScrollView/VSrollView can help detect gesture from scroll gesture
private struct CustomSideMenuGesture: UIGestureRecognizerRepresentable {
    var isEnabled: Bool
    @Binding var isExpanded: Bool
    var handle: (UIPanGestureRecognizer) -> Void

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let gesture = UIPanGestureRecognizer()
        gesture.delegate = context.coordinator
        gesture.maximumNumberOfTouches = 1
        return gesture
    }

    func updateUIGestureRecognizer(
        _ recognizer: UIPanGestureRecognizer,
        context _: Context
    ) {
        recognizer.isEnabled = isEnabled
    }

    func handleUIGestureRecognizerAction(
        _ recognizer: UIPanGestureRecognizer,
        context _: Context
    ) {
        handle(recognizer)
    }

    func makeCoordinator(converter _: CoordinateSpaceConverter) -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: CustomSideMenuGesture
        init(parent: CustomSideMenuGesture) {
            self.parent = parent
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            if let panGesture = gestureRecognizer as? UIPanGestureRecognizer {
                let velocity = panGesture.velocity(in: panGesture.view)
                let isHorizontalSwipe = abs(velocity.x) > abs(velocity.y)
                return (isHorizontalSwipe && velocity.x > 0) ||
                    (isHorizontalSwipe && velocity.x < 0 && parent.isExpanded)
            }
            return false
        }

        func gestureRecognizer(_: UIGestureRecognizer, shouldBeRequiredToFailByOtherGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            if let scrollView = otherGestureRecognizer.view as? UIScrollView {
                let offset = scrollView.contentOffset.x
                return offset <= 0
            }
            return false
        }
    }
}

#Preview {
    CustomIOS26SideMenuDemoView()
}
