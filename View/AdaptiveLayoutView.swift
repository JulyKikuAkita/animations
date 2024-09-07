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
    /// Gesture Properties
    @State private var offset: CGFloat = .zero
    @State private var lastDragOffset: CGFloat = .zero
    @State private var progress: CGFloat = .zero

    var body: some View {
        
        GeometryReader {
            let size = $0.size
            let sideBarWidth: CGFloat = 250
            
            ZStack(alignment: .leading) {
                SideBarView()
                    .frame(width: sideBarWidth)
                    .offset(x: -sideBarWidth)
                    .offset(x: offset)
                
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
                .overlay {
                    Rectangle()
                        .fill(.black.opacity(0.25))
                        .ignoresSafeArea()
                        .opacity(progress)
                }
                .offset(x: offset)
            }
            .gesture(
                CustomGesture { gesture in
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

#Preview {
    AdaptiveLayoutView()
}

fileprivate struct CustomGesture:UIGestureRecognizerRepresentable {
    var handle: (UIPanGestureRecognizer) -> ()
    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let gesture = UIPanGestureRecognizer()
        return gesture
    }
    
    func updateUIGestureRecognizer(
        _ recognizer: UIPanGestureRecognizer,
        context: Context
    ) {
    }
    
    func handleUIGestureRecognizerAction(
        _ recognizer: UIPanGestureRecognizer,
        context: Context
    ) {
        handle(recognizer)
    }
}
