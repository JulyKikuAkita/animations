//
//  RotatingIconEffectView.swift
//  animation
import SwiftUI

struct RotatingIconEffectDemoView: View {
    /// View properties
    @State private var selectedSportItem : SportItem = sportItems.first!
    @State private var introSportItems : [SportItem] = sportItems
    @State private var activeIndex: Int = 0
    var body: some View {
        VStack(spacing: 0) {
            /// Back button
            Button {
                updateItem(isForward: false)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.bold())
                    .foregroundStyle(.green.gradient)
                    .contentShape(.rect)
            }
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            /// only visible from the second item
            .opacity(selectedSportItem.id != introSportItems.first?.id ? 1 : 0)
            
            /// Animated icons
            ZStack {
                ForEach(introSportItems) { item in
                    AnimatedIconView(item)
                }
            }
            .frame(height: 250)
            .frame(maxHeight: .infinity)
            
            VStack(spacing: 6) {
                /// Progress indicator
                HStack(spacing: 4) {
                    ForEach(introSportItems) { item in
                        Capsule()
                            .fill(selectedSportItem.id == item.id ? Color.primary : .gray)
                            .frame(width: selectedSportItem.id == item.id ? 25 : 4, height: 4)
                    }
                }
                Text(selectedSportItem.title)
                    .font(.title.bold())
                    .contentTransition(.numericText())
                
                Text("RotatingIconEffectView Demo")
                    .font(.caption2)
                    .foregroundStyle(.gray)
                
                /// Next/Continue button
                Button {
                    updateItem(isForward: true)
                } label: {
                    Text(selectedSportItem.id == introSportItems.last?.id ? "Continue" : "Next")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .frame(width: 250)
                        .padding(.vertical, 12)
                        .background(.green.gradient, in: .capsule)
                }
                .padding(.top, 25)
            }
            .multilineTextAlignment(.center)
            .frame(width: 300)
            .frame(maxHeight: .infinity)
        }
    }
    
    @ViewBuilder
    func AnimatedIconView(_ item: SportItem) -> some View {
        let isSelected = selectedSportItem.id == item.id
        Image(systemName: item.image)
            .font(.system(size: 80))
            .foregroundStyle(.white.shadow(.drop(radius: 10)))
            .blendMode(.overlay)
            .frame(width: 120, height: 120)
            .background(.green.gradient, in: .rect(cornerRadius: 32))
            .background {
                RoundedRectangle(cornerRadius: 35)
                    .fill(.background)
                    .shadow(color: .primary.opacity(0.2) ,radius: 1, x: 1, y: 1)
                    .shadow(color: .primary.opacity(0.2) ,radius: 1, x: -1, y: -1)
                    .padding(-3)
                    .opacity(selectedSportItem.id == item.id ? 1 : 0)
            }
            /// Resetting rotation
            .rotationEffect(.init(degrees: -item.rotation))
            .scaleEffect(isSelected ? 1.1 : item.scale, anchor: item.anchor)
            .offset(x: item.offset)
            .rotationEffect(.init(degrees: item.rotation))
            /// placing the selected icon at the top
            .zIndex(isSelected ? 2 : item.zIndex)
    }
    
    /// shift the active icon to the center when continue or back button is pressed
    func updateItem(isForward: Bool) {
        guard isForward ? activeIndex != introSportItems.count - 1 : activeIndex != 0 else { return }
        var fromIndex: Int
        var extraOffset: CGFloat
        
        /// To Index
        if isForward {
            activeIndex += 1
        } else {
            activeIndex -= 1
        }
        
        /// From Index
        if isForward {
            fromIndex = activeIndex - 1
            extraOffset = introSportItems[activeIndex].extraOffset
        } else {
            extraOffset = introSportItems[activeIndex].extraOffset
            fromIndex = activeIndex + 1
        }
        
        /// Resetting zIndex
        for index in introSportItems.indices {
            introSportItems[index].zIndex = 0
        }
        
        /// Swift 6 error
        Task { [fromIndex, activeIndex] in
            withAnimation(.bouncy(duration: 1)) {
                introSportItems[fromIndex].scale = introSportItems[activeIndex].scale
                introSportItems[fromIndex].rotation = introSportItems[activeIndex].rotation
                introSportItems[fromIndex].anchor = introSportItems[activeIndex].anchor
                introSportItems[fromIndex].offset = introSportItems[activeIndex].offset
                
                /// Temporary adjustment
                introSportItems[activeIndex].offset = extraOffset
                
                /// when selected item is updated, the view pushed the from card all the way from the back by zIndex
                ///  To resolve this, make use of zIndex property to just place the from card below the to card
                ///  E.g., To card position: 2
                ///  From card position: 1, others 0
                introSportItems[fromIndex].zIndex = 1
            }
            
            try? await Task.sleep(for: .seconds(0.1))
            
            withAnimation(.bouncy(duration: 0.9)) {
                /// To location is always at the center
                introSportItems[activeIndex].scale = 1
                introSportItems[activeIndex].rotation = .zero
                introSportItems[activeIndex].anchor = .center
                introSportItems[activeIndex].offset = .zero
                
                /// Updating selected item
                selectedSportItem = introSportItems[activeIndex]
            }
        }
    }
}

struct RotatingIconEffectView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    RotatingIconEffectDemoView()
}