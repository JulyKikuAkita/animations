//
//  CircularCarouselSliderView.swift
//  animation
//
//  Created by IFang Lee on 4/4/24.
//

import SwiftUI

struct CircularCarouselSliderView: View {
    /// View properties
    @State private var pickerType: TripPicker = .normal
    @State var cards: [Card] = firstSetCards
    @State private var activeID: String? /// ios 17 api to track scroll view position
    var body: some View {
        VStack {
            Picker("", selection: $pickerType) {
                ForEach(TripPicker.allCases, id:\.rawValue) {
                    Text($0.rawValue)
                        .tag($0)
                }
            }
            .pickerStyle(.segmented)
//            .padding()
            
//            Spacer(minLength: 0)
            
            GeometryReader {
                let size = $0.size
                let padding = (size.width - 70) / 2
                
                /// Circular Slider
                ScrollView(.horizontal) {
                    HStack(spacing: 35) {
                        ForEach(cards, id: \.image) { card in
                            Image(card.image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 70, height: 70)
                                .clipShape(.circle)
                                /// Shadow
                                .shadow(color: .black.opacity(0.15), radius: 5, x: 5, y: 5)
                                .visualEffect { view, proxy in
                                    view
                                        .offset(y: offSet(proxy))
                                        .offset(y: scale(proxy) * 15) /// use scroll progress to achieve circular slider
                                } /// iOS 17 api to achieve circular slider (or use scroll progress)
                                .scrollTransition(.interactive, axis: .horizontal) { view, phase in
                                    view
//                                    .offset(y: phase.isIdentity && activeID == card.image ? 15 : 0)
                                      .scaleEffect(phase.isIdentity && activeID == card.image && pickerType == .scaled ? 1.5 : 1, anchor: .bottom) // use activeID to enlarge the center image
                                    
                                }
                        }
                    }
                    .frame(height: size.height)
                    .offset(y: -30)
//                    .padding(.horizontal, padding)  // comparing padding vs safeAreaPadding
                    .scrollTargetLayout()
                }
                .background(content: {
                    if pickerType == .normal {
                        Circle()
                            .fill(.white.shadow(.drop(color: .black.opacity(0.2), radius: 5)))
                            .frame(width: 85, height: 85)
                            .offset(y: -15)
                    }
                })
                .safeAreaPadding(.horizontal, padding)
                .scrollIndicators(.hidden)
                /// Snapping
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $activeID) /// ios 17 api to track scroll view posititon
                .frame(height: size.height)
            }
            .frame(height: 200)
//            .background(Color.green)
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }
    
    /// Circular slider view offset
    nonisolated func offSet(_ proxy: GeometryProxy) -> CGFloat {
        let progress = progress(proxy)
        /// Simply moving view up/down based on progress
        return progress < 0 ? progress * -30 : progress * 30
    }
    
    nonisolated func scale(_ proxy: GeometryProxy) -> CGFloat {
        let progress = min(max(progress(proxy), -1), 1)
        return progress < 0 ? 1 + progress : 1 - progress
    }
    
    nonisolated func progress(_ proxy: GeometryProxy) -> CGFloat {
        /// View Width
        let viewWidth = proxy.size.width
        let minX = (proxy.bounds(of: .scrollView)?.minX ?? 0)
        return minX / viewWidth
    }
}

#Preview {
    ContentView()
}

/// Slider Type
enum TripPicker: String, CaseIterable {
    case scaled = "Scaled"
    case normal = "Normal"
}
