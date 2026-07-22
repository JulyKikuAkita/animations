//
//  WallpaperStackedScrollView.swift
//  animation

// Learning notes (see WallpaperStackView below for detail):
// - Multi-flag animation state machine: scaleUp/expand/remove are staggered, not combined,
//   so layout, scroll-unlock, and height collapse can each settle at a different animation phase.
// - DispatchWorkItem: a cancellable handle around a delayed closure, used so a rapid re-trigger
//   can cancel a still-pending phase-2 step instead of letting stale state fire late.
// - AnyLayout: swaps ZStack <-> VStack at runtime based on state, driven by the same animation.

import SwiftUI

@available(iOS 26.0, *)
struct WallpaperStackedScrollDemo: View {
    @State private var showWallpapers: Bool = false
    @Namespace private var animation
    var body: some View {
        VStack {
            Text("ADD NEW")
                .fontWeight(.medium)

            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .fill(.fill.tertiary)
                    .aspectRatio(0.452, contentMode: .fit)
            }

            VStack {
                Text("7:77")
                    .font(.system(size: 90, weight: .medium, design: .rounded))
                    .padding(.top, 40)
                    .blendMode(.softLight)

                Spacer(minLength: 0)
            }

            Button {
                showWallpapers.toggle()
            } label: {
                Image(systemName: "plus")
                    .font(.title2)
                    .fontWeight(.medium)
                    .frame(width: 25, height: 25)
            }
            .buttonStyle(.glass)
            .matchedTransitionSource(id: "VIEW", in: animation)
        }
        .padding(50)
        .fullScreenCover(isPresented: $showWallpapers) {
            WallpaperPackView()
                .navigationTransition(.zoom(sourceID: "VIEW", in: animation))
        }
    }
}

@available(iOS 26.0, *)
struct WallpaperPackView: View {
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 30) {
                ForEach(packs) { pack in
                    WallpaperStackedRowView(pack: pack)
                }
            }
        }
        .scrollIndicators(.hidden)
        .safeAreaPadding(.horizontal, 25)
        .safeAreaPadding(.vertical, 30)
    }
}

@available(iOS 26.0, *)
struct WallpaperStackedRowView: View {
    var pack: WallpaperPack
    /// View Properties
    @State private var toggle: Bool = false

    var body: some View {
        WallpaperStackView(title: pack.title, description: pack.description, trigger: toggle) {
            ForEach(pack.imageSets, id: \.self) { wallpaper in
                Rectangle()
                    .foregroundStyle(.clear)
                    .overlay {
                        Image(wallpaper)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
            }
        } buttonView: {
            Button {
                toggle.toggle()
            } label: {
                if toggle {
                    Image(systemName: "xmark")
                        .frame(height: 25)
                } else {
                    Text("GET")
                }
            }
            .fontWeight(.medium)
            .buttonStyle(.borderedProminent)
            .tint(.gray.opacity(0.35))
            .buttonSizing(.flexible)
            .frame(maxWidth: toggle ? 20 : 80)
        }
    }
}

@available(iOS 26.0, *)
#Preview {
    WallpaperStackedScrollDemo()
        .preferredColorScheme(.dark)
}

@available(iOS 26.0, *)
#Preview {
    WallpaperPackView()
        .preferredColorScheme(.dark)
}

struct WallpaperStackView<Content: View, ButtonView: View>: View {
    var title: String
    var description: String
    /// covert toggle
    var trigger: Bool = false
    var minimizeWallpaperSize: CGSize = .init(width: 81, height: 176)
    var expandedWallpaperSize: CGSize = .init(width: 111, height: 241)
    @ContentBuilder var content: Content
    @ContentBuilder var buttonView: ButtonView

    /// View Properties
    /// `scaleUp`, `expand`, and `remove` are staggered rather than combined into one Bool because
    /// the layout change (ZStack -> VStack), the scroll-interaction unlock, and the collapse/expand
    /// of height all need to settle at different points in the spring vs. easeInOut animations below.
    @State private var scaleUp: Bool = false
    @State private var expand: Bool = false
    @State private var remove: Bool = false
    @State private var contentExpandedHeight: CGFloat = 0
    @State private var isExpanded: Bool = false
    /// `DispatchWorkItem` wraps a closure scheduled on GCD (here via `DispatchQueue.main.asyncAfter`)
    /// so it can be cancelled before it runs — a plain closure passed straight to `asyncAfter` has no
    /// handle to cancel once queued. `.cancel()` only stops it if it hasn't started executing yet;
    /// it can't interrupt work already in flight, which is fine here since main-thread closures run
    /// to completion anyway.
    /// Stored so the *next* trigger can cancel a still-pending phase-2 step from the *previous*
    /// trigger. Without this, spamming the toggle mid-animation queues multiple delayed closures, and
    /// an old one (e.g. a stale `expand = true` from an open that got interrupted by a close) can fire
    /// after newer state has already moved on, corrupting the animation.
    @State private var animationTask: DispatchWorkItem?

    var body: some View {
        /// Collapsed state overlays the title/description on top of the wallpaper stack (ZStack);
        /// expanded state stacks them vertically (VStack) above the full-size wallpaper grid.
        let layout = scaleUp ? AnyLayout(VStackLayout(alignment: .leading, spacing: 15)) : AnyLayout(ZStackLayout(alignment: .leading))

        layout {
            if !remove {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(title)
                            .font(.title.bold())
                            .lineLimit(1)

                        Spacer(minLength: 0)

                        /// this size change will cause animation stutter, switch to overlay
//                        if scaleUp {
//                            buttonView
//                        }
                    }
                    /// button padding
                    .padding(.trailing, scaleUp ? 50 : 0)
                    .overlay(alignment: .trailing) {
                        if scaleUp {
                            buttonView
                        }
                    }

                    /// Text effect
                    Group {
                        if scaleUp {
                            Text(description)
                                .lineLimit(2)
                                .transition(.blurReplace)
                        } else {
                            Text(description)
                                .lineLimit(3)
                                .transition(.blurReplace)
                        }
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)

                    if !scaleUp {
                        buttonView
                            .transition(.identity)
                    }
                }
                .padding(.leading, scaleUp ? 0 : minimizeWallpaperSize.width + 60)
                .transition(
                    .blurReplace
                        .combined(with: .move(edge: scaleUp ? .trailing : .leading))
                )
            }

            if !remove {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 18) {
                        Group(subviews: content) { collection in
                            ForEach(collection.prefix(scaleUp ? collection.count : 3)) { subview in
                                let index = collection.firstIndex(where: { $0.id == subview.id }) ?? 0

                                subview
                                    .frame(width: width, height: height)
                                    .visualEffect { [scaleUp, expand] content, proxy in
                                        let minX = proxy.frame(in: .scrollView).minX
                                        return content
                                            // Shrinks and steps each card back to fan a deck effect when collapsed.
                                            .scaleEffect(
                                                scaleUp ? 1 : 1 - (CGFloat(index) * 0.1),
                                                anchor: .trailing
                                            )
                                            .offset(x: scaleUp ? 0 : CGFloat(index) * 10)
                                            // Parallax counter-scroll: full-speed while opening (still fanned),
                                            // half-speed once expanded so cards drift rather than snap past.
                                            .offset(x: expand ? minX / 2 : -minX)
                                    }
                                    // Only the first 3 are rendered while collapsed (see .prefix above);
                                    // the rest exist once scaleUp expands the ForEach but stay invisible
                                    // until `expand` catches up, so they don't pop in ahead of the animation.
                                    .opacity(index > 2 ? (expand ? 1 : 0) : 1)
                                    .zIndex(Double(-index))
                            }
                        }
                    }
                }
                .frame(height: height)
                .allowsHitTesting(expand)
                .transition(
                    .blurReplace
                        .combined(with: .move(edge: scaleUp ? .leading : .trailing))
                )
            }
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onGeometryChange(for: CGFloat.self) { geometry in
            geometry.size.height
        } action: { newValue in
            // Only sample height while content is present; `remove` blanks the content but the
            // row's own frame keeps using this last-known height until the collapse animation below
            // has room to shrink it.
            if !remove {
                contentExpandedHeight = newValue
            }
        }
        .frame(minHeight: remove ? contentExpandedHeight : minimizeWallpaperSize.height)
        .onChange(of: trigger) { _, _ in
            isExpanded.toggle()
            /// cancel existing animation task
            animationTask?.cancel()
            animationTask = nil
            if isExpanded {
                // Phase 1: spring the layout/scale change immediately.
                withAnimation(.interpolatingSpring(duration: 0.35, bounce: 0, initialVelocity: 0)) {
                    remove = false
                    scaleUp = true
                }

                // Phase 2: unlock scroll (`expand`) only after the spring has mostly settled (0.32s,
                // just short of the 0.35s spring), so the horizontal scroll gesture doesn't fight the
                // still-animating card positions.
                animationTask = .init {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        expand = true
                    }
                }

                guard let animationTask else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.32, execute: animationTask)
            } else {
                // Phase 1: fade/collapse the content out while the row still holds its expanded
                // height (see the frame(minHeight:) above), so the row shrinks after the content is gone
                // instead of the content visibly getting squashed.
                withAnimation(.easeInOut(duration: 0.25)) {
                    remove = true
                }

                animationTask = .init {
                    scaleUp = false
                    expand = false
                    // Phase 2: re-add the content (now collapsed) one frame after `remove` cleared,
                    // then animate the row's height down to the minimized size.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            remove = false
                        }
                    }
                }

                guard let animationTask else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: animationTask)
            }
        }
    }

    private var width: CGFloat {
        scaleUp ? expandedWallpaperSize.width : minimizeWallpaperSize.width
    }

    private var height: CGFloat {
        scaleUp ? expandedWallpaperSize.height : minimizeWallpaperSize.height
    }
}
