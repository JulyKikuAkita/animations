//
//  View+Sheet.swift
//  animation
//
//  Created on 7/8/26.
//
//  Learning point
//  ──────────────
//  `adaptiveSheet(_:isActive:)` reaches through SwiftUI into the
//  underlying UIKit `UISheetPresentationController` to constrain the
//  presented sheet's container view to a maximum width — something
//  SwiftUI's `.presentationDetents` API cannot express (detents
//  control height, never width). Used by LandscapePinnedSheet.swift to
//  turn a full-width bottom sheet into a pinned floating card.
//
//  How the UIKit bridge works
//  ──────────────────────────
//  An empty `UIViewControllerRepresentable` is injected via
//  `.background`. Its controller is part of the presentation hierarchy,
//  so `controller.sheetPresentationController.containerView` is the
//  actual sheet view. We mutate that container's Auto Layout on the
//  main queue (the view/window aren't attached until after
//  `makeUIViewController` returns, hence the `DispatchQueue.main.async`).
//
//  The two constraint modes
//  ────────────────────────
//  • isActive: pin `leading` to the window, cap width at `width`
//    (`lessThanOrEqualToConstant`), and add a `.defaultHigh` "match
//    window width" constraint. The high-but-not-required priority lets
//    the hard width cap win on wide screens while still filling narrow
//    ones — that priority tug-of-war is the whole trick.
//  • inactive: restore the container to the full window frame with a
//    flexible autoresizing mask, undoing the pin.
//  Both wrapped in `sheetController.animateChanges { }` so the width
//  change is animated, not a jump.
//
//  Also clears the sheet's grey system background so the card reads as
//  floating, and adds a small `NSLayoutConstraint.priority(_:)` chaining
//  helper for readable inline constraint construction.
//
//  Caveat
//  ──────
//  This depends on UIKit's private-ish sheet view hierarchy (finding
//  the background subview, mutating the container frame). It works on
//  current iOS but is fragile across OS updates — revisit if the sheet
//  stops pinning after an SDK bump.
//

import SwiftUI

extension View {
    @ContentBuilder
    func adaptiveSheet(_ width: CGFloat, isActive: Bool) -> some View {
        background {
            if isActive {
                AdaptiveSheetHelper(width: width, isActive: true)
            } else {
                AdaptiveSheetHelper(width: width, isActive: false)
            }
        }
    }
}

private struct AdaptiveSheetHelper: UIViewControllerRepresentable {
    var width: CGFloat
    var isActive: Bool
    func makeUIViewController(context _: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear

        DispatchQueue.main.async {
            if let sheetController = controller.sheetPresentationController {
                guard let sheet = sheetController.containerView,
                      let window = controller.view.window else { return }

                /// set background view to clear
                if let backgroundView = sheet.subviews.first(where: {
                    $0.subviews.contains(where: { $0.backgroundColor != nil })
                }) {
                    for subview in backgroundView.subviews {
                        subview.backgroundColor = .clear
                    }
                }

                sheetController.animateChanges {
                    if isActive {
                        /// limit the sheet container view's width in landscape/vertical using set of constraints
                        sheet.translatesAutoresizingMaskIntoConstraints = true
                        NSLayoutConstraint.activate([
                            sheet.leadingAnchor.constraint(equalTo: window.leadingAnchor),
                            sheet.topAnchor.constraint(equalTo: window.bottomAnchor),
                            sheet.widthAnchor.constraint(lessThanOrEqualToConstant: width),
                            sheet.widthAnchor.constraint(equalTo: window.widthAnchor).priority(.defaultHigh),
                        ])
                    } else {
                        /// Resetting layout constraints
                        sheet.translatesAutoresizingMaskIntoConstraints = true
                        sheet.frame = window.frame
                        sheet.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    }
                }
            }
        }
        return controller
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}

extension NSLayoutConstraint {
    func priority(_ value: UILayoutPriority) -> Self {
        priority = value
        return self
    }
}
