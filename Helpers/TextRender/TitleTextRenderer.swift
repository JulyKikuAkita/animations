//
//  TitleTextRenderer.swift
//  animation
//
import SwiftUI

struct TitleTextRenderer: TextRenderer, Animatable {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func draw(layout: Text.Layout, in ctx: inout GraphicsContext) {
        let allLines = layout.flatMap({ $0 })
        let allChars = allLines.flatMap({ $0 }) /// get all chars in the line

        for (index, char) in allChars.enumerated() {
            let sliceProcessIndex = CGFloat(allChars.count) * progress
            let sliceProgress = max(min(sliceProcessIndex / CGFloat(index + 1), 1), 0)

            /// Note: to have each slice to begin from it's original point, create a local copy context for each loop
            ///  var copy = context
            ///  using the context directly without copy creates the effect for the context to be incremented after each loop
            ctx.addFilter(.blur(radius: 5 - (5 * sliceProgress)))
            ctx.opacity = sliceProgress
            ctx.translateBy(x: 0, y: 5 - (5 * sliceProgress))
            ctx.draw(char, options: .disablesSubpixelQuantization)
        }
    }
}
