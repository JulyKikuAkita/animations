//
//  UIFont+Extension.swift
//  animation
//
//  Created on 11/20/25.

import SwiftUI

public extension UIFont {
    /// Converting UIFont into CTFont
    var ctFont: CTFont {
        let descriptor = fontDescriptor
        return CTFontCreateWithFontDescriptor(descriptor, 0, nil)
    }

    /// Converting Font into NSAttributedString with the given value
    func toNSAttributedString(_ value: String) -> NSAttributedString {
        NSAttributedString(string: value, attributes: [.font: self])
    }

    /// Calculating TextSize for the given font
    func toSize(_ value: String) -> CGSize {
        NSString(string: value).size(withAttributes: [.font: self])
    }

    /// Return's Each Individual Glyph Path from the given text using the current font ( Can be used to Draw Text as Path)
    func drawGlyphs(_ value: String, draw: @escaping (_ position: CGPoint, _ glyphPath: CGPath) -> Void) {
        let ctFont = ctFont
        let attributedString = toNSAttributedString(value)
        /// Extracting Lines & Runs from the Attributed String using CoreText APIs
        let lines = CTLineCreateWithAttributedString(attributedString)
        let runs = CTLineGetGlyphRuns(lines)

        for runIndex in 0 ..< CFArrayGetCount(runs) {
            let run = unsafeBitCast(CFArrayGetValueAtIndex(runs, runIndex), to: CTRun.self)
            let runCount = CTRunGetGlyphCount(run)

            /// Iterating Run and drawing each Glyph
            for index in 0 ..< runCount {
                let range = CFRangeMake(index, 1)
                var glyph = CGGlyph()
                var position = CGPoint()

                /// Extracting Values
                CTRunGetGlyphs(run, range, &glyph)
                CTRunGetPositions(run, range, &position)

                if let glyphPath = CTFontCreatePathForGlyph(ctFont, glyph, nil) {
                    /// Passing to draw
                    draw(position, glyphPath)
                }
            }
        }
    }
}

#Preview {
    TextToShape(value: "Hello World", font: .systemFont(ofSize: 100, weight: .bold, width: .compressed))
}
