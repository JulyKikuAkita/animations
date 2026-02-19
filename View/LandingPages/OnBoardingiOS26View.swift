//
//  OnBoardingiOS26View.swift
//  animation
//
//  Created on 2/19/26.

import SwiftUI

@available(iOS 26.0, *)
struct OnBoardingiOS26DemoView: View {
    var body: some View {
        let image = UIImage(named: "Bitcoin") // use IMG_6162 for screenshot image
        let title = "Welcome to iOS 26"
        let subtitle = "Introducing a new design with\nLiquid Glass."
        IOS26StyeOnBoarding(
            tint: .orange,
            hideBezels: true, // hide device frame
            items: [
                .init(id: 0, title: title, subtitle: subtitle, screenshot: image, zoomScale: 0.8,),
                .init(id: 1, title: title, subtitle: subtitle, screenshot: image, zoomScale: 1.5, zoomAnchor: .topLeading),
                .init(id: 2, title: title, subtitle: subtitle, screenshot: image, zoomScale: 1.2, zoomAnchor: .bottom),
                .init(
                    id: 3,
                    title: title,
                    subtitle: subtitle,
                    screenshot: image,
                    zoomScale: 1.1,
                    zoomAnchor: .init(x: 0.5, y: -0.1)
                ),
                .init(id: 4, title: title, subtitle: subtitle, screenshot: image, zoomScale: 1,),
            ]
        ) {
            print("on completed")
        }
    }
}

@available(iOS 26.0, *)
struct IOS26StyeOnBoarding: View {
    var tint: Color = .blue
    var hideBezels: Bool = false
    var items: [Item]
    var onComplet: () -> Void = {}
    /// View Properties
    @State private var currentIndex: Int = 0
    @State private var screenshotSize: CGSize = .zero

    var body: some View {
        ZStack(alignment: .bottom) {
            screenshotView()
                .compositingGroup()
                .scaleEffect(
                    items[currentIndex].zoomScale,
                    anchor: items[currentIndex].zoomAnchor
                )
                .padding(.top, 35)
                .padding(.horizontal, 30)
                .padding(.bottom, 220)

            VStack(spacing: 10) {
                textContentView()
                indicatorView()
                continueButton()
            }
            .padding(.top, 20)
            .padding(.horizontal, 15)
            .frame(height: 210)
            .background {
                variableGlassBlur(15)
            }

            backButton()
        }
        .preferredColorScheme(.dark)
    }

    /// need to calculate corner radius for different screen size
    var deviceCornerRadius: CGFloat {
        if let imageSize = items.first?.screenshot?.size {
            let ratio = screenshotSize.height / imageSize.height
            let actualCornerRadius: CGFloat = 190
            return actualCornerRadius * ratio
        }
        return 0
    }

    func screenshotView() -> some View {
        let shape = ConcentricRectangle(corners: .concentric, isUniform: true)
        return GeometryReader {
            let size = $0.size
            Rectangle()
                .fill(.black)

            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(items.indices, id: \.self) { index in
                        let item = items[index]

                        Group {
                            if let screenshot = item.screenshot {
                                Image(uiImage: screenshot)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .onGeometryChange(for: CGSize.self) {
                                        $0.size
                                    } action: { newValue in
                                        screenshotSize = newValue
                                    }
                                    .clipShape(shape)
                            } else {
                                Rectangle()
                                    .fill(.black)
                            }
                        }
                        .frame(width: size.width, height: size.height)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollDisabled(true)
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
            .scrollPosition(id:
                .init(get: {
                    currentIndex
                }, set: { _ in })
            )
        }
        .clipShape(shape)
        .overlay {
            if screenshotSize != .zero, !hideBezels {
                /// Device frame UI
                ZStack {
                    shape
                        .stroke(.white, lineWidth: 6)
                    shape
                        .stroke(.black, lineWidth: 4)
                    shape
                        .stroke(.black, lineWidth: 6)
                        .padding(4)
                }
                .padding(-6)
            }
        }
        .frame(maxWidth: screenshotSize.width == 0 ? nil : screenshotSize.width,
               maxHeight: screenshotSize.height == 0 ? nil : screenshotSize.height)
        .containerShape(RoundedRectangle(cornerRadius: deviceCornerRadius))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func textContentView() -> some View {
        GeometryReader {
            let size = $0.size

            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(items.indices, id: \.self) { index in
                        let item = items[index]
                        let isActive: Bool = currentIndex == index

                        VStack(spacing: 6) {
                            Text(item.title)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                                .foregroundStyle(.white)

                            Text(item.subtitle)
                                .font(.callout)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .frame(width: size.width)
                        .compositingGroup()
                        .blur(radius: isActive ? 0 : 30)
                        .opacity(isActive ? 1 : 0) /// non selected item
                    }
                }
            }
            .scrollIndicators(.hidden)
            .scrollDisabled(true)
            .scrollTargetBehavior(.paging)
            .scrollClipDisabled(true)
            .scrollPosition(id:
                .init(get: {
                    currentIndex
                }, set: { _ in })
            )
        }
    }

    func indicatorView() -> some View {
        HStack(spacing: 6) {
            ForEach(items.indices, id: \.self) { index in
                let isActive: Bool = currentIndex == index

                Capsule()
                    .fill(.white.opacity(isActive ? 1 : 0.4))
                    .frame(width: isActive ? 25 : 6, height: 6)
            }
        }
        .padding(.bottom, 5)
    }

    func continueButton() -> some View {
        Button {
            if currentIndex == items.count - 1 {
                onComplet()
            }
            withAnimation(animation) {
                currentIndex = min(currentIndex + 1, items.count - 1)
            }
        } label: {
            Text(currentIndex == items.count - 1 ? "Get Started" : "Continue")
                .fontWeight(.medium)
                .contentTransition(.numericText())
                .padding(.vertical, 6)
        }
        .tint(tint)
        .buttonStyle(.glassProminent)
        .buttonSizing(.flexible)
        .padding(.horizontal, 30)
    }

    func backButton() -> some View {
        Button {
            withAnimation(animation) {
                currentIndex = max(currentIndex - 1, 0)
            }
        } label: {
            Image(systemName: "chevron.left")
                .font(.title3)
                .frame(width: 20, height: 30)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.leading, 15)
        .padding(.top, 4)
    }

    func variableGlassBlur(_ radius: CGFloat) -> some View {
        let tint: Color = .black.opacity(0.5)
        return Rectangle()
            .fill(tint)
            .glassEffect(.clear.tint(tint), in: .rect) // emphasize blurring effect
            .blur(radius: radius)
            .padding([.horizontal, .bottom], -radius * 2)
            .padding(.top, -radius / 2)
            .opacity(items[currentIndex].zoomScale != 1 ? 1 : 0) /// apply to scaled screenshots
            .ignoresSafeArea()
    }

    /// any preferred animation
    var animation: Animation {
        .interpolatingSpring(duration: 0.65, bounce: 0, initialVelocity: 0)
    }

    struct Item: Identifiable {
        var id: Int
        var title: String
        var subtitle: String
        var screenshot: UIImage?
        var zoomScale: CGFloat = 1
        var zoomAnchor: UnitPoint = .center
    }
}

@available(iOS 26.0, *)
#Preview {
    OnBoardingiOS26DemoView()
}
