//
//  BlurEffectSearchBarView.swift
//  animation
//
//  Learning points / Demo goals:
//  1. Make header sticky on top of a ScrollView using `safeAreaInset(edge: .top)`.
//  2. Fade the header out as the user scrolls (drive `progress` from scroll offset).
//  2.1 Caveat: when the header height shrinks during scroll, the content jumps faster than the finger.
//      Fix: counter-offset the content by the same amount the header lost (here: 75pt) and
//      add `.padding(.bottom, 75)` so the content end is preserved.
//  3. Expandable search bar driven by `@FocusState` — corners/edges animate when focus toggles.
//
//  Key SwiftUI APIs to study here:
//  • `onScrollGeometryChange` (iOS 18+) — read live scroll offset without `GeometryReader` hacks.
//  • Custom `ScrollTargetBehavior` — snap the header to either fully-shown or fully-hidden state.
//  • `visualEffect { content, proxy in ... }` — apply geometry-driven offsets without invalidating layout.
//  • `ProgressiveBlurView` (UIViewRepresentable) — reuse system blur with filters removed.
//

import SwiftUI

struct BlurEffectSearchBarDemoView: View {
    var body: some View {
        BlurEffectSearchBarView()
    }
}

struct BlurEffectSearchBarView: View {
    /// View Properties
    @State private var searchText: String = ""
    @State private var progress: CGFloat = 0
    @FocusState private var isFocused: Bool // TODO: 7:11

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 15) {
                ForEach(firstSetCards) { item in
                    cardView(item)
                }
            }
            .padding(15)
            .offset(y: isFocused ? 0 : progress * 75) // address 2.1
            .padding(.bottom, 75) // address 2.1
            .animation(.snappy(duration: 0.3, extraBounce: 0), value: isFocused)
            .safeAreaInset(edge: .top, spacing: 0) {
                resizableHeader()
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(CustomScrollTarget())
        .onScrollGeometryChange(for: CGFloat.self) {
            // Tip: include `contentInsets.top` so progress is 0 at the
            // true resting position (safe-area + inset aware), not just contentOffset.
            $0.contentOffset.y + $0.contentInsets.top
        } action: { _, newValue in
            /// ResizableHeader height 60 + bottom padding 15 = 75 (the divisor below)
            /// `clamp(0...1)` pattern: max(min(value, upper), lower).
            progress = max(min(newValue / 75, 1), 0)
        }
    }

    @ViewBuilder
    // swiftlint:disable:next function_body_length
    func resizableHeader() -> some View {
        let progress = isFocused ? 1 : progress
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome Back")
                        .font(.callout)
                        .foregroundStyle(.gray)

                    Text("Nanachi")
                        .font(.title.bold())
                }

                Spacer(minLength: 0)

                /// Profile Button
                Button {} label: {
                    Image("fox")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(.circle)
                }
            }
            .frame(height: 60 - (60 * progress), alignment: .bottom)
            .padding(.horizontal, 15)
            .padding(.top, 15)
            .padding(.bottom, 15 - (15 * progress))
            .opacity(1 - progress)
            .offset(y: -10 * progress)

            /// Floating Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")

                TextField("Search Photo", text: $searchText)
                    .focused($isFocused)

                /// Microphone Button
                Button {} label: {
                    Image(systemName: "microphone.fill")
                        .foregroundStyle(Color.red)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 15)
            .background {
                RoundedRectangle(cornerRadius: isFocused ? 0 : 30)
                    .fill(.background
                        .shadow(.drop(color: .black.opacity(0.08), radius: 5, x: 5, y: 5))
                        .shadow(.drop(color: .black.opacity(0.05), radius: 5, x: -5, y: -5))
                    )
                    .padding(
                        .top, isFocused ? -100 : 0
                    ) // roughly to let background fill the top space + safe areas
            }
            .padding(.horizontal, isFocused ? 0 : 15)
            .padding(.bottom, 10)
            .padding(.top, 5)
        }
        .background {
            ProgressiveBlurView()
                .blur(radius: isFocused ? 0 : 10)
                .padding(.horizontal, -15)
                .padding(.bottom, -10)
                .padding(.top, -100)
        }
        .visualEffect { content, proxy in
            content
                .offset(y: offsetY(proxy))
        }
    }

    /// Tip: `visualEffect` gives access to a `GeometryProxy` without needing a wrapping
    /// `GeometryReader` (which would otherwise eat layout space). Use the
    /// `.scrollView(axis:)` coordinate space to read offset relative to the scroll content.
    private func offsetY(_ proxy: GeometryProxy) -> CGFloat {
        let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
        // When focused, lock the header to the top by cancelling overscroll;
        // when scrolled past zero (minY < 0), pull header up to keep it pinned.
        return minY > 0 ? (isFocused ? -minY : 0) : -minY
    }

    @ViewBuilder
    func cardView(_ item: Card) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader {
                let size = $0.size

                Image(item.image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipShape(.rect(cornerRadius: 20))
            }
            .frame(height: 220)

            Text("By: \(item.title)")
                .font(.callout)
                .foregroundStyle(.primary.secondary)
        }
    }
}

/// Tip: a custom `ScrollTargetBehavior` is the modern way (iOS 17+) to "snap" a scroll
/// to a discrete target after a drag/fling. Use it to avoid leaving the header in a half-collapsed state.
/// Mid-zone (40..<75) snaps to the collapsed position (75); below 40 snaps back to the top.
private struct CustomScrollTarget: ScrollTargetBehavior {
    func updateTarget(_ target: inout ScrollTarget, context _: TargetContext) {
        let endPoint = target.rect.minY

        if endPoint < 75 {
            if endPoint > 40 {
                target.rect.origin = .init(x: 0, y: 75)
            } else {
                target.rect.origin = .zero
            }
        }
    }
}

#Preview {
    BlurEffectSearchBarDemoView()
}
