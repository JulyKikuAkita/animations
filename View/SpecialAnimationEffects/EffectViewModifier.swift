//
//  EffectViewModifier.swift
//  animation
//
//  Learning point
//  ──────────────
//  Workshop file showing how the file-local `.modifiers { ... }`
//  helper eliminates "duplicated subtree" code when a single view
//  needs to switch between mutually-exclusive modifier branches
//  based on state (e.g. picking between `.symbolEffect(.bounce)` /
//  `.symbolEffect(.breathe)` / `.symbolEffect(.pulse)` /
//  `.symbolEffect(.rotate)`).
//
//  The two structs in this file demonstrate the before/after:
//    • `EffectViewModifierDemo` — uses `.modifiers { content in ... switch ... }`
//      to apply a different modifier per state, with the underlying
//      `Image` (or `Rectangle`) declared ONCE.
//    • `EffectViewModifierDuplicatedCode` — the naive alternative,
//      where the entire `Image(systemName: "heart.fill")` chain is
//      repeated four times, once per branch. Same visual result,
//      4x the code, 4x the maintenance.
//
//  How the helper works
//  ────────────────────
//      func modifiers<Output: View>(@ViewBuilder content: @escaping (Self) -> Output) -> some View {
//          content(self)
//      }
//
//  It just calls the closure with `self`, returning the closure's
//  output as the view body. By being `@ViewBuilder`, the closure
//  can contain any SwiftUI control-flow (`if/else`, `switch`),
//  which would otherwise be illegal in a modifier chain. Crucially,
//  this preserves view IDENTITY across branches — meaning state,
//  animation, and `matchedGeometryEffect` survive the modifier
//  swap.
//
//  Why this beats `if/else` at the call site
//  ─────────────────────────────────────────
//  Each branch in the duplicated version creates a new view IDENTITY
//  in SwiftUI's diff. Switching branches resets `@State`, breaks
//  matchedGeometry, and cancels in-flight transitions. With
//  `.modifiers { ... }` the host view is the SAME instance — only
//  the modifier chain swaps.
//
//  Key APIs
//  ────────
//  • `@ViewBuilder` closure with `Self` argument — preserve identity
//    while branching modifier chains.
//  • Swift's `switch` works inside `@ViewBuilder` closures (iOS 14+).
//  • `.symbolEffect(.bounce / .breathe / .pulse / .rotate)` — iOS 17+
//    SF Symbol motion modifiers.
//
//  How to apply
//  ────────────
//  Drop the `modifiers { ... }` helper anywhere you need to choose
//  modifiers based on a state value: `.fill(...)` colour, `.scaleEffect`,
//  custom modifiers, even completely different chains. Reach for it
//  whenever you find yourself copy-pasting a base view across
//  if/else branches.
//
//  See also
//  ────────
//  • View/TextEffectView/MarqueeTextView.swift — uses the same
//    `modifiers { ... }` helper to gate marquee animation on overflow.
//

import SwiftUI

private enum Effect: String, CaseIterable {
    case bounce = "Bounce"
    case breath = "Breath"
    case pulse = "Pulse"
    case rotate = "Rotate"
}

/// switch animation without any duplicated code
struct EffectViewModifierDemo: View {
    @State private var effect: Effect = .bounce
    var body: some View {
        Group {
            Picker("", selection: $effect) {
                ForEach(Effect.allCases, id: \.rawValue) {
                    Text($0.rawValue)
                        .tag($0)
                }
            }
            .pickerStyle(.segmented)
            .padding(15)

            VStack {
                Image(systemName: "heart.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.red.gradient)
                    .modifiers { image in
                        switch effect {
                        case .bounce:
                            image.symbolEffect(.bounce)
                        case .breath:
                            image.symbolEffect(.breathe)
                        case .pulse:
                            image.symbolEffect(.pulse)
                        case .rotate:
                            image.symbolEffect(.rotate)
                        }
                    }

                Rectangle()
                    .modifiers { rectangle in
                        switch effect {
                        case .bounce: rectangle.fill(.blue)
                        case .breath: rectangle.fill(.pink)
                        case .pulse: rectangle.fill(.orange)
                        case .rotate: rectangle.fill(.gray)
                        }
                    }
                    .frame(width: 50, height: 20)
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func modifiers(@ViewBuilder content: @escaping (Self) -> some View) -> some View {
        /// since we are passing self, we can also utilize fill() modifier
        content(self)
    }
}

#Preview {
    EffectViewModifierDemo()
}

/// if without view modifier we'll need a lot of duplicated code to achieve the same result
struct EffectViewModifierDuplicatedCode: View {
    @State private var effect: Effect = .bounce
    var body: some View {
        Group {
            if effect == .bounce {
                Image(systemName: "heart.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.red.gradient)
                    .symbolEffect(.bounce)
            } else if effect == .breath {
                Image(systemName: "heart.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.red.gradient)
                    .symbolEffect(.breathe)
            } else if effect == .pulse {
                Image(systemName: "heart.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.red.gradient)
                    .symbolEffect(.pulse)
            } else {
                Image(systemName: "heart.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.red.gradient)
                    .symbolEffect(.rotate)
            }
        }
    }
}
