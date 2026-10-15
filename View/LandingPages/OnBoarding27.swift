//
//  OnBoarding27.swift
//  animation
//
//  Created on 10/14/26.

import AuthenticationServices
import SwiftUI

private struct OnBoarding27: View {
    var body: some View {
        VStack {
            Text("test")
        }
        .padding()
        .splashScreen(config: .init(), showOnBoarding: true) {
            OnBoardingView()
        }
    }
}

private struct OnBoardingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Discover your favorite\nApple products")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            SignInWithAppleButton { _ in
            } onCompletion: { _ in
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .clipShape(.capsule)

            Text("By continuing,you agree to our\nTerms of Service and Privacy Policy")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary.secondary)
        }
        .padding(.horizontal, 5)
        .padding(15)
    }
}

private struct LaunchConfig {
    var logo: Image = .init(.fox)
    var tint: Color = .black
    var initialDelay: CGFloat = 0.35
    var iconPadding: CGFloat = 30
    var iconSize: CGSize = .init(width: 150, height: 150)
    var iconRadius: CGFloat = 45
}

private extension View {
    @ContentBuilder
    func splashScreen(
        config: LaunchConfig,
        showOnBoarding: Bool,
        @ContentBuilder onBoarding: () -> some View
    ) -> some View {
        modifier(LaunchScreenModifier(
            config: config,
            showOnBoarding: showOnBoarding,
            onBoarding: onBoarding
        ))
    }
}

private struct LaunchScreenModifier<OnBoarding: View>: ViewModifier {
    var config: LaunchConfig
    var showOnBoarding: Bool
    @ContentBuilder var onBoarding: OnBoarding
    /// View Properties
    @State private var addSplash: Bool = false
    func body(content: Content) -> some View {
        content
            .onAppear(perform: toggleSplash)
            .fullScreenCover(isPresented: $addSplash) {
                ZStack {
                    if showOnBoarding {
                        LaunchScreenWithObBoarding(config: config) {
                            onBoarding
                        }
                    } else {
                        LaunchScreenOnly(config: config)
                            .presentationBackground(.clear)
                    }
                }
            }
    }

    private func toggleSplash() {
        DispatchQueue.main.async {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                addSplash.toggle()
            }
        }
    }
}

private struct LaunchScreenWithObBoarding<Content: View>: View {
    var config: LaunchConfig
    @ContentBuilder var onBoarding: Content
    /// View Properties
    @State private var pushIcon: Bool = false
    @State private var animateIcon: Bool = false
    var body: some View {
        let layout = animateIcon ? AnyLayout(VStackLayout(spacing: 0)) : AnyLayout(ZStackLayout(alignment: .bottom))

        layout {
            ZStack {
                RoundedRectangle(cornerRadius: animateIcon ? config.iconRadius : 0)
                    .fill(config.tint)

                config.logo
                    .frame(
                        width: animateIcon ? config.iconSize.width : nil,
                        height: animateIcon ? config.iconSize.height : nil
                    )
                    .animation(.none) {
                        $0.opacity(animateIcon ? 0 : 1)
                    }
                    .overlay {
                        config.logo
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .animation(.none) {
                                $0.opacity(animateIcon ? 1 : 0)
                            }
                            .padding(animateIcon ? config.iconPadding : 0)
                    }
            }
            .frame(
                width: animateIcon ? config.iconSize.width : nil,
                height: animateIcon ? config.iconSize.height : nil
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .offset(y: pushIcon ? 100 : 0)
            .zIndex(1)
            .geometryGroup()
            .ignoresSafeArea()

            onBoarding
                .compositingGroup()
                .visualEffect { [animateIcon] content, proxy in
                    content
                        .blur(radius: animateIcon ? 0 : 15)
                        .opacity(animateIcon ? 1 : 0)
                        .offset(y: animateIcon ? 0 : proxy.size.height)
                }
                .zIndex(0)
        }
        .task {
            guard !animateIcon else { return }
            try? await Task.sleep(for: .seconds(config.initialDelay))
            withAnimation(.bouncy(duration: 0.5, extraBounce: 0.05)) {
                pushIcon = true
                animateIcon = true
            }
            try? await Task.sleep(for: .seconds(0.15))
            withAnimation(.bouncy(duration: 0.4)) {
                pushIcon = false
            }
        }
    }
}

private struct LaunchScreenOnly: View {
    var config: LaunchConfig
    var body: some View {}
}

#Preview {
    OnBoarding27()
}
