//
//  MessengerGradientEffectView.swift
//  animation
//
//  Learning point
//  ──────────────
//  Recreate Apple Messages' iconic per-bubble gradient: each user
//  message is filled with a SCREEN-WIDE linear gradient, but each
//  bubble shows only the part of that gradient corresponding to
//  its current screen position. As the user scrolls, the bubble's
//  colour shifts because what's "visible through the window" of
//  that bubble changes.
//
//  How it actually works (the trick)
//  ─────────────────────────────────
//  Naively painting `LinearGradient(...)` per bubble would give
//  every bubble the SAME gradient locally — they'd all look
//  identical. The clever bit is:
//
//    1. Render the gradient at FULL SCREEN size (not bubble size).
//    2. Mask it with a rounded rectangle THE SHAPE of the bubble,
//       offset by the bubble's screen position (`rect.minX,
//       rect.minY` from a `GeometryReader`).
//    3. Negate that offset on the rendered gradient so it stays
//       fixed in screen coordinates while the mask follows the
//       bubble.
//
//  Result: each bubble acts as a "window" onto the same global
//  gradient. As the bubble scrolls up the screen, the window
//  moves over different parts of the gradient — the bubble's
//  colour smoothly changes from purple→pink→orange.
//
//  Why we need both `screenProxy` AND a per-bubble GeometryReader
//  ──────────────────────────────────────────────────────────────
//    • `screenProxy` (passed in from the outer ScrollView) gives
//      total screen size + safe-area insets. We need this so the
//      gradient is rendered at FULL screen height regardless of
//      the bubble's own size.
//    • The inner `GeometryReader` gives the bubble's frame in
//      `.global` coords — that's what tells us where the "window"
//      should land in the gradient.
//
//  Math worth understanding
//  ────────────────────────
//      .mask(alignment: .topLeading) {
//          RoundedRectangle(cornerRadius: 15)
//              .frame(width: actualSize.width, height: actualSize.height)
//              .offset(x: rect.minX, y: rect.minY)  // mask = bubble shape at bubble position
//      }
//      .offset(x: -rect.minX, y: -rect.minY)        // gradient = anchored to top-left of screen
//      .frame(width: screenSize.width,
//             height: screenSize.height + safeArea.top + safeArea.bottom)
//
//  The key insight: `.mask` clips the gradient TO the bubble's
//  silhouette at its current screen position. The negative offset
//  on the gradient ensures the gradient itself doesn't move with
//  the bubble — only the mask does.
//
//  Key APIs
//  ────────
//  • `GeometryReader` + `frame(in: .global)` — read screen
//    position of a bubble.
//  • `.mask(alignment: ...) { ... }` — clip the gradient to the
//    bubble shape.
//  • Outer `GeometryReader` passed down as a parameter — share
//    one screen-size measurement across all bubbles instead of
//    re-measuring per cell.
//
//  How to apply
//  ────────────
//  Use anywhere you want a "gradient that flows across the whole
//  screen but only paints inside specific shapes" — chat bubbles,
//  card lists, animated lists with material accents.
//
//  See also
//  ────────
//  • MeshGradientView.swift — sister demo showing iOS 18+
//    MeshGradient for organic 2D gradients (no scroll-tied logic).
//

import SwiftUI

struct MessengerGradientEffectDemoView: View {
    var body: some View {
        NavigationStack {
            MessengerGradientEffectView()
                .navigationTitle("Messages")
        }
    }
}

struct MessengerGradientEffectView: View {
    var body: some View {
        GeometryReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(spacing: 15) {
                    ForEach(messages) { message in
                        MessageCardView(screenProxy: proxy, message: message)
                    }
                }
                .padding(15)
            }
        }
    }
}

struct MessageCardView: View {
    var screenProxy: GeometryProxy
    var message: Message
    var body: some View {
        Text(message.message)
            .padding(10)
            .foregroundStyle(message.isReply ? Color.primary : .white)
            .background {
                if message.isReply {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(.gray.opacity(0.3))
                } else {
                    GeometryReader {
                        let actualSize = $0.size
                        let rect = $0.frame(in: .global)
                        let screenSize = screenProxy.size
                        let safeArea = screenProxy.safeAreaInsets

                        Rectangle()
                            .fill(.linearGradient(colors: [
                                .pink,
                                .pink.opacity(0.8),
                                .purple,
                                .purple.opacity(0.8),
                                .yellow,
                                .orange,
                                .brown,
                            ], startPoint: .top, endPoint: .bottom))
                            .mask(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 15)
                                    .frame(
                                        width: actualSize.width,
                                        height: actualSize.height
                                    )
                                    .offset(x: rect.minX, y: rect.minY)
                            }
                            .offset(x: -rect.minX, y: -rect.minY)
                            .frame(
                                width: screenSize.width,
                                height: screenSize.height + safeArea.top + safeArea.bottom
                            )
                    }
                }
            }
            .frame(
                maxWidth: 250,
                alignment: message.isReply ? .leading : .trailing
            )
            .frame(
                maxWidth: .infinity,
                alignment: message.isReply ? .leading : .trailing
            )
    }
}

#Preview {
    MessengerGradientEffectDemoView()
}
