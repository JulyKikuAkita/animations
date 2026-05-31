//
//  ScrollToHideHeaderView.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//  iOS 18+ — gated by `@available(iOS 18.0, *)` (line ~6).
//
//  Learning point
//  ──────────────
//  Lightest of the CustomHeaderEffect siblings: header simply
//  HIDES on scroll-down and REVEALS on scroll-up. No morph, no
//  glass material, no gesture coordination — just a direction
//  read on `onScrollGeometryChange` and a clamped `.offset(y:)`
//  driving `safeAreaInset(edge: .top)`.
//
//  Mechanics
//  ─────────
//    1. `onScrollGeometryChange` reads `contentOffset.y`.
//    2. Compare against the previous offset to infer direction.
//    3. Past a small threshold, slide the header in/out via
//       `.offset(y:)` clamped between 0 and `-headerHeight`.
//    4. `onScrollPhaseChange` snaps the header to fully-hidden or
//       fully-visible at scroll settle (no in-between rest state).
//
//  Key APIs
//  ────────
//  • `@available(iOS 18.0, *)` — relies on iOS 18 scroll-geometry
//    semantics.
//  • `onScrollGeometryChange` — live direction read.
//  • `onScrollPhaseChange` — snap-to-state on settle.
//  • `safeAreaInset(edge: .top)` with dynamic offset — the pinned-
//    but-translatable host.
//
//  How to apply
//  ────────────
//  Use as the lightest "Safari-style hide-on-scroll" pattern you
//  can ship. For morph, fade, glass chrome, or per-tab sync,
//  reach for the heavier siblings.
//
//  See also
//  ────────
//  • ResizableHeaderScrollView.swift — gesture-driven collapse.
//  • ResizableHeaderIOS26View.swift — Liquid Glass + snap.
//  • ResizableHeaderScrollViewiOS26.swift — generic progress-
//    driven collapse (filename misleads — no iOS 26 APIs).
//
import SwiftUI

@available(iOS 18.0, *)
struct ScrollToHideHeaderView: View {
    /// View properties
    @State private var naturalScrollOffset: CGFloat = 0
    @State private var lastNatureOffset: CGFloat = 0
    @State private var headerOffset: CGFloat = 0
    @State private var isScrollingUp: Bool = false
    var body: some View {
        GeometryReader {
            let safeArea = $0.safeAreaInsets
            let headerHeight = 60 + safeArea.top

            ScrollView(.vertical) {
                LazyVStack(spacing: 15) {
                    ForEach(1 ... 50, id: \.self) { _ in
                        DummyCardView()
                    }
                }
                .padding(15)
            }
            #if DEBUG
            .overlay(content: {
                    Text("\(naturalScrollOffset) \(headerHeight)") // debug
                })
            #endif
                .safeAreaInset(edge: .top, spacing: 0) {
                    headerView()
                        .padding(.bottom, 15)
                        .frame(height: headerHeight, alignment: .bottom)
                        .background(.background)
                        .offset(y: -headerOffset)
                }
                .onScrollGeometryChange(for: CGFloat.self) { proxy in
                    let maxHeight = proxy.contentSize.height - proxy.containerSize.height
                    return max(min(proxy.contentOffset.y + headerHeight, maxHeight), 0) // fix bounce header view hidden
                } action: { oldValue, newValue in
                    let isScrollingUp = oldValue < newValue
                    headerOffset = min(
                        max(newValue - lastNatureOffset, 0),
                        headerHeight
                    )
                    self.isScrollingUp = isScrollingUp

                    naturalScrollOffset = newValue
                }
                .onScrollPhaseChange { _, newPhase, _ in
                    // when user stop scrolling and header animation is in between state
                    if !newPhase.isScrolling,
                       headerOffset != 0 || headerOffset != headerHeight
                    {
                        withAnimation(.snappy(duration: 0.25, extraBounce: 0)) {
                            if headerOffset > (headerHeight * 0.5), naturalScrollOffset > headerHeight {
                                headerOffset = headerHeight
                            } else {
                                headerOffset = 0
                            }
                            lastNatureOffset = naturalScrollOffset - headerOffset
                        }
                    }
                }
                // show/hide header view based on scroll direction
                .onChange(of: isScrollingUp) { _, _ in
                    lastNatureOffset = naturalScrollOffset - headerOffset
                }
                .ignoresSafeArea(.container, edges: .top)
        }
    }

    func headerView() -> some View {
        HStack(spacing: 20) {
            Image("fox")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 25)

            Spacer(minLength: 0)

            Button("", systemImage: "airplayvideo") {}

            Button("", systemImage: "bell") {}

            Button("", systemImage: "magnifyingglass") {}
        }
        .font(.title2)
        .foregroundStyle(Color.primary)
        .padding(.horizontal, 15)
    }
}

#Preview {
    if #available(iOS 18.0, *) {
        ScrollToHideHeaderView()
            .preferredColorScheme(.dark)
    } else {
        // Fallback on earlier versions
    }
}
