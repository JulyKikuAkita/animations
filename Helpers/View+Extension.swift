//
//  View+Extension.swift
//  animation

import SwiftUI

/// dark mode animation
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
    func createImages(toggleDarkMode: Bool, currentImage: Binding<UIImage?>, previousImage: Binding<UIImage?>, activeDarkMode: Binding<Bool>) -> some View {
        onChange(of: toggleDarkMode) { _, newValue in
            Task { @MainActor in
                if let window = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first(where: { $0.isKeyWindow }) {
                    /// creating a dummy image to hide flicking transition
                    let imageView = UIImageView()
                    imageView.frame = window.frame
                    imageView.image = window.rootViewController?.view.image(window.frame.size)
                    imageView.contentMode = .scaleAspectFit
                    window.addSubview(imageView)

                    if let rootView = window.rootViewController?.view {
                        let frameSize = rootView.frame.size
                        /// Creating snapshots
                        ///  old one
                        activeDarkMode.wrappedValue = !newValue
                        previousImage.wrappedValue = rootView.image(frameSize)
                        /// new one with updated trait state
                        activeDarkMode.wrappedValue = newValue
                        /// wait for transition to complete
                        try await Task.sleep(for: .seconds(0.01))
                        currentImage.wrappedValue = rootView.image(frameSize)
                        /// remove dummy view once snapshot has taken
                        try await Task.sleep(for: .seconds(0.01))
                        imageView.removeFromSuperview()
                    }
                }
            }
        }
    }
}

/// For  Apple photo app
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

/// For Apple photo app

/// Converting UIView to UIImage
extension UIView {
    func image(_ size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            drawHierarchy(in: .init(origin: .zero, size: size), afterScreenUpdates: true)
        }
    }
}

/// For Pinterest Grid Animation
extension View {
    var safeAreaPinterest: UIEdgeInsets {
        if let safeArea = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.keyWindow?.safeAreaInsets {
            return safeArea
        }
        return .zero
    }

    @ViewBuilder
    func offsetY(result: @escaping (CGFloat) -> Void) -> some View {
        overlay {
            GeometryReader(content: { geometry in
                let minY = geometry.frame(in: .scrollView(axis: .vertical)).minY
                Color.clear
                    .preference(key: CGFloatKey.self, value: minY) /// Preference Key is defined in AnchorKey file
                    .onPreferenceChange(CGFloatKey.self, perform: { value in
                        result(value)
                    })

            })
        }
    }
}

/// For Pinterest Grid Animation

/// SwiftUI: Placing Tab Bar Over Sheet’s | Apple Map’s Bottom Sheet | iOS 17 | Xcode 15
extension View {
    @ViewBuilder
    func hideNaviTabBar() -> some View {
        toolbar(.hidden, for: .tabBar)
    }
}

/// For Dynamic Sheet Height - iOS 17 - ScrollView APIs
extension View {
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

    @ViewBuilder
    func minXChangePreference(completion: @escaping (CGFloat) -> Void) -> some View {
        overlay {
            GeometryReader(content: { geometry in
                let minX = geometry.frame(in: .scrollView).minX
                Color.clear
                    .preference(key: CGFloatKey.self, value: minX) /// Preference Key is defined in AnchorKey file
                    .onPreferenceChange(CGFloatKey.self, perform: { value in
                        completion(value)
                    })

            })
        }
    }
}

public extension View {
    @ViewBuilder
    func customOnChange<T: Equatable>(value: T, perform: @escaping (T) -> Void) -> some View {
        // SwiftUI's `onChange` has two overloads: one for iOS 17+ with `(oldValue, newValue)`
        // and one for earlier versions with just `(newValue)`.
        //
        // These overloads return different underlying view types, so using them in an
        // `if #available` block without `@ViewBuilder` causes a type mismatch under `some View`.
        //
        // `@ViewBuilder` allows Swift to reconcile both branches and avoid the compile error.
        //  Alternatively
        //  wrapped the return to AnyView
        if #available(iOS 17, *) {
            self
                .onChange(of: value) { _, newValue in
                    perform(newValue)
                }
        } else {
            onChange(of: value) { newValue in
                perform(newValue)
            }
        }
    }
}
