//
//  OnBoardingDM.swift
//  onBoarding
//
//  Created on 8/13/25.

import SwiftUI

private struct OnboardingItem: Identifiable {
    var id: Int
    var view: AnyView
    var maskLocation: CGRect
}

@Observable
private class OnBoardingCoordinator {
    var items: [OnboardingItem] = []
    var overlayWindow: UIWindow?
    var isOnBoardingFinished: Bool = false

    var orderedItems: [OnboardingItem] {
        items.sorted { $0.id < $1.id }
    }
}

struct OneTimeOnBoarding<Content: View>: View {
    @AppStorage var isOnBoarded: Bool
    var content: Content
    var beginOnboarding: () async -> Void
    var onBoardingFinished: () -> Void

    init(
        appStorageID: String,
        @ViewBuilder content: @escaping () -> Content,
        beginOnboarding: @escaping () async -> Void,
        onBoardingFinished: @escaping () -> Void
    ) {
        _isOnBoarded = .init(wrappedValue: false, appStorageID)
        self.content = content()
        self.beginOnboarding = beginOnboarding
        self.onBoardingFinished = onBoardingFinished
    }

    fileprivate var coordinator = OnBoardingCoordinator()
    var body: some View {
        content
            .environment(coordinator)
            .task {
                if !isOnBoarded {
                    await beginOnboarding()
                }
            }
            .onChange(of: coordinator.isOnBoardingFinished) { _, newValue in
                if newValue {
                    isOnBoarded = true
                    onBoardingFinished()
                    hideWindow()
                }
            }
    }

    private func createWindow() async {
        if let scene = (UIApplication.shared.connectedScenes.first as? UIWindowScene),
           !isOnBoarded, coordinator.overlayWindow == nil
        {
            if let window = scene.windows.first(where: { $0.tag == 1009 }) {
                /// Removing previews data
                window.rootViewController = nil
                window.isHidden = false
                window.isUserInteractionEnabled = true
                coordinator.overlayWindow = window
            } else {
                let window = UIWindow(windowScene: scene)
                window.backgroundColor = .clear
                window.isHidden = false
                window.isUserInteractionEnabled = true
                window.tag = 1009

                coordinator.overlayWindow = window
            }
            /// delay for loading items to coordinator object using the nGeomtryChange modifer
            try? await Task.sleep(for: .seconds(0.1))
            if coordinator.items.isEmpty {
                hideWindow()
            } else {
                /// Snapshot window and animate it
                guard let snapshot = snapshotScreen() else {
                    hideWindow()
                    return
                }

                let hoseController = UIHostingController(
                    rootView: OverlayWindowView(snapshot: snapshot)
                        .environment(coordinator)
                )
                hoseController.view.backgroundColor = .clear
                coordinator.overlayWindow?.rootViewController = hoseController
            }
        }
    }

    private func hideWindow() {
        coordinator.overlayWindow?.rootViewController = nil
        coordinator.overlayWindow?.isHidden = true
        coordinator.overlayWindow?.isUserInteractionEnabled = false
    }
}

extension View {
    @ViewBuilder
    func onBoarding(_ position: Int, @ViewBuilder content: @escaping () -> some View) -> some View {
        modifier(
            OnBoardingItemSetter(
                position: position,
                onBoardingContent: content
            )
        )
    }
}

private struct OnBoardingItemSetter<OnboardingContent: View>: ViewModifier {
    var position: Int
    @ViewBuilder var onBoardingContent: OnboardingContent

    @Environment(OnBoardingCoordinator.self) var coordinator
    func body(content: Content) -> some View {
        content
            /// adding/removing item to the coordinator
            .onGeometryChange(for: CGRect.self) {
                $0.frame(in: .global)
            } action: { newValue in
                coordinator.items.removeAll(where: { $0.id == position })
                let newItem = OnboardingItem(
                    id: position,
                    view: .init(onBoardingContent),
                    maskLocation: newValue
                )
                coordinator.items.append(newItem)
            }
            .onDisappear {
                coordinator.items.removeAll(where: { $0.id == position })
            }
    }
}

/// Overlay window view (animation view)
private struct OverlayWindowView: View {
    var snapshot: UIImage
    @Environment(OnBoardingCoordinator.self) var coordinator
    /// View Properties
    @State private var animate: Bool = false
    @State private var currentIndex: Int = 0
    var body: some View {
        GeometryReader {
            let safeArea = $0.safeAreaInsets
            let isHomeButtioniPhone = safeArea.bottom == 0
            let cornerRadius: CGFloat = isHomeButtioniPhone ? 15 : 35
            ZStack {
                Rectangle().fill(.black)

                Image(uiImage: snapshot)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .overlay {
                        Rectangle()
                            .fill(.black.opacity(0.5))
                            /// Reverse masking the current tapping location
                            .reverseMask(alignment: .topLeading) {
                                let maskLocation = orderedItems[currentIndex].maskLocation

                                RoundedRectangle(
                                    cornerRadius: 35,
                                    style: .continuous
                                )
                                .frame(
                                    width: maskLocation.width,
                                    height: maskLocation.height
                                )
                                .offset(x: maskLocation.minX, y: maskLocation.minY)
                            }
                            .opacity(animate ? 1 : 0)
                    }
                    .clipShape(
                        .rect(cornerRadius: animate ? cornerRadius : 0, style: .circular)
                    )
                    .overlay {
                        iPhoneShape(safeArea)
                    }
                    .scaleEffect(animate ? 0.65 : 1, anchor: .top)
                    .offset(y: animate ? safeArea.top + 25 : 0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(alignment: .bottom) {
                        bottomView(safeArea)
                    }
                    .background(alignment: .bottom) {
                        bottomView(safeArea)
                    }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            guard !animate else { return }
            withAnimation(.smooth(duration: 0.35)) {
                animate = true
            }
        }
    }

    private func iPhoneShape(_ safeArea: EdgeInsets) -> some View {
        let isHomeButtioniPhone = safeArea.bottom == 0
        let cornerRadius: CGFloat = isHomeButtioniPhone ? 20 : 45

        return ZStack(alignment: .top) {
            RoundedRectangle(
                cornerRadius: animate ? cornerRadius : 0,
                style: .continuous
            )
            .stroke(.white, lineWidth: animate ? 15 : 0)
            .padding(-6)

            /// Dynamic Island for all iphone excpet home-button
            if safeArea.bottom != 0 {
                Capsule()
                    .fill(.black)
                    .frame(width: 120, height: 40)
                    .offset(y: 20)
                    .opacity(animate ? 1 : 0)
            }
        }
    }

    private func bottomView(_ safeArea: EdgeInsets) -> some View {
        VStack(spacing: 10) {
            /// switching between the onboarding items view!
            ZStack {
                ForEach(orderedItems) { info in
                    if currentIndex == orderedItems.firstIndex(where: { $0.id == info.id }) {
                        info.view
                            .transition(.blurReplace)
                            .environment(\.colorScheme, .dark)
                    }
                }
            }
            .frame(height: 70)
            .frame(maxWidth: 280)

            /// continue, back & skip button
            HStack(spacing: 6) {
                if currentIndex > 0 {
                    Button {
                        withAnimation(.smooth(duration: 0.35, extraBounce: 0)) {
                            currentIndex = max(currentIndex - 1, 0)
                        }
                    } label: {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.system(size: 38))
                            .foregroundStyle(.white, .gray.opacity(0.4))
                    }
                }
                Button {
                    if currentIndex == orderedItems.count - 1 {
                        /// Finishing animation and remove window
                        closeWindow()
                    } else {
                        /// Next Index
                        withAnimation(.smooth(duration: 0.35, extraBounce: 0)) {
                            currentIndex += 1
                        }
                    }
                } label: {
                    Text(currentIndex == orderedItems.count - 1 ? "Finish" : "Next")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .contentTransition(.numericText())
                        .foregroundStyle(.white)
                        .padding(.vertical, 10)
                        .background(.blue.gradient, in: .capsule)
                }
            }
            .frame(maxWidth: 250)
            .frame(height: 50)
            .padding(.leading, currentIndex > 0 ? -45 : 0)

            Button(action: closeWindow) {
                Text("Skip Tutorial")
                    .font(.callout)
                    .underline()
            }
            .foregroundStyle(.gray)
        }
        .padding(.horizontal, 15)
        .padding(.bottom, safeArea.bottom + 10)
    }

    private func closeWindow() {
        withAnimation(.easeInOut(duration: 0.25), completionCriteria: .removed) {
            animate = false
        } completion: {
            coordinator.isOnBoardingFinished = true
        }
    }

    var orderedItems: [OnboardingItem] {
        coordinator.orderedItems
    }
}

extension View {
    /// snapshot the screen
    fileprivate func snapshotScreen() -> UIImage? {
        if let screen = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.screen {
            let snapshotView: UIView = screen.snapshotView(afterScreenUpdates: true)
            let renderer = UIGraphicsImageRenderer(size: snapshotView.bounds.size)
            let image: UIImage = renderer.image { _ in
                snapshotView.drawHierarchy(in: snapshotView.bounds, afterScreenUpdates: true)
            }
            return image
        }
        return nil
    }

    /// Reverse Mask
    func reverseMask(alignment: Alignment = .center, @ViewBuilder content: @escaping () -> some View) -> some View {
        mask {
            Rectangle()
                .overlay(alignment: alignment) {
                    content()
                        .blendMode(.destinationOut)
                }
        }
    }
}
