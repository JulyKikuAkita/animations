//
//  PicoCamPart1DemoView.swift
//  animation
//

import SwiftUI

private enum PicoFlowState {
    case gallery
    case movingToIsland
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
    @Namespace private var imageNamespace

    var body: some View {
        GeometryReader { proxy in
            let safeArea = proxy.safeAreaInsets
            let islandTop = safeArea.top + 12

            ZStack(alignment: .top) {
                Color.picoRed
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    DummyStatusBar()
                        .foregroundStyle(.white)

                    PicoGalleryGrid(
                        cards: cards,
                        selectedCard: selectedCard,
                        flowState: flowState,
                        namespace: imageNamespace,
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
                .padding(.top, safeArea.top)
                .zIndex(5)

                if let selectedCard, showsInstantCard {
                    PicoInstantCardView(card: selectedCard, flowState: flowState)
                        .frame(width: 190, height: 240)
                        .offset(y: islandTop + instantCardOffset)
                        .zIndex(8)
                }

                PicoIslandSlot(
                    card: selectedCard,
                    flowState: flowState,
                    namespace: imageNamespace
                )
                .frame(width: 158, height: 46)
                .padding(.top, islandTop)
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
        case .gallery, .movingToIsland, .retreatingCard:
            1
        case .generationMode, .flash, .ejectingCard, .previewingCard:
            0.18
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
            92
        case .previewingCard:
            148
        case .retreatingCard:
            6
        default:
            0
        }
    }

    private func selectCard(_ card: Card) {
        guard flowState == .gallery else { return }
        selectedCard = card

        withAnimation(.spring(response: 0.48, dampingFraction: 0.84)) {
            flowState = .movingToIsland
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 520_000_000)
            withAnimation(.easeInOut(duration: 0.24)) {
                flowState = .generationMode
            }
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
            }
        }
    }
}

private struct PicoGalleryGrid: View {
    let cards: [Card]
    let selectedCard: Card?
    let flowState: PicoFlowState
    let namespace: Namespace.ID
    let onSelect: (Card) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(cards) { card in
                    PicoGalleryCell(
                        card: card,
                        isSelected: selectedCard?.id == card.id,
                        flowState: flowState,
                        namespace: namespace
                    )
                    .onTapGesture {
                        onSelect(card)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }
}

private struct PicoGalleryCell: View {
    let card: Card
    let isSelected: Bool
    let flowState: PicoFlowState
    let namespace: Namespace.ID

    var body: some View {
        Image(card.image)
            .resizable()
            .scaledToFill()
            .frame(height: 142)
            .clipShape(.rect(cornerRadius: 14))
            .matchedGeometryEffect(id: card.id, in: namespace)
            .overlay(alignment: .bottomLeading) {
                Text(card.title)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.black.opacity(0.28), in: .capsule)
                    .padding(8)
            }
            .opacity(isSelected && flowState != .gallery ? 0.08 : 1)
            .shadow(color: .black.opacity(0.16), radius: 10, y: 6)
            .contentShape(.rect(cornerRadius: 14))
    }
}

private struct PicoIslandSlot: View {
    let card: Card?
    let flowState: PicoFlowState
    let namespace: Namespace.ID

    var body: some View {
        ZStack {
            Capsule()
                .fill(.black)
                .shadow(color: .black.opacity(0.35), radius: 16, y: 8)

            Capsule()
                .fill(.white.opacity(0.09))
                .padding(.horizontal, 10)
                .padding(.vertical, 9)

            if let card {
                Image(card.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: previewWidth, height: 30)
                    .clipShape(.capsule)
                    .matchedGeometryEffect(id: card.id, in: namespace, isSource: false)
                    .opacity(flowState == .gallery ? 0 : 1)
            }

            Capsule()
                .stroke(.white.opacity(0.18), lineWidth: 1)

            VStack(spacing: 0) {
                Capsule()
                    .fill(.white.opacity(0.16))
                    .frame(height: 2)
                    .padding(.horizontal, 26)
                    .padding(.top, 7)

                Spacer(minLength: 0)
            }
        }
        .scaleEffect(flowState == .flash ? 1.08 : 1)
        .animation(.spring(response: 0.24, dampingFraction: 0.72), value: flowState)
    }

    private var previewWidth: CGFloat {
        switch flowState {
        case .movingToIsland:
            106
        case .generationMode, .flash, .ejectingCard, .previewingCard, .retreatingCard:
            122
        case .gallery:
            96
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
        VStack(spacing: 12) {
            Image(card.image)
                .resizable()
                .scaledToFill()
                .frame(height: 154)
                .clipShape(.rect(cornerRadius: 6))
                .overlay {
                    Rectangle()
                        .fill(.white.opacity(flowState == .previewingCard ? 0.04 : 0.12))
                }

            VStack(spacing: 3) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(.black.opacity(0.18))
                    .frame(width: 76, height: 5)

                RoundedRectangle(cornerRadius: 2)
                    .fill(.black.opacity(0.1))
                    .frame(width: 44, height: 4)
            }
            .padding(.bottom, 4)
        }
        .padding(12)
        .background(.white, in: .rect(cornerRadius: 10))
        .shadow(color: .black.opacity(0.3), radius: 20, y: 14)
        .rotationEffect(.degrees(rotation))
        .scaleEffect(scale)
        .opacity(opacity)
    }

    private var rotation: Double {
        switch flowState {
        case .ejectingCard:
            -2
        case .previewingCard:
            1.5
        case .retreatingCard:
            0
        default:
            0
        }
    }

    private var scale: CGFloat {
        switch flowState {
        case .ejectingCard:
            0.92
        case .previewingCard:
            1
        case .retreatingCard:
            0.74
        default:
            0.72
        }
    }

    private var opacity: Double {
        flowState == .retreatingCard ? 0.82 : 1
    }
}

private extension Color {
    static let picoRed = Color(red: 0.9, green: 0.04, blue: 0.05)
}

#Preview {
    PicoCamPart1DemoView()
}
