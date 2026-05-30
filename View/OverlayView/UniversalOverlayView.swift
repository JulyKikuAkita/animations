//
//  UniversalOverlayView.swift
//  animation
//
//  ⚠️  HEAVILY-CONSUMED INFRASTRUCTURE FILE. Defines `RootView` and
//      the `View.universalOverlay(show:content:)` extension — the
//      project's standard pattern for presenting content ABOVE the
//      SwiftUI view hierarchy (above NavigationStack, sheets,
//      fullScreenCover, etc.).
//
//      Known consumers:
//        • View/OverlayView/UniversalOverlayView+AppleMusicMiniPlayer.swift
//        • View/MiniPlayerView/ExpandableMusicPlayerView.swift (preview)
//        • Helpers/Layout/CustomToast.swift
//        • (probably more — grep `RootView {` and `.universalOverlay`)
//      Don't rename or break the public surface (`RootView`,
//      `universalOverlay`, `UniversalOverlayProperties`) without
//      auditing all call sites.
//
//  TODO: Cleanup candidates
//        1. The commented-out drag-clamp block in `FloatingVideoPlayerView`
//           (lines ~86–92) clamps `offset.height` to `[0, size.height-250]`,
//           but the active code at line ~94 always SNAPS to bottom
//           (`max(size.height-250, 0)`). Confirm intent: if "always
//           snap to bottom" is the desired behaviour, delete the
//           commented block; if the user should be able to drop the
//           player anywhere vertically, restore the clamp.
//        2. Stale comment "not working for iOS 18 and above"
//           on `PassthroughWindow` (line ~180) — the code below it
//           has an `if #available(iOS 18, *)` branch that DOES work.
//           Either delete the stale comment or update it to reflect
//           that iOS 18 needs the alternate hit-test logic.
//
//  Learning point
//  ──────────────
//  Implements the "true overlay" pattern in SwiftUI: a content view
//  that floats above ALL the standard presentation surfaces (sheets,
//  alerts, NavigationStack), driven by a simple `@Binding var show:
//  Bool`. The trick is that SwiftUI's own overlays/sheets all sit
//  inside the same UIWindow as the host view, so they can mask each
//  other. To get UNCONDITIONAL "always on top," we need a SECOND
//  UIWindow.
//
//  Architecture
//  ────────────
//  Three pieces, in order of how they wire together:
//    1. `RootView<Content>` — wraps the app's content view. On
//       `.onAppear`, finds the active `UIWindowScene` and creates
//       a SECOND `PassthroughWindow` on top of the SwiftUI window.
//       Installs a `UIHostingController(rootView: UniversalOverlayViews())`
//       as that window's root view controller. Stores the window
//       handle in a shared `UniversalOverlayProperties` (`@Observable`)
//       which is injected via `.environment(...)`.
//    2. `UniversalOverlayProperties` — the bridge. Owns the window
//       reference and a `[OverlayView]` array. Any caller that wants
//       to show overlay content appends to the array; the
//       `UniversalOverlayViews` (root of the second window) renders
//       it in a ZStack.
//    3. `View.universalOverlay(show:content:)` — the public API.
//       A `@Binding<Bool>` toggles the overlay on/off; on toggle,
//       the modifier appends/removes from
//       `properties.views`. Each overlay gets a UUID so multiple
//       can coexist.
//
//  Why a custom `PassthroughWindow`?
//  ────────────────────────────────
//  By default, a second UIWindow steals all touch events — so the
//  user can't tap anything in the underlying app. `PassthroughWindow`
//  overrides `hitTest(_:with:)` to return `nil` for taps that DON'T
//  hit one of the overlay's child views, letting those events fall
//  through to the original window. The iOS 18 branch is needed
//  because SwiftUI's view tree changed; the older simple
//  "hitView == rootView ? nil : hitView" is wrong on iOS 18+.
//
//  Caveat (kept from the original inline comment): the host view's
//  `@State` properties don't propagate INTO the overlay — pass a
//  `Binding` or use an `@Environment(@Observable)` shared model.
//  This is because the overlay content is hosted by a SEPARATE
//  `UIHostingController` and doesn't inherit the original view's
//  environment.
//
//  Key APIs
//  ────────
//  • `UIWindowScene` + custom `UIWindow` subclass — the load-bearing
//    UIKit reach-through. There is no SwiftUI-native equivalent for
//    "render above all sheets."
//  • `UIHostingController(rootView:)` — embeds the SwiftUI overlay
//    `ZStack` inside the second window.
//  • `@Observable` `UniversalOverlayProperties` — shared state
//    bridge between the host hierarchy and the overlay window.
//  • `hitTest(_:with:)` override — the trick that makes the second
//    window pass through unrelated touches.
//
//  How to apply
//  ────────────
//  1. Wrap the app's root scene in `RootView { yourApp }`.
//  2. On any view, attach `.universalOverlay(show: $bool) { yourOverlay }`.
//  3. Toggle the bool to show/hide.
//  Use ONLY when you need "above sheets and alerts" semantics —
//  if a regular `.overlay` or `.sheet` works, use that; this pattern
//  is heavier (extra window, UIKit reach-through).
//
//  See also
//  ────────
//  • View/OverlayView/UniversalOverlayView+AppleMusicMiniPlaer.swift
//    — companion demo using this infrastructure for the
//    Apple-Music-style mini-player.
//  • View/MiniPlayerView/ExpandableMusicPlayerView.swift —
//    consumer in its preview.
//  • Helpers/Layout/CustomToast.swift — toast helper that uses
//    `RootView` for above-everything-else toast presentation.
//
import AVKit
import SwiftUI

struct UniversalOverlayDemoView: View {
    @State private var show: Bool = false
    @State private var showSheet: Bool = false
    @State private var showMiniPlayer: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Button("Floating Video Player") {
                    show.toggle()
                }
                /// current view's state properties does not work in the universal overlay wrapper
                /// instead, pass binding or pass observable Object using environment object
                .universalOverlay(show: $show) {
                    FloatingVideoPlayerView(show: $show)
                }

                Button("Dummy Sheet") {
                    showSheet.toggle()
                }

                Button("MiniPlayer Demo") {
                    showMiniPlayer.toggle()
                }
                .universalOverlay(show: $showMiniPlayer) {
                    ExpandableMusicPlayerView(show: $showMiniPlayer)
                }
            }
            .navigationTitle("Universal Overlay")
            .sheet(isPresented: $showSheet) {
                Text("placeholder")
            }
        }
    }
}

struct FloatingVideoPlayerView: View {
    /// View Properties
    @Binding var show: Bool
    @State private var player: AVPlayer?
    @State private var offset: CGSize = .zero
    @State private var lastStoredOffset: CGSize = .zero

    var body: some View {
        GeometryReader {
            let size = $0.size

            Group {
                if videoURL != nil {
                    VideoPlayer(player: player)
                        .background(.black)
                        .clipShape(.rect(cornerRadius: 25))
                } else {
                    RoundedRectangle(cornerRadius: 25)
                }
            }
            .frame(height: 250)
            .offset(offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let transition = value.translation + lastStoredOffset
                        offset = transition
                    }.onEnded { _ in
                        withAnimation(.bouncy) {
                            /// limiting movement within the screen
                            offset.width = 0

//                            if offset.height < 0 {
//                                offset.height = 0
//                            }
//
//                            if offset.height > (size.height - 250) {
//                                offset.height = (size.height - 250)
//                            }

                            offset.height = max(size.height - 250, 0)
                            lastStoredOffset = offset
                        }
                    }
            )
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .padding(.horizontal, 15)
        .transition(.blurReplace)
        .onAppear {
            if let videoURL {
                player = AVPlayer(url: videoURL)
                player?.play()
            }
        }
    }

    var videoURL: URL? {
        if let bundle = Bundle.main.path(forResource: "Reel1", ofType: "mp4") {
            return .init(filePath: bundle)
        }
        return nil
    }
}

private extension CGSize {
    static func + (lhs: CGSize, rhs: CGSize) -> CGSize {
        .init(
            width: lhs.width + rhs.width,
            height: lhs.height + rhs.height
        )
    }
}

private struct UniversalOverlayViewModifier<ViewContent: View>: ViewModifier {
    var animation: Animation
    @Binding var show: Bool
    @ViewBuilder var viewContent: ViewContent

    /// Local View Properties
    @Environment(UniversalOverlayProperties.self) private var properties
    @State private var viewID: String?

    func body(content: Content) -> some View {
        content
            .onChange(of: show) { _, newValue in
                if newValue {
                    addView()
                } else {
                    removeView()
                }
            }
    }

    private func addView() {
        if properties.window != nil, viewID == nil {
            viewID = UUID().uuidString
            guard let viewID else { return }

            withAnimation(animation) {
                properties.views
                    .append(.init(id: viewID, view: .init(viewContent)))
            }
        }
    }

    private func removeView() {
        if let viewID {
            withAnimation(animation) {
                properties.views.removeAll(where: { $0.id == viewID })
            }
        }
    }
}

private struct UniversalOverlayViews: View {
    @Environment(UniversalOverlayProperties.self) private var properties
    var body: some View {
        ZStack {
            ForEach(properties.views) {
                $0.view
            }
        }
    }
}

/// not working for iOS 18 and above
private class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event),
              let rootView = rootViewController?.view else { return nil }

        if #available(iOS 18, *) {
            for subview in rootView.subviews.reversed() {
                /// Finding if any of root view's receiving hit test
                let pointInSubView = subview.convert(point, from: rootView)
                if subview.hitTest(pointInSubView, with: event) == subview {
                    return hitView
                }
            }

            return nil
        } else {
            return hitView == rootView ? nil : hitView
        }
    }
}

/// Shared universal overlay properties
@Observable
class UniversalOverlayProperties {
    var window: UIWindow?
    var views: [OverlayView] = []

    struct OverlayView: Identifiable {
        var id: String = UUID().uuidString
        var view: AnyView
    }
}

/// Root View Wrapper to place views on top of the SwiftUI app
///  by crating an overlay window on top of the active key window
/// the demo app need to wrap the entry view with this wrapper
struct RootView<Content: View>: View {
    @ViewBuilder var content: Content
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }

    private var properties = UniversalOverlayProperties()

    var body: some View {
        content
            .environment(properties)
            .onAppear {
                if let windowScene = (UIApplication.shared.connectedScenes.first as? UIWindowScene),
                   properties.window == nil
                // swiftlint:disable:next opening_brace
                {
                    let window = PassthroughWindow(windowScene: windowScene) // for interacting with overlay view
                    window.isHidden = false
                    window.isUserInteractionEnabled = true
                    /// setup swift based root view controller
                    let rootViewController = UIHostingController(rootView:
                        UniversalOverlayViews()
                            .environment(properties)
                    )
                    rootViewController.view.backgroundColor = .clear
                    window.rootViewController = rootViewController
                    properties.window = window
                }
            }
    }
}

#Preview {
    RootView {
        UniversalOverlayDemoView()
    }
}

extension View {
    @ViewBuilder
    func universalOverlay(
        animation: Animation = .snappy,
        show: Binding<Bool>,
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        modifier(
            UniversalOverlayViewModifier(
                animation: animation,
                show: show,
                viewContent: content
            )
        )
    }
}
