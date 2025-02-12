//
//  RevealRenderer.swift
//  animation

import SwiftUI

struct RevealRenderer: TextRenderer, Animatable {
    var type: RevealType = .blur
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    func draw(layout: Text.Layout, in ctx: inout GraphicsContext) {
        let allLines = layout.flatMap({ $0 })
//        let allChars = allLines.flatMap({ $0 }) /// get all chars in the line
    
        for line in allLines {
            if line[APIKeyAttribute.self] != nil {
                var localContext = ctx
                let isBlur = type == .blur
                
                let blurProgress: CGFloat = 5 - (5 * progress)
                let blurFilter = GraphicsContext.Filter
                    .blur(radius: blurProgress)
                
                let pixellateProgress: CGFloat = 5 - (4.999 * progress)
                let pixellateFilter = GraphicsContext.Filter.distortionShader(
                    ShaderLibrary.pixellate(.float(pixellateProgress)),
                    maxSampleOffset: .zero
                )
                
                localContext.addFilter(isBlur ? blurFilter : pixellateFilter)
                localContext.draw(line)
            } else {
                let localContext = ctx
                localContext.draw(line)
            }
        }
    }
    
    enum RevealType: String, CaseIterable {
        case blur = "Blur"
        case pixellate = "Pixellate"
    }
}
