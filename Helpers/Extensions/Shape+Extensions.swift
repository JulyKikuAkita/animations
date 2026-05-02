//
//  Shape+Extensions.swift
//  animation
//
//  Created on 5/2/26.
//
// Purpose: `Shape`-specialized shortcuts (static factories on Shape subtypes).
//
// What belongs here:
//   - `extension Shape where Self == <ConcreteShape>` factories that let
//     callers write `.rounded(cornerRadius: 12)` instead of
//     `.rect(cornerRadius: 12, style: .continuous)`.
//
// What does NOT belong here:
//   - View modifiers that *use* shapes (those go in the appropriate
//     View+<Concern>.swift file).
//   - Custom `Shape`-conforming types (give them their own file).
//

import SwiftUI

extension Shape where Self == RoundedRectangle {
    static func rounded(cornerRadius: CGFloat = 20) -> RoundedRectangle {
        .rect(cornerRadius: cornerRadius, style: .continuous)
    }
}
