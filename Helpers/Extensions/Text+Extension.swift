//
//  Text+Extension.swift
//  animation
//
//  Created on 12/16/25.
//
//  The default animation (provided by the line limit) modifier is fade in/out effect
//  To customized a different animation effect, use onGeometryReader to get the
//  expanded/limited text box size then apply animation on the content transition

import SwiftUI

extension Text {
    @ViewBuilder
    func truncationEffect(length: Int, isEnabled: Bool, animation: Animation) -> some View {
        modifier(
            TruncationEffectViewModifier(
                length: length,
                isEnabled: isEnabled,
                animation: animation
            )
        )
    }
}

private struct TruncationEffectViewModifier: ViewModifier {
    var length: Int
    var isEnabled: Bool
    var animation: Animation
    /// View Properties
    @State private var limitedSize: CGSize = .zero
    @State private var fullSize: CGSize = .zero
    @State private var animatedProgress: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .lineLimit(length)
            .opacity(0)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onGeometryChange(for: CGSize.self) {
                $0.size
            } action: { newValue in
                limitedSize = newValue
            }
            .frame(height: isExpanded ? fullSize.height : nil)
            .overlay {
                /// full content with animation
                GeometryReader {
                    let contentSize = $0.size

                    content
                        .textRenderer(
                            TruncationTextRenderer(length: length, progress: animatedProgress)
                        )
                        .fixedSize(horizontal: false, vertical: true)
                        .onGeometryChange(for: CGSize.self) {
                            $0.size
                        } action: { newValue in
                            fullSize = newValue
                        }
                        .frame(
                            width: contentSize.width,
                            height: contentSize.height,
                            alignment: isExpanded ? .leading : .topLeading
                        )
                }
            }
//            .clipped() // without using TextRendererAPi
            .contentShape(.rect)
            .onChange(of: isEnabled) { _, newValue in
                withAnimation(animation) {
                    animatedProgress = !newValue ? 1 : 0
                }
            }
            .onAppear {
                /// Setting initial value without animation
                animatedProgress = !isEnabled ? 1 : 0
            }
    }

    var isExpanded: Bool {
        animatedProgress == 1
    }
}

/// TextRenderer is for iOS 18+ API
private struct TruncationTextRenderer: TextRenderer {
    @AnimatableIgnored var length: Int
    /// only animate the progress
    var progress: CGFloat
    func draw(layout: Text.Layout, in ctx: inout GraphicsContext) {
        for (index, line) in layout.enumerated() {
            var copyContext = ctx
            if index == length - 1 {
                drawMoreTextAtEnd(line: line, context: &copyContext)
            } else {
                if index < length {
                    /// Drawing all other lines
                    copyContext.draw(line)
                } else {
                    drawLinesWithBlurEffect(index: index, layout: layout, in: &copyContext)
                }
            }
        }
    }

    func drawLinesWithBlurEffect(index: Int, layout: Text.Layout, in ctx: inout GraphicsContext) {
        let line = layout[index]
        let lineIndex = Double(index - length)
        let totalExtraLines = Double(layout.count - length)

        /// Divide the animation progress among all lines
        let lineStartProgress = lineIndex / max(1, totalExtraLines)
        let lineEndProgress = (lineIndex + 1) / max(1, totalExtraLines)

        /// Calculate this specific line's  progress
        let lineProgress: CGFloat = max(
            0,
            min(1, (progress - lineStartProgress) / (lineEndProgress - lineStartProgress))
        )
        ctx.opacity = lineProgress
        ctx.addFilter(.blur(radius: 6 - (6 * lineProgress)))
        ctx.draw(line)
    }

    func drawMoreTextAtEnd(line: Text.Layout.Element, context: inout GraphicsContext) {
        let runs = line.flatMap(\.self)
        let runsCount = runs.count
        let text = "...More"
        let textCount = text.count

        /// Drawing the runs till the text count
        for index in 0 ..< max(runsCount - textCount, 0) {
            let run = runs[index]
            context.draw(run)
        }

        /// Drawing the remaining run with opacity filter
        for index in max(runsCount - textCount, 0) ..< runsCount {
            let run = runs[index]
            context.opacity = progress
            context.draw(run)
        }

        /// Drawing Text
        let textRunIndex = max(runsCount - textCount, 0)
        guard !runs.isEmpty else { return }
        let run = runs[textRunIndex]

        let typography = run.typographicBounds
        let fontSize: CGFloat = typography.ascent
        let font = UIFont.systemFont(ofSize: fontSize)
        let spacing: CGFloat = NSString(string: text).size(withAttributes: [
            .font: font,
        ]).width / 2

        let swiftUIText = Text(text)
            .font(Font(font))
            .foregroundStyle(.gray)

        let origin = CGPoint(
            x: typography.rect.minX + spacing,
            y: typography.rect.midY
        )

        context.opacity = 1 - progress
        context.draw(swiftUIText, at: origin)
    }
}
