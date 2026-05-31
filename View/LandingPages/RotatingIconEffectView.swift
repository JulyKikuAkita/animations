//
//  RotatingIconEffectView.swift
//  animation
//
//  Standalone demo (not wired into the app's demo browser; preview-only).
//
//  Learning point
//  ──────────────
//  Button-driven sport-icon carousel with a deliberately staged,
//  multi-step transition. Tapping NEXT/BACK doesn't just swap the
//  centre icon — it choreographs three motions in sequence:
//
//    1. Active icon scales DOWN and fades; flanking icons reveal.
//    2. Stack ROTATES one slot left/right (`rotationEffect` on
//       the whole HStack).
//    3. New centre icon scales UP, with a 2nd `rotationEffect`
//       cancelling the parent rotation so the icon itself stays
//       upright.
//
//  Two `.rotationEffect` calls per icon are load-bearing: one
//  rotates the LAYOUT, the other counter-rotates the GLYPH so it
//  reads naturally even as the layout pivots underneath. Compare
//  with [[Paywall3DAnimation]] (also in this repo) which uses the
//  same counter-rotation trick on a 3D-tilted ring.
//
//  Animation chaining via `Task`
//  ─────────────────────────────
//  `updateItem(_:)` (around line ~126) uses `Task` + `Task.sleep`
//  to chain three `withAnimation` blocks back-to-back so one
//  finishes before the next starts. The inline comment about
//  "Swift 6 error" refers to the strict-concurrency requirement
//  that mutations on `@MainActor` state happen via `await
//  MainActor.run` or inside an actor-isolated context — the
//  `Task { @MainActor in ... }` shape addresses that.
//
//  Key APIs
//  ────────
//  • `.rotationEffect(_:)` ×2 per icon — layout vs. glyph rotation.
//  • `.scaleEffect(_, anchor:)` — anchored scale so icons appear
//    to grow from the centre slot.
//  • `.zIndex(_:)` — keeps the active icon above its neighbours.
//  • `Task { @MainActor in ... }` + `Task.sleep` — sequential
//    animation chaining without `withAnimation(_:completion:)`'s
//    closure pyramid.
//  • `.bouncy(duration:)` — spring curve with overshoot for the
//    "settle into centre" feel.
//
//  How to apply
//  ────────────
//  Reach for this when carousel transitions need to TEACH the user
//  about each item (sports onboarding, feature spotlight, category
//  picker). For scroll-driven instead of button-driven, see
//  [[InfiniteHorizontalScrollViewDemo]] — different interaction
//  model, similar visual outcome.
//
//  See also
//  ────────
//  • InfiniteHorizontalScrollViewDemo.swift — scroll-driven
//    sibling carousel; auto-advances.
//  • View/Carousel/* — the broader carousel zoo.
//  • View/3DAnimation/Paywall3DAnimation.swift — same
//    layout-vs-glyph counter-rotation trick on a 3D tilted ring.
//
import SwiftUI

struct RotatingIconEffectDemoView: View {
    /// View properties
    @State private var selectedSportItem: SportItem = sportItems.first!
    @State private var introSportItems: [SportItem] = sportItems
    @State private var activeIndex: Int = 0
    var body: some View {
        VStack(spacing: 0) {
            /// Back button
            Button {
                updateItem(isForward: false)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.bold())
                    .foregroundStyle(.green.gradient)
                    .contentShape(.rect)
            }
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            /// only visible from the second item
            .opacity(selectedSportItem.id != introSportItems.first?.id ? 1 : 0)

            /// Animated icons
            ZStack {
                ForEach(introSportItems) { item in
                    animatedIconView(item)
                }
            }
            .frame(height: 250)
            .frame(maxHeight: .infinity)

            VStack(spacing: 6) {
                /// Progress indicator
                HStack(spacing: 4) {
                    ForEach(introSportItems) { item in
                        Capsule()
                            .fill(selectedSportItem.id == item.id ? Color.primary : .gray)
                            .frame(width: selectedSportItem.id == item.id ? 25 : 4, height: 4)
                    }
                }
                Text(selectedSportItem.title)
                    .font(.title.bold())
                    .contentTransition(.numericText())

                Text("RotatingIconEffectView Demo")
                    .font(.caption2)
                    .foregroundStyle(.gray)

                /// Next/Continue button
                Button {
                    updateItem(isForward: true)
                } label: {
                    Text(selectedSportItem.id == introSportItems.last?.id ? "Continue" : "Next")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .frame(width: 250)
                        .padding(.vertical, 12)
                        .background(.green.gradient, in: .capsule)
                }
                .padding(.top, 25)
            }
            .multilineTextAlignment(.center)
            .frame(width: 300)
            .frame(maxHeight: .infinity)
        }
    }

    func animatedIconView(_ item: SportItem) -> some View {
        let isSelected = selectedSportItem.id == item.id
        return Image(systemName: item.image)
            .font(.system(size: 80))
            .foregroundStyle(.white.shadow(.drop(radius: 10)))
            .blendMode(.overlay)
            .frame(width: 120, height: 120)
            .background(.green.gradient, in: .rect(cornerRadius: 32))
            .background {
                RoundedRectangle(cornerRadius: 35)
                    .fill(.background)
                    .shadow(color: .primary.opacity(0.2), radius: 1, x: 1, y: 1)
                    .shadow(color: .primary.opacity(0.2), radius: 1, x: -1, y: -1)
                    .padding(-3)
                    .opacity(selectedSportItem.id == item.id ? 1 : 0)
            }
            /// Resetting rotation
            .rotationEffect(.init(degrees: -item.rotation))
            .scaleEffect(isSelected ? 1.1 : item.scale, anchor: item.anchor)
            .offset(x: item.offset)
            .rotationEffect(.init(degrees: item.rotation))
            /// placing the selected icon at the top
            .zIndex(isSelected ? 2 : item.zIndex)
    }

    /// shift the active icon to the center when continue or back button is pressed
    func updateItem(isForward: Bool) {
        guard isForward ? activeIndex != introSportItems.count - 1 : activeIndex != 0 else { return }
        var fromIndex: Int
        var extraOffset: CGFloat

        /// To Index
        if isForward {
            activeIndex += 1
        } else {
            activeIndex -= 1
        }

        /// From Index
        if isForward {
            fromIndex = activeIndex - 1
            extraOffset = introSportItems[activeIndex].extraOffset
        } else {
            extraOffset = introSportItems[activeIndex].extraOffset
            fromIndex = activeIndex + 1
        }

        /// Resetting zIndex
        for index in introSportItems.indices {
            introSportItems[index].zIndex = 0
        }

        /// Swift 6 error
        Task { [fromIndex, activeIndex] in
            withAnimation(.bouncy(duration: 1)) {
                introSportItems[fromIndex].scale = introSportItems[activeIndex].scale
                introSportItems[fromIndex].rotation = introSportItems[activeIndex].rotation
                introSportItems[fromIndex].anchor = introSportItems[activeIndex].anchor
                introSportItems[fromIndex].offset = introSportItems[activeIndex].offset

                /// Temporary adjustment
                introSportItems[activeIndex].offset = extraOffset

                /// when selected item is updated, the view pushed the from card all the way from the back by zIndex
                ///  To resolve this, make use of zIndex property to just place the from card below the to card
                ///  E.g., To card position: 2
                ///  From card position: 1, others 0
                introSportItems[fromIndex].zIndex = 1
            }

            try? await Task.sleep(for: .seconds(0.1))

            withAnimation(.bouncy(duration: 0.9)) {
                /// To location is always at the center
                introSportItems[activeIndex].scale = 1
                introSportItems[activeIndex].rotation = .zero
                introSportItems[activeIndex].anchor = .center
                introSportItems[activeIndex].offset = .zero

                /// Updating selected item
                selectedSportItem = introSportItems[activeIndex]
            }
        }
    }
}

#Preview {
    RotatingIconEffectDemoView()
}
