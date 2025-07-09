//
//  iOS26OnBoardingSheet.swift
//  animation
//
//  Created on 7/8/25.

import SwiftUI

struct OnBoardingSheetiOS26Demo: View {
    @State private var showOnBoarding: Bool = true
    var body: some View {
        NavigationStack {
            List {}
                .navigationTitle("Game Arcade")
        }
        .sheet(isPresented: $showOnBoarding) {
            AppleonBoardingView(
                tint: .red,
                title: "Welcome to Arcade"
            ) {
                /// ICON
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 50))
                    .frame(width: 100, height: 100)
                    .foregroundStyle(.white)
                    .background(.red.gradient, in: .rect(cornerRadius: 25))
                    .frame(height: 180)
            }
            cards: {
                OnBoardingCard(
                    symbol: "list.bullet",
                    title: "See What's New. Just for you",
                    subTitle: "Explore what's happending in your games and what to play next."
                )
                OnBoardingCard(
                    symbol: "person.2",
                    title: "Play and Compete with Friends",
                    subTitle: "Challenge friends, see what they're playing and play together."
                )
                OnBoardingCard(
                    symbol: "square.stack",
                    title: "All your Games in One Place",
                    subTitle: "Access your full game library from anywhere."
                )
            }
            footer: {
                VStack(alignment: .leading, spacing: 6) {
                    Image(systemName: "person.3.fill")
                        .foregroundStyle(.red)

                    Text("Your gameplay information, inclduing what you play and your game activity, is used to improve Game Center.")
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
                .padding(.vertical, 15)
            }
            onContinue: {
                showOnBoarding = false
            }
        }
    }
}

@resultBuilder
struct OnBoardingCardResultBuilder {
    static func buildBlock(_ components: OnBoardingCard...) -> [OnBoardingCard] {
        components.compactMap(\.self)
    }
}

struct AppleonBoardingView<Icon: View, Footer: View>: View {
    var tint: Color
    var title: String
    var icon: Icon
    var cards: [OnBoardingCard]
    var footer: Footer
    var onContinue: () -> Void

    init(tint: Color, title: String, @ViewBuilder icon: @escaping () -> Icon,
         @OnBoardingCardResultBuilder cards: @escaping () -> [OnBoardingCard],
         @ViewBuilder footer: @escaping () -> Footer,
         onContinue: @escaping () -> Void)
    {
        self.tint = tint
        self.title = title
        self.icon = icon()
        self.cards = cards()
        self.footer = footer()
        self.onContinue = onContinue

        /// init the animateCards array value to match the card count
        _animateCards = .init(
            initialValue: Array(repeating: false, count: self.cards.count)
        )
    }

    /// View Properties
    @State private var animateIcon: Bool = false
    @State private var animateTitle: Bool = false
    @State private var animateCards: [Bool]
    @State private var animateFooter: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 20) {
                    icon
                        .frame(maxWidth: .infinity)
                        .blurSlide(animateIcon)

                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .blurSlide(animateTitle)

                    cardsView()
                }
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)

            VStack(spacing: 0) {
                footer

                Button(action: onContinue) {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                    #if os(macOS)
                        .padding(.vertical, 8)
                    #else
                        .padding(.vertical, 4)
                    #endif
                }
                .tint(tint)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .padding(.bottom, 10)
            }
            .blurSlide(animateFooter)
        }
        /// limit maxWidth to 330
        .frame(maxWidth: 330)
        /// disable interactive dismissal
        .interactiveDismissDisabled()
        /// Disable interaction until footer is animated
        .allowsHitTesting(animateFooter)
        .task {
            guard !animateIcon else { return }

            /// We need to set initial delay as 0.35 for waiting sheet animation to complete
            /// and avoid unwated view interactions
            await delayedAnimation(0.35) {
                animateIcon = true
            }

            await delayedAnimation(0.2) {
                animateTitle = true
            }

            try? await Task.sleep(for: .seconds(0.2))

            for index in animateCards.indices {
                let delay = Double(index) * 0.1 // you custom value
                await delayedAnimation(delay) {
                    animateCards[index] = true
                }
            }

            await delayedAnimation(0.2) {
                animateFooter = true
            }
        }
        .setupOnBoarding()
    }

    /// Specify indices here for animation purpose
    func cardsView() -> some View {
        Group {
            ForEach(cards.indices, id: \.self) { index in
                let card = cards[index]
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: card.symbol)
                        .font(.title2)
                        .foregroundStyle(.tint)
                        .symbolVariant(.fill)
                        .frame(width: 45)
                        .offset(y: 10)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(card.title)
                            .font(.title3)
                            .lineLimit(1)

                        Text(card.subTitle)
                            .lineLimit(2)
                    }
                }
                .blurSlide(animateCards[index])
            }
        }
    }

    func delayedAnimation(_ delay: Double, action: @escaping () -> Void) async {
        try? await Task.sleep(for: .seconds(delay))

        withAnimation(.smooth) {
            action()
        }
    }
}

#Preview {
    OnBoardingSheetiOS26Demo()
}

extension View {
    /// use compositingGroup to group the view and apply blur to gether rather than to each node view
    func blurSlide(_ show: Bool) -> some View {
        compositingGroup()
            .blur(radius: show ? 0 : 10)
            .opacity(show ? 1 : 0)
            .offset(y: show ? 0 : 100)
    }

    @ViewBuilder
    fileprivate func setupOnBoarding() -> some View {
        #if os(macos)
            padding(.horizontal, 20)
                .frame(minHeight: 600)
        #else
            if UIDevice.current.userInterfaceIdiom == .pad {
                /// Making it to be fitted on iPadOS 18+ devices
                if #available(iOS 18, *) {
                    self
                        .presentationSizing(.fitted)
                        .padding(.horizontal, 20)
                } else {
                    self
                }
            } else {
                self
            }
        #endif
    }
}
