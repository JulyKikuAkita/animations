//
//  GlassEffectTextDemoView.swift
//  animation
//
//  Created on 11/20/25.
import SwiftUI

struct GlassEffectTextDemoView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Glass Effect Demo") {
                    Example1()
                }

                NavigationLink("Writing Effect Demo") {
                    Example2()
                }
            }
            .navigationTitle("Text to Shape")
        }
    }
}

private struct Example1: View {
    @State private var progressSlider: CGFloat = 0
    @State private var lastStoredValue: CGFloat = 0

    var body: some View {
        ZStack {
            let backgroundShape = RoundedRectangle(cornerRadius: 15)
                .stroke(lineWidth: 3)

            let grabberShape = Circle()
                .trim(from: 0.28, to: 0.5)
                .stroke(style: .init(lineWidth: 18, lineCap: .round, lineJoin: .round))

            Rectangle()
                .foregroundStyle(.clear)
                .overlay {
                    Image(.IMG_0207)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
                .ignoresSafeArea()

            GlassEffectText(text: "Budapest",
                            font: .systemFont(ofSize: 100 + progressSlider,
                                              weight: .bold,
                                              width: .compressed),
                            fallbackColor: .white)
                .frame(maxWidth: .infinity)
                .overlay {
                    ZStack {
                        /// Drawing background border
                        Group {
                            if #available(iOS 26, *) {
                                backgroundShape
                                    .fill(.clear)
                                    .glassEffect(.clear, in: backgroundShape)
                            } else {
                                backgroundShape
                                    .fill(.white)
                            }
                        }

                        /// Drawing background shape
                        Group {
                            if #available(iOS 26, *) {
                                grabberShape
                                    .fill(.clear)
                                    .glassEffect(.clear, in: grabberShape)
                            } else {
                                grabberShape
                                    .fill(.white)
                            }
                        }
                        .frame(width: 50, height: 50)
                        .contentShape(.rect)
                        .scaleEffect(x: -1)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .gesture(dragGesture)
                    }
                }
                .padding(.horizontal, 15)
                .padding(.top, 10)
                .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                progressSlider = max(min(value.translation.height + lastStoredValue, 100), 0)
            }.onEnded { _ in
                lastStoredValue = progressSlider
            }
    }
}

/// Effect only apply to stroked path not Filled Path
private struct Example2: View {
    @State private var animated: Bool = false
    var body: some View {
        List {
            let textShape = TextToShape(value: "Budapest", font: textFont)
            Section("Demo") {
                textShape
                    .trim(from: 0, to: animated ? 1 : 0)
                    .stroke(lineWidth: 4)
                    .frame(height: 100)
            }
            Button("Animate Text") {
                withAnimation(.easeInOut(duration: 5)) {
                    animated.toggle()
                }
            }
        }
        .navigationTitle("Writing Effect")
    }

    var textFont: UIFont {
        if let customFont = UIFont(name: "Bradley Hand", size: 60) { return customFont }
        return .systemFont(ofSize: 40, weight: .bold)
    }
}

struct GlassEffectText: View {
    var text: String
    var font: UIFont
    var fallbackColor: Color = .primary
    var isClear: Bool = true
    var glassTint: Color = .clear
    var body: some View {
        let textShape = TextToShape(value: text, font: font)
        if #available(iOS 26.0, *) {
            Text(text)
                .font(Font(font))
                .opacity(0)
                .glassEffect((isClear ? Glass.clear : Glass.regular).tint(glassTint), in: textShape)
        } else {
            Text(text)
                .font(Font(font))
                .foregroundStyle(fallbackColor)
        }
    }
}

struct TextToShape: Shape {
    var value: String
    var font: UIFont
    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        font.drawGlyphs(value) { position, glyphPath in
            let transform = CGAffineTransform(translationX: position.x, y: position.y)
                .scaledBy(x: 1, y: -1)
            let newPath = Path(glyphPath).applying(transform)
            /// Adding it to the main path
            path.addPath(newPath)
        }

        /// centering to the current bounds
        let bounds = path.boundingRect
        let offsetX = rect.midX - bounds.midX
        let offsetY = rect.midY - bounds.midY
        let centerTransform = CGAffineTransform(translationX: offsetX, y: offsetY)
        return path.applying(centerTransform)
    }
}

#Preview {
    GlassEffectTextDemoView()
}
