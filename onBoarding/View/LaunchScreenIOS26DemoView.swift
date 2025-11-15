//
//  LaunchScreenIOS26DemoView.swift
//  onBoarding
//
//  Created on 11/15/25.
//
// Check the image use in Info.plist/launch screen image, background for visual consistency in splash screen
//
// Two ways to customize the splash screen + scaling logo effect
// 1. LaunchScreen(config: .init(scaling: 9))) since each logo is different,
// play around to get the best scaling config to achieve smooth scaling animation
//
// 2.  LaunchScreen(config: .init(forceHideLogo: true)) to achieve similar effect
// when set to true, the logo will be scaled to the specified value and remove the splash screen
// when set to false, adding an fade blur effect to smooth out the scaling effect
//
import SwiftUI

@main
struct LaunchScreenIOS26DemoApp: App {
    var body: some Scene {
        /// since each logo is different, play around to get the best scaling config to achieve smooth scaling animation
        LaunchScreen(config: .init(forceHideLogo: false)) {
//            Image(.redIcon) /// matches the launch screen logo name .redIcon in the info.plist
            Image(systemName: "playstation.logo")
                .font(.system(size: 100))
        } rootContent: {
            ContentView()
        }
    }
}

struct LaunchScreenIOS26DemoView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct LaunchScreenConfig {
    var initialDelay: Double = 0.35
    var backgroundColor: Color = .black
    var logoBackgroundColor: Color = .white
    var scaling: CGFloat = 4
    var forceHideLogo: Bool = false
    var animation: Animation = .smooth(duration: 1, extraBounce: 0)
}

struct LaunchScreen<RootView: View, Logo: View>: Scene {
    var config: LaunchScreenConfig = .init()
    @ViewBuilder var logo: () -> Logo
    @ViewBuilder var rootContent: RootView
    var body: some Scene {
        WindowGroup {
            rootContent
                .modifier(LaunchScreenModifier(config: config, logo: logo))
        }
    }
}

private struct LaunchScreenModifier<Logo: View>: ViewModifier {
    var config: LaunchScreenConfig
    @ViewBuilder var logo: Logo
    /// View Properties
    @Environment(\.scenePhase) private var scenePhase
    @State private var splashWindow: UIWindow?

    func body(content: Content) -> some View {
        content
            /// adding an overlay  window so the splash screen will be visible on top of the entire app
            .onAppear {
                let scenes = UIApplication.shared.connectedScenes
                for scene in scenes {
                    guard let windowScene = scene as? UIWindowScene,
                          checkScene(state: windowScene.activationState),
                          !windowScene.windows.contains(where: { $0.tag == 1009 })
                    else {
                        print("Already have a splash window for this scene")
                        continue
                    }

                    let window = UIWindow(windowScene: windowScene)
                    window.backgroundColor = .clear
                    window.isHidden = false
                    window.isUserInteractionEnabled = true
                    let rootViewController = UIHostingController(rootView: LaunchScreenView(config: config) {
                        logo
                    } isComplete: {
                        /// hiding splash window
                        window.isHidden = true
                        window.isUserInteractionEnabled = false
                    })
                    window.tag = 1009
                    rootViewController.view.backgroundColor = .clear
                    window.rootViewController = rootViewController
                    splashWindow = window
                }
            }
    }

    private func checkScene(state: UIWindowScene.ActivationState) -> Bool {
        switch scenePhase {
        case .active: state == .foregroundActive
        case .inactive: state == .foregroundInactive
        case .background: state == .background
        default: state.hashValue == scenePhase.hashValue
        }
    }
}

private struct LaunchScreenView<Logo: View>: View {
    var config: LaunchScreenConfig
    @ViewBuilder var logo: Logo
    var isComplete: () -> Void
    /// View Properties
    @State private var scaleDown: Bool = false
    @State private var scaleUp: Bool = false
    var body: some View {
        Rectangle()
            .fill(config.backgroundColor)
            /// Reverse logo masking
            .mask {
                GeometryReader {
                    let size = $0.size.applying(.init(scaleX: config.scaling, y: config.scaling))
                    Rectangle()
                        .overlay {
                            logo
                                .blur(radius: config.forceHideLogo ? 0 : (scaleUp ? 15 : 0))
                                .blendMode(.destinationOut)
                                .animation(.smooth(duration: 0.3, extraBounce: 0)) { content in
                                    content
                                        .scaleEffect(scaleDown ? 0.8 : 1)
                                }
                                .visualEffect { [scaleUp] content, proxy in
                                    let scaleX: CGFloat = size.width / proxy.size.width
                                    let scaleY: CGFloat = size.height / proxy.size.height
                                    /// scale logo size based on content
                                    let maxScale = Swift.max(scaleX, scaleY)
                                    return content.scaleEffect(scaleUp ? maxScale : 1)
                                }
                        }
                }
            }
            .opacity(config.forceHideLogo ? 1 : (scaleUp ? 0 : 1))
            .background {
                Rectangle()
                    .fill(config.logoBackgroundColor)
                    /// gradually fading background during the logo scaling animation
                    .opacity(scaleUp ? 0 : 1)
            }
            .ignoresSafeArea()
            .task {
                guard !scaleDown else { return }
                try? await Task.sleep(for: .seconds(config.initialDelay))
                scaleDown = true
                try? await Task.sleep(for: .seconds(0.1))
                withAnimation(config.animation, completionCriteria: .logicallyComplete) {
                    scaleUp = true
                } completion: {
                    isComplete()
                }
            }
    }
}

#Preview {
    LaunchScreenIOS26DemoView()
}
