//
//  ThemeSwitcherIOS27.swift
//  animation
//
//  Created on 10/11/26.

import SwiftUI

@available(iOS 27.0, *)
private struct ThemePickerDemo: View {
    @State private var showPicker: Bool = false
    @State private var activeTheme: Theme = .light
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack {}
            .themePickerIOS27(
                isPresented: $showPicker,
                value: $activeTheme,
                envColorScheme: colorScheme
            )
            .onAppear {
                showPicker = true
            }
            .preferredColorScheme(activeTheme == .light ? .light : activeTheme == .dark ? .dark : nil)
    }
}

@available(iOS 27.0, *)
struct ThemePickerIOS27: View {
    var colorScheme: ColorScheme
    @Binding var value: Theme
    init(value: Binding<Theme>, colorTheme: ColorScheme) {
        _value = value
        colorScheme = colorTheme

        isDark = colorScheme == .dark
    }

    /// View Properties
    @State private var isDark: Bool
    @Namespace private var animation
    var body: some View {
        VStack(spacing: 15) {
            animatedPreview()
                .frame(height: 200)

            themeSegmentControl()

            Text(value.captionText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .animation(.smooth(duration: 0.45, extraBounce: 0), value: value)
        }
        .padding(.horizontal, 15)
        .padding(.top, 15)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .presentationBackground(isDark ? .black.mix(with: .white, by: 0.2) : .white)
        .onChange(of: colorScheme) { _, newValue in
            let isDark = newValue == .dark
            DispatchQueue.main.async {
                withAnimation(.interpolatingSpring(duration: 1, bounce: 0, initialVelocity: 0)) {
                    self.isDark = isDark
                }
            }
        }
        // debug only
//        .onTapGesture {
//            withAnimation(.interpolatingSpring(duration: 1, bounce: 0, initialVelocity: 0)) {
//                isDark.toggle()
//            }
//        }
    }

    @ContentBuilder
    private func themeSegmentControl() -> some View {
        HStack(spacing: 0) {
            ForEach(Theme.allCases, id: \.rawValue) { theme in
                let isSelected = value == theme
                let tintColor: Color = isDark ? .indigo : .yellow.mix(with: .orange, by: 0.2)
                let rotation: CGFloat = theme == .light ? 180 : theme == .dark ? -15 : (isDark ? 180 : 0)

                HStack(spacing: 8) {
                    Image(systemName: theme.symbol)
                        .font(.system(size: 16))
                        .foregroundStyle(isSelected ? tintColor : isDark ? .white : .black)
                        .environment(\.colorScheme, .light)
                        .rotationEffect(.init(degrees: isSelected ? rotation : 0))

                    Text(theme.rawValue)
                        .font(.callout)
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    if isSelected {
                        ZStack {
                            Capsule()
                                .fill(isDark ? .black : .white)

                            Capsule()
                                .stroke(tintColor, lineWidth: 1.5)
                                .padding(0.5)
                        }
                        .compositingGroup()
                        .shadow(color: tintColor.opacity(0.3), radius: 10)
                        .matchedGeometryEffect(id: "CAPSULE", in: animation)
                    }
                }
                .onTapGesture {
                    value = theme
                }
            }
        }
        .frame(height: 40)
        .padding(4)
        .background(.gray.opacity(0.15), in: .capsule)
        .animation(.bouncy(duration: 0.5, extraBounce: 0.1), value: value)
    }

    @ContentBuilder
    private func animatedPreview() -> some View {
        GeometryReader {
            let size = $0.size
            let gradientColors = isDark ? [Color.darkTop, Color.darkBottom] : [Color.lightTop, Color.lightBottom]
            ZStack {
                LinearGradient(colors: gradientColors, startPoint: .top, endPoint: .bottom)

                // dark mode with stars
                StarsView(count: 15)
                    .opacity(isDark ? 1 : 0)

                celestialBodies(size: size)

                // dark mode with a shooing star
                shootingStar()

                // clouds
                clouds()

                // Ground layers
                groundLayers()
            }
        }
        .clipShape(ConcentricRectangle(corners: .concentric, isUniform: true))
    }

    private func celestialBodies(size: CGSize) -> some View {
        ZStack {
            Image(systemName: "moon.fill")
                .font(.system(size: 50))
                .foregroundStyle(Color.moon)
                .shadow(color: Color.moon.opacity(0.6), radius: 15)
                .rotationEffect(.init(degrees: isDark ? -130 : 0))
                .frame(width: size.width, height: size.width)
                .offset(x: -(size.width - 40) / 2)
                .rotationEffect(.init(degrees: isDark ? 130 : -30))
                .offset(y: 10)

            Image(systemName: "sun.max.fill")
                .font(.system(size: 85, weight: .ultraLight))
                .foregroundStyle(.yellow)
                .shadow(color: .white, radius: 15)
                .compositingGroup()
                .keyframeAnimator(initialValue: CGFloat.zero, repeating: true) { content, rotation in
                    content
                        .rotationEffect(.degrees(rotation))
                } keyframes: { _ in
                    LinearKeyframe(360, duration: 60)
                }
                .frame(width: size.width, height: size.width)
                .offset(x: -(size.width - 40) / 2)
                .rotationEffect(.init(degrees: isDark ? 200 : 130))
                .offset(y: 10)
        }
        .frame(width: size.width, height: size.height, alignment: .top)
    }

    @ViewBuilder
    private func shootingStar() -> some View {
        if isDark {
            KeyframeAnimator(initialValue: CGFloat.zero, repeating: true) { offset in
                let opacity = max(min(offset / 200, 1), 0)
                Capsule()
                    .fill(
                        LinearGradient(colors: [
                            Color.moon,
                            Color.moon.opacity(0.5),
                            Color.moon.opacity(0.3),
                            Color.moon.opacity(0.3),
                            .clear,
                        ], startPoint: .trailing, endPoint: .leading)
                    )
                    .frame(width: 100, height: 2)
                    .offset(x: offset, y: 25)
                    .rotationEffect(.init(degrees: 25))
                    .opacity(1 - opacity)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } keyframes: { _ in
                MoveKeyframe(-100)
                LinearKeyframe(-100, duration: 0.8)
                CubicKeyframe(200, duration: 1.2)
                LinearKeyframe(200, duration: 3)
            }
        }
    }

    private func clouds() -> some View {
        HStack(spacing: 0) {
            Image(systemName: "cloud.fill")
                .font(.system(size: 50))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.1), radius: 5)
                .offset(x: isDark ? -100 : 0, y: -30)

            Spacer(minLength: 0)

            Image(systemName: "cloud.fill")
                .font(.system(size: 55))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.1), radius: 5)
                .offset(x: isDark ? 100 : 0)

            Spacer(minLength: 0)

            Image(systemName: "cloud.fill")
                .font(.system(size: 40))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.1), radius: 5)
                .offset(x: isDark ? 100 : 0, y: 35)
        }
        .padding(.horizontal, 20)
        .compositingGroup()
        .blur(radius: isDark ? 30 : 0)
        .opacity(isDark ? 0 : 1)
    }

    private func groundLayers() -> some View {
        ZStack {
            GroundShape(density: 0.5)
                .fill(isDark ? Color.hillTopDark : Color.hillTopLight)

            GroundShape(density: 0.35)
                .fill(isDark ? Color.hillCenterDark : Color.hillCenterLight)

            GroundShape(density: 0.2)
                .fill(isDark ? Color.hillBottomDark : Color.hillBottomLight)

            Image(systemName: "house.lodge.fill")
                .font(.system(size: 20))
                .foregroundStyle(.black.mix(with: .white, by: isDark ? 0.1 : 0.4))
                .background(alignment: .bottom) {
                    Circle()
                        .fill(.yellow.opacity(isDark ? 1 : 0))
                        .frame(width: 12, height: 12)
                        .shadow(color: .yellow.opacity(isDark ? 1 : 0), radius: 5)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .offset(x: 50, y: -120 * 0.37)
        }
        .frame(height: 100)
        .frame(maxHeight: .infinity, alignment: .bottom)
    }
}

@available(iOS 27.0, *)
extension View {
    func themePickerIOS27(
        isPresented: Binding<Bool>,
        value: Binding<Theme>,
        envColorScheme: ColorScheme
    ) -> some View {
        sheet(isPresented: isPresented) {
            Rectangle()
                .fill(.clear)
                .overlay {
                    ThemePickerIOS27(value: value, colorTheme: envColorScheme)
                }
                .ignoresSafeArea()
                .environment(\.colorScheme, envColorScheme)
                .presentationCompactAdaptation(.sheet)
                .presentationDetents([.height(300)])
        }
    }
}

private struct StarsView: View {
    var count: Int
    var body: some View {
        Canvas { context, size in
            for index in 0 ..< count {
                let xPosition = random(index, 1) * size.width
                let yPosition = random(index, 2) * size.height
                let starSize = random(index, 3) > 0.66 ? 3.0 : 2.0
                let opacity = 0.5 + random(index, 4) * 0.5

                let star = Path(ellipseIn: CGRect(x: xPosition, y: yPosition, width: starSize, height: starSize))
                context.fill(star, with: .color(.white.opacity(opacity)))
            }
        }
        .allowsHitTesting(false)
    }

    private func random(_ index: Int, _ seed: Double) -> Double {
        let value = sin(Double(index) * 22.5 + seed * 99.2) * 43.6
        return value - value.rounded(.down)
    }
}

private struct GroundShape: Shape {
    var density: CGFloat
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let base = height * (1 - density)
        let wave = height * density * 0.55

        return Path { path in
            path.move(to: CGPoint(x: 0, y: base))

            path.addCurve(to: CGPoint(x: width * 0.5, y: base + wave * 0.3),
                          control1: CGPoint(x: width * 0.18, y: base - wave),
                          control2: CGPoint(x: width * 0.35, y: base - wave * 0.8))

            path.addCurve(to: CGPoint(x: width, y: base - wave * 0.4),
                          control1: CGPoint(x: width * 0.65, y: base + wave * 1.4),
                          control2: CGPoint(x: width * 0.85, y: base - wave))

            path.addLine(to: CGPoint(x: width, y: height))
            path.addLine(to: CGPoint(x: 0, y: height))
            path.closeSubpath()
        }
    }
}

@available(iOS 27.0, *)
#Preview {
    ThemePickerDemo()
}
