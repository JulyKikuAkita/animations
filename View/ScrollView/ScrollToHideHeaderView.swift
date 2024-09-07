//
//  ScrollToHideHeaderView.swift
//  animation
import SwiftUI

@available(iOS 18.0, *)
struct ScrollToHideHeaderView: View {
    /// View properties
    @State private var naturalScrollOffset: CGFloat = 0
    @State private var lastNatureOffset: CGFloat = 0
    @State private var headerOffset: CGFloat = 0
    @State private var isScrollingUp: Bool = false
    var body: some View {
        GeometryReader {
            let safeArea = $0.safeAreaInsets
            let headerHeight = 60 + safeArea.top
            
            ScrollView(.vertical) {
                LazyVStack(spacing: 15) {
                    ForEach(1...50, id:\.self) { _ in
                        DummyCardView()
                    }
                }
                .padding(15)
            }
            .overlay(content: {
                Text("\(naturalScrollOffset) \(headerHeight)") //debug
            })
            .safeAreaInset(edge: .top, spacing: 0) {
                HeaderView()
                    .padding(.bottom, 15)
                    .frame(height: headerHeight, alignment: .bottom)
                    .background(.background)
                    .offset(y: -headerOffset)
            }
            .onScrollGeometryChange(for: CGFloat.self) { proxy in
                let maxHeight = proxy.contentSize.height - proxy.containerSize.height
                return max(min(proxy.contentOffset.y + headerHeight, maxHeight), 0) // fix bounce header view hidden
            } action: { oldValue, newValue in
                let isScrollingUp = oldValue < newValue
                headerOffset = min(
                    max(newValue - lastNatureOffset, 0),
                    headerHeight)
                self.isScrollingUp = isScrollingUp
                
                naturalScrollOffset = newValue
            }
            .onScrollPhaseChange({ oldPhase, newPhase, context in
                // when user stop scrolling and header animation is in between state
                if !newPhase.isScrolling && (
                    headerOffset != 0 || headerOffset != headerHeight
                ) {
                    withAnimation(.snappy(duration: 0.25, extraBounce: 0)) {
                        if headerOffset > (headerHeight * 0.5) && naturalScrollOffset > headerHeight {
                            headerOffset = headerHeight
                        } else {
                            headerOffset = 0
                        }
                        lastNatureOffset = naturalScrollOffset - headerOffset
                    }
                }
            })
            // show/hide header view based on scroll direction
            .onChange(of: isScrollingUp, { oldValue, newValue in
                lastNatureOffset = naturalScrollOffset - headerOffset
            })
            .ignoresSafeArea(.container, edges: .top)
        }
    }
    
    @ViewBuilder
    func HeaderView() -> some View {
        HStack(spacing: 20) {
            Image("fox")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 25)
            
            Spacer(minLength: 0)
            
            Button("", systemImage: "airplayvideo") {}
            
            Button("", systemImage: "bell") {}

            Button("", systemImage: "magnifyingglass") {}
        }
        .font(.title2)
        .foregroundStyle(Color.primary)
        .padding(.horizontal, 15)
    }
    
    @ViewBuilder
    func DummyCardView() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: 6)
                .frame(minHeight: 220)
            
            HStack(spacing: 10) {
                Circle()
                    .frame(width: 45, height: 45)
                
                VStack(alignment: .leading, spacing: 4) {
                    Rectangle()
                        .frame(height: 10)
                    
                    HStack(spacing: 10) {
                        Rectangle()
                            .frame(width: 100)
                        
                        Rectangle()
                            .frame(width: 80)
                        
                        
                        Rectangle()
                            .frame(width: 60)
                    }
                    .frame(height: 10)
                }
            }
        }
        .foregroundStyle(.tertiary)
    }
}

#Preview {
    if #available(iOS 18.0, *) {
        ScrollToHideHeaderView()
            .preferredColorScheme(.dark)
    } else {
        // Fallback on earlier versions
    }
}
