//
//  UniversalOverlayView.swift
//  animation

import SwiftUI
import AVKit

// example
//@main
struct UniversalViewApp: App {
    var body: some Scene {
        WindowGroup {
            RootView {
                UniversalOverlayDemoView()
            }
        }
    }
}

struct UniversalOverlayDemoView: View {
    @State private var show: Bool = false
    @State private var showSheet: Bool = false
    @State private var showMiniPlayer: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Button("Floating Video Player") {
                    show.toggle()
                }
                /// current view's state properties does not work in the universal overlay wrapper
                /// instead, pass binding or pass observable Object using environment object
                .universalOverlay(show: $show) {
                    FloatingVideoPlayerView(show: $show)
                }

                Button("Dummy Sheet") {
                    showSheet.toggle()
                }


                Button("MiniPlayer Demo") {
                    showMiniPlayer.toggle()
                }
                .universalOverlay(show: $showMiniPlayer) {
                    ExpandableMusicPlayerView(show: $showMiniPlayer)
                }
            }
            .navigationTitle("Universal OVerlay")
            .sheet(isPresented: $showSheet) {
                Text("placeholder")
            }
        }
    }
}

struct FloatingVideoPlayerView: View {
    /// View Properties
    @Binding var show: Bool
    @State private var player: AVPlayer?
    @State private var offset: CGSize = .zero
    @State private var lastStoredOffset: CGSize = .zero

    var body: some View {
        GeometryReader {
            let size = $0.size

            Group {
                if let videoURL {
                    VideoPlayer(player: player)
                        .background(.black)
                        .clipShape(.rect(cornerRadius: 25))
                } else {
                    RoundedRectangle(cornerRadius: 25)
                }
            }
            .frame(height: 250)
            .offset(offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let transition = value.translation + lastStoredOffset
                        offset = transition
                    }.onEnded { value in
                        withAnimation(.bouncy) {
                            /// limiting movement within the screen
                            offset.width = 0

//                            if offset.height < 0 {
//                                offset.height = 0
//                            }
//
//                            if offset.height > (size.height - 250) {
//                                offset.height = (size.height - 250)
//                            }

                            offset.height = max((size.height - 250), 0)
                            lastStoredOffset = offset
                        }
                    }
            )
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .padding(.horizontal, 15)
        .transition(.blurReplace)
        .onAppear {
            if let videoURL {
                player = AVPlayer(url: videoURL)
                player?.play()
            }
        }
    }


    var videoURL: URL? {
        if let bundle = Bundle.main.path(forResource: "Reel1", ofType: "mp4") {
            return .init(filePath: bundle)
        }
        return nil
    }
}

fileprivate extension CGSize {
    static func +(lhs: CGSize, rhs: CGSize) -> CGSize {
        return .init(
            width: lhs.width + rhs.width,
            height: lhs.height + rhs.height
        )
    }
}

fileprivate struct UniversalOverlayViewModifier<ViewContent: View>: ViewModifier {
    var animation: Animation
    @Binding var show: Bool
    @ViewBuilder var viewContent: ViewContent

    /// Local View Properties
    @Environment(UniversalOverlayProperties.self) private var properties
    @State private var viewID: String?

    func body(content: Content) -> some View {
        content
            .onChange(of: show) { oldValue, newValue in
                if newValue {
                    addView()
                } else {
                    removeView()
                }
            }
    }

    private func addView() {
        if properties.window != nil && viewID == nil {
            viewID = UUID().uuidString
            guard let viewID else { return }

            withAnimation(animation) {
                properties.views
                    .append(.init(id: viewID, view: .init(viewContent)))
            }
        }
    }

    private func removeView() {
        if let viewID {
            withAnimation(animation) {
                properties.views.removeAll(where: { $0.id == viewID })
            }
        }
    }
}

fileprivate struct UniversalOverlayViews: View {
    @Environment(UniversalOverlayProperties.self) private var properties
    var body: some View {
        ZStack {
            ForEach(properties.views) {
                $0.view
            }
        }
    }
}

/// not working for iOS 18 and above
fileprivate class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event),
              let rootView = rootViewController?.view else { return nil }

        if #available(iOS 18, *) {
            for subview in rootView.subviews.reversed() {
                /// Finding if any of root view's receiving hit test
                let pointInSubView = subview.convert(point, from: rootView)
                if subview.hitTest(pointInSubView, with: event) == subview {
                    return hitView
                }
            }

            return nil
        } else {
            return hitView == rootView ? nil : hitView

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
