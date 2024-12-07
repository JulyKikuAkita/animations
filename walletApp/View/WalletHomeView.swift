//
//  WalletHomeView.swift
//  walletApp

import SwiftUI

struct WalletHomeView: View {
    var size: CGSize
    var safeArea: EdgeInsets
    /// View Properties
    @State private var showDetailView: Bool = false
    @State private var selectedCard: CreditCardModel?
    @Namespace private var animation
    var body: some View {
        /// note: refrain from modifying the main view's frame to preserve the scroll position when coming back from detail view to the home view
        ScrollView(.vertical) {
            LazyVStack(spacing: 10) {
                Text("My Wallet")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity)
                    .overlay(alignment: .trailing) {
                        Button {
                            
                        } label: {
                            Image(.fox)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 35, height: 35)
                                .clipShape(.circle)
                        }
                    }
                /// adding fade effect when expanding detail view
                    .blur(radius: showDetailView ? 5 : 0)
                    .opacity(showDetailView ? 0 : 1)
                
                /// Cards
                ///  if use vStack, need to move the view -15 due to padding, not required for LazyVStack
                let mainOffset = CGFloat(cards.firstIndex(where: { $0.id == selectedCard?.id }) ?? 0) * -size.width
                
                LazyVStack(spacing: 10) {
                    ForEach(cards) { card in
                        /// convert the scroll view to horizontal view using offset modifier
                        let cardOffset = CGFloat(cards.firstIndex(where: { $0.id == card.id }) ?? 0) * size.width
                        
                        CardView(card)
                            .frame(width: showDetailView ? size.width : nil) /// occupy the full screen
                            .visualEffect { [showDetailView] content, proxy in
                                content
                                    .offset(x: showDetailView ? cardOffset : 0,
                                            y: showDetailView ? -proxy.frame(in: .scrollView).minY : 0)
                            
                        }
                    }
                }
                .padding(.top, 25)
                .offset(x: showDetailView ? mainOffset : 0)
            }
            .safeAreaPadding(15)
            .safeAreaPadding(.top, safeArea.top)
        }
        .scrollDisabled(showDetailView) /// disable scroll when detail view is show
        .scrollIndicators(.hidden)
        .overlay {
            if let selectedCard, showDetailView {
                DetailView(selectedCard: selectedCard)
                    .padding(.top, expandedCardHeight)
                    .transition(.move(edge: .bottom))
            }
        }
    }
    
    @ViewBuilder
    func CardView(_ card: CreditCardModel) -> some View {
        ZStack {
            Rectangle()
                .fill(card.color.gradient)
            
            /// details view
            VStack(alignment: .leading, spacing: 15) {
                if !showDetailView {
                    CardNetworkImageView(card.jcbGeometryID, height: 40)
                }
                
                Spacer(minLength: 0)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.number)
                        .font(.caption)
                        .foregroundStyle(.white.secondary)
                    
                    Text("$3878.98")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: showDetailView ? .center : .leading)
                .overlay {
                    /// Moving the icon using match geometry effect
                    if showDetailView {
                        CardNetworkImageView(card.jcbGeometryID, height: 20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .offset(y: 30) /// push image to bottom
                    }
                    
                    if let selectedCard, selectedCard.id == card.id, showDetailView {
                        /// Closing detail view
                        Button {
                            withAnimation(.smooth(duration: 0.5, extraBounce: 0)) {
                                self.selectedCard = nil
                                showDetailView = false
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                                .contentShape(.rect)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.asymmetric(insertion: .opacity, removal: .identity))
                    }
                    
                }
                .padding(.top, showDetailView ? safeArea.top - 10 : 0)
                
                HStack {
                    Text("Expires: \(card.expires)")
                        .font(.caption)
                    
                    Spacer()

                    Text("Fox Mr")
                        .font(.callout)
                }
                .foregroundStyle(.white.secondary)
            }
            .padding(showDetailView ? 15: 25)
        }
        .frame(height: showDetailView ? 130 : nil)
        .frame(height: 200, alignment: .top) //keep this to preserve the scroll position when dismiss from detail view
        .clipShape(.rect(cornerRadius: showDetailView ? 0: 25))
        .onTapGesture {
            /// close action through back button
            guard !showDetailView else { return }
            withAnimation(.smooth(duration: 0.5, extraBounce: 0)) {
                selectedCard = card
                showDetailView = true
            }
        }
    }
    
    @ViewBuilder
    func CardNetworkImageView(_ id: String, height: CGFloat) -> some View {
        Image(.JCB)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .matchedGeometryEffect(id: id, in: animation)
            .frame(height: height)
    }
    
    /// occupied the safeArea top when expanded
    var expandedCardHeight: CGFloat {
        safeArea.top + 130
    }
}

/// placing a tmp view or any view you like
struct DetailView: View {
    var selectedCard: CreditCardModel
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 12) {
                ForEach(1...20, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 15)
                        .fill(.black.gradient)
                        .frame(height: 45)
                }
            }
            .padding(15)
        }
    }
}

#Preview {
    ContentView()
}
