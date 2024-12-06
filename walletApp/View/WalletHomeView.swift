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
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
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
                
                /// Cards
                LazyVStack(spacing: 10) {
                    ForEach(cards) { card in
                            CardView(card)
                    }
                }
                .padding()
            }
            .safeAreaPadding(15)
            .safeAreaPadding(.top, safeArea.top)
        }
    }
    
    @ViewBuilder
    func CardView(_ card: CreditCardModel) -> some View {
        ZStack {
            Rectangle()
                .fill(card.color.gradient)
            
            /// details view
            VStack(alignment: .leading, spacing: 15) {
                Image(.bitcoin)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 20)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.number)
                        .font(.caption)
                        .foregroundStyle(.white.secondary)
                    
                    Text("$3878.98")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                
                HStack {
                    Text("Fox Mr")
                        .font(.callout)
                    
                    Spacer()
                    
                    Text("Expires: \(card.expires)")
                        .font(.caption)
                }
                .foregroundStyle(.white.secondary)
            }
            .padding(25)
        }
        .frame(height: 200)
        .clipShape(.rect(cornerRadius: 25))
        .onTapGesture {
            /// close action through back button
            guard !showDetailView else { return }
            withAnimation(.smooth(duration: 0.5, extraBounce: 0)) {
                selectedCard = card
                showDetailView = true
            }
        }
    }
}

#Preview {
    ContentView()
}
