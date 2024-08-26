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
                        .offset(y: offset(tab))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.7)) {
                                activeTab = tab
                            }
                        }
                        .frame(maxWidth: .infinity)
                    
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .padding(.bottom, safeArea.bottom == 0 ? 30 : safeArea.bottom)
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
                    .fill(.clear)
                    .frame(width: maxedWidth, height: maxedWidth)
                    .background(alignment: .top) {
                        Rectangle()
                            .fill(
                                .linearGradient(
                                    colors: [
                                        .purple.opacity(0.2),
                                        .purple.opacity(0.5),
                                        .purple.opacity(0.5),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            /// Masking into a big circle shape
                            .mask(alignment: .top) {
                                Circle()
                                    .frame(
                                        width: maxedWidth,
                                        height: maxedWidth,
                                        alignment: .top)
                            }
                    }
                    /// Border
                    .overlay {
                        Circle()
                            .stroke(.white, lineWidth: 0.2)
                            .blur(radius: 0.5)
                    }
                    .frame(width: width)
                    /// custom indicator
                    .background(content: {
                        Rectangle()
                            .fill(.white)
                            .frame(width: 45, height: 4)
                            /// custom glow effect
                            .glow(.white.opacity(0.5), radius: 50)
                            .glow(.yellow.opacity(0.7), radius: 30)
                            .offset(y: -1.5)
                            /// when at center, move to top location
                            .offset(y: -maxedWidth / 2)
                            .rotationEffect(.init(degrees: calculateRotation(maxedWidth: maxedWidth / 2, actualWidth: width, true)))
                            .rotationEffect(.init(degrees: calculateRotation(maxedWidth: maxedWidth / 2, actualWidth: width)))
                    })
                    .offset(y: height / 2.1)
                
            }
            /// Active Tab text
            .overlay(alignment: .bottom) {
                Text(activeTab.rawValue)
                    .font(.system(size: 14))
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .offset(y: safeArea.bottom == 0 ? -15 : -safeArea.bottom + 12)
            }
        }
        .preferredColorScheme(.light)
    }
    
    /// https://www.youtube.com/watch?v=4zyuGXTyZ80 at 8:00-8:10 to get 85.4 degree s of rotation
    ///  tan - 1(y/x) = tan - 1(975/78) = tan -1(12.5) = 1.4 radians == 84.5 degrees
    /// calculating rotate using Trigonometry
    func calculateRotation(maxedWidth y: CGFloat, actualWidth: CGFloat, _ isInitial: Bool = false) -> CGFloat {
        let tabWidth = actualWidth / PS_Tab.count
        let firstTabPositionX: CGFloat = -(actualWidth - tabWidth) / 2 /// tested by return this value to validate indicator
        let tan = y / firstTabPositionX
        let radians = atan(tan) /// reverse of tan == atan
        let degree = radians * 180 / .pi
        
        if isInitial {
            return -(degree + 90)
        }
        
        let x = tabWidth * activeTab.index
        let tan_ = y / x
        let radian_ = atan(tan_)
        let degree_ = radian_ * 180 / .pi
        
        return -(degree_ - 90)
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
