//
//  PicoCamPart1DemoView.swift
//  animation
//

import SwiftUI

private enum PicoFlowState {
    case gallery
    case generationMode
    case flash
    case ejectingCard
    case previewingCard
    case retreatingCard
}

struct PicoCamPart1DemoView: View {
    @State private var cards = firstSetCards
    @State private var selectedCard: Card?
    @State private var flowState: PicoFlowState = .gallery

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    PicoGalleryGrid(
                        cards: cards,
                        selectedCard: selectedCard,
                        flowState: flowState,
                        onSelect: selectCard
                    )
                    .padding(.top, 58)
                    .opacity(galleryOpacity)
                    .allowsHitTesting(flowState == .gallery)
                }

                PicoGenerationOverlay(
                    isVisible: flowState == .generationMode,
                    onShutterTap: runCaptureAnimation
                )
                .padding(.top, proxy.safeAreaInsets.top)
                .zIndex(5)

                // snap effect
                if let selectedCard, showsInstantCard {
                    PicoInstantCardView(card: selectedCard, flowState: flowState)
                        .frame(width: 190, height: 240)
                        .offset(y: PicoHardwareIslandMetrics.printFrameTop + instantCardOffset)
                        .zIndex(instantCardZIndex)
                }

                PicoIslandPrintFrame(
                    card: selectedCard,
                    flowState: flowState
                )
                .frame(
                    width: PicoHardwareIslandMetrics.slotSize.width,
                    height: PicoHardwareIslandMetrics.slotSize.height
                )
                .position(
                    x: proxy.size.width / 2,
                    y: PicoHardwareIslandMetrics.printFrameTop +
                        (PicoHardwareIslandMetrics.slotSize.height / 2)
                )
                .zIndex(12)

                if flowState == .flash {
                    Color.white
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .zIndex(20)
                }
            }
        }
        .background(Color.picoRed)
    }

    private var galleryOpacity: Double {
        switch flowState {
        case .gallery:
            1
        case .generationMode, .flash, .ejectingCard, .previewingCard, .retreatingCard:
            0.12
        }
    }

    private var showsInstantCard: Bool {
        flowState == .ejectingCard ||
            flowState == .previewingCard ||
            flowState == .retreatingCard
    }

    private var instantCardOffset: CGFloat {
        switch flowState {
        case .ejectingCard:
            PicoHardwareIslandMetrics.dynamicIslandHeight - 2
        case .previewingCard:
            130
        case .retreatingCard:
            PicoHardwareIslandMetrics.dynamicIslandHeight - 8
        default:
            0
        }
    }

    private var instantCardZIndex: Double {
        switch flowState {
        case .ejectingCard:
            13
        case .previewingCard:
            14
        case .retreatingCard:
            9
        default:
            8
        }
    }

    private func selectCard(_ card: Card) {
        guard flowState == .gallery else { return }
        selectedCard = card

        withAnimation(.easeInOut(duration: 0.28)) {
            flowState = .generationMode
        }
    }

    // TODO: Make the card visually eject *from* the dynamic island, not just
    // appear below it. Today the card materializes at `offset = 32` (already
    // past the island's bottom edge) at zIndex 13, in front of the island
    // (zIndex 12), so there's no "printing through a slot" feel.
    //
    // Suggested approach (changes are coupled — do them together):
    //   1. Include `.flash` in `showsInstantCard` so the card is in the
    //      hierarchy *before* the eject begins, positioned at `offset = 0`
    //      (centered on the island) with `instantCardZIndex < 12` so the
    //      island visually contains it.
    //   2. Add a mask/clip on the card whose top edge is the island's bottom
    //      edge (`printFrameTop + dynamicIslandHeight`). Only the portion of
    //      the card past that line is visible — as `instantCardOffset`
    //      animates 0 → 32 inside the existing spring, the card appears to
    //      slide out through the island's bottom.
    //   3. Drop the `flash` opacity *before* (or with a much shorter duration
    //      than) the 0.45s spring. The current shared spring hides the first
    //      ~150ms of the slide behind the white flash.
    //
    // TODO: Grow `dynamicIslandWidth` to match the printed card's width
    // during `.flash`/`.ejectingCard`/`.previewingCard` so the slot looks
    // wide enough to print a 190pt card. Today it's a static 128.
    //   - Convert `PicoHardwareIslandMetrics.dynamicIslandWidth` (and
    //     `slotSize`) from `static let` constants into a flowState-driven
    //     value (e.g., 128 in `.gallery`/`.generationMode`/`.retreatingCard`,
    //     ~210 in the printing states to fit the 190 card + side frames).
    //   - Pass that width into `PicoIslandPrintFrame.frame(width:)` and the
    //     `.position(x:)` calc in `body` (both currently read the enum).
    //   - Apply the width change inside the same `withAnimation(.spring(...))`
    //     that drives `.ejectingCard` so it interpolates with the eject.
    private func runCaptureAnimation() {
        guard flowState == .generationMode, let selectedCard else { return }

        Task { @MainActor in
            withAnimation(.easeOut(duration: 0.08)) {
                flowState = .flash
            }

            try? await Task.sleep(nanoseconds: 110_000_000)

            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                flowState = .ejectingCard
            }

            try? await Task.sleep(nanoseconds: 560_000_000)

            withAnimation(.easeInOut(duration: 0.2)) {
                flowState = .previewingCard
            }

            try? await Task.sleep(nanoseconds: 680_000_000)

            withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
                flowState = .retreatingCard
            }

            try? await Task.sleep(nanoseconds: 440_000_000)

            cards.insert(
                Card(
                    image: selectedCard.image,
                    title: "Instant Print",
                    subTitle: selectedCard.title
                ),
                at: 0
            )
            self.selectedCard = nil

            withAnimation(.easeInOut(duration: 0.24)) {
                flowState = .gallery
            }
        }
    }
}

private struct PicoGalleryGrid: View {
    let cards: [Card]
    let selectedCard: Card?
    let flowState: PicoFlowState
    let onSelect: (Card) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(generatedCards.prefix(3)) { card in
                        PicoGalleryCell(
                            card: card,
                            isSelected: false,
                            flowState: flowState
                        )
                    }
                }
                .frame(height: 142, alignment: .top)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(sourceCards) { card in
                        PicoGalleryCell(
                            card: card,
                            isSelected: selectedCard?.id == card.id,
                            flowState: flowState
                        )
                        .onTapGesture {
                            onSelect(card)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }

    private var generatedCards: [Card] {
        cards.filter(\.isPicoGeneratedInstantCard)
    }

    private var sourceCards: [Card] {
        cards.filter { !$0.isPicoGeneratedInstantCard }
    }
}

private struct PicoGalleryCell: View {
    let card: Card
    let isSelected: Bool
    let flowState: PicoFlowState

    var body: some View {
        Group {
            if card.isPicoGeneratedInstantCard {
                PicoGalleryInstantCardCell(card: card)
            } else {
                PicoSourceImageCell(card: card)
            }
        }
        .opacity(isSelected && flowState != .gallery ? 0 : 1)
        .shadow(color: .black.opacity(0.16), radius: 10, y: 6)
        .contentShape(.rect(cornerRadius: 14))
    }
}

private struct PicoSourceImageCell: View {
    let card: Card

    var body: some View {
        Image(card.image)
            .resizable()
            .scaledToFill()
            .frame(height: 142)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(alignment: .bottomLeading) {
                PicoGalleryTitlePill(title: card.title)
            }
    }
}

private struct PicoGalleryInstantCardCell: View {
    let card: Card

    var body: some View {
        VStack(spacing: 7) {
            Image(card.image)
                .resizable()
                .scaledToFill()
                .frame(height: 96)
                .clipShape(.rect(cornerRadius: 6))

            Capsule()
                .fill(.black.opacity(0.16))
                .frame(width: 58, height: 4)

            Capsule()
                .fill(.black.opacity(0.1))
                .frame(width: 34, height: 3)
        }
        .padding(8)
        .frame(height: 142)
        .background(.white, in: .rect(cornerRadius: 10))
    }
}

private struct PicoGalleryTitlePill: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption.bold())
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.black.opacity(0.28), in: .capsule)
            .padding(8)
    }
}

// TODO: Make tcan ch-resizable while in the snap view
// (i.e., `flowState == .generationMode`, after the user taps a thumbnail).
//
// Desired behavior:
//   - Add a `MagnifyGesture` (or `simultaneousGesture` with the existing
//     shutter tap) to this frame so the user can pinch to scale the photo
//     and its surrounding U-shaped frame together.
//   - The frame's TOP edge stays pinned to the bottom of the dynamic island
//     — the island itself acts as the top bar of the frame, so the rendered
//     U-shape only draws the two sides + bottom. Anchor scaling at the top
//     center (`.scaleEffect(_, anchor: .top)`) so the bottom grows downward
//     while the top stays glued to the island.
//   - Width clamping:
//       * Min width = `PicoHardwareIslandMetrics.dynamicIslandWidth` —
//         pinching smaller than the island is a no-op.
//       * No fixed max — let the user pinch larger (the camera "zooms").
//   - When the pinched width exceeds the dynamic island width, draw two
//     additional black rectangles flanking the island at its top y-range
//     (height = `dynamicIslandHeight`, width = `(pinchedWidth - islandWidth) / 2`
//     on each side) so the frame's top bar visually extends out past the
//     island and the whole thing reads as one continuous frame around the
//     photo. Inside the island's own width, draw nothing on top — the real
//     island is the top bar.
//   - Persist the pinched size as `@State private var pinchedSize: CGSize`
//     on `PicoCamPart1DemoView` (or via a `GestureState` while pinching +
//     committed `@State` on end). Reset to the default when returning to
//     `.gallery`.
//   - Reuse the same width when ejecting: this dovetails with the
//     `dynamicIslandWidth` TODO above — the eject animation should expand
//     the slot to match whatever width the user pinched to.
private struct PicoIslandPrintFrame: View {
    let card: Card?
    let flowState: PicoFlowState

    var body: some View {
        ZStack(alignment: .top) {
            if let card {
                Image(card.image)
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: PicoHardwareIslandMetrics.dynamicIslandWidth -
                            (PicoHardwareIslandMetrics.frameEdgeThickness * 2),
                        height: PicoHardwareIslandMetrics.printFrameHeight +
                            PicoHardwareIslandMetrics.dynamicIslandOverlap -
                            PicoHardwareIslandMetrics.frameEdgeThickness
                    )
                    .clipShape(.rect(cornerRadius: 3))
                    .offset(y: -PicoHardwareIslandMetrics.dynamicIslandOverlap)
                    .opacity(imageOpacity)
                    .blur(radius: imageBlur)
            }

            HStack(alignment: .bottom, spacing: 0) {
                frameSide

                Spacer(minLength: 0)

                frameSide
            }

            RoundedRectangle(cornerRadius: 25)
                .fill(frameColor)
                .frame(height: PicoHardwareIslandMetrics.frameEdgeThickness)
                .offset(
                    y: PicoHardwareIslandMetrics.printFrameHeight -
                        PicoHardwareIslandMetrics.frameEdgeThickness
                )
        }
        .scaleEffect(flowState == .flash ? 1.08 : 1)
        .opacity(frameOpacity)
        .animation(.spring(response: 0.24, dampingFraction: 0.72), value: flowState)
    }

    private var frameSide: some View {
        RoundedRectangle(cornerRadius: 25)
            .fill(frameColor)
            .frame(
                width: PicoHardwareIslandMetrics.frameEdgeThickness,
                height: PicoHardwareIslandMetrics.printFrameHeight +
                    PicoHardwareIslandMetrics.dynamicIslandOverlap
            )
            .offset(y: -PicoHardwareIslandMetrics.dynamicIslandOverlap)
    }

    private var frameColor: Color {
        .black
    }

    private var imageOpacity: Double {
        switch flowState {
        case .gallery:
            0
        case .generationMode, .flash:
            0.86
        case .ejectingCard:
            0.28
        case .previewingCard:
            0
        case .retreatingCard:
            0.18
        }
    }

    private var imageBlur: CGFloat {
        switch flowState {
        case .generationMode, .flash:
            0
        case .ejectingCard, .retreatingCard:
            2
        case .gallery, .previewingCard:
            0
        }
    }

    private var frameOpacity: Double {
        switch flowState {
        case .gallery:
            0
        case .generationMode:
            1
        case .flash, .ejectingCard, .previewingCard, .retreatingCard:
            0
        }
    }
}

private struct PicoGenerationOverlay: View {
    let isVisible: Bool
    let onShutterTap: () -> Void

    var body: some View {
        VStack {
            Spacer()

            Button(action: onShutterTap) {
                ZStack {
                    Circle()
                        .fill(.yellow)
                        .frame(width: 84, height: 84)

                    Circle()
                        .stroke(.white.opacity(0.95), lineWidth: 5)
                        .frame(width: 96, height: 96)
                }
                .shadow(color: .black.opacity(0.28), radius: 16, y: 8)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Generate instant card")
            .padding(.bottom, 48)
        }
        .opacity(isVisible ? 1 : 0)
        .allowsHitTesting(isVisible)
        .animation(.easeInOut(duration: 0.22), value: isVisible)
    }
}

private struct PicoInstantCardView: View {
    let card: Card
    let flowState: PicoFlowState

    var body: some View {
        VStack(spacing: 0) {
            Image(card.image)
                .resizable()
                .scaledToFill()
                .frame(height: imageHeight, alignment: .bottomLeading)
                .clipShape(.rect(cornerRadius: 6))
        }
        .padding(cardPadding)
        .background(.white, in: .rect(cornerRadius: 10))
        .shadow(color: .black.opacity(0.3), radius: 20, y: 14)
        .rotationEffect(.degrees(rotation))
        .scaleEffect(scale, anchor: .top)
        .opacity(opacity)
    }

    private var imageHeight: CGFloat {
        switch flowState {
        case .ejectingCard:
            126
        case .previewingCard:
            128
        case .retreatingCard:
            118
        default:
            126
        }
    }

    private var cardPadding: CGFloat {
        switch flowState {
        case .ejectingCard, .retreatingCard:
            10
        default:
            12
        }
    }

    private var rotation: Double {
        switch flowState {
        case .ejectingCard:
            -10
        case .previewingCard:
            4
        case .retreatingCard:
            -3
        default:
            0
        }
    }

    private var scale: CGFloat {
        switch flowState {
        case .ejectingCard:
            0.56
        case .previewingCard:
            1
        case .retreatingCard:
            0.5
        default:
            0.5
        }
    }

    private var opacity: Double {
        flowState == .retreatingCard ? 0.72 : 1
    }
}

private extension Color {
    static let picoRed = Color(red: 0.9, green: 0.04, blue: 0.05)
}

private extension Card {
    var isPicoGeneratedInstantCard: Bool {
        title == "Instant Print"
    }
}

private enum PicoHardwareIslandMetrics {
    static let dynamicIslandWidth: CGFloat = 128
    static let dynamicIslandHeight: CGFloat = 34
    static let frameEdgeThickness: CGFloat = 16
    static let dynamicIslandOverlap: CGFloat = 23
    static let printFrameHeight: CGFloat = 112
    static let printFrameTop: CGFloat = -12
    static let slotSize = CGSize(
        width: dynamicIslandWidth,
        height: printFrameHeight
    )
}

#Preview {
    PicoCamPart1DemoView()
}
