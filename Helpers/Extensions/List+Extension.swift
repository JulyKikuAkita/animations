//
//  List+Extension.swift
//  animation
//
//  Created on 7/11/26.
//
//  Learning point
//  ──────────────
//  A pull-to-refresh where the indicator is a "gooey" blob that grows out
//  of the Dynamic Island: as you pull, a black circle drops from the pill
//  and the two fuse into one liquid shape (metaball morph), then a spinner
//  fades in once the pull is deep enough. The native `.refreshable` still
//  drives the refresh — this only replaces the *visual*.
//
//  Mechanics — the layer stack is the whole trick
//  ──────────────────────────────────────────────
//    1. `compositingGroup()` on the pill + black circle flattens them into
//       ONE alpha layer. Only then do the next two modifiers see them as a
//       single shape rather than two independent views.
//    2. `.blur` smears that combined alpha into soft gradients; the
//       `alphaV2Threshold` shader (`.visualEffect` → `layerEffect`) snaps
//       the gradient back to a hard edge. Where the pill's and circle's
//       faded edges overlap, their alpha sums past the threshold and the
//       gap reads as solid — that is the metaball "fuse". Blur shrinks to 0
//       as the pull completes, so the blob resolves into crisp shapes.
//       (See AlphaThreshold.metal for the shader's math.)
//    3. TWO `.overlay(.bottom)` layers use the SAME size/offset on purpose:
//       the FIRST (black `Circle`) sits INSIDE the compositing group, so it
//       feeds the blur+threshold and becomes part of the goo. The SECOND
//       (the `ProgressView` spinner) is added AFTER the shader, so it stays
//       sharp and rides on top of the finished blob, fading in near the end
//       of the pull.
//    4. Outer `.mask { Rectangle().ignoresSafeArea() }` clips the whole
//       content+overlay composite to the screen rect. The morphing overlay
//       deliberately bleeds up into the status-bar / island region with
//       `ignoresSafeArea()`; the mask bounds that bleed so it composites
//       cleanly instead of drawing over system chrome.
//
//  Key APIs
//  ────────
//  • `.refreshable` — still owns the async refresh; the morph is cosmetic.
//  • `onScrollGeometryChange` — turns pull distance into 0→1 `scrollProgress`
//    that drives blur, offset, indicator size, and spinner fade.
//  • `compositingGroup()` + `.blur` + `.visualEffect`/`layerEffect` — the
//    metaball recipe: flatten → smear alpha → threshold.
//  • `RefreshControlTintUpdater` (`UIViewRepresentable`) — walks the private
//    UIScrollView hierarchy to tint the native `UIRefreshControl`.
//
//  How to apply
//  ────────────
//  Reach for this when you want a branded refresh indicator anchored to the
//  Dynamic Island. The two-overlay split (one inside the goo, one above it)
//  is the reusable idea: composite what should fuse, layer sharp UI on top.
//
//  Note: `morphingRefreshable` needs no `@ViewBuilder`/`@ContentBuilder` —
//  its body is a single `modifier(...)` expression, so a result builder
//  would be a no-op here (unlike the generic `content` properties elsewhere
//  in the project, where the builder is load-bearing).
//
//  See also
//  ────────
//  • AlphaThreshold.metal — the threshold shader and why blur must precede it.
//  • MetaballAnimation_iOS26.swift — the same fuse effect on plain shapes.
//
import SwiftUI

extension List {
    func morphingRefreshable(onRefresh: @escaping () async -> Void) -> some View {
        modifier(MorphingRefreshableModifier(onRefresh: onRefresh))
    }
}

extension ScrollView {
    func morphingRefreshable(onRefresh: @escaping () async -> Void) -> some View {
        modifier(MorphingRefreshableModifier(onRefresh: onRefresh))
    }
}

private struct MorphingRefreshableModifier: ViewModifier {
    var onRefresh: () async -> Void
    /// View Properties
    @State private var scrollProgress: CGFloat = 0
    @State private var isRefreshing: Bool = false
    @State private var isAnimating: Bool = false
    @State private var tintColor: Color = .gray
    @State private var isTintUpdateAvailable: Bool = false
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .background(RefreshControlTintUpdater(color: $tintColor) {
                isTintUpdateAvailable = $0
            })
            /// Flatten the content so the top overlay + mask below composite
            /// against a single layer rather than the raw List/ScrollView.
            .compositingGroup()
            .overlay(alignment: .top) {
                GeometryReader {
                    let safeArea = $0.safeAreaInsets
                    /// A bare status bar / Dynamic Island tops out around the
                    /// iPhone Air's 68pt inset; 70 is the buffer above it.
                    let iPhoneAirSafeAreaHeightBuffer: CGFloat = 70.0

                    ZStack {
                        /// Only morph against a plain top inset. A larger inset
                        /// means a nav bar (or similar) sits there, so hide the
                        /// blob rather than draw it under that chrome.
                        if safeArea.top < iPhoneAirSafeAreaHeightBuffer, scrollProgress != 0 {
                            morphingView(safeArea)
                        }
                    }
                    .ignoresSafeArea()
                }
                .frame(height: 1)
                .allowsHitTesting(false)
            }
            /// Bounds the `ignoresSafeArea` overlay above to the screen rect so
            /// its bleed into the status-bar region composites cleanly.
            .mask {
                Rectangle()
                    .ignoresSafeArea()
            }
            /// The native refresh still runs; the morphing blob is layered on top.
            .refreshable {
                isRefreshing = true
                await onRefresh()
                isAnimating = true

                /// Retract the blob on our own clock instead of waiting for the
                /// next scroll-geometry callback (which may lag the refresh end).
                withAnimation(.easeInOut(duration: 0.2), completionCriteria: .logicallyComplete) {
                    /// Animate to ~0 (not exactly 0): 0 would drop the view
                    /// instantly via the `scrollProgress != 0` guard above.
                    scrollProgress = 0.01
                } completion: {
                    scrollProgress = 0
                    isAnimating = false
                }
                isRefreshing = false
            }
            .onScrollGeometryChange(for: CGFloat.self) {
                $0.contentOffset.y + $0.contentInsets.top
            } action: { _, newValue in
                /// Map the top 60pt of overscroll to 0→1.
                let progress = max(min(-newValue / 60, 1), 0)
                /// While retracting (isAnimating) let the completion handler own
                /// the value; pin to 1 during refresh so the blob stays formed.
                if !isAnimating {
                    scrollProgress = isRefreshing ? 1 : progress
                }
            }
    }

    private func morphingView(_ safeArea: EdgeInsets) -> some View {
        /// Dynamic Island devices report a top inset of ~59pt or more.
        let hasDynamicIsland = safeArea.top >= 59
        /// Notch/older devices lack the island, so drop the circle a little
        /// further to clear the status bar.
        let extraScrollOffset = hasDynamicIsland ? 0 : 15.0
        /// How far the circle travels down as you pull, scaled by progress.
        let scrollOffset = (safeArea.top < 35 ?
            (safeArea.top + 35 + 15) :
            (safeArea.top + extraScrollOffset)) * scrollProgress
        let blurRadius = 25.0

        /// Transparent spacer sized to the top inset — the canvas the blob is
        /// pinned within (centered under the island, or top-aligned without it).
        return Rectangle()
            .fill(.clear)
            .frame(height: safeArea.top)
            .overlay(alignment: hasDynamicIsland ? .center : .top) {
                /// The island's fitting size is ~120×36; we go slightly smaller
                /// so the pill never bleeds past the real island cutout.
                Capsule()
                    .fill(.black)
                    .frame(width: 100, height: 33)
                    /// Hide while backgrounded so it doesn't ghost in the app switcher.
                    .opacity(scenePhase == .active ? 1 : 0)
                    /// Trim the pill's top edge so the blob only ever grows
                    /// downward, out from under the island.
                    .mask {
                        Capsule()
                            .padding(.top, 5)
                    }
                    /// LAYER 1 (inside the goo): the black circle that drops from
                    /// the pill. Being before `compositingGroup` + blur + shader,
                    /// it fuses with the pill into one metaball shape.
                    .overlay(alignment: .bottom) {
                        let indicatorSize = 30 + (scrollProgress * 10)
                        Circle()
                            .fill(.black)
                            .frame(width: indicatorSize, height: indicatorSize)
                            .offset(y: scrollOffset)
                    }
                    /// Flatten pill + circle into a single alpha layer so the
                    /// blur/threshold pair below acts on their combined shape.
                    .compositingGroup()
                    /// Smear alpha at rest, sharpen to 0 as the pull completes.
                    .blur(radius: blurRadius - (blurRadius * scrollProgress))
                    /// Snap the blurred alpha back to a hard edge → the fuse.
                    /// Disabled at full pull (progress == 1) where blur is 0 and
                    /// the shapes are already crisp, so the shader adds nothing.
                    .visualEffect { [scrollProgress] content, proxy in
                        content
                            .layerEffect(
                                ShaderLibrary.alphaV2Threshold(),
                                maxSampleOffset: proxy.size,
                                isEnabled: scrollProgress != 1
                            )
                    }
                    /// LAYER 2 (above the goo): the real spinner. Added AFTER the
                    /// shader so it stays sharp; same size/offset as the circle so
                    /// it lands on the fused blob, fading in over the last 20% of
                    /// the pull.
                    .overlay(alignment: .bottom) {
                        let indicatorSize = 30 + (scrollProgress * 10)
                        let indicatorOpacity = scrollProgress > 0.8 ? (scrollProgress - 0.8) / 0.2 : 0

                        ProgressView()
                            .tint(.white)
                            .controlSize(.small)
                            .opacity(indicatorOpacity)
                            .frame(width: indicatorSize, height: indicatorSize)
                            .offset(y: scrollOffset)
                    }
                    /// Nudge up on short status bars so the pill aligns with the cutout.
                    .offset(y: safeArea.top < 35 ? -35 : 0)
            }
            .opacity(0.4)
    }
}

/// Updating refresh control tint color
private struct RefreshControlTintUpdater: UIViewRepresentable {
    @Binding var color: Color
    /// Fallback check
    var result: (Bool) -> Void
    func makeUIView(context _: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        updateTint(view)
        return view
    }

    func updateUIView(_ uiView: UIView, context _: Context) {
        updateTint(uiView)
    }

    private func updateTint(_ view: UIView) {
        DispatchQueue.main.async {
            if let compositingGroup = view.superview?.superview,
               let scrollview = compositingGroup.subviews.last?.subviews.last as? UIScrollView
            {
                scrollview.refreshControl?.tintColor = UIColor(color)
                result(true)
            } else {
                result(false)
            }
        }
    }
}
