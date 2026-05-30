//
//  InteractiveNavigationGestureView.swift
//  animation
//
//  Learning point
//  ──────────────
//  Bridge UIKit's INTERACTIVE POP GESTURE (the edge-swipe-back) into
//  SwiftUI so the bottom tab bar can morph IN PROGRESS with the swipe:
//  inactive icons blur and shrink as the user swipes back to root, and
//  fully restore once the pop completes. Keeps the visual feedback
//  truthful to where the gesture actually is — not a binary appear/
//  disappear at the end.
//
//  The trick: walk to the hosting `UINavigationController` via
//  `.viewExtractor`, attach a target/action to its
//  `interactivePopGestureRecognizer`, and read
//  `transitionCoordinator?.percentComplete` on each callback. SwiftUI
//  `NavigationPath` alone can't expose this — it only fires AFTER
//  the transition resolves.
//
//  Key APIs
//  ────────
//  • `@Observable class NavigationHelper: NSObject, UIGestureRecognizerDelegate`
//    — owns `popProgress: CGFloat` (0...1). All visual modifiers read
//    from this single source.
//  • `controller.interactivePopGestureRecognizer?.addTarget(_:action:)`
//    — UIKit target/action attached to the system pop gesture.
//  • `controller.transitionCoordinator?.percentComplete` — the live
//    progress signal during the swipe.
//  • `gestureRecognizerShouldBegin(_:)` — overridden so the pop gesture
//    works even when the navigation bar is hidden.
//  • `.viewExtractor` (project helper, UIViewRepresentable) — finds
//    the parent `UINavigationController` from a SwiftUI `NavigationStack`.
//  • SwiftUI side: `.blur(radius:)` + `.scaleEffect(_:)` driven by
//    `(1 - popProgress)` for inactive tabs.
//
//  How to apply
//  ────────────
//  Use when ANY part of the UI should move WITH a back-swipe (parallax
//  headers, breadcrumb fades, tab-bar reveals). The same helper class
//  pattern generalizes — `popProgress` is just one signal, you can
//  expose more.
//
//  See also
//  ────────
//  • iOS26/CustomToolBarIOS26.swift — uses scroll progress instead of
//    pop progress to drive a similar in-flight morph.
//

import SwiftUI

@Observable
class NavigationHelper: NSObject, UIGestureRecognizerDelegate {
    var path: NavigationPath = .init()
    var popProgress: CGFloat = 1.0
    /// UINavigationController properties
    private var isAdded: Bool = false
    private var navController: UINavigationController?
    func addPopGestureListener(_ controller: UINavigationController) {
        guard !isAdded else { return }
        controller.interactivePopGestureRecognizer?.addTarget(self, action: #selector(didInteractivePopGestureChange))
        navController = controller
        controller.interactivePopGestureRecognizer?.delegate = self /// hide tool bar
        isAdded = true
    }

    /// we use UINavigationController to get the view pop progress for fade in fade out animation
    /// we want fade in/out animation only on root view
    /// use SwiftUI Path didn't work as this is UIKit view callback
    @objc
    func didInteractivePopGestureChange() {
        if let completeProfess = navController?.transitionCoordinator?.percentComplete,
           let state = navController?.interactivePopGestureRecognizer?.state,
           navController?.viewControllers.count == 1
        {
            popProgress = completeProfess

            if state == .ended || state == .cancelled {
                if completeProfess > 0.5 {
                    popProgress = 1 /// pop view
                } else {
                    /// reset
                    popProgress = 0
                }
            }
        }
    }

    /// enable interactive pop gesture even with navigation bar is hidden
    func gestureRecognizerShouldBegin(_: UIGestureRecognizer) -> Bool {
        navController?.viewControllers.count ?? 0 > 1
    }
}

struct InteractiveNavigationGestureDemoView: View {
    var navigationHelper: NavigationHelper = .init()
    var body: some View {
        VStack(spacing: 0) {
            @Bindable var bindableHelper = navigationHelper
            NavigationStack(path: $bindableHelper.path) {
                List {
                    Button {
                        navigationHelper.path.append("Fox")
                    } label: {
                        Text("Fox tail")
                            .foregroundStyle(.primary)
                    }
                }
                .navigationTitle("Home")
                .navigationDestination(for: String.self) { navTitle in
                    Button {
                        navigationHelper.path.append("More Fox")
                    } label: {
                        Text("More Fox tail")
                            .foregroundStyle(.primary)
                    }
                    .navigationTitle(navTitle)
                    .toolbarVisibility(.hidden, for: .navigationBar)
                }
            }
            .viewExtractor {
                if let navController = $0.next as? UINavigationController {
                    navigationHelper.addPopGestureListener(navController)
                }
            }

            CustomBottomBar()
        }
        .environment(navigationHelper)
    }
}

struct CustomBottomBar: View {
    @Environment(NavigationHelper.self) private var navigationHelper
    @State private var selectedTab: TabiOS17 = .chat
    var body: some View {
        HStack(spacing: 0) {
            let blur = (1 - navigationHelper.popProgress) * 3
            let scale = (1 - navigationHelper.popProgress) * 0.1
            ForEach(TabiOS17.allCases, id: \.rawValue) { tab in
                Button {
                    if tab == .apps {
                    } else {
                        selectedTab = tab
                    }
                } label: {
                    Image(systemName: tab.rawValue)
                        .font(.title3)
                        .foregroundStyle(selectedTab == tab || tab == .apps ? Color.primary : Color.gray)
                        .blur(radius: tab != .apps ? blur : 0)
                        .scaleEffect(tab == .apps ? 1.5 : 1 - scale)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .contentShape(.rect)
                }
                .opacity(tab != .photos ? navigationHelper.popProgress : 1)
                .overlay {
                    ZStack {
                        if tab == .notifications {
                            Button {} label: {
                                Image(systemName: "exclamationmark.bubble")
                                    .font(.title3)
                                    .foregroundStyle(Color.primary)
                            }
                        }

                        if tab == .profile {
                            Button {} label: {
                                Image(systemName: "ellipsis")
                                    .font(.title3)
                                    .foregroundStyle(Color.primary)
                            }
                        }
                    }
                    .opacity(1 - navigationHelper.popProgress)
                }
            }
        }
        .onChange(of: navigationHelper.path) { oldValue, newValue in
            guard newValue.isEmpty || oldValue.isEmpty else { return }
            if newValue.count > oldValue.count { // push view
                navigationHelper.popProgress = 0.0
            } else { // pop view
                navigationHelper.popProgress = 1.0
            }
        }
        .animation(.easeInOut(duration: 0.25), value: navigationHelper.popProgress)
    }
}

#Preview {
    InteractiveNavigationGestureDemoView()
        .preferredColorScheme(.dark)
}
