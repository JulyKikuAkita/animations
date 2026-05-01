//
//  WalletCardAnimation.swift
//  animation
//
//  Created on 4/29/26.
//
//  ─────────────────────────────────────────────────────────────────────────────
//  Main learning: coordinating geometry, state, and `.visualEffect` to build a
//  wallet-style stack where tapping a card expands it and slides the rest away.
//
//  Key techniques demonstrated:
//
//  1. Negative `VStack` spacing (-150) to overlap cards into a physical stack.
//
//  2. Geometry-to-state pipeline via three observer modifiers — none of which
//     wrap the view in a new layout container (unlike `GeometryReader`):
//       • `.onGeometryChange(for: CGSize.self)`     → container size
//       • `.onGeometryChange(for: EdgeInsets.self)` → safe-area insets
//       • `.onGeometryChange(for: CGFloat.self)`    → global minY of the scroll
//       • `.onScrollGeometryChange(for: CGFloat.self)` → scroll offset
//     All four write into a single `Info` struct held in `@State`, so the
//     layout math downstream has one source of truth.
//
//  3. `.visualEffect` to animate each card's offset/scale based on its index
//     relative to the selected card — reads the live geometry via the passed-in
//     `GeometryProxy` without disturbing layout.
//
//  4. `.sheet(item:)` bound directly to an optional model (`selectedCard`) —
//     setting it non-nil presents the sheet, nil dismisses it. Sheet detents
//     are computed from the geometry state (`containerSize` + `minY`) so the
//     sheet lines up exactly below the expanded card.
//
//  5. `.allowsHitTesting` + `.scrollDisabled` to quarantine interaction to the
//     selected card once expanded, preventing stray taps and scroll conflicts.
//
//  Requires iOS 26 for `.onScrollGeometryChange`, `ToolbarSpacer`, and the
//  `.presentationBackgroundInteraction(.enabled(upThrough:))` API.
//  ─────────────────────────────────────────────────────────────────────────────

import SwiftUI

@available(iOS 26.0, *)
struct WalletDemoView: View {
    /// `selectedCard` doubles as selection state and as the `.sheet(item:)` binding.
    /// Setting it to non-nil triggers the sheet; setting to nil dismisses it.
    @State private var selectedCard: PaymentType?
    /// Geometry values flow into `info` via `.onGeometryChange` / `.onScrollGeometryChange`
    /// modifiers below, then get read by `visualEffect` and the sheet's detent math.
    /// Keeping them in one struct means a single `@State` triggers re-renders.
    @State private var info: Info = .init()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                // Negative spacing makes cards overlap (stacked-wallet look).
                VStack(spacing: -150) {
                    ForEach(payments) { payment in
                        cardView(payment)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .safeAreaPadding(15)
            // Lock scrolling while a card is expanded so gestures don't fight the sheet.
            .scrollDisabled(isCardSelected)
            .navigationTitle(isNavigationTitleHidden ? "" : "Wallet")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if isCardSelected {
                        Button("Close", systemImage: "xmark") {
                            withAnimation(animation) {
                                selectedCard = nil
                            }
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(isCardSelected ? "Edit" : "Add Card", systemImage: isCardSelected ? "creditcard.and.numbers" : "plus") {}
                }

                if !isCardSelected {
                    ToolbarSpacer(.fixed, placement: .topBarTrailing)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if !isCardSelected {
                        Button("Search", systemImage: "magnifyingglass") {}
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Options", systemImage: "ellipsis") {}
                }
            }
            // `.onScrollGeometryChange` fires only for scroll-related changes (offset, insets,
            // content size). The closure computes a derived value; `action` runs when it
            // changes. Cheaper than reading a full ScrollViewProxy every frame.
            .onScrollGeometryChange(for: CGFloat.self) {
                $0.contentOffset.y + $0.contentInsets.top
            } action: { _, newValue in
                info.scrollOffset = newValue
            }
            // `.onGeometryChange` is the generic form — fires whenever the attached view's
            // geometry changes. Here we track the ScrollView's global minY so we can compute
            // where the sheet should sit relative to the content area.
            .onGeometryChange(for: CGFloat.self) {
                $0.frame(in: .global).minY
            } action: { newValue in
                info.minY = newValue - info.safeArea.top
            }
            .background(.gray.opacity(0.25))
        }
        .sheet(item: $selectedCard) { payment in
            let spacing: CGFloat = 20
            // Sheet detents are derived from container size + the NavigationStack's minY.
            // Both of those come from the `.onGeometryChange` modifiers below — which is
            // why this file reads top-down: geometry -> info -> layout math.
            let minSheetHeight: CGFloat = info.containerSize.height - info.minY - (220 + spacing)
            let maxSheetHeight: CGFloat = info.containerSize.height - info.minY + 15

            TransactionSheetView(payment: payment)
                .presentationDetents([.height(minSheetHeight), .height(maxSheetHeight)])
                .presentationBackgroundInteraction(.enabled(upThrough: .height(maxSheetHeight)))
                .interactiveDismissDisabled()
                .presentationBackground(schemaBackground)
        }
        // Track the full container size (NavigationStack's frame).
        // `info.containerSize.height` feeds the `visualEffect` below — specifically the
        // `pushOffset = bounds.height - rect.minY` branch that shoves cards *below* the
        // tapped one off the bottom of the screen. If this modifier is missing,
        // `containerSize` stays `.zero`, `bounds.height` is 0, and the push-down math
        // collapses — see note in `cardView` for the visual consequence.
        .onGeometryChange(for: CGSize.self) {
            $0.size
        } action: { newValue in
            info.containerSize = newValue
        }
        // Safe-area insets are needed to normalize `info.minY` (subtract the top inset so
        // sheet math works in content-space, not window-space).
        .onGeometryChange(for: EdgeInsets.self) {
            $0.safeAreaInsets
        } action: { newValue in
            info.safeArea = newValue
        }
    }

    var isNavigationTitleHidden: Bool {
        info.scrollOffset > 1 || isCardSelected
    }

    func cardView(_ card: PaymentType) -> some View {
        let isCurrent = card.id == selectedCardID
        let currentIndex = payments.firstIndex(where: { $0.id == card.id }) ?? 0
        // `selectedCardIndex` is the index of the tapped card in `payments`.
        // When no card is selected, `selectedCardID` is nil and this falls back to 0 —
        // that's fine because `isCardSelected` gates the `visualEffect` branch that uses it.
        let selectedCardIndex = payments.firstIndex(where: { $0.id == selectedCardID }) ?? 0
        return Rectangle()
            .foregroundStyle(.clear)
            .overlay {
                Image(card.cardBackground)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            .overlay {
                VStack {
                    HStack {
                        Text(card.cardCategory.rawValue)
                            .monospaced()
                            .fontWeight(.semibold)

                        Spacer(minLength: 0)

                        Text(card.cardType.rawValue)
                            .monospaced()
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.primary)

                    Spacer(minLength: 0)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.title)
                            .monospaced()

                        Text("**** 1234")
                            .monospaced()
                    }
                    .foregroundStyle(.white)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(20)
            }
            .clipShape(.rect(cornerRadius: 20))
            .frame(height: 220)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(animation) {
                    selectedCard = card
                }
            }
            // `.visualEffect` lets us read the view's own geometry (via `proxy`) inside a
            // closure that returns a modified view. Unlike `GeometryReader`, it does NOT
            // wrap the view in a new layout container, so it won't distort the stack.
            // The capture list `[info, isCardSelected]` pins the values at call time so
            // SwiftUI re-invokes the closure when they change.
            .visualEffect { [info, isCardSelected] content, proxy in
                let rect = proxy.frame(in: .scrollView)
                let bounds = info.containerSize

                // Cards above the tapped one (selectedCardIndex >= currentIndex): push UP
                // to the top of the scroll view (`-rect.minY` zeroes out their position).
                // Cards below the tapped one (selectedCardIndex < currentIndex): push DOWN
                // off the bottom (`bounds.height - rect.minY`).
                //
                // NOTE: `bounds.height` comes from `info.containerSize`, populated by the
                // `.onGeometryChange(for: CGSize.self)` modifier on the NavigationStack.
                // If that modifier is removed, `bounds.height == 0`, so the push-down
                // branch becomes `-rect.minY` — identical to the push-up branch. Every
                // card then stacks at the top regardless of which one was tapped, which
                // looks like "index 0 is always selected."
                let pushOffset = selectedCardIndex < currentIndex ? (bounds.height - rect.minY) : -rect.minY
                let scale = selectedCardIndex < currentIndex ? 1 : 0.95
                return content
                    .offset(y: isCardSelected ? pushOffset : 0)
                    .scaleEffect(isCardSelected ? (isCurrent ? 1 : scale) : 1, anchor: .top)
            }
            // Once a card is selected, only the selected one accepts taps — prevents
            // stray taps on the off-screen stack from re-selecting.
            .allowsHitTesting(isCardSelected ? isCurrent : true)
    }

    struct Info {
        var scrollOffset: CGFloat = 0
        var containerSize: CGSize = .zero
        var safeArea: EdgeInsets = .init()
        var minY: CGFloat = 0
    }

    var animation: Animation = .interactiveSpring(response: 0.55, dampingFraction: 0.8)

    var isCardSelected: Bool { selectedCard != nil }

    var selectedCardID: String? {
        selectedCard?.id
    }

    var schemaBackground: Color {
        colorScheme == .dark ? .white : .black
    }
}

struct TransactionSheetView: View {
    var payment: PaymentType
    var body: some View {
        DummyMessagesView(count: 5)
    }
}

@available(iOS 26.0, *)
#Preview {
    WalletDemoView()
}
