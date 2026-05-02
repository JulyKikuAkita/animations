//
//  View+Geometry.swift
//  animation
//
// Purpose: generic geometry readers built on GeometryReader + PreferenceKey.
//
// What belongs here:
//   - Modifiers that expose a view's size/frame/offset via a callback,
//     usable from *any* feature (not tied to one demo).
//   - Shared PreferenceKey types (e.g. `CGFloatKey`) used by multiple readers.
//
// What does NOT belong here:
//   - Readers that only make sense for one demo (dark mode, Pinterest, photos, …).
//     Put those next to the demo view or in View+FeatureHelpers.swift.
//   - Geometry + version-gating combos — pick the concern that dominates;
//     if it's the version gate, put it in View+Compat.swift.
//
// Convention: name modifiers `<metric>ChangePreference` when they fire a
// callback on change, so readers can predict the signature.
//

import SwiftUI

extension View {
    /// Reports the view's height whenever it changes.
    /// Originally written for dynamic sheet-height detection on iOS 17+.
    @ViewBuilder
    func heightChangePreference(completion: @escaping (CGFloat) -> Void) -> some View {
        overlay {
            GeometryReader(content: { geometry in
                Color.clear
                    .preference(key: CGFloatKey.self, value: geometry.size.height)
                    .onPreferenceChange(CGFloatKey.self, perform: { value in
                        completion(value)
                    })
            })
        }
    }

    /// Reports the view's `minX` in the nearest scroll view's coordinate space.
    @ViewBuilder
    func minXChangePreference(completion: @escaping (CGFloat) -> Void) -> some View {
        overlay {
            GeometryReader(content: { geometry in
                let minX = geometry.frame(in: .scrollView).minX
                Color.clear
                    .preference(key: CGFloatKey.self, value: minX)
                    .onPreferenceChange(CGFloatKey.self, perform: { value in
                        completion(value)
                    })
            })
        }
    }
}
