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
    @State private var committedSlotScale: CGFloat = 1
    @GestureState private var slotScaleDelta: CGFloat = 0

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
                        .frame(
                            width: PicoHardwareIslandMetrics.cardLayoutSize.width,
                            height: PicoHardwareIslandMetrics.cardLayoutSize.height
                        )
                        .scaleEffect(cardScale, anchor: .top)
                        .offset(y: PicoHardwareIslandMetrics.printFrameTop + instantCardOffset)
                        .zIndex(instantCardZIndex)
                }

                PicoIslandPrintFrame(card: selectedCard, flowState: flowState)
                    .frame(
                        width: PicoHardwareIslandMetrics.baseDynamicIslandWidth,
                        height: PicoHardwareIslandMetrics.printFrameHeight
                    )
                    .scaleEffect(slotScale, anchor: .top)
                    .position(
                        x: proxy.size.width / 2,
                        y: PicoHardwareIslandMetrics.printFrameTop +
                            (PicoHardwareIslandMetrics.printFrameHeight / 2)
                    )
                    .zIndex(12)
                    .gesture(slotResizeGesture, isEnabled: flowState == .generationMode)

                // Fills the area beside the hardware dynamic island so the
                // frame's top reads as one continuous bar. Stays visible
                // through the eject so the printed card emerges from
                // beneath the bar; hides during preview (card is held
                // mid-screen, slot is empty).
                UnevenRoundedRectangle(
                    topLeadingRadius: 25,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 25
                )
                .fill(.black)
                .frame(
                    width: PicoHardwareIslandMetrics.baseDynamicIslandWidth * slotScale,
                    height: PicoHardwareIslandMetrics.dynamicIslandTopBarHeight
                )
                .position(
                    x: proxy.size.width / 2,
                    y: -PicoHardwareIslandMetrics.dynamicIslandTopBarHeight / 2
                )
                .opacity(flowState == .gallery || flowState == .previewingCard ? 0 : 1)
                .zIndex(11)

                Color.white
                    .ignoresSafeArea()
                    .opacity(flowState == .flash ? 1 : 0)
                    .allowsHitTesting(false)
                    .animation(.easeOut(duration: 0.12), value: flowState)
                    .zIndex(20)
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
        flowState == .flash ||
            flowState == .ejectingCard ||
            flowState == .previewingCard ||
            flowState == .retreatingCard
    }

    // TODO: The eject spring (`runCaptureAnimation` line ≈215, response 0.45)
    // is too fast — the print-out motion barely registers visually. Bump
    // response to ~0.7 and the matching `Task.sleep` (560ms → ~800ms) so the
    // next phase doesn't fire mid-spring.
    //
    // TODO: User wants the top bar's width to match the photo's width. Today
    // the bar = `baseDynamicIslandWidth × slotScale`, which is the *outer*
    // card width including white border. With rotation in `.ejectingCard`,
    // the visible photo (rotated rectangle) reads narrower than the bar.
    // Either remove the eject rotation, or compute the bar width from the
    // image's effective width (cardWidth − 2×padding) × cardScale.
    //
    // TODO: Explore Y-only variant. Currently emerge uses Y offset + Z
    // (card behind bar) + mask (clip in unsafe area). The mask exists only
    // because the card travels into the status-bar region where the bar
    // doesn't reach. If we either (a) make the bar tall enough to cover
    // the card's full upward travel, or (b) clip the parent ZStack to its
    // safe-area-respecting bounds, the mask becomes redundant and the
    // emerge is purely "card slides Y, opaque bar occludes in front".
    private var cardScale: CGFloat {
        switch flowState {
        case .flash, .ejectingCard:
            slotScale * PicoHardwareIslandMetrics.baseDynamicIslandWidth /
                PicoHardwareIslandMetrics.cardLayoutSize.width
        case .previewingCard:
            1
        case .retreatingCard:
            0.5
        default:
            0.5
        }
    }

    // Offset moves the card's layout top in screen Y. With the mask edge at
    // y = 0 (top bar bottom), placing card top at -0.9 × cardVisualHeight
    // leaves only the bottom 10% visible below the bar. .ejectingCard pushes
    // the top down to y = 0 (fully clear of the bar). .retreatingCard goes
    // back to the 10%-visible position before the gallery removes the card.
    private var instantCardOffset: CGFloat {
        let printFrameTop = PicoHardwareIslandMetrics.printFrameTop
        let cardVisualHeight = PicoHardwareIslandMetrics.cardLayoutSize.height * cardScale
        switch flowState {
        case .flash, .retreatingCard:
            return -0.9 * cardVisualHeight - printFrameTop
        case .ejectingCard:
            return -printFrameTop
        case .previewingCard:
            return 130
        default:
            return 0
        }
    }

    private var instantCardZIndex: Double {
        switch flowState {
        case .flash, .ejectingCard, .retreatingCard:
            10
        default:
            0
        }
    }

    private var instantCardMaskCutoff: CGFloat {
        let cardTopInScreen = PicoHardwareIslandMetrics.printFrameTop + instantCardOffset
        return -cardTopInScreen
    }

    private var slotScale: CGFloat {
        max(1, committedSlotScale + slotScaleDelta)
    }

    private var slotResizeGesture: some Gesture {
        DragGesture()
            .updating($slotScaleDelta) { value, state, _ in
                state = value.translation.height / PicoHardwareIslandMetrics.dragScaleSensitivity
            }
            .onEnded { value in
                let delta = value.translation.height / PicoHardwareIslandMetrics.dragScaleSensitivity
                committedSlotScale = max(1, committedSlotScale + delta)
            }
    }

    private func selectCard(_ card: Card) {
        guard flowState == .gallery else { return }
        selectedCard = card

        withAnimation(.easeInOut(duration: 0.28)) {
            flowState = .generationMode
        }
    }

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
                committedSlotScale = 1
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
                        width: PicoHardwareIslandMetrics.baseDynamicIslandWidth -
                            (PicoHardwareIslandMetrics.frameEdgeThickness * 2),
                        height: PicoHardwareIslandMetrics.printFrameHeight -
                            PicoHardwareIslandMetrics.frameEdgeThickness
                    )
                    .clipShape(.rect(cornerRadius: 3))
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
                height: PicoHardwareIslandMetrics.printFrameHeight
            )
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
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 10)
                .fill(.white)

            Image(card.image)
                .resizable()
                .scaledToFill()
                .frame(height: imageHeight)
                .clipShape(.rect(cornerRadius: 6))
                .padding(cardPadding)
        }
        .shadow(color: .black.opacity(0.3), radius: 20, y: 14)
        .rotationEffect(.degrees(rotation))
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
    static let baseDynamicIslandWidth: CGFloat = 128
    static let dynamicIslandHeight: CGFloat = 34
    static let dynamicIslandTopBarHeight: CGFloat = 55
    static let frameEdgeThickness: CGFloat = 16
    static let printFrameHeight: CGFloat = 112
    static let printFrameTop: CGFloat = -12
    static let dragScaleSensitivity: CGFloat = 220
    static let cardLayoutSize = CGSize(width: 190, height: 240)
}

#Preview {
    PicoCamPart1DemoView()
}
