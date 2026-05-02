//
//  View+FeatureHelpers.swift
//  animation
//
// Purpose: temporary home for helpers that are tied to a specific demo view.
//
// Why this file exists:
//   These helpers used to live in `View+Extension.swift` (a grab-bag). They
//   belong next to the demo that uses them, but moving each one is a
//   separate rename; this file keeps them in one place so it's visible
//   which helpers should eventually be colocated.
//
// What belongs here (TEMPORARY):
//   - Helpers used by exactly one feature/demo. When you touch such a helper,
//     consider moving it into that demo's folder (or a sibling
//     `<Demo>Helpers.swift`) and deleting the entry here.
//
// What does NOT belong here:
//   - Anything reused across demos — promote to the appropriate
//     View+<Concern>.swift file (Geometry, Visibility, Animation, Compat).
//
// Rule for future additions: do NOT add new helpers to this file. Either
// colocate with the demo from day one, or put it in the right concern file.
//

import SwiftUI

// MARK: - Dark Mode Animation demo

extension View {
    @ViewBuilder
    func darkModeRect(value: @escaping ((CGRect) -> Void)) -> some View {
        overlay {
            GeometryReader(content: { geometry in
                let rect = geometry.frame(in: .global)

                Color.clear
                    .preference(key: OffsetKey.self, value: rect)
                    .onPreferenceChange(OffsetKey.self, perform: { rect in
                        value(rect)
                    })
            })
        }
    }

    @ViewBuilder
    func createImages(toggleDarkMode: Bool,
                      currentImage: Binding<UIImage?>,
                      previousImage: Binding<UIImage?>,
                      activeDarkMode: Binding<Bool>) -> some View
    {
        onChange(of: toggleDarkMode) { _, newValue in
            Task { @MainActor in
                if let window = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
                    .windows.first(where: { $0.isKeyWindow })
                {
                    /// dummy image to hide the flicker during the trait change
                    let imageView = UIImageView()
                    imageView.frame = window.frame
                    imageView.image = window.rootViewController?.view.image(window.frame.size)
                    imageView.contentMode = .scaleAspectFit
                    window.addSubview(imageView)

                    if let rootView = window.rootViewController?.view {
                        let frameSize = rootView.frame.size
                        /// old snapshot (opposite mode)
                        activeDarkMode.wrappedValue = !newValue
                        previousImage.wrappedValue = rootView.image(frameSize)
                        /// new snapshot (updated trait state)
                        activeDarkMode.wrappedValue = newValue
                        try await Task.sleep(for: .seconds(0.01))
                        currentImage.wrappedValue = rootView.image(frameSize)
                        try await Task.sleep(for: .seconds(0.01))
                        imageView.removeFromSuperview()
                    }
                }
            }
        }
    }
}

// MARK: - Apple Photo demo

extension View {
    @ViewBuilder
    func didFrameChange(result: @escaping (CGRect, CGRect) -> Void) -> some View {
        overlay {
            GeometryReader {
                let frame = $0.frame(in: .scrollView(axis: .vertical))
                let bounds = $0.bounds(of: .scrollView(axis: .vertical)) ?? .zero

                Color.clear
                    .preference(key: FrameKey.self, value: .init(frame: frame, bounds: bounds))
                    .onPreferenceChange(FrameKey.self, perform: { value in
                        result(value.frame, value.bounds)
                    })
            }
        }
    }
}

struct ViewFrame: Equatable {
    var frame: CGRect = .zero
    var bounds: CGRect = .zero
}

struct FrameKey: PreferenceKey {
    static var defaultValue: ViewFrame = .init()
    static func reduce(value: inout ViewFrame, nextValue: () -> ViewFrame) {
        value = nextValue()
    }
}

// MARK: - Pinterest Grid demo

extension View {
    var safeAreaPinterest: UIEdgeInsets {
        if let safeArea =
            (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
                .keyWindow?.safeAreaInsets
        {
            return safeArea
        }
        return .zero
    }

    /// `CGFloatKey` preference key lives in `Helpers/AnchorKey.swift`.
    @ViewBuilder
    func offsetY(result: @escaping (CGFloat) -> Void) -> some View {
        overlay {
            GeometryReader(content: { geometry in
                let minY = geometry.frame(in: .scrollView(axis: .vertical)).minY
                Color.clear
                    .preference(key: CGFloatKey.self, value: minY)
                    .onPreferenceChange(CGFloatKey.self, perform: { value in
                        result(value)
                    })
            })
        }
    }
}
