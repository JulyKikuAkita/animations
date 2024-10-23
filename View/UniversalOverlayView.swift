//
//  UniversalOverlayView.swift
//  animation

import SwiftUI

struct UniversalOverlayDemoView: View {
    @State private var show: Bool = false
    var body: some View {
        NavigationStack {
            List {
                Button("Floating Video Player") {
                    show.toggle()
                }
                .universalOverlay(show: $show) {
                    
                }
            }
            .navigationTitle("Universal OVerlay")
        }
        Text("Hello, World!")
    }
}

fileprivate struct UniversalOverlayViewModifier<ViewContent: View>: ViewModifier {
    var animation: Animation
    @Binding var show: Bool
    @ViewBuilder var viewContent: ViewContent
    
    func body(content: Content) -> some View {
        content
    }
}

/// not working for iOS 18 and above
fileprivate class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event),
              let rootView = rootViewController?.view else { return nil }
        
        return hitView == rootView ? nil : hitView
    }
}

struct UniversalOverlayViews: View {
    var body: some View {
        Button("Tap") {
            print("test")
        }
    }
}

/// Shared universal overlay properties
@Observable
class UniversalOverlayProperties {
    var window: UIWindow?
    var views: [OverlayView] = []
    
    struct OverlayView: Identifiable {
        var id: String = UUID().uuidString
        var view: AnyView
    }
}


/// Root View Wrapper to place views on top of the SwiftUI app
///  by crating an overlay window on top of the active key window
/// the demo app need to wrap the entry view with this wrapper
struct RootView<Content: View>: View {
    @ViewBuilder var content: Content
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }
    
    private var properties = UniversalOverlayProperties()
    
    var body: some View {
        content
            .environment(properties)
            .onAppear {
                if let windowScene = (UIApplication.shared.connectedScenes.first as? UIWindowScene),
                   properties.window == nil {
                    let window = PassthroughWindow(windowScene: windowScene) // for interacting with overlay view
                    window.isHidden = false
                    window.isUserInteractionEnabled = true
                    /// setup swift based root view controller
                    let rootViewController = UIHostingController(rootView:
                        UniversalOverlayViews()
                            .environment(properties)
                    )
                    rootViewController.view.backgroundColor = .clear
                    window.rootViewController = rootViewController
                    properties.window = window
                }
            }
    }
}

// example
@main
struct UniversalViewApp: App {
    var body: some Scene {
        WindowGroup {
            RootView {
                UniversalOverlayDemoView()
            }
        }
    }
}

#Preview {
    RootView {
        UniversalOverlayDemoView()
    }
}

extension View {
    @ViewBuilder
    func universalOverlay<Content: View>(
        animation: Animation = .snappy,
        show: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self
            .modifier(
                UniversalOverlayViewModifier(
                    animation: animation,
                    show: show,
                    viewContent: content
                )
            )
    }
}
