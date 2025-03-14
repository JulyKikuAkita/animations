//
//  ContentView.swift
//  animation

import SwiftUI

struct ContentView: View {
    @State private var showSplashScreen: Bool = true
    var body: some View {
        ZStack {
            if showSplashScreen {
                SplashScreen()
                    .transition(VerticalSplashTransition(isSplash: true))
            } else {
//                PlayerAnimationView()
//                    .transition(HorizontalSplashTransition(isSplash: false))
                CustomDragDropScrollDemoView()
                    .transition(VerticalSplashTransition(isSplash: true))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.primary)
        .ignoresSafeArea()
        .task {
            guard showSplashScreen else { return }
            try? await Task.sleep(for: .seconds(0.5)) // keep splash screen 0.5~0.8 seconds
            withAnimation(.smooth(duration: 0.55)) {
                showSplashScreen = false
            } completion: {
                // if root view has sheet, launch sheet at this block
            }
        }
    }

    var safeArea: UIEdgeInsets {
        if let safeArea = (
            UIApplication.shared.connectedScenes.first as? UIWindowScene
        )?.keyWindow?.safeAreaInsets {
            return safeArea
        }

        return .zero
    }
}

struct HorizontalSplashTransition: Transition {
    var isSplash: Bool

    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .rotation3DEffect(
                .init(degrees: phase.isIdentity ? 0 : isSplash ? -70 : 70),
                axis: (x: 0, y: 1, z: 0),
                anchor: isSplash ? .trailing : .leading
            )
            .offset(x: phase.isIdentity ? 0 : isSplash ? -screenSize.width : screenSize.width)
    }

    /// current screen size without the usage of GeometryReader
    var screenSize: CGSize {
        if let screenSize = (
            UIApplication.shared.connectedScenes.first as? UIWindowScene
        )?.screen.bounds.size {
            return screenSize
        }
        return .zero
    }
}

struct VerticalSplashTransition: Transition {
    var isSplash: Bool

    func body(content: Content, phase: TransitionPhase) -> some View {
        content
            .offset(y: phase.isIdentity ? 0 : isSplash ? -screenSize.height : screenSize.height)
    }

    /// current screen size without the usage of GeometryReader
    var screenSize: CGSize {
        if let screenSize = (
            UIApplication.shared.connectedScenes.first as? UIWindowScene
        )?.screen.bounds.size {
            return screenSize
        }
        return .zero
    }
}

struct SplashScreen: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.primary)

            Image("AI_grn")
        }
        .ignoresSafeArea()
    }
}
