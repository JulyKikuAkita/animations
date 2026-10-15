//
//  OnBoarding27.swift
//  animation
//
//  Created on 10/14/26.
//
//  Learning points — `LaunchScreenOnly`: why a reverse mask AND a plain overlay
//  ───────────────────────────────────────────────────────────────────────
//  Goal: a tinted splash with the logo in the middle; the logo then grows
//  until it "opens up" and reveals the app underneath (Twitter-style).
//
//  1. Reverse (inverse) mask = cut a logo-shaped hole.
//     A normal `.mask { logo }` keeps the tint only INSIDE the logo — the
//     opposite of what we want. SwiftUI has no built-in inverted mask, so we
//     build one: an opaque `Rectangle()` with the logo overlaid using
//     `.blendMode(.destinationOut)`. destinationOut erases wherever the logo's
//     alpha is opaque, so the mask is solid everywhere except a logo-shaped hole.
//     The mask is rendered in its own offscreen layer, so the blend only
//     erases the mask — not the tint or the app behind it.
//
//  2. The hole only reveals something because the cover is transparent.
//     `.presentationBackground(.clear)` on the fullScreenCover lets the hole
//     show the real app content instead of the cover's default background.
//
//  3. Why the plain overlay logo is still needed.
//     A mask can only remove pixels; it can't draw the logo's artwork. Before
//     the reveal we want to SEE the logo, not a hole showing the app through
//     it. So two copies of the same logo crossfade during `scaleUp`:
//       • overlay (isMask: false): opacity 1 → 0  — the visible logo
//       • mask    (isMask: true):  opacity 0 → 1  — the hole
//     At opacity 0 the destinationOut copy erases nothing, so the splash starts
//     as a solid tint + logo. Both copies go through `logoView`, so they share
//     the exact same scale transforms and stay pixel-aligned while animating.
//
//  4. Scale target.
//     Only the logo's opaque pixels punch through, and its silhouette isn't a
//     rectangle. Scaling it to `max(...)` of 4× the screen size makes the
//     silhouette large enough to fully cover the screen, so the hole swallows
//     the whole splash before `dismiss()` removes the cover.

import AuthenticationServices
import SwiftUI

private struct OnBoarding27: View {
    @AppStorage("isOnBoardingCompleted") private var isOnBoardingComplete: Bool = false
    var body: some View {
        VStack {
            Text("test")
        }
        .padding()
        .splashScreen(config: .init(), showOnBoarding: !isOnBoardingComplete) {
            OnBoardingView()
        }
    }
}

private struct OnBoardingView: View {
    @AppStorage("isOnBoardingCompleted") private var isOnBoardingComplete: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Discover your favorite\nApple products")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            SignInWithAppleButton { _ in
            } onCompletion: { _ in
                dismiss()
                isOnBoardingComplete = true
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
    /// View Properties
    @State private var scaleUp: Bool = false
    @State private var scaleDown: Bool = false
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Rectangle()
            .fill(.clear)
            .overlay {
                GeometryReader {
                    let scaleFactor: CGFloat = 4
                    let size = $0.size.applying(.init(scaleX: scaleFactor, y: scaleFactor))

                    Rectangle()
                        .fill(config.tint)
                        .mask {
                            // inverse mask
                            Rectangle()
                                .overlay {
                                    logoView(true, size: size)
                                }
                        }
                        .overlay {
                            logoView(false, size: size)
                        }
                }
            }
            .ignoresSafeArea()
            .task {
                guard !scaleDown else { return }

                // bounce down
                try? await Task.sleep(for: .seconds(config.initialDelay))
                withAnimation(.smooth(duration: 0.3, extraBounce: 0)) {
                    scaleDown = true
                }

                // scale up & mask up
                try? await Task.sleep(for: .seconds(0.1))
                withAnimation(.interpolatingSpring(duration: 0.6, bounce: 0, initialVelocity: 0)) {
                    scaleUp = true
                }

                // Dismiss splash screen
                try? await Task.sleep(for: .seconds(0.6))
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    dismiss()
                }
            }
    }

    private func logoView(_ isMask: Bool, size: CGSize) -> some View {
        config.logo
            .blendMode(isMask ? .destinationOut : .normal)
            .scaleEffect(scaleDown ? 0.8 : 1)
            .visualEffect { [scaleUp] content, proxy in
                let imageSize = proxy.size
                let scale = max(
                    size.width / imageSize.width,
                    size.height / imageSize.height
                )

                return content
                    .scaleEffect(scaleUp ? scale : 1)
                    .opacity(isMask ? (scaleUp ? 1 : 0) : (scaleUp ? 0 : 1))
            }
    }
}

#Preview {
    OnBoarding27()
}
