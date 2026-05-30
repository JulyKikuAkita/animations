//
//  ExpandableMusicPlayerView.swift
//  animation
//
//  ⚠️  Reusable component. Consumed by
//      [[View/OverlayView/UniversalOverlayView+AppleMusicMiniPlaer]]
//      as the floating mini-player in a `UniversalOverlay` host.
//      Don't rename or remove without updating that file.
//
//  TODO: Cleanup candidates
//        1. The `resizeWindow(_:)` helper (line ~181) reaches into
//           `UIApplication.shared.connectedScenes.first.keyWindow.subviews.first`
//           and applies a `CGAffineTransform` to scale the
//           underlying app content. This is a private-implementation-
//           detail trap — the chain assumes a specific UIWindow
//           subview hierarchy that Apple may restructure. Same risk
//           profile as `View/Carousel/InfiniteLoopingScrollView.swift`.
//           If Apple ever ships a public API for "scale the content
//           behind me," migrate.
//        2. Inline note "personal preference (not work in preview)"
//           at line ~188 — accurate, but a one-liner explaining
//           WHY (no real `UIWindow` in preview canvas) would help
//           future readers. Or move the corner-radius write behind
//           `if !ProcessInfo.processInfo.isPreviewing`.
//
//  Learning point
//  ──────────────
//  Apple-Music-style fullscreen player: tap a small pill-shaped
//  bar at the bottom and it expands to fill the screen WHILE THE
//  HOME SCREEN BEHIND IT TILTS AND SHRINKS — the iconic Apple Music
//  trick. Drag down to dismiss; mid-drag, the underlying app
//  un-shrinks proportionally so the dismiss feels physical.
//
//  Two layers of motion driven by ONE drag gesture:
//    1. **The player itself** — `expandPlayer: Bool` toggles
//       chrome (corner radius, color gradient), a separate
//       `offsetY` tracks live drag distance. Standard drag-dismiss
//       mechanics with velocity-aware threshold.
//    2. **The host app behind the player** — `resizeWindow(_:)`
//       reaches up to the keyWindow's first subview (the SwiftUI
//       host) and applies a `CGAffineTransform` to scale + offset
//       it. As the user drags down, `windowProgress` decreases
//       from 0.1 → 0, smoothly returning the host to its native
//       size. On dismiss, `resetResizeWindow()` un-does the
//       transform via `UIView.animate`.
//
//  Why bridge to UIKit?
//  ───────────────────
//  SwiftUI doesn't expose the host UIWindow's transform. To get
//  the iOS-system Music-app's "tilting home screen" feel, you have
//  to reach through `UIApplication.shared.connectedScenes`. There
//  is no SwiftUI-native equivalent today.
//
//  Velocity-aware dismiss
//  ──────────────────────
//  `.onEnd { ... let velocity = value.velocity.height / 5 }` plus
//  the threshold check `if (translation + velocity) > size.height * 0.5`
//  — a flick dismisses even on a small actual translation. Same
//  trick used in [[MiniPlayerView]] and
//  [[View/CustomMenu/PopOutMenuView]].
//
//  Key APIs
//  ────────
//  • Custom `PanGesture` (project helper at
//    `Gesture/PanGesture.swift`) — wraps `UIPanGestureRecognizer`
//    via `UIGestureRecognizerRepresentable`. Used here because
//    SwiftUI's `DragGesture` doesn't deliver `velocity.height`
//    cleanly across the gesture lifecycle.
//  • `UIApplication.shared.connectedScenes` chain — the load-
//    bearing reach-through to find the host window.
//  • `CALayer.cornerRadius` + `mainWindow.layer.masksToBounds = true`
//    — applies rounded-corner clipping on the host's UIView layer
//    while the player is expanded.
//  • `UIView.animate(withDuration:)` — used INSTEAD of SwiftUI's
//    `withAnimation` for the un-resize because we're animating a
//    UIKit transform, not a SwiftUI value.
//  • `@Namespace private var animation` — declared but used by
//    the `miniPlayer` ↔ `expandedPlayer` content swap.
//
//  How to apply
//  ────────────
//  Reach for this when the brief literally says "make it feel like
//  Apple Music." Otherwise [[MiniPlayerView]] (in the same folder)
//  is simpler and doesn't reach through UIKit. The window-resize
//  trick is the part that matters; lift `resizeWindow` /
//  `resetResizeWindow` if you want to apply the same effect in
//  another expanding-overlay UI.
//
//  See also
//  ────────
//  • View/OverlayView/UniversalOverlayView+AppleMusicMiniPlaer.swift
//    — the consumer; embeds this view inside the `UniversalOverlay`
//    host so it sits above NavigationStack / Sheet boundaries.
//  • View/MiniPlayerView/MiniPlayerView.swift — sibling demo
//    designed for tab-bar-integrated playback (no UIWindow tilt,
//    different host model). Compare and contrast.
//  • Gesture/PanGesture.swift — the UIKit pan-gesture bridge.
//
import SwiftUI

struct ExpandableMusicPlayerView: View {
    @Binding var show: Bool

    /// View Properties
    @State private var expandPlayer: Bool = false
    @State private var offsetY: CGFloat = 0
    @State private var mainWindow: UIWindow?
    @State private var windowProgress: CGFloat = 0
    @Namespace private var animation
    var body: some View {
        GeometryReader {
            let size = $0.size
            let safeArea = $0.safeAreaInsets

            ZStack(alignment: .top) {
                ZStack {
                    /// miniplayer background
                    Rectangle()
                        .fill(.orange.gradient)

                    /// background
                    Rectangle()
                        .fill(
                            .linearGradient(
                                colors: [.pink, .orange],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .opacity(expandPlayer ? 1 : 0)
                }
                .clipShape(.rect(cornerRadius: expandPlayer ? 45 : 15))
                .frame(height: expandPlayer ? nil : 55)
                .shadow(color: .primary.opacity(0.06), radius: 5, x: 5, y: 5)
                .shadow(color: .primary.opacity(0.05), radius: 5, x: -5, y: -5)

                miniPlayer()
                    .opacity(expandPlayer ? 0 : 1)

                expandedPlayer(size, safeArea)
                    .opacity(expandPlayer ? 1 : 0)
            }
            .frame(height: expandPlayer ? nil : 55, alignment: .top)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, expandPlayer ? 0 : safeArea.bottom + 55)
            .padding(.horizontal, expandPlayer ? 0 : 15)
            .offset(y: offsetY)
            .gesture(
                PanGesture { value in
                    guard expandPlayer else { return }
                    let translation = max(value.translation.height, 0)
                    offsetY = translation
                    windowProgress = max(min(translation / size.height, 1), 0) * 0.1

                    resizeWindow(0.1 - windowProgress)
                } onEnd: { value in
                    guard expandPlayer else { return }
                    let translation = max(value.translation.height, 0)
                    let velocity = value.velocity.height / 5

                    withAnimation(.smooth(duration: 0.3, extraBounce: 0)) {
                        if (translation + velocity) > (size.height * 0.5) {
                            expandPlayer = false

                            /// reset resize Window to identity
                            resetResizeWindow()
                        } else { /// reset resize Window to 0.1
                            UIView.animate(withDuration: 0.3) {
                                resizeWindow(0.1)
                            }
                        }
                    }
                    offsetY = 0
                }
            ) /// draggable on image area
            .ignoresSafeArea()
        }
        .onAppear {
            if let window = (
                UIApplication.shared.connectedScenes.first as? UIWindowScene
            )?.keyWindow, mainWindow == nil {
                mainWindow = window
            }
        }
    }

    @ViewBuilder
    func miniPlayer() -> some View {
        HStack(spacing: 12) {
            ZStack {
                if !expandPlayer {
                    Image(.fox)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(.rect(cornerRadius: 10))
                        .matchedGeometryEffect(id: "Artwork", in: animation)
                }
            }
            .frame(width: 45, height: 45)

            Text("Fox")

            Spacer(minLength: 0)

            Group {
                Button("", systemImage: "play.fill") {}

                Button("", systemImage: "forward.fill") {}
            }
            .font(.title3)
            .foregroundStyle(.primary)
        }
        .padding(.horizontal, 10)
        .frame(height: 55)
        .contentShape(.rect)
        .onTapGesture {
            withAnimation(.smooth(duration: 0.3, extraBounce: 0)) {
                expandPlayer = true
            }

            /// reset resize Window to 0.1
            UIView.animate(withDuration: 0.3) {
                resizeWindow(0.1)
            }
        }
    }

    @ViewBuilder
    func expandedPlayer(_: CGSize, _ safeArea: EdgeInsets) -> some View {
        VStack(spacing: 12) {
            Capsule()
                .fill(.white.secondary)
                .frame(width: 35, height: 5)
                .offset(y: -10)

            /// Sample Player View
            HStack(spacing: 12) {
                ZStack {
                    if expandPlayer {
                        Image(.fox)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipShape(.rect(cornerRadius: 10))
                            .matchedGeometryEffect(id: "Artwork", in: animation)
                            .transition(.offset(y: 1))
                    }
                }
                .frame(width: 80, height: 80)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Fox")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    Text("Fox tale")
                        .font(.caption2)
                        .foregroundStyle(.white.secondary)
                }

                Spacer(minLength: 0)

                HStack {
                    Button("", systemImage: "star.circle.fill") {}

                    Button("", systemImage: "ellipsis.circle.fill") {}
                }
                .foregroundStyle(.white, .white.tertiary)
                .font(.title2)
            }
        }
        .padding(15)
        .padding(.top, safeArea.top)
    }

    func resizeWindow(_ progress: CGFloat) {
        /// first subview of keyWindow is swift app content
        /// then sheets/full screen covers, inspectors etc
        /// [min, max] of progress value is [0.1, 0.9]
        if let mainWindow = mainWindow?.subviews.first {
            let offsetY = (mainWindow.frame.height * progress) / 2

            /// personal preference (not work in preview)
            mainWindow.layer.cornerRadius = (progress / 0.1) * 30
            mainWindow.layer.masksToBounds = true

            mainWindow.subviews.first?.transform = .identity
                .scaledBy(x: 1 - progress, y: 1 - progress)
                .translatedBy(x: 0, y: offsetY)
        }
    }

    func resetResizeWindow() {
        if let mainWindow = mainWindow?.subviews.first {
            UIView.animate(withDuration: 0.3) {
                mainWindow.layer.cornerRadius = 0
                mainWindow.transform = .identity
            }
        }
    }
}

#Preview {
    RootView {
        UniversalOverlayAppleMiniPlayerDemoView()
    }
}
