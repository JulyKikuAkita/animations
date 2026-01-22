//
//  ToastView.swift
//  animation
//
//  Created on 1/21/26.

import SwiftUI

@available(iOS 26.0, *)
extension View {
    @ViewBuilder
    func dynamicIslandToast(isPresented: Binding<Bool>, value: Toast) -> some View {
        modifier(
            DynamicIslandToastViewModifier(
                isPresented: isPresented,
                value: value
            )
        )
    }
}

@available(iOS 26.0, *)
struct DynamicIslandToastViewModifier: ViewModifier {
    @Binding var isPresented: Bool
    var value: Toast
    /// View Properties
    @State private var overlayWindow: PassThroughWindow?
    @State private var overlayController: CustomHostingView?

    func body(content: Content) -> some View {
        content
            .background(WindowExtractor { mainWindow in
                createOverlayWindow(mainWindow)
            })
            .onChange(of: isPresented, initial: true) { _, newValue in
                guard let overlayWindow else { return }
                if newValue {
                    /// setting up current toast
                    overlayWindow.toast = value
                }
                overlayWindow.isPresented = newValue
                /// update status bar
                overlayController?.isStatusBarHidden = newValue
            }
            /// close isPresented properties when toast is closed
            .onChange(of: overlayWindow?.isPresented) { _, newValue in
                if let newValue, let overlayWindow,
                   overlayWindow.toast?.id == value.id,
                   newValue != isPresented
                {
                    isPresented = false
                }
            }
    }

    func createOverlayWindow(_ mainWindow: UIWindow) {
        guard let windowScene = mainWindow.windowScene else { return }

        if let window = windowScene.windows.first(where: { $0.tag == 1009 }) as? PassThroughWindow {
            overlayWindow = window
            overlayController = window.rootViewController as? CustomHostingView

        } else {
            let overlayWindow = PassThroughWindow(windowScene: windowScene)
            overlayWindow.backgroundColor = .clear
            overlayWindow.isHidden = false
            overlayWindow.isUserInteractionEnabled = true
            overlayWindow.tag = 1009
            createRootController(overlayWindow)

            self.overlayWindow = overlayWindow
        }
    }

    func createRootController(_ window: PassThroughWindow) {
        let hostingController = CustomHostingView(
            rootView: ToastView(window: window)
        )

        hostingController.view.backgroundColor = .clear
        window.rootViewController = hostingController

        overlayController = hostingController
    }
}

@available(iOS 26.0, *)
struct ToastView: View {
    var window: PassThroughWindow
    var body: some View {
        GeometryReader {
            let safeArea = $0.safeAreaInsets
            let size = $0.size

            /// dynamic Island
            let haveDynamicIsland: Bool = safeArea.top >= 59
            let dynamicIslandWidth: CGFloat = 120
            let dynamicIslandHeight: CGFloat = 36
            let topOffset: CGFloat = 11 + max(safeArea.top - 59, 0)
            // note: different iPhone dynamic island safe area top offset range from 59, 62, 68

            /// expanded properties
            let expandedWidth = size.width - 20
            let expandedHeight: CGFloat = haveDynamicIsland ? 90 : 70
            let scaleX: CGFloat = isExpanded ? 1 : (dynamicIslandWidth / expandedWidth)
            let scaleY: CGFloat = isExpanded ? 1 : (dynamicIslandHeight / expandedHeight)

            ZStack {
                ConcentricRectangle(corners: .concentric(minimum: .fixed(30)),
                                    isUniform: true)
                    .fill(.black)
                    .overlay {
                        toastContent(haveDynamicIsland)
                            /// avoid text wrap and maintain the exact expanded ratio
                            .frame(width: expandedWidth, height: expandedHeight)
                            .scaleEffect(x: scaleX, y: scaleY)
                    }
                    .frame(
                        width: isExpanded ? expandedWidth : dynamicIslandWidth,
                        height: isExpanded ? expandedHeight : dynamicIslandHeight
                    )
                    .offset(y: haveDynamicIsland ? topOffset : (isExpanded ? safeArea.top + 10 : -80))
                    /// for phones without dynamic island
                    .opacity(haveDynamicIsland ? 1 : 0)
                    /// for phones with dynamic island
                    /// showing capsule when the effect is active and hide it when effect is off
                    .animation(.linear(duration: 0.02).delay(isExpanded ? 0 : 0.28)) { content in
                        content.opacity(haveDynamicIsland ? 1 : isExpanded ? 1 : 0)
                    }
                    .geometryGroup()
                    .contentShape(.rect)
                    .gesture(
                        DragGesture().onEnded { value in
                            if value.translation.height < 0 {
                                /// Dismiss
                                window.isPresented = false
                            }
                        }
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea()
            .animation(.bouncy(duration: 0.3, extraBounce: 0), value: isExpanded)
        }
    }

    @ViewBuilder
    func toastContent(_ haveDynamicIsland: Bool) -> some View {
        if let toast = window.toast {
            HStack(spacing: 10) {
                Image(systemName: toast.symbol)
                    .font(toast.symbolFont)
                    .foregroundStyle(toast.symbolForegroundStyle.0, toast.symbolForegroundStyle.1)
                    .symbolEffect(.wiggle, options: .default.speed(1.5), value: isExpanded)
                    .frame(width: 50)

                VStack(alignment: .leading, spacing: 4) {
                    if haveDynamicIsland {
                        Spacer(minLength: 0)
                    }
                    Text(toast.title)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    Text(toast.message)
                        .font(.caption)
                        .foregroundStyle(.white.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, haveDynamicIsland ? 12 : 0)
                .lineLimit(1)
            }
            .padding(.horizontal, 20)
            .compositingGroup()
            .blur(radius: isExpanded ? 0 : 5)
            .opacity(isExpanded ? 1 : 0)
        }
    }

    var isExpanded: Bool {
        window.isPresented
    }
}

#Preview {
    if #available(iOS 26.0, *) {
        ToastDemoView()
    } else {
        // Fallback on earlier versions
    }
}
