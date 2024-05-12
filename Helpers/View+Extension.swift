//
//  View+Extension.swift
//  animation

import SwiftUI

/// dark mode animation
extension View {
    @ViewBuilder
    func darkModeRect(value: @escaping((CGRect) -> ())) -> some View {
        self
            .overlay {
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
    func createImages(toggleDarkMode: Bool, currentImage: Binding<UIImage?>, previousImage:Binding<UIImage?>, activeDarkMode: Binding<Bool>) -> some View {
        self
            .onChange(of: toggleDarkMode) { oldValue, newValue in
                Task { @MainActor in
                    if let window = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first(where: { $0.isKeyWindow}) {
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
                            previousImage.wrappedValue = await rootView.image(frameSize)
                            /// new one with updated trait state
                            activeDarkMode.wrappedValue = newValue
                            /// wait for transition to complete
                            try await Task.sleep(for: .seconds(0.01))
                            currentImage.wrappedValue = await rootView.image(frameSize)
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
    func didFrameChange(result: @escaping (CGRect, CGRect) -> ()) -> some View {
        self
        .overlay {
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
