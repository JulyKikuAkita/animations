//
//  Skeleton + Redacted Demo .swift
//  animation
//
//  Learning point
//  ──────────────
//  Demo for the **shape-substitution** approach to skeletons: instead
//  of redacting a real view, swap each leaf for a `SkeletonView(.rect)`
//  while data is loading, then swap back when the data arrives. Shows
//  three subtle UX details:
//
//    1. **Empty-state vs. loaded-state branching at the leaf level.**
//       Each text/image leaf has its own `if let card { ... } else { SkeletonView(...) }`
//       so the layout structure (frames, paddings, alignment) is
//       identical in both states. No layout shift when data arrives.
//    2. **`.scrollDisabled(cards.isEmpty)`** — disable scrolling while
//       loading, since there's nothing to scroll past. Prevents the
//       skeleton bars from being scrollable into nonsense positions.
//    3. **Tap-to-load fake.** `.onTapGesture { withAnimation(.smooth) { cards = [...] } }`
//       — wraps the data swap in a smooth animation so the skeleton →
//       real content transition crossfades naturally.
//
//  Why the demo uses the shape-skeleton approach (not the
//  redacted-modifier approach)
//  ─────────────────────────────────────────────────────────
//  Two valid strategies in this folder:
//
//    • **Shape-substitution** (this file + `SkeletonView`) — simpler,
//      lets you control each placeholder's shape independently
//      (rounded corners on text, full rect on image). More verbose at
//      call sites.
//    • **Redacted-modifier** (`SkeletonViewModifier`) — drop-in:
//      `.skeleton(isRedacted: isLoading)` on the real view. Less code
//      at the call site, less control over per-leaf shape (relies on
//      `.redacted(.placeholder)` to draw the bars).
//
//  Reach for shape-substitution when each placeholder needs custom
//  geometry. Reach for the redacted modifier when you want a
//  one-liner for a complex existing view.
//
//  Key APIs
//  ────────
//  • `SkeletonView(_ shape:_ color:)` — see `[[SkeletonView]]`.
//  • `withAnimation(.smooth)` — system animation curve for swap.
//  • `.scrollDisabled(_:)` — gate scrolling per state.
//
//  See also
//  ────────
//  • SkeletonView.swift — the shimmering shape primitive.
//  • SkeletonViewModifier.swift — the redacted-modifier alternative.
//
import SwiftUI

struct SkeletonViewDemo: View {
    @State private var isLoading: Bool = false
    @State private var cards: [Card] = []
    var body: some View {
        ScrollView {
            VStack {
                if cards.isEmpty {
                    ForEach(0 ..< 3, id: \.self) { _ in
                        CardPlacerHolderView()
                    }
                } else {
                    ForEach(cards) { card in
                        CardPlacerHolderView(card: card)
                    }
                }
            }
            .padding(20)
        }
        .scrollDisabled(cards.isEmpty)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .onTapGesture {
            withAnimation(.smooth) {
                cards = [.init(
                    image: "fox",
                    title: "Redacted Demo Card",
                    subTitle: "From June 9th 2025"
                )]
            }
        }
    }
}

/// Tip: the layout-stable card pattern.
/// Even when `card == nil`, the outer `Rectangle().frame(height: 220)`
/// reserves the same vertical slot as the loaded image — so when data
/// arrives, the surrounding layout doesn't reflow. Same trick applies
/// to the text rows below: each Skeleton uses an explicit `frame`
/// matching the eventual rendered text height.
struct CardPlacerHolderView: View {
    var card: Card?
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Rectangle()
                .foregroundStyle(.clear)
                .overlay {
                    if let card {
                        Image(card.image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)

                    } else {
                        SkeletonView(.rect)
                    }
                }
                .frame(height: 220)
                .clipped()

            VStack(alignment: .leading, spacing: 6) {
                if let card {
                    Text(card.title)
                        .fontWeight(.semibold)
                } else {
                    SkeletonView(.rect(cornerRadius: 5))
                        .frame(height: 20)
                }

                Group {
                    if let card {
                        Text(card.subTitle)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    } else {
                        SkeletonView(.rect(cornerRadius: 5))
                            .frame(height: 20)
                    }
                }
                .padding(.trailing, 30)

                ZStack {
                    if card != nil {
                        Text(dummyDescription)
                            .font(.caption)
                            .foregroundStyle(.gray)
                    } else {
                        SkeletonView(.rect(cornerRadius: 5))
                    }
                }
                .frame(height: 50)
                .lineLimit(3)
            }
            .padding([.horizontal, .top], 15)
            .padding(.bottom, 25)
        }
        .background(.background)
        .clipShape(.rect(cornerRadius: 15))
        .shadow(color: .black.opacity(0.1), radius: 10)
    }
}

#Preview {
    SkeletonViewDemo()
}
