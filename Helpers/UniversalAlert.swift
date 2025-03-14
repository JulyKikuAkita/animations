//
//  UniversalAlert.swift
//  animation

import SwiftUI

/// Alert Config
struct AlertConfig {
    fileprivate var enabledBackgroundBlur: Bool = true
    var disableOutsideTap: Bool = true
    var transitionType: TransitionType = .slide
    var slideEdge: Edge = .bottom
    /// Properties for animation
    var show: Bool = true
    var showView: Bool = false

    init(enabledBackgroundBlur: Bool = true,
         disableOutsideTap: Bool = true,
         transitionType: TransitionType = .slide,
         slideEdge: Edge = .bottom)
    {
        self.enabledBackgroundBlur = enabledBackgroundBlur
        self.disableOutsideTap = disableOutsideTap
        self.transitionType = transitionType
        self.slideEdge = slideEdge
    }

    /// TransitionType
    enum TransitionType {
        case slide
        case opacity
    }

    /// Alert Present/Dismiss Methods
    mutating func present() {
        show = true
    }

    mutating func dismiss() {
        show = false
    }
}

struct AlertView<Content: View>: View {
    @Binding var config: AlertConfig
    /// View Tag
    var tag: Int
    @ViewBuilder var content: () -> Content
    /// View properties
    @State var showView: Bool = false
    public var body: some View {
        GeometryReader(content: { _ in
            ZStack {
                if config.enabledBackgroundBlur {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                } else {
                    Rectangle()
                        .fill(.primary.opacity(0.25))
                }
            }
            .ignoresSafeArea()
            .contentShape(.rect)
            .onTapGesture {
                if !config.disableOutsideTap {
                    config.dismiss()
                }
            }
            .opacity(showView ? 1 : 0)

            if showView, config.transitionType == .slide {
                content()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.move(edge: config.slideEdge))
            } else {
                content()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .opacity(showView ? 1 : 0)
            }
        })
        .onAppear(perform: {
            withAnimation((.smooth(duration: 0.35, extraBounce: 0))) {
                config.showView = true
            }
        })
        .onChange(of: config.showView) { _, newValue in
            withAnimation((.smooth(duration: 0.35, extraBounce: 0))) {
                showView = newValue
            }
        }
    }
}

/// Customg Alert View
extension View {
    @ViewBuilder
    func alert(alertConfig: Binding<AlertConfig>, @ViewBuilder content: @escaping () -> some View) -> some View {
        modifier(AlertModifer(config: alertConfig, alertContent: content))
    }
}

/// Alert handling view modifier
struct AlertModifer<AlertContent: View>: ViewModifier {
    @Binding var config: AlertConfig
    @ViewBuilder var alertContent: () -> AlertContent
    /// Scene Delegate
    @Environment(SceneDelegate.self) private var sceneDelegate
    /// View Tag
    @State private var viewTag: Int = 0
    func body(content: Content) -> some View {
        content
            .onChange(of: config.show, initial: false) { _, newValue in
                if newValue {
                    /// Simply call the function we implemented on sceneDelegate
                    sceneDelegate.alert(config: $config, content: alertContent) { tag in
                        viewTag = tag
                    }
                } else {
                    guard let alertWindow = sceneDelegate.overlayWindow else { return }
                    if config.showView {
                        withAnimation(.smooth(duration: 0.35, extraBounce: 0)) {
                            config.showView = false
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            if sceneDelegate.alerts.isEmpty {
                                alertWindow.rootViewController = nil
                                alertWindow.isHidden = true
                                alertWindow.isUserInteractionEnabled = false
                            } else {
                                /// Presenting next alert
                                if let first = sceneDelegate.alerts.first {
                                    ///  Removing the preview view
                                    alertWindow.rootViewController?.view.subviews.forEach { view in
                                        view.removeFromSuperview()
                                    }

                                    alertWindow.rootViewController?.view.addSubview(first)
                                    /// Removing the added alert from the array
                                    sceneDelegate.alerts.removeFirst()
                                }
                            }
                        }
                    } else {
                        print("View is not Appeared")
                        /// Removing the view from the Array with the help of the view tag
                        sceneDelegate.alerts.removeAll(where: { $0.tag == viewTag })
                    }
                }
            }
    }
}

struct CustomAlertDemoView: View {
    /// View properties
    @State private var alert: AlertConfig = .init()
    @State private var alert1: AlertConfig = .init(slideEdge: .top)
    @State private var alert2: AlertConfig = .init(slideEdge: .leading)
    @State private var alert3: AlertConfig = .init(disableOutsideTap: false, slideEdge: .trailing)

    var body: some View {
        Button("Show alert") {
            alert.present()
            alert1.present()
            alert2.present()
            alert3.present()
        }
        .alert(alertConfig: $alert) {
            RoundedRectangle(cornerRadius: 15)
                .fill(.red.gradient)
                .frame(width: 150, height: 150)
                .onTapGesture {
                    alert.dismiss()
                }
        }
        .alert(alertConfig: $alert1) {
            RoundedRectangle(cornerRadius: 15)
                .fill(.blue.gradient)
                .frame(width: 150, height: 150)
                .onTapGesture {
                    alert1.dismiss()
                }
        }
        .alert(alertConfig: $alert2) {
            RoundedRectangle(cornerRadius: 15)
                .fill(.yellow.gradient)
                .frame(width: 150, height: 150)
                .onTapGesture {
                    alert2.dismiss()
                }
        }
        .alert(alertConfig: $alert3) {
            RoundedRectangle(cornerRadius: 15)
                .fill(.orange.gradient)
                .frame(width: 150, height: 150)
                .onTapGesture {
                    alert3.dismiss()
                }
        }
    }
}

#Preview {
    CustomAlertDemoView()
        .environment(SceneDelegate())
}
