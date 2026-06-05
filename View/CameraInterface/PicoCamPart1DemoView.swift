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

                // snap effect — wrapped in a clear container that clips
                // the card to the safe area, so the part of the card above
                // the bar (during .flash and the early eject spring) is
                // masked off instead of leaking into the status-bar strips.
                if let selectedCard, showsInstantCard {
                    Color.clear
                        .overlay(alignment: .top) {
                            PicoInstantCardView(card: selectedCard, flowState: flowState)
                                .frame(
                                    width: PicoHardwareIslandMetrics.cardLayoutSize.width,
                                    height: PicoHardwareIslandMetrics.cardLayoutSize.height
                                )
                                .scaleEffect(cardScale, anchor: .top)
                                .offset(y: PicoHardwareIslandMetrics.printFrameTop + instantCardOffset)
                        }
                        .clipped()
                        .zIndex(instantCardZIndex)
                        .transition(.opacity)
                        .allowsHitTesting(false)
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
                    bottomLeadingRadius: topBarBottomCornerRadius,
                    bottomTrailingRadius: topBarBottomCornerRadius,
                    topTrailingRadius: 25
                )
                .fill(.black)
                .frame(
                    width: topBarWidth,
                    height: PicoHardwareIslandMetrics.dynamicIslandTopBarHeight
                )
                .position(
                    x: proxy.size.width / 2,
                    y: -PicoHardwareIslandMetrics.dynamicIslandTopBarHeight / 2
                )
                .opacity(flowState == .gallery ? 0 : 1)
                .zIndex(11)

                Color.white
                    .ignoresSafeArea()
                    .opacity(flowState == .flash ? 1 : 0)
                    .allowsHitTesting(false)
                    .animation(.easeOut(duration: 0.12), value: flowState)
                    .zIndex(20)
            }
        }
        .background(Color.picoRed.ignoresSafeArea())
    }

    private var galleryOpacity: Double {
        switch flowState {
        case .gallery:
            1
        case .generationMode, .flash, .ejectingCard:
            0.12
        }
    }

    private var showsInstantCard: Bool {
        flowState == .flash || flowState == .ejectingCard
    }

    // ---------- Part 2: iOS Camera Controls ----------
    // Replace the static `cards` / `selectedCard` source with a live
    // AVFoundation pipeline, reusing the Part 1 print animation unchanged.
    // Out of scope: video recording, AI animation, MP4 export, social
    // sharing. The animation must not care whether the image came from a
    // local array, photo library, or camera capture.
    //
    // TODO: Add CameraManager (NSObject + ObservableObject) owning the
    // AVCaptureSession. Publishes `authorizationStatus: AVAuthorizationStatus`
    // and `capturedImage: UIImage?`. API: configureSession, startSession,
    // stopSession, capturePhoto, switchCamera, setFlashMode(_:). Keep all
    // AVFoundation work off SwiftUI views — never block the main actor on
    // session config.
    //
    // TODO: Add CameraPreviewView as UIViewRepresentable hosting an
    // AVCaptureVideoPreviewLayer bound to the manager's session. SwiftUI
    // has no native camera preview, so this is the standard bridge.
    //
    // TODO: Introduce PicoCameraState — requestingPermission /
    // permissionDenied / previewing / capturing / animatingResult /
    // completed — to drive the camera screen. PicoFlowState stays scoped
    // to the print animation; the camera state owns capture and hands the
    // resulting UIImage off to the print flow.
    //
    // TODO: Permission handling. .authorized → start session;
    // .notDetermined → request and branch on the result; .denied /
    // .restricted → fallback view explaining that camera access is
    // required. Set NSCameraUsageDescription in Info.plist.
    //
    // TODO: Camera UI chrome. Top controls: close, flash-mode toggle.
    // Bottom controls: gallery placeholder, shutter, flip-camera. Reuse
    // the existing yellow shutter from PicoGenerationOverlay rather than
    // duplicating it — extend its action to call CameraManager.capturePhoto.
    //
    // TODO: Shutter tap behavior — scale button to 0.92, fire a medium
    // UIImpactFeedbackGenerator, call capturePhoto(), and show a ~80ms
    // white flash overlay. The existing `.flash` state already paints the
    // overlay (easeOut 0.08s ≈ 80ms); align timing rather than adding a
    // second flash layer.
    //
    // TODO: Capture handoff. On photo capture: disable shutter, pause the
    // preview visually, resize the UIImage so its max dimension is ~1500px
    // (don't animate full-resolution sensor output), feed it into the
    // Part 1 print animation as the selected card image, then re-enable
    // the shutter when flowState returns to .gallery.
    //
    // TODO: Extract the Part 1 animation into a reusable surface so the
    // camera flow can drive it without depending on the static `cards`
    // array — either `InstantPhotoCardView(image:animationState:)` or
    // `PicoInstantAnimator.play(image:)`. Card-source decoupling is the
    // whole point of Part 2's split.
    private var cardScale: CGFloat {
        switch flowState {
        case .flash, .ejectingCard:
            slotScale * PicoHardwareIslandMetrics.baseDynamicIslandWidth /
                PicoHardwareIslandMetrics.cardLayoutSize.width
        case .gallery, .generationMode:
            0.5
        }
    }

    // .flash starts the card hidden behind the bar (top at -0.9 ×
    // cardVisualHeight). .ejectingCard slides the top down so 15% stays
    // tucked behind the bar and the remaining 85% prints out.
    private var instantCardOffset: CGFloat {
        let printFrameTop = PicoHardwareIslandMetrics.printFrameTop
        let cardVisualHeight = PicoHardwareIslandMetrics.cardLayoutSize.height * cardScale
        switch flowState {
        case .flash:
            return -0.9 * cardVisualHeight - printFrameTop
        case .ejectingCard:
            return -0.15 * cardVisualHeight - printFrameTop
        case .gallery, .generationMode:
            return 0
        }
    }

    private var instantCardZIndex: Double {
        switch flowState {
        case .flash, .ejectingCard:
            10
        case .gallery, .generationMode:
            0
        }
    }

    private var slotScale: CGFloat {
        min(
            PicoHardwareIslandMetrics.maxSlotScale,
            max(1, committedSlotScale + slotScaleDelta)
        )
    }

    // Bottom corners round out during eject so the bar reads as a full
    // pill; square in gallery/generation mode so the bar visually continues
    // into the open print frame below it.
    private var topBarBottomCornerRadius: CGFloat {
        switch flowState {
        case .flash, .ejectingCard:
            25
        case .gallery, .generationMode:
            0
        }
    }

    // Bar width tracks the visible photo during eject so the emerging
    // photo doesn't peek past the bar's edges. Otherwise it matches the
    // dynamic-island width × slotScale to read as one continuous bar.
    private var topBarWidth: CGFloat {
        switch flowState {
        case .flash, .ejectingCard:
            PicoHardwareIslandMetrics.cardLayoutSize.width * cardScale *
                PicoHardwareIslandMetrics.barOvershoot
        case .gallery, .generationMode:
            PicoHardwareIslandMetrics.baseDynamicIslandWidth * slotScale
        }
    }

    private var slotResizeGesture: some Gesture {
        DragGesture()
            .updating($slotScaleDelta) { value, state, _ in
                state = value.translation.height / PicoHardwareIslandMetrics.dragScaleSensitivity
            }
            .onEnded { value in
                let delta = value.translation.height / PicoHardwareIslandMetrics.dragScaleSensitivity
                committedSlotScale = min(
                    PicoHardwareIslandMetrics.maxSlotScale,
                    max(1, committedSlotScale + delta)
                )
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

            withAnimation(.spring(response: 1.0, dampingFraction: 0.85)) {
                flowState = .ejectingCard
            }

            // Spring settle plus a hold so the printed card reads before
            // the gallery returns.
            try? await Task.sleep(nanoseconds: 2_000_000_000)

            cards.insert(
                Card(
                    image: selectedCard.image,
                    title: "Instant Print",
                    subTitle: selectedCard.title
                ),
                at: 0
            )

            withAnimation(.easeInOut(duration: 0.32)) {
                self.selectedCard = nil
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
        case .generationMode, .flash:
            0.86
        case .ejectingCard:
            0.28
        case .gallery:
            0
        }
    }

    private var imageBlur: CGFloat {
        switch flowState {
        case .ejectingCard:
            2
        case .gallery, .generationMode, .flash:
            0
        }
    }

    private var frameOpacity: Double {
        switch flowState {
        case .generationMode:
            1
        case .gallery, .flash, .ejectingCard:
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
                .frame(
                    width: PicoHardwareIslandMetrics.cardLayoutSize.width - 2 * cardPadding,
                    height: 126
                )
                .clipShape(.rect(cornerRadius: 6))
                .padding(cardPadding)
        }
        .shadow(color: .black.opacity(0.3), radius: 20, y: 14)
        .rotation3DEffect(
            .degrees(tiltX),
            axis: (x: 1, y: 0, z: 0),
            anchor: .top,
            perspective: 1.0
        )
    }

    private var cardPadding: CGFloat {
        PicoHardwareIslandMetrics.cardPadding(for: flowState)
    }

    private var tiltX: Double {
        flowState == .ejectingCard ? 18 : 0
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
    // Height keeps the bottom white margin at ~30% of the image height
    // (174 − 10 top padding − 126 image = 38 ≈ 30% × 126).
    static let cardLayoutSize = CGSize(width: 190, height: 174)
    // Bar extends past the card outer width so it reads as the printer
    // slot, not a tight outline of the print.
    static let barOvershoot: CGFloat = 1.25
    // Caps the drag-resize so the bar/card can't grow past typical
    // screen widths and clip at the edges.
    static let maxSlotScale: CGFloat = 2.0

    static func cardPadding(for state: PicoFlowState) -> CGFloat {
        state == .ejectingCard ? 10 : 12
    }
}

#Preview {
    PicoCamPart1DemoView()
}
