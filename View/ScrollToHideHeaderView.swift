//
//  ScrollToHideHeaderView.swift
//  animation
//
//  With iOS 18 Scroll API
// TODO: 3:23
// https://www.youtube.com/watch?v=C6fO9jsaOBg
import SwiftUI

@available(iOS 18.0, *)
struct ScrollToHideHeaderView: View {
    @State private var naturalScrollOffset: CGFloat = 0
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
            .safeAreaInset(edge: .top, spacing: 0) {
                HeaderView()
                    .padding(.bottom, 15)
                    .frame(height: headerHeight, alignment: .bottom)
                    .background(.background)
            }
            .onScrollGeometryChange(for: CGFloat.self) { proxy in
                proxy.contentOffset.y
            } action: { oldValue, newValue in
                print(newValue)
            }
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
