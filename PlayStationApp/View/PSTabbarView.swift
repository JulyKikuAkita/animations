//
//  PSTabbarView.swift
//  PlayStationApp

import SwiftUI

struct PSTabbarView: View {
    @Binding var activeTab: PS_Tab
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(PS_Tab.allCases, id: \.rawValue) { tab in
                    Image(tab.rawValue)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .frame(maxWidth: .infinity)
                    
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .padding(.bottom, safeArea.bottom == 0 ? 15 : safeArea.bottom)
        .background {
            ZStack {
                /// Adding border
                TabBarTopCurve()
                    .stroke(.black, lineWidth: 0.5)
                    .blur(radius: 0.5)
                    .padding(.horizontal, -10)
                
                TabBarTopCurve()
                    .fill(.pink.opacity(0.5).gradient)
            }
        }
        .overlay {
            GeometryReader { proxy in
                let rect = proxy.frame(in: .global)
                let width = rect.width
                let maxedWidth = width * 5
                let height = rect.height
                
                Circle()
                    .fill(.orange)
                    .frame(width: maxedWidth, height: maxedWidth)
                    .frame(width: width)
                    /// custom indicator
                    .overlay(content: {
                        Rectangle()
                            .fill(.white)
                            .frame(width: 34, height: 4)
                            .offset(y: -1.5)
                        /// when at center, move to top location
                            .offset(y: -maxedWidth / 2)
                    })
                    .offset(y: height / 2.1)
                
            }
        }
        .preferredColorScheme(.light)
    }
    
    /// https://www.youtube.com/watch?v=4zyuGXTyZ80 at 8:00
    /// calculating rotate using Trigonometry
    func rotation() -> CGFloat {
        return .zero
    }
    ///  Offset based on Tab position
    ///  Offset gradually increased until mid tab and then decreasing, produce a smooth circle type layout
    ///  index 0: 0
    ///  index 1: -10
    ///  index 2: -20
    ///  index 3: -10
    ///  index 4: 0
    func offset(_ tab: PS_Tab) -> CGFloat {
        let totalIndices = PS_Tab.count
        let currentIndex = tab.index
        let progress = currentIndex / totalIndices
        
        return progress < 0.5 ? (currentIndex * -10) : (
            (totalIndices - currentIndex - 1) * -10
        )
    }
}

#Preview {
    ContentView()
}

/// Tab bar custom shapes
struct TabBarTopCurve: Shape {
    func path(in rect: CGRect) -> Path {
        return Path { path in
            let width = rect.width
            let height = rect.height
            let midWith = width / 2
            
            path.move(to: .init(x: 0, y: 5))
            
            /// Adding Curve
            path
                .addCurve(
                    to: .init(x: midWith, y: -20),
                    control1: .init(x: midWith / 2, y: -20),
                    control2: .init(x: midWith, y: -20)
                )
            
            path
                .addCurve(
                    to: .init(x: width, y: -5),
                    control1: .init(x: midWith + (midWith / 2), y: -20),
                    control2: .init(x: width, y: -5)
                )
            
            /// complete rectangle
            path.addLine(to: .init(x: width, y: height))
            path.addLine(to: .init(x: 0, y: height))
            
            /// closing path
            path.closeSubpath()
        }
    }
}
