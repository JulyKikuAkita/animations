//
//  FlipClockTextEffectView.swift
//  animation

import SwiftUI

struct FlipClockTextEffectDemoView: View {
    var body: some View {
        NavigationStack {
            VStack {
                FlipClockTextEffectView(
                    value: 0,
                    size: CGSize(width: 100, height: 150),
                    fontSize: 70,
                    cornerRadius: 10,
                    foreground: .white,
                    background: .green
                )
            }
            .padding()
        }
    }
}
struct FlipClockTextEffectView: View {
    var value: Int
    /// Config
    var size: CGSize
    var fontSize: CGFloat
    var cornerRadius: CGFloat
    var foreground: Color
    var background: Color
    
    /// View Properties
    @State private var nextValue: Int = 1
    @State private var currentValue: Int = 0
    @State private var rotation: CGFloat = 0

    var body: some View {
        let halfHeight = size.height * 0.5
        ZStack {
            UnevenRoundedRectangle(
                topLeadingRadius: cornerRadius,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: cornerRadius
            )
            .fill(background.gradient.shadow(.inner(radius: 1)))
            .frame(height: halfHeight)
            .overlay(alignment: .top) {
                TextView(nextValue)
                    .frame(width: size.width, height: size.height)
            }
            .clipped()
            .frame(maxHeight: .infinity, alignment: .top)
            
            UnevenRoundedRectangle(
                topLeadingRadius: cornerRadius,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: cornerRadius
            )
            .fill(background.gradient.shadow(.inner(radius: 1)))
            .frame(height: halfHeight)
            .modifier(
                RotationModifier(
                    rotation: rotation,
                    currentValue: currentValue,
                    nextValue: nextValue,
                    fontSize: fontSize,
                    foreground: foreground,
                    size: size
                )
            )
            .clipped()
            .rotation3DEffect(
                .init(degrees: rotation),
                axis: (x: 1.0, y: 0.0, z: 0.0),
                anchor: .bottom,
                perspective: 0.4
            )
            .frame(maxHeight: .infinity, alignment: .top)
            .zIndex(10)
            
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: cornerRadius,
                bottomTrailingRadius: cornerRadius,
                topTrailingRadius: 0
            )
            .fill(background.gradient.shadow(.inner(radius: 1)))
            .frame(height: halfHeight)
            .overlay(alignment: .bottom) {
                TextView(currentValue)
                    .frame(width: size.width, height: size.height)
            }
            .clipped()
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(width: size.width, height: size.height)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 3)) {
                rotation = -180
            }
        }
        // TODO: 6:22
    // https://www.youtube.com/watch?v=Lekoc7QS-K4&list=PLimqJDzPI-H97JcePxWNwBXJoGS-Ro3a-&index=108
    }
    
    @ViewBuilder
    func TextView(_ value: Int) -> some View  {
        Text("\(value)")
            .font(.system(size: fontSize).bold())
            .foregroundStyle(foreground)
    }
}

/// when rotate > 90 degrees, the text content needs to updated to the next value
/// since default swiftUI behavior is the end value will be directly reflected rather than progression
/// we need to use animatableData to progressively update the value from start to end
fileprivate struct RotationModifier: ViewModifier, Animatable {
    var rotation: CGFloat
    var currentValue: Int
    var nextValue: Int
    var fontSize: CGFloat
    var foreground: Color
    var size: CGSize
    var animatableData: CGFloat {
        get { rotation }
        set { rotation = newValue }
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                Group {
                    if -rotation > 90 {
                        Text("\(nextValue)")
                            .font(.system(size: fontSize).bold())
                            .foregroundStyle(foreground)
                            .scaleEffect(x: 1, y: -1) /// flip the view since it's been rotated
                            .transition(.identity)
                    } else {
                        Text("\(currentValue)")
                            .font(.system(size: fontSize).bold())
                            .foregroundStyle(foreground)
                            .transition(.identity)
                    }
                }
                .frame(width: size.width, height: size.height)
            }
    }
  
}

#Preview {
    FlipClockTextEffectDemoView()
}
