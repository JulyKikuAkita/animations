//
//  SlideToCancelText.swift
//  animation
//
//  Created on 1/23/26.
//
//  Learning point
//  ──────────────
//  WhatsApp / Telegram-style "‹ Slide to cancel" hint that loops
//  forever during voice recording. The text is grey-out by default;
//  a thin BRIGHT BAND moves across it left → right → left,
//  highlighting characters as it passes. Used as a passive
//  affordance during voice memos to remind the user how to abort.
//
//  How the shimmer is built (the trick)
//  ────────────────────────────────────
//  Two copies of the same content are stacked:
//    • Bottom layer — `viewContent().foregroundStyle(.gray.secondary)`
//      (the grey "rest" state).
//    • Top layer — `viewContent().foregroundStyle(.primary)`
//      (the bright state) MASKED by a vertical bar.
//
//  The mask is a single 15pt-wide rectangle, blurred by 5pt for
//  soft edges, that animates its X offset from `+30` (just past
//  the right edge) to `-size.width * 1.1` (well past the left
//  edge), with `.repeatForever(autoreverses: false)`. Wherever the
//  mask is opaque, the user sees the BRIGHT layer through it; the
//  rest stays grey.
//
//  Why `compositingGroup()` matters
//  ────────────────────────────────
//  Without it, the mask would clip each leaf inside `viewContent`
//  separately, and the chevron + text could shimmer at slightly
//  different times. `compositingGroup` flattens the foreground
//  copy first, so the bright band sweeps both icons and text as
//  ONE unit.
//
//  Why `linear(duration: 3).repeatForever(autoreverses: false)`
//  ────────────────────────────────────────────────────────────
//    • Linear — the band moves at constant speed (no ease at
//      ends), which reads as "passively rolling."
//    • `autoreverses: false` — the band always moves the SAME
//      direction; on reaching the far end it teleports back to
//      start. Avoids the awkward bounce of `autoreverses: true`.
//
//  About the `CustomTrashCanView` companion
//  ────────────────────────────────────────
//  Sister widget shown next to the slide hint in the demo: a
//  stylised trash-can icon with a lid that opens (rotates -90° at
//  the bottom-leading anchor) when the user has dragged far
//  enough to cancel. Same compositingGroup trick to animate lid
//  + body together.
//
//  Key APIs
//  ────────
//  • `.mask { GeometryReader { ... rectangle.offset(...) } }` —
//    motion-driven mask = shimmer.
//  • `.repeatForever(autoreverses: false)` — one-direction loop.
//  • `compositingGroup()` — flatten before mask/blur for whole-
//    block animation cohesion.
//  • `withAnimation(.linear(duration: 3).repeatForever) { ... }`
//    inside `.onAppear` — one-shot animation kick.
//
//  How to apply
//  ────────────
//  Use anywhere you want a "this is the affordance, please notice
//  it" passive shimmer hint. Voice recording, drag-to-action
//  hints, Apple-Pay confirmations, scan tutorials. Pair with a
//  drag gesture on a sibling button.
//
//  See also
//  ────────
//  • TextFieldMicroInteractionView.swift — call site that uses
//    this shimmer inside a chat composer's recording state.
//  • View/Slider/MicroInteractionSlider.swift — sister shimmer
//    pattern on a slider's idle hint.
//
import SwiftUI

struct SlideToCancelTextDemo: View {
    var body: some View {
        HStack {
            CustomTrashCanView(isOpen: false)
            SlideToCancelText(text: "Hello World!")
        }
    }
}

struct SlideToCancelText: View {
    var text: String
    @State private var animate: Bool = false
    var body: some View {
        viewContent()
            .foregroundStyle(.gray.secondary)
            .overlay {
                viewContent()
                    .foregroundStyle(.primary)
                    .mask {
                        GeometryReader {
                            let size = $0.size

                            Rectangle()
                                .frame(width: 15, height: size.height)
                                .blur(radius: 5)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .offset(x: animate ? -size.width * 1.1 : 30)
                        }
                    }
            }
            .compositingGroup()
            .onAppear {
                guard !animate else { return }
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    animate = true
                }
            }
    }

    func viewContent() -> some View {
        HStack(spacing: 5) {
            Image(systemName: "chevron.left")
                .font(.caption)

            Text(text)
                .font(.callout)
        }
    }
}

struct CustomTrashCanView: View {
    var isOpen: Bool
    var body: some View {
        VStack(spacing: 2) {
            VStack(spacing: 0) {
                UnevenRoundedRectangle(
                    topLeadingRadius: 10,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 10
                )
                .frame(width: 15, height: 6)

                Capsule()
                    .frame(height: 4)
            }
            .compositingGroup()
            .rotationEffect(.init(degrees: isOpen ? -90 : 0), anchor: .bottomLeading)
            .offset(y: isOpen ? 10 : 0)

            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 5,
                bottomTrailingRadius: 5,
                topTrailingRadius: 0
            )
            .frame(width: 20, height: 20)
        }
        .frame(width: 35)
        .foregroundStyle(.gray)
        .compositingGroup()
        .scaleEffect(0.8)
        .animation(.easeInOut(duration: 0.3), value: isOpen)
    }
}

#Preview {
    SlideToCancelTextDemo()
}
