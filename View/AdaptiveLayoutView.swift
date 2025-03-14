//
//  AdaptiveLayoutView.swift
//  animation

import SwiftUI

enum TabState: String, CaseIterable {
    case home = "Home"
    case search = "Search"
    case notifications = "Notifications"
    case profile = "Profile"

    var symbolImage: String {
        switch self {
        case .home: "house"
        case .search: "magnifyingglass"
        case .notifications: "bell"
        case .profile: "person.crop.circle"
        }
    }
}

struct AdaptiveLayoutView: View {
    /// View Properties
    @State private var activeTab: TabState = .home
    @State private var panGesture: UIPanGestureRecognizer?
    /// Gesture Properties
    @State private var offset: CGFloat = .zero
    @State private var lastDragOffset: CGFloat = .zero
    @State private var progress: CGFloat = .zero
    /// Navigation Path
    @State private var navigationPath: NavigationPath = .init()

    var body: some View {
        AdaptiveView { _, isLandscape in
            let sideBarWidth: CGFloat = isLandscape ? 220 : 250
            let layout = isLandscape ? AnyLayout(
                HStackLayout(spacing: 0)
            ) : AnyLayout(ZStackLayout(alignment: .leading))

            NavigationStack(path: $navigationPath) {
                layout {
                    SideBarView(path: $navigationPath) {
                        toggleSideBar()
                    }
                    .frame(width: sideBarWidth)
                    .offset(x: isLandscape ? 0 : -sideBarWidth)
                    .offset(x: isLandscape ? 0 : offset)

                    TabView(selection: $activeTab) {
                        Tab(TabState.home.rawValue, systemImage: TabState.home.symbolImage, value: .home) {
                            Text("home")
                        }

                        Tab(
                            TabState.search.rawValue,
                            systemImage: TabState.search.symbolImage,
                            value: .search
                        ) {
                            Text("Search")
                        }

                        Tab(
                            TabState.notifications.rawValue,
                            systemImage: TabState.notifications.symbolImage,
                            value: .notifications
                        ) {
                            Text("Notifications")
                        }

                        Tab(
                            TabState.profile.rawValue,
                            systemImage: TabState.profile.symbolImage,
                            value: .profile
                        ) {
                            Text("Profile")
                        }
                    }
                    .tabViewStyle(.tabBarOnly) /// do not convert to side bar at iPadOS
                    .overlay {
                        Rectangle()
                            .fill(.black.opacity(0.25))
                            .ignoresSafeArea()
                            .opacity(isLandscape ? 0 : progress)
                    }
                    .offset(x: isLandscape ? 0 : offset)
                }
                .gesture(
                    CustomGesture(isEnabled: !isLandscape) { gesture in
                        /// UIGestureRepresentable doesn't update once the gesture has been created. Thus, isEnabled will have no effect.
                        ///  Thus need to enable it manually
                        if panGesture == nil { panGesture = gesture }

                        let state = gesture.state
                        let translation = gesture.translation(
                            in: gesture.view
                        ).x + lastDragOffset

                        let velocity = gesture.velocity(in: gesture.view).x / 3

                        if state == .began || state == .changed {
                            /// onChanged
                            offset = max(min(translation, sideBarWidth), 0)

                            /// storing drag progress for fading tab view when dragging effect
                            progress = max(min(offset / sideBarWidth, 1), 0)
                        } else {
                            /// onEnded
                            withAnimation(.snappy(duration: 0.25, extraBounce: 0)) {
                                if (velocity + offset) > (sideBarWidth * 0.5) {
                                    /// Expand fully
                                    offset = sideBarWidth
                                    progress = 1
                                } else { /// reset value
                                    offset = 0
                                    progress = 0
                                }
                            }

                            /// Saving last drag offset
                            lastDragOffset = offset
                        }
                    }
                )
                .onChange(of: isLandscape) { _, newValue in
                    panGesture?.isEnabled = !newValue
                }
                .navigationDestination(for: String.self) { value in
                    Text("\(value) view")
                        .navigationTitle(value)
                }
                //            /// iOS 18 gesture API ignore view with buttons, tap gesture and long press gesture
                //            /// highPriorityGesture() or SimultaneousGesture() does not have this issue but do not work with scroll view
                //            /// UI\ikit UiPanGesture does not have the above issues
                //            .gesture(DragGesture()
                //                .onChanged({ value in
                //                    let translation = value.translation.width + lastDragOffset
                //                    offset = max(min(translation, sideBarWidth), 0)
                //
                //                    /// storing drag progress for fading tab view when dragging effect
                //                    progress = max(min(offset / sideBarWidth, 1), 0)
                //                }).onEnded({ value in
                //                    let velocity = value.translation.width / 3
                //
                //                    withAnimation(.snappy(duration: 0.25, extraBounce: 0)) {
                //                        if (velocity + offset) > (sideBarWidth * 0.5) {
                //                            /// Expand fully
                //                            offset = sideBarWidth
                //                            progress = 1
                //                        } else { /// reset value
                //                            offset = 0
                //                            progress = 0
                //                        }
                //                    }
                //
                //                    /// Saving last drag offset
                //                    lastDragOffset = offset
                //                }))
            }
        }
    }

    func toggleSideBar() {
        withAnimation(.snappy(duration: 0.25, extraBounce: 0)) {
            progress = 0
            offset = 0
            lastDragOffset = 0
        }
    }
}

#Preview {
    AdaptiveLayoutView()
}

private struct CustomGesture: UIGestureRecognizerRepresentable {
    var isEnabled: Bool
    var handle: (UIPanGestureRecognizer) -> Void
    func makeUIGestureRecognizer(context _: Context) -> UIPanGestureRecognizer {
        let gesture = UIPanGestureRecognizer()
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
}

struct AdaptiveView<Content: View>: View {
    var showsSideBarOniPadPortrait: Bool = true
    @ViewBuilder var content: (CGSize, Bool) -> Content
    @Environment(\.horizontalSizeClass) private var hClass
    var body: some View {
        GeometryReader {
            let size = $0.size
            let isLandscape = size.width > size.height || (
                hClass == .regular && showsSideBarOniPadPortrait
            )
            content(size, isLandscape)
        }
    }
}
