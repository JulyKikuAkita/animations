//
//  WalletCardView.swift
//  walletApp
import SwiftUI

enum ActiveField {
    case none
    case number
    case name
    case month
    case year
    case cvv
}

struct WalletCardView: View {
    @State private var card: CreditCardModel = .init(secretNumber: "", month: "", year: "", color: .black)
    @FocusState private var activeField: ActiveField? /// buggy for animate
    @State private var animateField: ActiveField?
    @Namespace private var animation
    var body: some View {
        VStack(spacing: 15) {
            ZStack {
                if activeField == .cvv {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(.red.mix(with: .blue, by: 0.2))
                        .overlay {
                            CardBackView()
                        }
                        .frame(height: 200)
                        .transition(.reverseFlip)
                } else {
                    CardMeshBackground()
                       .clipShape(.rect(cornerRadius: 25))
                       .overlay {
                           CardFrontView()
                       }
                       .transition(.flip)
                }
            }
            .frame(height: 200)

            
            /// Limiting length of 16 and adding spacing for each 4-digit group
            CustomTextField(title: "Card Number", hint: "", value: $card.secretNumber) {
                /// 16 digits + 3 space
                card.secretNumber = String(card.secretNumber.group(" ", count: 4).prefix(19))
            }
            .focused($activeField, equals: .number)
            
            CustomTextField(title: "Card Nick Name", hint: "", value: $card.name) {
                /// feel free to customize
            }
            .focused($activeField, equals: .name)

            
            HStack(spacing: 10) {
                /// Limiting length of 2
                CustomTextField(title: "Month", hint: "", value: $card.month) {
                    card.month = String(card.month.prefix(2))
                    
                    /// auto switch to year textfield
                    if card.month.count == 2 {
                        activeField = .year
                    }
                }
                .focused($activeField, equals: .month)
                
                /// Limiting length of 2
                CustomTextField(title: "Year", hint: "", value: $card.year) {
                    card.year = String(card.year.prefix(2))
                }
                .focused($activeField, equals: .year)

                /// Limiting length of 3
                CustomTextField(title: "CVV", hint: "", value: $card.cvv) {
                    card.cvv = String(card.cvv.prefix(3))
                }
                .focused($activeField, equals: .cvv)
            }
            .keyboardType(.numberPad)
            
            Spacer(minLength: 0)
        }
        .padding()
        .onChange(of: activeField) { oldValue, newValue in
            withAnimation(.snappy) {
                animateField = newValue
            }
        }
        /// Close button
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                Button("Done") {
                    activeField = nil
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
    
    @ViewBuilder
    func CardFrontView() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            VStack(alignment: .leading, spacing: 4) {
                Text("CARD NUMBER")
                    .font(.caption)
                
                /// display a default dummy value and the replace in run time while user input card number
                Text(
                    String(card.secretNumber.dummyText("*", count: 16).prefix(16))
                        .group(" ", count: 4)
                )
                .font(.title2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(AnimatedRing(animateField == .number))
            .frame(maxHeight: .infinity)
            
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CARD HOLDER")
                        .font(.caption)
                    
                    Text(card.name.isEmpty ? "YOUR NAME" : card.name)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(AnimatedRing(animateField == .name))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("EXPIRES")
                        .font(.caption)
                    
                    HStack(spacing: 4) {
                        Text(card.month.dummyText("M", count: 2))
                        Text("/")
                        Text(card.year.dummyText("Y", count: 2))
                    }
                }
                .padding(10)
                .background(AnimatedRing(animateField == .month || animateField == .year))
            }
        }
        .foregroundStyle(.white)
        .monospaced()
        .contentTransition(.numericText())
        .animation(.snappy, value: card)
        .padding(15)
    }
    
    @ViewBuilder
    func CardBackView() -> some View {
        VStack(spacing: 15) {
            Rectangle()
                .fill(.black)
                .frame(height: 45)
                .padding(.horizontal, -15)
                .padding(.top, 10)
            
            VStack(alignment: .trailing, spacing: 6) {
                Text("CVV")
                    .font(.caption)
                    .padding(.trailing, 10)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white)
                    .frame(height: 45)
                    .overlay(alignment: .trailing) {
                        Text(String(card.cvv.prefix(3)).dummyText("*", count: 3))
                            .foregroundStyle(.black)
                            .padding(.trailing, 15)
                    }
            }
            .foregroundStyle(.white)
            .monospaced()
            
            Spacer(minLength: 0)
        }
        .padding(15)
        .contentTransition(.numericText())
        .animation(.snappy, value: card)
    }
    
    /// Highlight effect with focused textfield
    @ViewBuilder
    func AnimatedRing(_ status: Bool) -> some View {
        if status {
            RoundedRectangle(cornerRadius: 10)
                .stroke(.white, lineWidth: 1.5)
                .matchedGeometryEffect(id: "RING", in: animation)
        }
    }
}

/// Custom Sectioned TextField
struct CustomTextField: View {
    var title: String
    var hint: String
    @Binding var value: String
    var onChange: () -> ()
    /// View Properties
    @FocusState private var isActive: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.gray)
            
            TextField(hint, text: $value)
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
                .contentShape(.rect)
                .background {
                    /// Changing Stoke color when active
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isActive ? .blue : .gray.opacity(0.5), lineWidth: 1.5)
                        .animation(.snappy, value: isActive)
                }
                .focused($isActive)
        }
        .onChange(of: value) { oldValue, newValue in
                onChange()
        }
    }
}

struct CardMeshBackground: View {
    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                .init(0, 0), .init(0.5, 0), .init(1, 0),
                .init(0, 0.5), .init(0.9, 0.6), .init(1, 0.5),
                .init(0, 1), .init(0.5, 1), .init(1, 1)
            ],
            colors: [
                .red, .red, .pink,
                .pink, .orange, .red,
                .red, .orange, .red
            ]
        )
    }
}


#Preview {
    WalletCardView()
}


